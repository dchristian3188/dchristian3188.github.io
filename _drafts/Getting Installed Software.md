---
layout: post
title: Getting Installed Software
---

# The Bad - Win32_Product
Please don't do this. I did this... What's sad is if you look for how to get installed software this is still a common recommendation. 

Runs slow
![_config.yml]({{ site.baseurl }}/images/InstalledProgramsSlow.png)

What it does to the event log
```powershell
Get-EventLog -LogName Application -After (Get-Date).AddMinutes(-5) -Source MsiInstaller | 
    Where-Object {$PSItem.EventID -eq '1035'} | 
    Measure-Object
````
All of the entries look like
![_config.yml]({{ site.baseurl }}/images/InstalledProgramsEventViewer.png)

# Good - Registry
A better and much much faster way is to query the registry (in fact, this is how add remove programs does it). When software is installed it ***should*** leave an entry in the registry. 

## Using Dot net
```powershell

$computerName = $env:COMPUTERNAME
$registryHive = [Microsoft.Win32.RegistryHive]::LocalMachine
$registry = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($registryHive,$computerName)
$registryPath = "Software\Microsoft\Windows\CurrentVersion\Uninstall"

$keyNames = $registry.OpenSubKey($registryPath).GetSubKeyNames()
ForEach($key in $keyNames)
{
    $registry.OpenSubKey($registryPath).OpenSubKey($key).GetValue('DisplayName')
}
```
## Using the registry provider
```powershell
Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*
```
There's one catch. This registry location could be in a couple of different locations. There's 2 sections for software installed at the ***machine*** level, one for 32-bit applications and one for 64-bit.
```
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\
HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\
```
The other 2 locations are for software installed at the ***user*** level. Again there is a location for 32 and 64 bit.
```
HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\
HKCU:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall
```
There's alot of great information in these registry keys, including the uninstall string. This is the command that get executed when you click uninstall from add remove programs. To make working with these keys easier, I created a function [Get-InstallProgram](https://github.com/dchristian3188/Main/blob/master/Functions/Get-InstalledProgram.ps1). It basically wraps the loop funcitonality required to check all 4 locations and adds parameters for ```DisplayName``` and ```Publisher```. Here's a shot of it in action:
![_config.yml]({{ site.baseurl }}/images/InstalledProgramFunction.png)

# The New
In version 5 of PowerShell the team introduced the PackageManagement module. This module introduced a ton of great functionality for managing software and modules. ```Get-Package``` is now built in, and can be used to retrieve locally installed software. Not only will it find installed programs, it'll also list any chocolatey packages you have installed. 
![_config.yml]({{ site.baseurl }}/images/InstalledProgramGetPackage.png)