<!-- TOC -->

- [A More Complex Example](#a-more-complex-example)
    - [Overview](#overview)
    - [Properties](#properties)
    - [Helper Methods](#helper-methods)
    - [Big Three Methods](#big-three-methods)
- [Debugging A Class-Based Resource](#debugging-a-class-based-resource)
    - [Debug The Class](#debug-the-class)

<!-- /TOC -->
# A More Complex Example
## Overview
I came across this use case for work.
One of our services had a config file that we were managing through DSC.
Unfortunately the service was not smart enough to reload the configuration if this file change.
THe only way for the new config to be applied was to restart the service. 
It seemed heavy handed to restart every DSC run, so this resource was created.
It takes a Service name, a file path and optionally a filter. 
If the file has a newer write time than the service start time, the service will be restarted.
## Properties
Let's start by defining our resource and parameters.
I created two ```NotConfigurable``` properties to store the date times we're comparing.
```powershell
[DscResource()]
class SmartSeviceRestart
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
Since we need to retrieve the same information from both the ```Get``` and ```Test``` method, it just makes sense to move this logic to their own helper methods.
First we start with a ```[DateTime]``` method that will get the last write time for our file.
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
        Write-Verbose -Message "No lastwrite time found. Setting to min date"
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
[SmartSeviceRestart]Get()
{        
    $this.ProcessStartTime = $this.GetProcessStartTime()
    $this.LastWriteTime = $this.GetLastWriteTime()
    return $this
} 
```
Next we our ```Test```.
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
The set method couldn't be easier.
```powershell
[Void]Set()
{
    Restart-Service -Name $this.ServiceName -Force
}
```
# Debugging A Class-Based Resource
## Debug The Class
It took me a while to realize this one. 
Since the resource was defined as a PowerShell Class, it's available to us just like any other type is. 
What that means is we can debug this just like we do any other class.
When initially designing a resource, this is my preferred approach.
Usually at initial design I have my resource saved in a ```.ps1``` file. 
Its not till module compilation time that all files are combined into the finished ```.psm1```.
With our class defined, I'll set a breakpoint to the method in question.
Next all we have to do is create an instance of the class, and run the method. 
I also like to set ```$VerbosePreference = 'Continue'``` to see as much information as possible.
```powershell
$ogVerbosePerf = $VerbosePreference
$VerbosePreference = 'Continue'
$sw = [SmartSeviceRestart]::new()
$sw.ServiceName = 'Spooler'
$sw.Path = 'C:\Temp\test.txt'
$sw.Test()
$VerbosePreference = $ogVerbosePerf
```
![debug](https://github.com/dchristian3188/dchristian3188.github.io/blob/master/images/classDebugGif.gif)