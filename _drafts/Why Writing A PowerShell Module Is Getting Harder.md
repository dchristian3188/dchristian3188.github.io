---
layout: post
title: Why Writing A PowerShell Module Is Getting Harder
---

Writing a PowerShell module is hard.
A lot harder than it use to be.
Honestly it's your fault.
Not just you, but the whole PowerShell community.
Apparently we're a mature language now and everybody is demanding more.
I mean I was just starting to accept that fact that I have to include Pester tests, but now I need documentation too?
Geez, what else does it take to write a professional quality module these days?

**The Good Stuff:**
The skills you should be investing in to take your modules to the next level.

<!-- more -->

# PowerShell

This one seems obvious, but you need to be good at PowerShell.
If your making a module for someone else, that module better have sound code.
Getting better at PowerShell is the ongoing journey.
You can master the basics quickly but you're never done.
I feel like there's levels of progression people go through with PowerShell.

1. I know a couple of commands
1. I can save commands in a ps1 file
1. I make my own functions / my scripts take parameters
1. I make modules / DSC resources.

The thing is by the time you realize you need a module, you're probably already pretty far along.
Which is good because your going to need to leverage those skills to get the most out of the following tools.

# Pester

[Pester](https://github.com/pester/Pester) is the testing framework chosen not only by the community but the PowerShell team.
In fact, Pester's adoption has been so wide spread, it was the first open source project to actually ship with Windows.
Pester allows you to define scriptblocks that ensure your code is working as expected.
The idea is every time you make a change, your run the Pester tests.
As new bugs are found, you create tests to ensure your code fixes worked.
Pester does have its own DSL, but still feels and reads very much like PowerShell.
# Git

Git is an open source version control system.
Some of the biggest names in the industry use Git, such as Google, Facebook, Microsoft and Netflix.
If you're not using source control, you should be.
Its an absolute must if you're working on large projects, coding on multiple machines, or developing in a group.
A good version control system provides change tracking and the ability to work features or branches in parallel.
Git provides all that and more.
Git introduces a whole suite of utilities and new commands to learn.
Unfortunately since its cross platform and been around forever, it feels nothing like PowerShell syntax.


# Invoke-Build

[Invoke-Build](https://github.com/nightroman/Invoke-Build) is a powerful, build automation system written in PowerShell created by [Roman Kuzmin.](https://github.com/nightroman)
As of late it has been generally accepted by the community as the go to tool, replacing psake.
Using ```Invoke-Build``` gives us a lot of neat features including: task groups,  incremental and parallel builds and a easy way to define conditions or dependencies.
Using ```Invoke-Build``` is straight forward, with its custom DSL.
Every task is essentially a script block and looks very close to vanilla PowerShell.

# Plaster

[Plaster](https://github.com/powershell/plaster) is a PowerShell scaffolding module and a most for module creators.
Think of the new project wizard from Visual Studio, but only written in PowerShell where you control all the options.
Plaster's wizard process is all driven by an XML manifest, with a little bit of PowerShell sprinkled throughout.
It also provides a custom syntax to template files, based on PowerShell.
While this does present a learning curve, the investment is well worth it to avoid the duplication of work.

# PSGraph

[PSGraph](https://github.com/KevinMarquette/PSGraph) is a wrapper for Graphiz created by [Kevin Marquette.](https://kevinmarquette.github.io/)
If you haven't seen Graphiz before, it's an open source graph library.
Thanks to [Kevin's](https://twitter.com/kevinmarquette) module, creating graphs in PowerShell is a breeze.
For example, a new addition to all my modules, is a Graphiz diagram that'll detail how the functions in the module call each other. 



# PlayPS

Sorry but you need to document your code.
I know, it sucks.

