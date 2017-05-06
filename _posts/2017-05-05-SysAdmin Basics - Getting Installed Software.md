---
layout: post
title: SysAdmin Basics -  Getting Installed Software
---
I spent a few years consulting in the field and one question would always come up. 
How do I tell whats installed on my servers?
There's tons of advice on how to do this, some good and some bad, lets go thru it.
**The Good Stuff**: A function to get installed programs from the registry. [Get-InstalledProgram](https://github.com/dchristian3188/Main/blob/master/Functions/Get-InstalledProgram.ps1)
# The Bad - Win32_Product
```powershell
Get-WmiObject -Class Win32_Product
```
Please don't do this. I did this... What's sad is if you look for how to get installed software this is still a common recommendation. 
While this does accomplish the goal, it comes with limitations. 
The first being that it's incredibly slow.
![_config.yml]({{ site.baseurl }}/images/InstalledProgramsSlow.png)

The reason this command is so slow is that when you query the class, the provider actually performs a reconfiguration on every package installed on the system.
If you check the event log after running the command (OMG you didn't run it did you?!?!) you'll see a ton of events from the MsiInstaller source.
```powershell
Get-EventLog -LogName Application -After (Get-Date).AddMinutes(-5) -Source MsiInstaller | 
    Where-Object {$PSItem.EventID -eq '1035'} | 
    Measure-Object
````
If I perform just one query against ```Win32_Product``` on my machine, it generates over 550 events!
All of them looking something like the example below.
![_config.yml]({{ site.baseurl }}/images/InstalledProgramsEventViewer.png)

## WMIC 
Please bear with me as we take a trip down memory lane. 
Did you know PowerShell wasn't Snover's first time at the command line? 
Before Posh was even a thing, there was ```WMIC.exe```. 
This tool is ***interesting*** to say the least. 
With a syntax that is oddly familiar and built specifically to interact with WMI, ```WMIC.exe``` might even be PowerShells big brother. 
Take a look how to get the cpu information from the local machine.
```
WMIC.exe CPU GET NAME
```
Which produced the following output
```
Caption                               Name                                      NumberOfCores
Intel64 Family 6 Model 60 Stepping 3  Intel(R) Core(TM) i7-4790K CPU @ 4.00GHz  4
```
Since it's just interacting with WMI, you can use ```WMIC.exe``` to get installed software. 
```
WMIC.exe Product Get Name,Version
```
This same query could even be run against remote machines using the ```node``` switch.
```
WMIC.exe /node:Server1 Product Get Name,Version
```
The reason I wanted to include WMIC is because there are still a lot of references to it online. 
It's not obvious at first, but the above ```WMIC.exe``` command is performing a query against ```Win32_Product```. 
Due to this, it suffers from all of the same limitations and should be avoided where ever possible.

# The Good - Registry
A much more efficient way to enumerate software is to query the registry (in fact, this is how add remove programs does it). 
When software is installed it ***should*** leave an entry in the registry. 
There's just one catch, the location of this entry could be in a couple of different places. 
There's 2 sections for software installed at the ***machine*** level, one for 32-bit applications and one for 64-bit.
```
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\
HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\
```
There's also 2 other locations for software installed at the ***user*** level, again one for 32 bit applications and one for 64 bit.
```
HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\
HKCU:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall
```
## Using The Registry Provider
```powershell
Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*
```
There's a lot of great information in these registry keys, including the uninstall string. This is the command that get executed when you click uninstall from add remove programs. To make working with these keys easier, I created a function [Get-InstallProgram](https://github.com/dchristian3188/Main/blob/master/Functions/Get-InstalledProgram.ps1). It basically wraps the loop functionality required to check all 4 locations and adds parameters for ```DisplayName``` and ```Publisher```. Here's a shot of it in action:
![_config.yml]({{ site.baseurl }}/images/InstalledProgramFunction.png)


## Using Dot Net
You can also use the raw dot net methods to interact with the registry.
The below example uses the registry hive on the local machine to find the installed programs.
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
What's neat about using this method is, you can query computers using the remote registry service. 
This could be useful in some scenario where PowerShell remoting is not available but remote registry is. 
[This function](https://github.com/dchristian3188/Main/blob/master/Functions/Get-RemoteRegistryProgram.ps1) was created to make interacting with the remote registry a little easier. 
# The New - PackageManagement
In version 5 of PowerShell the team introduced the PackageManagement module. 
This module introduced a ton of great functionality for managing software. 
```Get-Package``` is now built in, and can be used to retrieve locally installed software. 
Not only will it find installed programs, it'll also list any chocolatey packages you have installed. 
If you're on version 5 or later its quick, easy and built in.
![_config.yml]({{ site.baseurl }}/images/InstalledProgramGetPackage.png)
# Wrapping Up
I hope this post was helpful. 
With these new tools at your disposal, the next time the boss tells you to inventory the servers it should be a breeze. 