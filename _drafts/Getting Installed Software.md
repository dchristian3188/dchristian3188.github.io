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