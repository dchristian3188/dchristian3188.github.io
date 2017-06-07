---
layout: post
title: Troubleshooting DSC
---

While I know everyone out there writes perfect code first try, I am not so lucky.
I'm a little superstitious but I think if your code works first try, it's bad luck.
We've all been there, you've been chugging away at a new project, go to run it and it blows up.
Even worse, sometimes you have a resource that's been working great, but chokes on a particular server.
No way around it, debugging and troubleshooting are part of the game.
This article will take your existing debugging knowledge and help you apply it to DSC.

**The Good Stuff:**
How to Debug a DSC Resource.
<!-- more -->

<!-- TOC -->

- [Learning Debugging](#learning-debugging)
- [Debug The Class](#debug-the-class)
    - [Define The Class](#define-the-class)
    - [Turn On Verbosity](#turn-on-verbosity)
    - [Create An Instance](#create-an-instance)
    - [Debug The Method](#debug-the-method)
- [Debug DSC](#debug-dsc)
    - [Adjust The LCM](#adjust-the-lcm)
    - [Create A Small Configuration](#create-a-small-configuration)
    - [Enter The Session](#enter-the-session)
    - [Disable Debugging](#disable-debugging)
- [Wrapping Up](#wrapping-up)

<!-- /TOC -->

# Learning Debugging

If your new to the PowerShell debugging, I highly recommend you spend a few minutes reading these articles as a primer.
There's a couple of nuances with debugging and being able to navigate your editor and debugger will make you that much more efficient.

- [Quick and Efficient PowerShell Script Debugging with Breakpoints](http://www.informit.com/articles/article.aspx?p=2421573)
- [Use the Debugger in the Windows PowerShell ISE](https://blogs.technet.microsoft.com/heyscriptingguy/2011/11/24/use-the-debugger-in-the-windows-powershell-ise/)
- [How to Debug Scripts in Windows PowerShell ISE](https://msdn.microsoft.com/en-us/powershell/scripting/core-powershell/ise/how-to-debug-scripts-in-windows-powershell-ise)



# Debug The Class

This first method only applies if you are using a PowerShell Class-Based Resources (which you should be).
It took me a while to realize this but Class-Based Resources add a new type to PowerShell.
After defining the class, the new type is available to us, like ```[string]``` or ```[int]``` is.
What that means is we can create a new instance of our resource and debug directly against the class.
When initially designing a resource, this is my preferred approach as it's quick and easy.
For today's example, I'm going to be using the [SmartServiceRestart](https://github.com/dchristian3188/Main/tree/master/DSC/SmartServiceRestart) resource from my previous post.

## Define The Class

First thing I do, is place a copy of the completed class in a ```.ps1``` file.
You can also place the complete class in a separate ```.ps1``` file and then dot source / use ```Import-Module``` on it.
Personally, I like keeping everything it one place, but both approaches work.
With the completed class defined, place a breakpoint on the method in question.

## Turn On Verbosity

I try to be good about my verbose messages in DSC resources.
One because I want the end user to know whats going on, but also for me when troubleshooting.
Since we will be interacting with the class directly, there's no ```-Verbose``` switch to add.
If we want to see our messages we need to adjust the ```VerbosePreference``` variable.
I use the below snippet to save the original value of ```VerbosePreference```.
My plan is to restore this value at the end of my debugging.

```powershell
$ogVerbosePerf = $VerbosePreference
$VerbosePreference = 'Continue'
```

## Create An Instance

With the setup out of the way, we need to create a new instance of the class.
I'll use the dot net constructor here, but ```New-Object``` would also work.
Next step is to assign the resource's parameters.
The parameters are properties that get assigned directly to the object.
Here we'll set the ```ServiceName``` and ```Path``` parameter (object property).

```powershell
$sw = [SmartServiceRestart]::new()
$sw.ServiceName = 'Spooler'
$sw.Path = 'C:\Temp\test.txt'
```

## Debug The Method

Double check the breakpoint is in place on the method and then call it from the object.
Next step is to run your script and let it hit your breakpoint.
From here, it's the traditional debugging experience.
Here's what the code would look like to execute the ```Test``` method and restore my ```VerbosePreference``` variable.


```powershell
$sw.Test()
$VerbosePreference = $ogVerbosePerf
```

Once you get into the debugger its no different then working with any other function.
This is ideal if you need to make quick changes and are still hammering out the details of a resource.
Here's a screen shot of it in action in VSCode.
VSCode is awesome, but any editor that has a PowerShell debugger works.

![_config.yml]({{ site.baseurl }}/images//classDebugGif.gif)

# Debug DSC

Version 5 of PowerShell introduced some new DSC debugging capabilities.
One of the coolest features is the ability to stop a configuration and debug against a live server.
I tend to use this approach when I'm having trouble with a particular configuration, I.E. this resource, on this role, in this environment, blows up for some reason.

## Adjust The LCM

The first thing you need to do is enable debugging at the LCM level.
Thankfully, the PowerShell team provided a cmdlet for this.

```powershell
Enable-DscDebug -BreakAll -Verbose
```

After you run the command, verify the changes by using ```Get-DscLocalConfigurationManager```.
The below example, returns the debug mode of the LCM.
You should see the two entries below.

```powershell
(Get-DscLocalConfigurationManager).DebugMode
```

Output:

```powershell
ForceModuleImport
ResourceScriptBreakAll
```

## Create A Small Configuration

To make isolating the problem easier, create a configuration with only the resource you want to debug.
When you make the change to the LCM, it will break at every resource.
In large configurations, this becomes tedious and makes re-entering a method harder than it should be.
Here's what the small configuration would look like for our current example.

```powershell
configuration RestartExample
{
    Import-DscResource -ModuleName SmartServiceRestart
    node ('localhost')
    {
        SmartServiceRestart PrintSpooler
        {
            ServiceName = 'Spooler'
            Path        = 'C:\temp\controller.txt'
        }
    }
}
```

## Enter The Session

When we run the configuration it will start the first resource, hit a breakpoint and create a debugging session.
The most awesome part, the PowerShell team left us a message on how to connect to this new session.
Take a look at this screenshot.

![_config.yml]({{ site.baseurl }}/images/dscClassDebug.png)

Let's examine what's going on here.
The first command creates a PSSession to the server.
In my example, I'm directly on the server, but I could also do this remotely.
The next command connects to the PowerShell process that is running the resource.
The last command, ```Debug-Runspace```, is where the magic happens.
Executing this command will open a new window in our editor and allow us to step through the method.
Here's the commands that I copied from the verbose message.
Yours will be different depending on your machine name and PID.

```powershell
Enter-PSSession -ComputerName WIN-5D6IRQOFU97
Enter-PSHostProcess -Id 2980 -AppDomainName DscPsPluginWkr_AppDomain
Debug-Runspace -Id 12
```

What I love about this approach is that its perfect for those problematic servers.
Sometimes the only way to find a bug is to step through the affected machine.
Even better this debugging technique works great in Windows Server, with a vanilla ISE.
Here's the whole process from a Server 2012 VM.

![_config.yml]({{ site.baseurl }}/images/classDebugDSCGif.gif)

## Disable Debugging

If you did use a real machine to debug a resource, please remember to disable debugging when you're done.
After running the below command your LCM should return to normal.

```powershell
Disable-DscDebug -Verbose
```

# Wrapping Up

This was a fun one for me.
Often times that first pass of code is the easy part.
It's the details that get you.


- Part 1: [Creating A DSC Class-Based Resource](http://overpoweredshell.com/Creating-A-DSC-Class-Based-Resource/)
- Part 2: [DSC Classes - Using Helper Methods](http://overpoweredshell.com/DSC-Classes-Using-Helper-Methods/)
- Part 3: [TroubleShooting DSC](http://overpoweredshell.com/Troubleshooting-DSC/)
