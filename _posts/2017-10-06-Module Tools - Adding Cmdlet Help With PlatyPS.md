---
layout: post
title: Module Tools - Adding Cmdlet Help With PlatyPS
---

So the bad news is we have to write help for our modules.
The good news is PlatyPS streamlines the process and makes it a lot more bearable.
Plus all of the help can be written in Markdown and packaged up for easy distribution.
I promise, even though we're writing help, it won't be too bad.

**The Good Stuff:**
Start using [PlatyPS](https://github.com/PowerShell/PlatyPS/) to build your help files.

<!-- more -->

# Getting Started

PlatyPS is an open source tool that makes writing help for PowerShell modules a lot easier.
The biggest feature is that you can write the help in Markdown.
This makes the overall layout and formatting simpler to manage than writing the help inline.
Plus it has the ability to scaffold the initial files by inspecting your module!
Even better, as your code changes and evolves over time, you can run a couple of commands and update the help files you already have.

# Installation

[PlatyPS](https://github.com/PowerShell/PlatyPS/) is available from the PowerShell Team's Github page.
It's also available on the PowerShell Gallery, which means installation is super simple.
To install PlatyPS, fire up a new PowerShell Window in administrator mode and run the below command.

```powershell
Install-Module -Name PlatyPS -Verbose -Force 
```

# Generating Help

In today's example, we'll be adding help to my [HideWindowsExplorerDrive](https://github.com/dchristian3188/HideWindowsExplorerDrives) module we've been using for this series.
To get started, the first thing I like to do is create a new folder at the root of my module called help.
Next, we need to import the module into our current session.
Here are the commands from the root of the project.

```powershell
New-Item -Path Help -ItemType Directory -Verbose
Import-Module .\HideWindowsExplorerDrives.psd1
```

With the module imported and a location for our help files, it's time to start generating.
To create our help, we'll run the ```New-MarkDownHelp``` command.
There's a couple of different parameters for this cmdlet.
Let's see what our options are.

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

We will be focusing on the first parameterset that generates the help for a module.
All of the important conecpts carry over to the other parametersets.
The main difference being, where your source is coming from, a module, command or maml file.

Alright, let's generate some help.
We need to pass the Module name into PlatyPS.
It's important that the module is loaded into your session.
If not, you'll run into an error when running the command.
We also need to tell PlatyPS the output folder so it knows where to save our help.
I also like to include the ```AlphabeticParamsOrder``` switch, because why not, and the ```WithModulePage``` option.
The module page is not needed to package up our module but does provide a nice summary view.
This is useful if we're hosting this documentation on Github or anything else that can render Markdown.

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

That's all there is to it.
PlatyPS will inspect your module's commands and generate the skeleton of the help files.
Lets dive into one to see what it created.

![_config.yml]({{ site.baseurl }}/images/ModuleTools/PlatyPS/skelton.png)

Even though PlatyPS does most of the heavy lifting, we still have to write the more detailed information ourselve.
PlatyPS uses brackets ```{% raw %}{{ }}{% endraw %}``` to designate the template text.
What is really neat is PlatyPS can tell when you removed this text from the Markdown.
This is incredibly helpful if you make a change to your module and want to run the ```Update-MarkdownHelp``` cmdlet.
It'll add any new information it needs to, but not delete any of the changes you made!

# Packaging Help

I'll skip you the pain of writing the help file details.
Now that we have our markdown completed it's time to package up our files.
What we'll do is tell PlatyPS to package up our Markdown into XML.
To have the help autoloaded we need to export this XML in a folder for the language at the root of the module.
Here's what that PlatyPS command looks like for "en-US".
This command assumes you are at the root of the module.

```
New-ExternalHelp -Path .\Help\ -OutputPath .\en-us
```

With that final command, our help is packaged up and ready for deployment.
If we look inside the XML, we can see our help documents and feel grateful we didn't have to write this part by hand.
In a future post, we'll see how we can include this step as part of Invoke-Build.