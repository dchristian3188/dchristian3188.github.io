
Since there's more methods, there's more chance for something to go wrong.
While I know everyone out there writes perfect code first try, I am not so lucky.
I'm a little superstitious but I think if your code works first try, its bad luck.
With that in mind, we'll define our new resource, and jump straight into some tips on troubleshooting.

How to we debug when something goes wrong.

# Debugging A Class-Based Resource

## Debug The Class

It took me a while to realize this one.
Since the resource is defined as a PowerShell Class, it's available to us like any other type is.
What that means is we can debug this like we do any other class.
When initially designing a resource, this is my preferred approach.
At initial design I have my resource saved in a ```.ps1``` file.
Its not till module compilation time that all files are combined into the finished ```.psm1```.
This is import because the below commands will not work if the file extension is ```psm1```.
Alright with that out of the way, lets debug our class.

### Define The Class

First thing I do, is place a copy of the completed class in a ```.ps1``` file.
You can also place the complete class in a separate ```.ps1``` file and then dot source / use ```Import-Module``` on it.
Personally, I like keeping everything it one file, but both approaches work.
With the completed class defined, place a breakpoint on the method in question.

### Turn On Verbosity

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

### Create An Instance And Set Parameters

With the setup out of the way, we need to create a new instance of the class.
I'll use the dot net constructor here, but ```New-Object``` would also work.
Once the class is created, the resource parameters can then be assigned.
Parameters are assigned directly to object as properties.

```powershell
$sw = [SmartServiceRestart]::new()
$sw.ServiceName = 'Spooler'
$sw.Path = 'C:\Temp\test.txt'
```

### Debug the Method

I double check my breakpoint is place on the method and then run the method from my object.
At this point its my traditional debugging experience.
Here's what the code would look like to execute the ```Test``` method and restore my ```VerbosePreference```.


```powershell
$sw.Test()
$VerbosePreference = $ogVerbosePerf
```

Once you get into the debugger its no different then working with any other function.
Here's a screen shot of it in action in VSCode (any editor with a debugger will work).
![debug](https://github.com/dchristian3188/dchristian3188.github.io/blob/master/images/classDebugGif.gif)

## Debug DSC

The next approach is not exclusive to Class-Based resource.
Version 5 of PowerShell introduced some new DSC debugging capabilities.
I tend to use this approach when I'm having trouble with a particular configuration, I.E. this resource on this role in this environment blows up for some reason.

### Turn On Debugging In The LCM

The first thing you need to do is enable debugging at the LCM level.
Thankfully, the PowerShell team provided a cmdlet to do just that.

```powershell
Enable-DscDebug -BreakAll -Verbose
```

After running the command you can verify debugging is enabled by checking the LCM using ```Get-DscLocalConfigurationManager```.
The below example, returns the debugging configuration.

```powershell
(Get-DscLocalConfigurationManager).DebugMode
```

Output:

```powershell
ForceModuleImport
ResourceScriptBreakAll
```

### Creating A Small Configuration

To make isolating the problem easier, create a configuration with only the resource you want to debug.
In this example, I'm going to debug the

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

### Entering The Session

When we run the configuration it will immediately pause

![_config.yml]({{ site.baseurl }}/images/dscClassDebug.png)

```powershell
Enter-PSSession -ComputerName WIN-5D6IRQOFU97 
Enter-PSHostProcess -Id 2980 -AppDomainName DscPsPluginWkr_AppDomain
Debug-Runspace -Id 12
```
![_config.yml]({{ site.baseurl }}/images/dscClassDebug1.png)

![debug](https://github.com/dchristian3188/dchristian3188.github.io/blob/master/images/classDebugDSCGif.gif)