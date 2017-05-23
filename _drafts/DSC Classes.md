---
layout: post
title: DSC Class-Based Resources
---
Now that we know what a PowerShell class is, it's time we start putting them to use.
Classes are new with version 5 and one of the best places for them is DSC. 
While the syntax maybe different, all the DSC concepts are the same. 
**The Good Stuff**: How to create a DSC Class-Based Resource
<!-- TOC -->

- [Declaring a Resource](#declaring-a-resource)
    - [Resource Parameters - Properties](#resource-parameters---properties)
        - [DscProperty - Key](#dscproperty---key)
        - [DscProperty - Mandatory](#dscproperty---mandatory)
        - [DscProperty - NotConfigurable](#dscproperty---notconfigurable)
    - [The Big Three Methods](#the-big-three-methods)
        - [Get](#get)
        - [Test](#test)
        - [Set](#set)
- [Creating The Module Structure](#creating-the-module-structure)
    - [Module Manifest](#module-manifest)
    - [PSM1 Module](#psm1-module)
- [Working With The Resource](#working-with-the-resource)
    - [Checking Syntax](#checking-syntax)
    - [Creating a Configuration](#creating-a-configuration)
- [A More Complex Example](#a-more-complex-example)
    - [Overview](#overview)
    - [Properties](#properties)
    - [Helper Methods](#helper-methods)
    - [Big Three Methods](#big-three-methods)
- [Debugging A Class-Based Resource](#debugging-a-class-based-resource)
    - [Debug The Class](#debug-the-class)
- [Wrapping Up](#wrapping-up)

<!-- /TOC -->
# Declaring a Resource
The first example for today will be a resource to update the drive label.
To define our new resource, we start by creating a class.
The only difference is, just before the class declaration we're going to add the ```[DSCResource]``` attribute.
```powershell
[DscResource()]
class DriveLabel
{

}
```
## Resource Parameters - Properties
Resource parameters are just properties to the DSC class. 
In this example, we are going to add a ```DriveLetter``` and ```Label``` parameter.
Just like any class, we will prefix these properties with their types.
```powershell
[DscResource()]
class DriveLabel
{
    [string]
    $DriveLetter

    [string]
    $Label
}
```
### DscProperty - Key
We want to prevent the user from trying to define two labels for the same drive. 
To accomplish this, we'll assign the ```$DriveLabel``` property the ```DscProperty(Key)]``` attribute.
This key attribute uniquely identifies the an instance of the DSC resource.
This is important because we cannot have multiple DSC resources in a configuration share the same key.
At least one parameter in the class will need to have the attribute of ```[DscProperty(Key)]```.
```powershell
class DriveLabel
{
    [DscProperty(Key)]
    [string]
    $DriveLetter

    [string]
    $Label
}
```
### DscProperty - Mandatory
Assigning a property the ```[DscProperty(Mandatory)]``` attribute does exactly what it sounds like.
We can use this attribute when we want to ensure our user sets this value in their configuration.
For our example below, we will tag the ```$Label``` parameter mandatory.
```powershell
class DriveLabel
{
    [DscProperty(Key)]
    [string]
    $DriveLetter

    [DscProperty(Mandatory)]
    [string]
    $Label
}
```
### DscProperty - NotConfigurable
The ```[DscProperty(NotConfigurable)]``` attribute is used in a couple of scenarios.
The first is if we want to include additional information to our user in the ```Get``` Method.
This can be helpful for reporting purposes.
Here we'll add a new property for the filesystem type.
Our ```Get``` method will then populate this property before returning it back to the user. 
Since this new property is ```NotConfigurable``` it will not be a parameter to the resource.
```powershell
[DscResource()]
class DriveLabel
{
    [DscProperty(Key)]
    [string]
    $DriveLetter

    [DscProperty(Mandatory)]
    [string]
    $Label

    [DscProperty(NotConfigurable)]
    [string]
    $FileSystemType
}
```
The next big scenario to use a ```NotConfigurable``` property is when two methods need to share information. 
The advanced example in the later in this article will provide an example of this. 
## The Big Three Methods
All DSC Class-Based resources must override the next three methods. 
Each of these methods should be implemented with no parameters.
### Get
The main responsibility of the ```Get``` method is to check the current state of the resource. 
When defining the ```Get``` method, prefix it with the type of the class.
Once all processing is complete, return ```$this```. 
Here's what that would look like for our drive label example.
```powershell
[DscResource()]
class DriveLabel
{
...
    [DriveLabel]Get()
    {
        $volumeInfo = Get-Volume -DriveLetter $this.DriveLetter
        $this.Label = $volumeInfo.FileSystemLabel
        $this.FileSystemType = $volumeInfo.FileSystemType
        return $this
    }
...
}
```
### Test
This ```Test``` method is responsible for checking if this current state matches our desired state.
When defining the ```Test``` method make sure it has a return type of ```[bool]```.
Below we will test if the drive label matches the user supplied value.
```powershell
[DscResource()]
class DriveLabel
{
...
    [bool]Test()
    {
        $labelCorrect = Get-Volume -DriveLetter $this.DriveLetter |
            Where-Object -FilterScript {$PSItem.FileSystemLabel -eq $this.Label}
        if($labelCorrect)
        {
            return $true
        }
        else
        {
            return $false
        }
    }
...
}
```
### Set
The ```Set``` method needs to enforce our actual desired state.
Considering we are not expecting output, this method should be prefixed with the ```[void]``` type.
In our current example, we will use the ```Set-Volume``` cmdlet to update the label.
```powershell
[DscResource()]
class DriveLabel
{
...
    [void]Set()
    {
        Write-Verbose -Message "Adding label [$($this.Label)] to [$($this.DriveLetter)] Drive"
        Get-Volume -DriveLetter $this.DriveLetter  |
            Set-Volume -NewFileSystemLabel $this.Label
    }
}
```
# Creating The Module Structure
The structure of a DSC Classed-Based resource is the same as any other module.
First we'll need a new directory to hold the contents of our module.
```powershell
New-Item -Path DCDisk -ItemType Directory
```
## Module Manifest
Inside of the new directory we need to create a module manifest. 
My list of parameters gets a little long so I like to create a hashtable and splat them into ```New-ModuleManifest```.
Notice the ```DscResourcesToExport``` key?
Remember that as you add resources to a module, this needs to be updated inside of the manifest.
```powershell
$manifestProperties = @{
    Path = 'DCDisk.psd1'
    RootModule = 'DCDisk.psm1'
    Author = 'David Christian'
    Description = 'Custom module for disk related DSC resources'
    PowerShellVersion = '5.0'
    DscResourcesToExport = 'DriveLabel'
    CompanyName = 'OverPoweredShell.com'
    Verbose = $true
}

New-ModuleManifest @manifestProperties
```
## PSM1 Module
Next we'll create a new psm1 named ```DCDisk.psm1```.
Here we'll place our completed class.
```powershell
[DscResource()]
class DriveLabel
{
    [DscProperty(Key)]
    [string]
    $DriveLetter

    [DscProperty(Mandatory)]
    [string]
    $Label

    [DscProperty(NotConfigurable)]
    [string]
    $FileSystemType

    [DriveLabel]Get()
    {
        $volumeInfo = Get-Volume -DriveLetter $this.DriveLetter
        $this.Label = $volumeInfo.FileSystemLabel
        $this.FileSystemType = $volumeInfo.FileSystem
        return $this
    }

    [bool]Test()
    {
        $labelCorrect = Get-Volume -DriveLetter $this.DriveLetter |
            Where-Object -FilterScript {$PSItem.FileSystemLabel -eq $this.Label}
        
        if($labelCorrect)
        {
            return $true
        }
        else
        {
            return $false
        }
    }

    [void]Set()
    {
        Write-Verbose -Message "Adding label [$($this.Label)] to [$($this.DriveLetter)] Drive"
        Get-Volume -DriveLetter $this.DriveLetter  |
            Set-Volume -NewFileSystemLabel $this.Label
    }
}
```
With these two files saved, we can place the entire folder in our module directory. 
# Working With The Resource
## Checking Syntax
Now let's see if our resource is properly registered.
To do this, we can call the ```Get-DscResource``` cmdlet.
I also include the ```Syntax``` switch to inspect the parameters.
Two birds one stone.
```powershell
Get-DscResource -Name DriveLabel -Syntax
```
Output:
```powershell
DriveLabel [String] #ResourceName
{
    DriveLetter = [string]
    Label = [string]
    [DependsOn = [string[]]]
    [PsDscRunAsCredential = [PSCredential]]
}
```
## Creating a Configuration
Ok moment of truth. 
Lets create a new configuration to test the new resource.
```powershell
configuration DiskConfig
{
    Import-DscResource -ModuleName DCDisk
    node ("localhost")
    {
        DriveLabel CDrive
        {
            DriveLetter = 'C'
            Label = 'OperatingSystem'
        }
    }
}
```
The only thing left to do, is run the config.
The below commands will create the localmof in the ```C:\PS``` directory.
```powershell
New-Item -ItemType Directory -Path C:\PS -Verbose -ErrorAction SilentlyContinue
Push-Location -Path C:\PS
DiskConfig
Start-DscConfiguration .\DiskConfig -Verbose -Wait -Force 
Pop-Location 
```
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

# Wrapping Up
PowerShell class FTW.
