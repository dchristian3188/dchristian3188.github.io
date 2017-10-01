---
layout: post
title: Module Tools - Adding Cmdlet Help With PlatyPS
---

So the bad news is we have to write help for our modules.
The good news is PlatyPS streamlines the process and makes it a lot more bareable.
Plus all of the help can be written in Markdown and compiled into a cab file for easy distribution.
I promise, even though we're writting help, it won't be too bad.

**The Good Stuff:**
Start using [PlatyPS](https://github.com/PowerShell/PlatyPS/) to build your help files.

<!-- more -->

# Getting Started

PlatyPS is an open source tool, to make writing help for PowerShell a lot easier.
The biggest feature is that you can write the help in Markdown.
This makes the overall layout and formatting much easier.
Plus it has the ability to scafold the intial files by inspecting your module!
As your code changes and evolves over time, you can run a couple of commands and update the help files you already have.

## Installation

[PlatyPS](https://github.com/PowerShell/PlatyPS/) is available from the PowerShell Team's github page.
It's also avaiable on the PowerShell Gallery, which means installation is super simple.
To install PlatyPS, fire up a new PowerShell Window in adminsitrator mode and run the below fommand.

```powershell
Install-Module -Name PlatyPS -Verbose -Force 
```

# Generating Help

In today's example, we'll be adding help to my HideWindowsExplorerDrive module.
The first thing I like to do is create a new folder at the root of my module called help.
Next, we need to import the module into our current session.
Here's the commands from the root of the project.

```powershell
New-Item -Path Help -ItemType Directory -Verbose
Import-Module .\HideWindowsExplorerDrives.psd1
```

Alright with the module imported and a location for our help files, its time to start generating.
To create our help, we'll run the ```New-MarkDownHelp``` command.
There's a couple of differnt paramters for this cmdlet.
Lets see what our options are.

```powershell
Get-Command New-MarkdownHelp -Syntax
```

Output:

```powershell
New-MarkdownHelp -Module <string[]> -OutputFolder <string> [-Force] [-AlphabeticParamsOrder] [-Metadata <hashtable>] [-NoMetadata] [-UseFullTyp
eName] [-Encoding <Encoding>] [-WithModulePage] [-Locale <string>] [-HelpVersion <string>] [-FwLink <string>] [<CommonParameters>]

New-MarkdownHelp -Command <string[]> -OutputFolder <string> [-Force] [-AlphabeticParamsOrder] [-Metadata <hashtable>] [-OnlineVersionUrl <strin
g>] [-NoMetadata] [-UseFullTypeName] [-Encoding <Encoding>] [<CommonParameters>]

New-MarkdownHelp -MamlFile <string[]> -OutputFolder <string> [-ConvertNotesToList] [-ConvertDoubleDashLists] [-Force] [-AlphabeticParamsOrder]
[-Metadata <hashtable>] [-NoMetadata] [-UseFullTypeName] [-Encoding <Encoding>] [-WithModulePage] [-Locale <string>] [-HelpVersion <string>] [-
FwLink <string>] [-ModuleName <string>] [-ModuleGuid <string>] [<CommonParameters>]
```

The parameterset that we will be focusing is for modules.
All of the important conecpts carry over to the other options.
The main difference being, where your source is coming from.

I'm going to splat my parameters into the cmdlet, since I think it increases readibility.
We need to pass the Module name into PlatyPS.
It's important that the module is loaded into your session.
If not, you'll run into an error when running the command.
We also need to tell PlatyPS what the output folder is to save our help.
I also like to include the ```AlphabeticParamsOrder```, because why not and the ```WithModulePage```.
The module page is not needed to package up our module, but does provide a new summary if we're hosting this documenation on Github or something else.

```powershell
$mdHelp = @{
    Module                = 'HideWindowsExplorerDrives'
    OutputFolder          = 'Help'
    AlphabeticParamsOrder = $true
    WithModulePage        = $true
    Verbose               = $true
}
New-MarkdownHelp @mdHelp
```