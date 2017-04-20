---
layout: post
title: Adding Sudo to PowerShell
---
Lets be honest, before PowerShell the windows command line was a joke and the Linux guys were running circles around us. One of the best functions from Linux is sudo. Sudo is used when you need to run a command with elevated privileges, similar to running a program as administrator in windows. Here's my implementation of sudo for PowerShell. **The Good Stuff**: A script that implements sudo in Powershell. [Start-ElevatedProcess.ps1](https://github.com/dchristian3188/Scripts/blob/master/Functions/Start-ElevatedProcess.ps1)

First we start with defining our parameters. Notice the ParameterSetName  in the parameter field. Parameter sets allow us to use totally different collections of parameters for the same command. If a parameter needs to be available to multiple sets, we simply add all the sets in the parameter declaration.

```powershell
[CmdletBinding(DefaultParameterSetName = 'Manual')]
    param(
        [Parameter(ParameterSetName = 'Manual', Position = 0)]
        [System.Management.Automation.ScriptBlock]
        $Command,

        [Parameter(ParameterSetName = 'Manual', Position = 1)]
        [System.String]
        $Program = (Join-Path -Path $PsHome -ChildPath 'powershell.exe'),

        [Parameter(ParameterSetName = 'History')]
        [Switch]
        $Last,

        [Parameter(ParameterSetName = 'History')]
        [Parameter(ParameterSetName = 'Manual')]
        [Parameter(ParameterSetName = 'Script')]
        [Switch]
        $NoExit,

        [Parameter(ParameterSetName = 'Script')]
        [ValidateScript( 
            {
                if (Test-Path -Path $_ -PathType Leaf)
                {
                    $true
                }
                else
                {
                    Throw "$_ is not a valid Path"
                }
            }
        )]
        [System.String]
        $Script
    )
```

We are going to use splatting to run Start-Process later in our code. Splatting is useful if you need to build up a list of parameters. Instead of having to code multiple if blocks to properly pass all the parameters to a function, you can create a hashtable to store the parameters. The key is the parameter name, and the value is the value to pass to that parameter. Below are all the parameters that are common to all of our use cases.

```powershell
#Base parameters for the start-process cmdlet
$startArgs = @{
    FilePath = $Program
    Verb = 'RunAs'
    ErrorAction = 'Stop'
}
```
From here I can go thru my parameters and add any keys to my ```$StartArgs``` HashTable. Here's what the splat looks like in action. the ```@``` sign replaces the normal ```$```. Its also important to note that even though I'm not doing it, you can mix a splat and regular parameters together. 

```powershell
try
{
    Start-Process @StartArgs 
}
catch
{
    Write-Warning -Message (
        "Error starting process. Error Message: {0}" -f $_.Exception.Message)
}
```
I like to add this function to my profile. I also add this alias: ```New-Alias -Name sudo -Value Start-ElevatedProcess```. The full code can be downloaded [here.](https://github.com/dchristian3188/Scripts/blob/master/Functions/Start-ElevatedProcess.ps1) Hope this helps!