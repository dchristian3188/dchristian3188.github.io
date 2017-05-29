---
layout: post
title: DSC Classes - Using Helper Methods and Troubleshooting
---
Today we are going to cover a resource with more than the standard ```Get```,```Set``` and ```Test```.
Since there's more methods, there's more chance for something to go wrong.
While I know everyone out there writes perfect code first try, I am not so lucky.
I'm a little superstitious but I think if your code works first try, its bad luck.
With that in mind, we'll define our new resource, and jump straight into some tips on troubleshooting.

**The Good Stuff:**
DSC Class-Based Resources and troubleshooting tips.
<!-- more -->

<!-- TOC -->

- [Overview](#overview)
    - [Properties](#properties)
    - [Helper Methods](#helper-methods)
    - [Big Three Methods](#big-three-methods)
- [Debugging A Class-Based Resource](#debugging-a-class-based-resource)
    - [Debug The Class](#debug-the-class)
        - [Define The Class](#define-the-class)
        - [Turn On Verbosity](#turn-on-verbosity)
        - [Create An Instance And Set Parameters](#create-an-instance-and-set-parameters)
        - [Debug the Method](#debug-the-method)

<!-- /TOC -->

# Overview

I came across the use case for this resource at work.
One of our services had a config file that we were managing through DSC.
The service was not smart enough to reload the configuration if this file change.
In fact, the configuration was only applied at service start time.
It seemed heavy handed to restart the service every time DSC ran.
Hence the creation of this resource.
It takes a Service name, a file path and optionally a filter.
If the file has a newer write time than the service start time, the service is restarted.

## Properties

Let's start by defining our resource and parameters.
I'm going to need to keep track of multiple times so I create properties for them.
Both of these are created with the ```NotConfigurable``` attribute since I don't want the user to be able to set them.

```powershell
[DscResource()]
class SmartServiceRestart
{

    [DscProperty(Key)]
    [string]
    $ServiceName

    [DscProperty(Mandatory)]
    [string[]]
    $Path

    [DscProperty()]
    [String]
    $Filter

    [DscProperty(NotConfigurable)]
    [Nullable[datetime]]
    $ProcessStartTime

    [DscProperty(NotConfigurable)]
    [Nullable[datetime]]
    $LastWriteTime
...
```

## Helper Methods

Since we need to retrieve the same information from both the ```Get``` and ```Test``` methods, it made sense to move this logic to helper functions.
When working with Class-Based resources we can define as many helper functions as we need.
DSC doesn't care as long as it's big three methods work.
In this example I start with a ```[DateTime]``` method that will get the last write time for our file.

```powershell
[DateTime]GetLastWriteTime()
{
    $getSplat = @{
        Path = $this.Path
        Recurse = $true
    }

    Write-Verbose -Message "Checking Path: $($this.Path -join ", ")"
    if ($this.Filter)
    {
        Write-Verbose -Message "Using Filter: $($this.Filter)"
        $getSplat["Filter"] = $this.Filter
    }

    $lastWrite = Get-ChildItem @getSplat |
        Sort-Object -Property LastWriteTime |
        Select-Object -ExpandProperty LastWriteTime -First 1

    if (-not($lastWrite))
    {
        Write-Verbose -Message "No last write time found. Setting to min date"
        $lastWrite = [datetime]::MinValue
    }

    Write-Verbose -Message "Last write time: $lastWrite"
    return $lastWrite
}
```

Next we need to find the process start time of the service. 
To do this, we first need to get the process id that's running the service.

```powershell
[DateTime]GetProcessStartTime()
{
    $service = Get-CimInstance -ClassName Win32_Service -Filter "Name='$($this.ServiceName)'" -ErrorAction Stop
    if (-not($service))
    {
        Throw "Could not find a service with name: $($this.ServiceName)"
    }

    Write-Verbose -Message "Checking for process id: $($service.ProcessId)"
    $processInfo = (Get-CimInstance win32_process -Filter "processid='$($service.ProcessId)'")

    if ($processInfo.ProcessId -eq 0)
    {
        Write-Verbose -Message "Could not find a running process, setting start time to min date value"
        $processStart = [datetime]::MinValue
    }
    else
    {
        $processStart = $processInfo.CreationDate
        Write-Verbose -Message "Process started at: $($processStart)"
    }
    return $processStart
}
```

## Big Three Methods

With the new helper methods in place the big three are pretty straight forward.
Below is our ```Get```.

```powershell
[SmartServiceRestart]Get()
{
    $this.ProcessStartTime = $this.GetProcessStartTime()
    $this.LastWriteTime = $this.GetLastWriteTime()
    return $this
}
```


Next our ```Test``` method.

```powershell
[bool]Test()
{
    $this.ProcessStartTime = $this.GetProcessStartTime()
    $this.LastWriteTime = $this.GetLastWriteTime()

    Write-Verbose -Message "PID: [$($this.ProcessStartTime)]. File Last Write Time: [$($this.LastWriteTime)]"
    if ($this.ProcessStartTime -gt $this.LastWriteTime)
    {
        return $true
    }
    else
    {
        return $false
    }
}
```

And the set method couldn't be easier, its just a ```Restart-Service```.

```powershell
[Void]Set()
{
    Restart-Service -Name $this.ServiceName -Force
}
```

# Debugging A Class-Based Resource

## Debug The Class

It took me a while to realize this one.
Since the resource is defined as a PowerShell Class, it's available to us like any other type is.
What that means is we can debug this like we do any other class.
When initially designing a resource, this is my preferred approach.
At initial design I have my resource saved in a ```.ps1``` file.
Its not till module compilation time that all files are combined into the finished ```.psm1```.
This is import because the below commands will not work if the file extension is ```psm1```.
Alright with that out of the way, lets debug our class.

### Define The Class

First thing I do, is place a copy of the completed class in a ```.ps1``` file.
You can also place the complete class in a separate ```.ps1``` file and then dot source / use ```Import-Module``` on it.
Personally, I like keeping everything it one file, but both approaches work.
With the completed class defined, place a breakpoint on the method in question.

### Turn On Verbosity

I try to be good about my verbose messages in DSC resources.
One because I want the end user to know whats going on, but also for me when troubleshooting.
Since we will be interacting with the class directly, there's no ```-Verbose``` switch to add.
If we want to see our messages we need to adjust the ```VerbosePreference``` variable.
I use the below snippet to save the original value of ```VerbosePreference```.
My plan is to restore this value at the end of my debugging.

```powershell
$ogVerbosePerf = $VerbosePreference
$VerbosePreference = 'Continue'
```

### Create An Instance And Set Parameters

With the setup out of the way, we need to create a new instance of the class.
I'll use the dot net constructor here, but ```New-Object``` would also work.
Once the class is created, the resource parameters can then be assigned.
Parameters are assigned directly to object as properties.

```powershell
$sw = [SmartServiceRestart]::new()
$sw.ServiceName = 'Spooler'
$sw.Path = 'C:\Temp\test.txt'
```

### Debug the Method

I double check my breakpoint is place on the method and then run the method from my object.
At this point its my traditional debugging experience.
Here's what the code would look like to execute the ```Test``` method and restore my ```VerbosePreference```.


```powershell
$sw.Test()
$VerbosePreference = $ogVerbosePerf
```

Once you get into the debugger its no different then working with any other function.
Here's a screen shot of it in action in VSCode (any editor with a debugger will work).
![debug](https://github.com/dchristian3188/dchristian3188.github.io/blob/master/images/classDebugGif.gif)