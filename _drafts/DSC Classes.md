---
layout: post
title: DSC Class-Based Resources
---
Now that we know what a PowerShell class is, it's time we start using them.
DSC Classes are new with version 5.
While the syntax maybe different, all the concepts are the same. 
**The Good Stuff** How to create a DSC Class-Based Resource
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
- [Working with the resource](#working-with-the-resource)
    - [Checking syntax](#checking-syntax)
    - [Creating a Configuration](#creating-a-configuration)

<!-- /TOC -->
# Declaring a Resource
The first example for today will be a resource to set the drive label.
To define our new resource, we start by create a class.
However, before the class declaration we're going to add the ```[DSCResource]``` attribute.
```powershell
[DscResource()]
class DriveLabel
{

}
```
## Resource Parameters - Properties
Resource parameters are just properties to the DSC class. 
In this example, we are going to add a ```DriveLetter``` and ```Label``` parameter.
Just like any class, we will prefix these variables with their types.
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
The key property uniquely identifies an instance of the DSC resource.
This is important because we cannot have multiple DSC resources in a configuration with the same key property.
When creating our own resources, at least one parameter in the class will need to have the attribute of ```[DscProperty(Key)]```.
Since we don't want the user to have two resources with the same drive letter in a configuration we'll assign it the ```[DscProperty(Key)]``` attribute.
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
We can use this attribute when we want to ensure our user set this value in their configuration.
For our example below, we will mark the ```$Label``` parameter mandatory.
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
### DscProperty - NotConfigurable
The ```[DscProperty(NotConfigurable)]``` attribute is used in a couple of scenarios.
The first is if we want to include additional information to our user in the ```Get``` Method.
We'll add a new property to the class for the filesystem type. 
Since this new property has the ```[DscProperty(NotConfigurable)]``` attribute, it will not be a parameter to the resource.
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
The next big scenario to use a NotConfigurable property is when two help methods need to share information. 
The advanced example in the second half of this article will provide an example of this. 
## The Big Three Methods
All DSC Class-Based resources must implement the next three methods. 
Each of these methods should be implemented with no parameters.
### Get
The get method must return a type of the current class. 
This means the last thing in our ```Get``` method should be the variable ```$this```.
The main responsibility of the ```Get``` method is to check the current state of the resource. 
Here's what that would look like for our drive label example.
```powershell
[DscResource()]
class DriveLabel
{
...
    [DriveLabel]Get()
    {
        $this.DriveLetter
        $volumeInfo = Get-Volume -DriveLetter $this.DriveLetter
        $this.Label = $volumeInfo.FileSystemLabel
        $this.FileSystemType = $volumeInfo.FileSystemType
        return $this
    }
...
}
```
### Test
This method is responsible for checking if this current state matches our desired state.
The ```Test``` method must return the type of ```[boo]```.
Below we will test if the drive label matches the value the user supplied.
If it doesn't we will return ```$false``` for this method.
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
The set method should return the type of ```[void]```.
This resource is response for correcting the current state.
```powershell
[DscResource()]
class DriveLabel
{
...
    [void]Set()
    {
        Get-Volume -DriveLetter $this.DriveLetter  |
            Set-Volume -NewFileSystemLabel $this.Label
    }
}
```
# Creating The Module Structure
The first thing we'll need is a new folder for our module.
```powershell
New-Item -Path DCDisk -ItemType Directory
```
## Module Manifest
GO TRY PLASTER.
Next we need to create a module manifest. 
We can use the same ```New-ModuleManifest```.
Let's see what's available to us.
```powershell
Get-Command -Name New-ModuleManifest -Syntax
```
Output:
```powershell
New-ModuleManifest [-Path] <string> [-NestedModules <Object[]>] [-Guid <guid>] [-Author <string>] [-CompanyName <string>] [-Copyright <string>] [-RootModule <string>] [-ModuleVersion <version>] [-Description <string>] [-ProcessorArchitecture <ProcessorArchit
ecture>] [-PowerShellVersion <version>] [-ClrVersion <version>] [-DotNetFrameworkVersion <version>] [-PowerShellHostName <string>] [-PowerShellHostVersion <version>] [-RequiredModules <Object[]>] [-TypesToProcess <string[]>] [-FormatsToProcess <string[]>] [-
ScriptsToProcess <string[]>] [-RequiredAssemblies <string[]>] [-FileList <string[]>] [-ModuleList <Object[]>] [-FunctionsToExport <string[]>] [-AliasesToExport <string[]>] [-VariablesToExport <string[]>] [-CmdletsToExport <string[]>] [-DscResourcesToExport <
string[]>] [-CompatiblePSEditions <string[]>] [-PrivateData <Object>] [-Tags <string[]>] [-ProjectUri <uri>] [-LicenseUri <uri>] [-IconUri <uri>] [-ReleaseNotes <string>] [-HelpInfoUri <string>] [-PassThru] [-DefaultCommandPrefix <string>] [-WhatIf] [-Confir
m] [<CommonParameters>]
```
We'll set out options and create.
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
Next we'll create a new psm1 named ```DCDisk.psm1``` in the same folder. 
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
        $this.DriveLetter
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
With these two files saved, we can place them in our module directory. 
# Working with the resource
## Checking syntax
We can check that our new resource is register.
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
Lets create a new configuration 
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
Running the configuration
```powershell
New-Item -ItemType Directory -Path C:\PS -Verbose -ErrorAction SilentlyContinue
Push-Location -Path C:\PS
DiskConfig
Start-DscConfiguration .\DiskConfig -Verbose -Wait -Force 
Pop-Location 
```