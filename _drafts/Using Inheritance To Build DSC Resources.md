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
This resource watched a file path and a service.
It would then compare the start time of the service against the last write time of the file.
if the file has a later last write time, the service gets restarted.
Its a great tool for services that are not smart enough to automatically reload their configurations.

I liked the idea of having a file watcher that would reload the service and wanted to see if I could apply this logic anywhere else.
I thought it would be cool to have a similar resource to manage processes and websites.
Before we look at the new resources, lets examine the original class.

The original resource contained the following methods:

- **GetLastWriteTime** - A helper method to get the last write time of the file(s)
- **GetProcessStartTime** - A helper method to get the start time of the process
- **Get** - Ran all helper methods and return an instance
- **Test** - Compared the to helper methods to determine who was older
- **Set** - Restarted a service

Looking over the list of methods, the only ones that are specific to a service are the ```GetProcessStartTime``` and the ```Set```.
What that means is we can move the rest of the methods to a base class.
This new base class will have the ```Get```, ```Test``` and ```GetLastWriteTime```.

Now that I have my base defined, I know I only need to create the ```Set``` and ```GetProcessStartTime``` methods for each resource.
The idea is final classes will come together like this:

![_config.yml]({{ site.baseurl }}/images/DSCInheritance/FileWatcherInheritance.png)

We also have to perform this same inventory the properties / parameters.
All resources share the below properties.

- **Path** - Path to the folder or files to check
- **Filter** - A filter to apply to the files
- **LastWriteTime** - Date time property to store last write time of the file
- **ProcessStartTime** - Date time property to store the process start time

The specific parameters for each resource will be considerably different.
Here's a breakdown of the final structure.

![_config.yml]({{ site.baseurl }}/images/DSCInheritance/FIleWatcherInheritanceProperties.png)

During development I like to create a separate PS1 for every class and resource.
I feel that this structure is the cleanest and easiest to manage in source.
Here is a snippet of what that module structure looks like.

```powershell
C:.
│   .gitignore
│   FileWatcher.build.ps1
│   FileWatcher.psd1
│   FileWatcher.psm1
│
├───.vscode
│       settings.json
│
├───Classes
│       BaseFileWatcher.ps1
│
├───DSCResources
│       ProcessFileWatcher.ps1
│       ServiceFileWatcher.ps1
│       WebsiteFileWatcher.ps1

...
```

With my base class defined, its time to create the new resources. 
Since all of the comparison logic is in the base class, each new resource just needs to identify its specific information.

We've already covered the ServiceFileWatcher, so let's take a look at the new ProcessFileWatcher.
This resource is going to have a couple of new parameters.
We are going to need to have the process name, a path to the processes executable and any startup parameters.

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
if more than one process matches the name, the resource returns the start time of the oldest.

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
Lets make another one.
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
Once we know this, we can check when the app pool started.

```powershell
[DateTime]GetProcessStartTime()
{

    Write-Verbose -Message "Checking for Application pool running [$($this.WebsiteName)]"
    $websiteInfo = Get-Website -Name $this.WebsiteName

    if(-not($websiteInfo))
    {
        throw "Unable to find website $($this.WebsiteName)"
    }

    Write-Verbose -Message "Checking for process running applicaiton pool: $($websiteInfo.applicationPool)"

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


This does create some challenges.
The biggest is that PowerShell throws a parse error when a class is defined in a script that references an external type.
The PowerShell team is tracking the issue [here.](https://github.com/PowerShell/PowerShell/issues/3641)

To work around this, I have an Invoke-Build script that compiles the files into a completed PS1 and then runs the Pester tests. 