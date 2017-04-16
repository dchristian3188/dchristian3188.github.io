--- 
layout: post
title: Getting Some Random Help?
--- 
**The Good Stuff**: A script to get a random help file. [Open-PSCommandHelp.ps1](https://github.com/dchristian3188/dchristian3188.github.io/blob/master/scripts/Open-PSCommandHelp.ps1).

I think one of the biggest hurdles learning PowerShell is trying to find what command to run. What i use to do is read a different help file every morning. Now i don't expect anyone to be able to look at a help file once and instantly know the ins and outs of a command. But forcing yourself to read a random help file can get the mental juices flowing. The goal of this script is to just start learning what PowerShell CAN do.

Open-PSCommandHelp takes a couple of parameters: module, verb and noun. Depending on what variables are used, this script opens a random text file with the full help of a command that meets the criteria. The variables are passed directly into Get-Command. I use two very neat tricks to perform this cleanly. The first trick is referencing the ```PSBoundParameters``` variable. ```PSBoundParameters``` is a special hash table that gets created inside a script (or function). The key value pairs in the hash table are your parameters and their values.

With this hashtable automagically created for us, we can use the second trick, splatting. Splatting is the process of passing a hashtable as an argument to a cmdlet. The only caveat is we need to prefix the name of the hashtable with a ```@``` instead of a ```$```.

```powershell
[CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [System.String]
        $Module,
        
        [Parameter(Position = 1)]
        [System.String]
        $Verb,
        
        [Parameter(Position = 2)]
        [System.String]
        $Noun
    )
    
    $Command = Get-Command @PSBoundParameters | 
        Get-Random -Count 1
```
Take a look at the last line in the above code. Notice that I only call Get-Command  once. With the use of splatting I can handle every possible combination of parameters in one line!

Trying to learn a new module? Throw this script in your profile with the -Module parameter. Now every time you open the shell you will see a new help file for a command from that module. The full code can be download [here.](https://github.com/dchristian3188/dchristian3188.github.io/blob/master/scripts/Open-PSCommandHelp.ps1) Hope this helps!