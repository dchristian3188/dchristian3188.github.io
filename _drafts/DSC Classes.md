---
layout: post
title: DSC Class-Based Resources
---
Now that we know what a PowerShell class is, it's time we start putting them to use.
Classes are new with version 5 and one of the best places for them is DSC. 
While the syntax maybe different, all the DSC concepts are the same.
If you need a refresher on the basics of a PowerShell class, please see my previous post, [Intro to PowerShell Classes.](http://overpoweredshell.com/Introduction-to-PowerShell-Classes/)
**The Good Stuff**: How to create a DSC Class-Based Resource.
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
- [Wrapping Up](#wrapping-up)

<!-- /TOC -->
# Declaring a Resource
The example for today will be a resource to update the drive label.
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
To accomplish this, we'll assign the ```$DriveLabel``` parameter the ```[DscProperty(Key)]``` attribute.
This key attribute uniquely identifies the instance of a DSC resource.
This is important because we cannot have multiple DSC resources in a configuration share the same key.
When creating our own resources, we must define at least one parameter as the key field.
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
Assigning a parameter the ```[DscProperty(Mandatory)]``` attribute does exactly what it sounds like.
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
This use case will be covered in an upcoming post. 
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
The ```Test``` method is responsible for checking if this current state matches our desired state.
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
First we'll need a new directory to hold all of our files.
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
With these two files saved, we can place the entire folder in our module directory, ```"$Env:ProgramFiles\WindowsPowerShell\Modules\"```
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
Let's create a new configuration to test the new resource.
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
The below commands will create the localhost mof in the ```C:\PS``` directory and then execute it.
```powershell
New-Item -ItemType Directory -Path C:\PS -Verbose -ErrorAction SilentlyContinue
Push-Location -Path C:\PS
DiskConfig
Start-DscConfiguration .\DiskConfig -Verbose -Wait -Force 
Pop-Location 
```
Here's a screen shot of our resource in action.
![_config.yml]({{ site.baseurl }}/images/dscClassesRun.png)

Also, remember since we set our ```NotConfigurable``` it will be returned in our ```Get```
![_config.yml]({{ site.baseurl }}/images/dscClassesGet.png)
# Wrapping Up
Thats really it for a basic DSC Class-Based resource.
I hope this post was helpful and points you in the right direction creating your own resources.
Stay on the look out for an upcoming post where we'll cover a more advanced example. 