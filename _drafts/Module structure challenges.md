---
layout: post
title: Module Structure Challenges
---

A brief note on module structure.
During development I like to create a separate PS1 for every class and resource.
I feel that this structure is the cleanest and easiest to manage in source.
Here is a snippet of the FileWatcher modules layout.

```powershell
C:.
│   .gitignore
│   FileWatcher.build.ps1
│   FileWatcher.psd1
│   FileWatcher.psm1
│
├───.vscode
│       settings.json
│
├───Classes
│       BaseFileWatcher.ps1
│
├───DSCResources
│       ProcessFileWatcher.ps1
│       ServiceFileWatcher.ps1
│       WebsiteFileWatcher.ps1

...
```

This does create some challenges.
The biggest is that PowerShell throws a parse error when a class is defined in a script that references an external type.
The PowerShell team is tracking the issue [here.](https://github.com/PowerShell/PowerShell/issues/3641)

To work around this, I have an Invoke-Build script that compiles the files into a completed PS1 and then runs the Pester tests. 