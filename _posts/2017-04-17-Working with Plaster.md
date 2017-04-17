---
layout: post
title: Working With Plaster
---
**The Good Stuff**: Go check out plaster, a template-based file and project generator written in PowerShell. [Plaster Project Page](https://github.com/PowerShell/Plaster)

## Installing
Get latest version from Gallery
```powershell
Install-Package -Name Plaster -Source PSGallery -Verbose -Force -ForceBootstrap
```

## Exploring Commands
```powershell
C:\> Get-Command -Module Plaster

CommandType     Name                                               Version    Source
-----------     ----                                               -------    ------
Function        Get-PlasterTemplate                                1.0.1      plaster
Function        Invoke-Plaster                                     1.0.1      plaster
Function        New-PlasterManifest                                1.0.1      plaster
Function        Test-PlasterManifest                               1.0.1      plaster
```

The default plaster template
```powershell
PS C:\> Get-PlasterTemplate


Title        : New PowerShell Manifest Module
Author       : Plaster
Version      : 1.0.0
Description  : Creates files for a simple, non-shared PowerShell manifest module.
Tags         : {Module, ModuleManifest}
TemplatePath : C:\Program Files\WindowsPowerShell\Modules\plaster\1.0.1\Templates\NewPowerShellManifestModule
```

Invoking the default plaster template. Creating our first module. 
```powershell
$plasterDest = 'C:\temp'
$defaultTemplate = Get-PlasterTemplate | 
    Where-Object -FilterScript {$PSItem.Title -eq 'New PowerShell Manifest Module'}

Invoke-Plaster -TemplatePath $defaultTemplate.TemplatePath -DestinationPath $plasterDest\MyFirstPlasterModule  -Verbose  
```

Walking through the wizard. Prompted for module name, version, if you want to include pester tests (you know you should) and if you want a code folder created. 
![_config.yml]({{ site.baseurl }}/images/plaster/plasterFirstModule.png)

Here's what that ended up looking like.
![_config.yml]({{ site.baseurl }}/images/plaster/MyFirstModule.psm1.png)

Since we chose to include pester tests, this folder and structure was created by plaster.
![_config.yml]({{ site.baseurl }}/images/plaster/MyFirstModule.Test.Ps1.png)

Ok thats not too bad, but this isn't exactly what i use. How can we change this behavior?