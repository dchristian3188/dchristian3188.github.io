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