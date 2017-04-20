---
layout: post
title: Working With Plaster
---
Plaster is a powershell scaffolding module. It helps keep your module and resouces consists and following best practices. 
**The Good Stuff**: Go check out plaster, a template-based file and project generator written in PowerShell. [Plaster Project Page](https://github.com/PowerShell/Plaster)
<!-- TOC -->

- [Installing](#installing)
- [Exploring Commands](#exploring-commands)
- [The default plaster template](#the-default-plaster-template)
- [Creating our own Plaster template](#creating-our-own-plaster-template)
    - [Examining a manifest and its schema](#examining-a-manifest-and-its-schema)
        - [Content](#content)

<!-- /TOC -->
# Installing
Get latest version from Gallery
```powershell
Install-Package -Name Plaster -Source PSGallery -Verbose -Force -ForceBootstrap
```

# Exploring Commands
```powershell
C:\> Get-Command -Module Plaster

CommandType     Name                                               Version    Source
-----------     ----                                               -------    ------
Function        Get-PlasterTemplate                                1.0.1      plaster
Function        Invoke-Plaster                                     1.0.1      plaster
Function        New-PlasterManifest                                1.0.1      plaster
Function        Test-PlasterManifest                               1.0.1      plaster
```

# The default plaster template
Lets start with our only Get command in the module.
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

# Creating our own Plaster template
Ok thats not too bad, but this isn't exactly what i use. How can we change this behavior? Lets take a look at ```New-PlasterManifest```
![_config.yml]({{ site.baseurl }}/images/plaster/New-PlasterSyntax.png)

So lets go ahead and create our first manifest. One important thing to note is the path name __must__ end in either ```PlasterManifest.xml```
```powershell
$manifestProperties = @{
    Path = "C:\Temp\PlasterManifest.xml"
    Title = "DC Custom Plaster Template"
    TemplateName = 'MyCustomPlasterTemplate'
    TemplateVersion = '0.0.1'
    Author = 'David Christian'
}

New-PlasterManifest @manifestProperties
```
Which produced the below xml
```xml
PS C:\Temp> cat .\PlasterManifest.xml
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest
  schemaVersion="1.0" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
  <metadata>
    <name>MyCustomPlasterTemplate</name>
    <id>7ed96752-fc70-4346-8861-d2373d530181</id>
    <version>0.0.1</version>
    <title>DC Custom Plaster Template</title>
    <description></description>
    <author>David Christian</author>
    <tags></tags>
  </metadata>
  <parameters></parameters>
  <content></content>
</plasterManifest>
```

Ok. Lets try running that
![_config.yml]({{ site.baseurl }}/images/plaster/plasterError.png)

What a bust! At this point, I went back and actually read the Plaster docs. Turns out there is more to a manifest that whats is given to you from ```New-PlasterManifest```. A whole lot more. 

## Examining a manifest and its schema
Essentially a manifest can be broken into 3 parts. 

1. Metadata - This is information about the plaster template itself
2. Parameters - These will be presented as prompts to your users
3. Content - What is actually going to be created using those parameters

Knowing this i re-examined my manifest. It turns on the ```New-PlasterManifest``` only helps you fill out the Metadata section. The rest is on you. 

Lets start looking at the parameter section. One parameters I'm going to need for sure is the module name. 
```xml
<parameter name="ModuleName" type="text" prompt="Name of your module" />
<parameter name="ModuleDesc" type="text" prompt="Brief description on this module" />
```
When working with modules locally i like to separate each function into a PS1 file. I then separate this into a folder for Public function and one for Internal. I also like to place any dlls or binaries my module maybe dependant on in their own folder. To get these options in Plaster, you can use the multichoice switch.
```xml
<parameter name="FunctionFolders" type="multichoice" prompt="Please select folders to include" default='0,1,2'>
    <choice label="&amp;Public" help="Adds a public folder to module root" value="Public" />
    <choice label="&amp;Internal" help="Adds a internal folder to module root" value="Internal" />
    <choice label="&amp;Classes" help="Adds a classes folder to module root" value="Classes" />
    <choice label="&amp;Binaries" help="Adds a binaries folder to module root" value="Binaries" />
    <choice label="&amp;Data" help="Adds a data folder to module root" value="Data" />
</parameter>
```

Finally I wanted the option to include pester tests. Notice the default of yes (hint hint).
```xml
<parameter name="Pester" type="choice" prompt="Include Pester Tests?" default='0'>
    <choice label="&amp;Yes" help="Adds a pester folder" value="Yes" />
    <choice label="&amp;No" help="Does not add a pester folder" value="No" />
</parameter>
```
### Content
This section tells Plaster what actions to take based on our parameters. 

First thing We needed to do was create our PSM1 and PSD1. For the psd1, I'm using the built in Plaster commannd of newModuleManifest. The PSM1 is being pulled from a template file.
```xml
<newModuleManifest destination='${PLASTER_PARAM_ModuleName}.psd1' moduleVersion='$PLASTER_PARAM_Version' rootModule='${PLASTER_PARAM_ModuleName}.psm1' author='$PLASTER_PARAM_FullName' description='$PLASTER_PARAM_ModuleDesc'/>
<file source='template.psm1' destination='${PLASTER_PARAM_ModuleName}.psm1'/>
```    

Content of the template file
```powershell
$functionFolders = @('Public', 'Internal', 'Classes')
ForEach ($folder in $functionFolders)
{
    $folderPath = Join-Path -Path $PSScriptRoot -ChildPath $folder
    If (Test-Path -Path $folderPath)
    {
        Write-Verbose -Message "Importing from $folder"
        $functions = Get-ChildItem -Path $folderPath -Filter '*.ps1' 
        ForEach ($function in $functions)
        {
            Write-Verbose -Message "  Importing $($function.BaseName)"
            . $($function.FullName)
        }
    }    
}
$publicFunctions = (Get-ChildItem -Path "$PSScriptRoot\Public" -Filter '*.ps1').BaseName
Export-ModuleMember -Function $publicFunctions
```