---
layout: post
title: Using Inheritance To Build DSC Resources
---

Today we are going to use inheritance to create multiple resource from a base class.
I'm the first to admit I'm lazy and always trying to get the most bang for my lines of code.
Inheritance is a great way to reduce code duplication and pretty easy once you wrap your head around it.

**The Good Stuff:**
My DSC [FileWatcher module](https://github.com/dchristian3188/FileWatcher) and an example of building resources with inheritance.

<!-- more -->

I'm going to be building off my SmartServiceRestart resource from [this](http://overpoweredshell.com/DSC-Classes-Using-Helper-Methods/) post.
This resource watches a file path and a service.
It then compares the start time of the service against the last write time of the file.
If the file has an older last write time, the service gets restarted.
Its a great tool for services that are not smart enough to automatically reload their configurations.

I liked the idea of having a file watcher that would reload the service and wanted to see if I could apply this logic anywhere else.
I thought it would be cool to have similar resources to manage processes and websites.
Before we look at the new resources, lets examine the original class.

The original resource contained the following methods:

- **GetLastWriteTime** - A helper method to get the last write time of the file(s)
- **GetProcessStartTime** - A helper method to get the start time of the process
- **Get** - Runs both helper methods and returns an instance of the class
- **Test** - Compares the two dates returned by the helper methods and determines who's older
- **Set** - Restarts the service

Looking over the list of methods, the only ones that are specific to a service are the ```GetProcessStartTime``` and the ```Set```.
What that means is we can move the rest of the methods to a base class.
This new base class will have the ```Get```, ```Test``` and ```GetLastWriteTime``` methods.

Now that I have my base defined, I know I only need to create the ```Set``` and ```GetProcessStartTime``` methods for each resource.
The idea is final classes will come together like this:

![_config.yml]({{ site.baseurl }}/images/DSCInheritance/FileWatcherInheritance.png)

We also have to perform this same inventory for the properties / parameters.

All resources will share the below properties:

- **Path** - Path to the folder or files to check
- **Filter** - A filter to apply to the files
- **LastWriteTime** - Non-configurable date time property to store last write time of the file
- **ProcessStartTime** - Non-configurable date time property to store the process start time

The specific parameters for each resource will be considerably different.
Here's a breakdown of the final structure.

![_config.yml]({{ site.baseurl }}/images/DSCInheritance/FIleWatcherInheritanceProperties.png)

With my base class defined, its time to create the new resources.
Since the comparison logic is in the base class, each new resource really only needs to be able to determine when ***Its*** type process started up.

We've already covered the ServiceFileWatcher, so let's take a look at the new ProcessFileWatcher.
This resource is going to have a couple of new parameters.
We will add a parameter for process name, process path (path to the executable), and any startup parameters.

```powershell
[DscResource()]
class ProcessFileWatcher : BaseFileWatcher
{

    [DscProperty(Key)]
    [string]
    $ProcessName

    [DscProperty(Mandatory = $true)]
    [string]
    $ProcessPath

    [DscProperty()]
    [string]
    $ProcessStartArgs
...
```

This is what the ProcessFileWatcher's ```GetProcessStart``` method ended up looking like.
If more than one process matches the name, the resource returns the start time of the oldest.

```powershell
[DateTime]GetProcessStartTime()
{
    Write-Verbose -Message "Checking for process Name: $($this.ProcessName)"
    $processInfo = (Get-CimInstance win32_process -Filter "name='$($this.ProcessName)'")

    if ($processInfo.ProcessId -eq $null)
    {
        Write-Verbose -Message "Could not find a running process, setting start time to min date value"
        $processStart = [datetime]::MinValue
    }
    else
    {
        $processStart = $processInfo |
            Sort-Object -Property CreationDate -Descending |
            Select-Object -ExpandProperty CreationDate -First 1

        Write-Verbose -Message "Process started at: $($processStart)"
    }
    Return $processStart
}
```

The ProcessFileWatcher ```Set``` is a little more tricky.
In this example, we're going to have to kill all process that match that name.
We also need to use the Process path to essentially restart the process.

```powershell
[Void]Set()
{
    $runningProcs = Get-CimInstance win32_process -Filter "name='$($this.ProcessName)'"

    if ($runningProcs)
    {
        Write-Verbose -Message "Stopping running Processes $($runningProcs.ProcessId -join ', ')"
        Stop-Process -ID $runningProcs.ProcessId -ErrorAction Stop -Force
    }

    Write-Verbose -Message "Starting Process [$($this.ProcessName)] at path [$($this.ProcessPath)] with args [$($this.ProcessStartArgs)]"

    $startProcessArgs = @{
        FilePath = $this.ProcessPath
        PassThru = $true
    }
    if (-not([string]::IsNullOrEmpty($this.ProcessStartArgs)))
    {
        $startProcessArgs['ArgumentList'] = $this.ProcessStartArgs
    }
    Start-Process @startProcessArgs
}
```

And that's it!
The whole resource is the properties and the two methods.
Should we make another one?
Next up is the website file watcher.
Here's the single resource specific parameter.

```powershell
[DscResource()]
class WebSiteFileWatcher : BaseFileWatcher
{

    [DscProperty(Key)]
    [string]
    $WebsiteName

...
```

Next we need to define the WebsiteFileWatcher's ```GetProcessStartTime```.
To get this, we first need to find what application pool is running the website.
Once we know this, we can check when the application pool started.

```powershell
[DateTime]GetProcessStartTime()
{

    Write-Verbose -Message "Checking for Application pool running [$($this.WebsiteName)]"
    $websiteInfo = Get-Website -Name $this.WebsiteName

    if(-not($websiteInfo))
    {
        throw "Unable to find website $($this.WebsiteName)"
    }

    Write-Verbose -Message "Checking for process running applicaiton pool [$($websiteInfo.applicationPool)]"

    $AppPoolName = @{
        Name       = 'AppPoolName'
        Expression = {(Invoke-CimMethod -InputObject $PSItem -MethodName 'GetOwner').User}
    }
    $processInfo = (Get-CimInstance win32_process -Filter "name='w3wp.exe'") |
        Select-Object *, $AppPoolName |
        Where-Object -FilterScript {$PSItem.AppPoolName -eq $($websiteInfo.applicationPool)}

    if (($processInfo.ProcessId -eq 0) -or $processInfo -eq $null)
    {
        Write-Verbose -Message "Could not find a running process, setting start time to min date value"
        $processStart = [datetime]::MinValue
    }
    Else
    {
        $processStart = $processInfo.CreationDate
        Write-Verbose -Message "Process started at: $($processStart)"
    }
    Return $processStart
}
```

Next up is the WebsiteFileWatchers ```Set``` method.
First step is to find the application pool running the site.
Once we have this, we can restart the app pool.
Now, this could cause trouble if you have websites or web applications sharing the same application pool.
Good thing nobody does that.

```powershell
[Void]Set()
{
    $webInfo = Get-Website -Name $this.WebsiteName
    Write-Verbose -Message "Restarting Application pool [$($webInfo.applicationPool)]"
    Restart-WebAppPool -Name $webInfo.applicationPool
}
```

And we're done with the Website watcher.
I hope this helped highlight some of the power of inheritance.
With a little bit of planning we were able to turn one resource into three!
The completed resource is [here.](https://github.com/dchristian3188/FileWatcher)
Once I finish up the remaining Pester tests, I plan to submit the module to the gallery.
