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
If the file has a later last write time, the service gets restarted.
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
Here's what that would look like.

```powershell
class BaseFileWatcher
{
    [DscProperty(Mandatory)]
    [String[]]
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

    [BaseFileWatcher]Get()
    {
        $this.ProcessStartTime = $this.GetProcessStartTime()
        $this.LastWriteTime = $this.GetLastWriteTime()
        Return $this
    }

    [Bool]Test()
    {
        If (-not($this.ProcessStartTime))
        {
            $this.ProcessStartTime = $this.GetProcessStartTime()
        }

        If (-not($this.LastWriteTime))
        {
            $this.LastWriteTime = $this.GetLastWriteTime()
        }

        If ($this.ProcessStartTime -ge $this.LastWriteTime)
        {
            Write-Verbose -Message "Process has a later start time. No action will be taken"
            Return $true
        }
        Else
        {
            Write-Verbose -Message "One or more files has a later start time. The process will be restarted."
            Return $false
        }
    }

    [DateTime]GetLastWriteTime()
    {
        $getSplat = @{
            Path = $this.Path
            Recurse = $true
        }

        Write-Verbose -Message "Checking Path: $($this.Path -join ", ")"
        If ($this.Filter)
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
}
```