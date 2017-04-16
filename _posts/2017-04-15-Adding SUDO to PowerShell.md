---
layout: post
title: Adding Sudo to PowerShell
---
Lets be honest, before PowerShell the windows command line was a joke. The Linux guys were running circles around us. One of the best functions from Linux is sudo. Sudo is used when you need to run a command with elevated privileges. Similar to running a program as administrator in windows. Here's my implementation of sudo for PowerShell.

First we start with defining our parameters. Notice the ParameterSetName  in the parameter field. Parameter sets allow us to use totally different collections of parameters for the same command. If a parameter needs to be available to multiple sets, we simply add all the sets in the parameter declaration.

```powershell
[CmdletBinding(DefaultParameterSetName='Manual')]
    param(
        [Parameter(ParameterSetName='Manual',Position=0)]
        [System.Management.Automation.ScriptBlock]
        $Command,

        [Parameter(ParameterSetName='Manual',Position=1)]
        [System.String]
        $Program = (Join-Path -Path $PsHome -ChildPath 'powershell.exe'),

        [Parameter(ParameterSetName='History')]
        [switch]
        $Last,

        [Parameter(ParameterSetName='History')]
        [Parameter(ParameterSetName='Manual')]
        [Parameter(ParameterSetName='Script')]
        [switch]
        $NoExit,

        [Parameter(ParameterSetName='Script')]
        [ValidateScript({if(Test-Path -Path $_ -PathType Leaf){
                    $true}
                else{Throw "$_ is not a valid Path"}})]
        [system.String]
        $Script
    )
```

We are going to use splatting to run Start-Process later in our code. Splatting is the process of creating a hash table of parameters. The key is the parameter name, and the value is the value to pass to that parameter. Below are the parameters that are required to run Start-Process.