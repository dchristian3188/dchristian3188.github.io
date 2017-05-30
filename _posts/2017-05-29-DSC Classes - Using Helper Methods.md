---
layout: post
title: DSC Classes - Using Helper Methods
---
This is going to be part two on DSC Classes.
Today we are going to cover a resource with more than the standard ```Get```,```Set``` and ```Test``` methods.
Helper methods are a great way to organize your resource.
By making use of class properties and methods, we can create a clean resource with no code duplication.

**The Good Stuff:**
Use helper functions to organize your Class-Based resources.
<!-- more -->

# Overview

I came across the use case for this resource at work.
One of our services had a config file that we were managing through DSC.
The service was not smart enough to reload the configuration if this file change.
In fact, the configuration is only applied when the service starts.
It seemed heavy handed to restart the service every time DSC ran, hence the creation of this resource.
It takes a Service name, a file path and optionally a filter.
If the file has a newer write time than the service start time, the service gets restarted.

## Properties

Let's start by defining our resource and parameters.
We are going to create a couple of properties, ```$ProcessStartTime``` and ```$LastWriteTime```  to track the dates we'll be comparing.
We are also going to add the ```NotConfigurable``` attribute to these properties.
This will prevent the user from seeing them as parameters but still make them available to our methods.
Plus it has an added benefit for reporting.
When the ```Get``` method runs, it'll populate these properties.
If we have DSC reporting in place, we can track these changes over time.

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
    [Nullable[dateTime]]
    $ProcessStartTime

    [DscProperty(NotConfigurable)]
    [Nullable[dateTime]]
    $LastWriteTime
...
```

## Helper Methods

Since we need to retrieve the same information from both the ```Get``` and ```Test``` methods, it made sense to move this logic to helper functions.
When working with Class-Based resources we can define an unlimited number of helper functions.
The only requirement, is they all must have a unique [method signature](http://overpoweredshell.com/Introduction-to-PowerShell-Classes/#method-signature).
DSC also doesn't care as long as it's big three methods work.
In this example I start with a ```[dateTime]``` method that will get the last write time for our file.

```powershell
[dateTime]GetLastWriteTime()
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
        $lastWrite = [dateTime]::MinValue
    }

    Write-Verbose -Message "Last write time: $lastWrite"
    return $lastWrite
}
```

Next we need to find the process start time of the service.
This ones a little more tricky since we first need to find the process ID that it spawned.
After checking a couple of CIM classes, we return another ```[dateTime]```.

```powershell
[dateTime]GetProcessStartTime()
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
        $processStart = [dateTime]::MinValue
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

With the new helper methods in place, the big three are pretty straight forward.
Our ```Get``` method will call the two helper functions to populate ```$this```.

```powershell
[SmartServiceRestart]Get()
{
    $this.ProcessStartTime = $this.GetProcessStartTime()
    $this.LastWriteTime = $this.GetLastWriteTime()
    return $this
}
```

Our ```Test``` method also calls these helper functions.
Here we compare our two times and check if we need to restart the service.

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

Our set method is one line.
Its kind of a cheat since the heavy lifting and checks happen in the other methods.
Quick for a million points, whats the command to restart a service.

```powershell
[Void]Set()
{
    Restart-Service -Name $this.ServiceName -Force
}
```

# Wrapping up

[Here's](https://github.com/dchristian3188/Main/tree/master/DSC/SmartServiceRestart) a link to the completed module for the resource.
Our next post in the DSC Class series will cover troubleshooting.
As always, hope this post was helpful and gets you further along on your DSC journey.

* Part 1: [Creating A DSC Class-Based Resource](http://overpoweredshell.com/Creating-A-DSC-Class-Based-Resource/)
* Part 2: [DSC Classes - Using Helper Methods](http://overpoweredshell.com/DSC-Classes-Using-Helper-Methods/)
* Part 3: TroubleShooting DSC (Coming Soon)

**Disclaimer:** all points are made and don't matter.
