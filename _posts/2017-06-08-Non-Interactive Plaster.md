---
layout: post
title: Non-Interactive Plaster
tags: [Plaster]
---

I have a talk coming up on Plaster.
It's been almost 2 months since my post on it and I've been playing around the last couple of days to get comfortable.
One thing that hit me was that Plaster will turn the parameters in your manifest into dynamic parameters of the ```Invoke-Plaster``` cmdlet.
What this means is you could pull a list from anywhere and run that through a Plaster manifest, all without stepping through the wizard!

**The Good Stuff:**
Make sure you're using Plaster's dynamic parameters.
<!-- more -->

For this example I'm going to be using my [function](https://github.com/dchristian3188/Main/tree/master/Plaster/Function) template.
This Plaster template is pretty straightforward.
There is a parameter for the function name, if the function should have cmdlet help, support pipeline input and the type of cmdlet binding.
I also use the ```ComputerName``` parameter a lot so I like to include an option for that too.

Now let's pretend were working on a new module.
This new module is going to managed DCWebServers (whatever those are).
So far I know I have to make the following cmdlets: ```New-DCWebServer```, ```Get-DCWebServer```, ```Set-DCWebServer```, and ```Remove-DCWebServer```.
I first start by generating a hashtable for each new cmdlet.
After that, we can just splat directly into ```Invoke-Plaster```.

```powershell
$verbs = @('New','Get','Set','Remove')

ForEach($verb in $verbs)
{
    $functionDetails = @{
        FunctionName = "$($verb)-DCWebServer"
        Help = 'Yes'
        PipeLineSupport = 'Yes'
        CmdletBinding = 'Advanced'
        ComputerName = 'Yes'
        TemplatePath =  'C:\github\Main\Plaster\Function'
        DestinationPath = 'C:\temp'
        Verbose = $true
    }
    Invoke-Plaster @functionDetails
}
```

Here's a screenshot of it action. Since we provided all of the parameters the wizard starts but doesn't ask us for anything.

![_config.yml]({{ site.baseurl }}/images/plasterNonInteractive.png)

If we check our output directory, all the functions are there!

```powershell
PS C:\github\dchristian3188.github.io> Get-ChildItem -Path C:\temp



    Directory: C:\temp


Mode                LastWriteTime         Length Name
----                -------------         ------ ----
-a----         6/8/2017  10:53 PM            788 Get-DCWebServer.ps1
-a----         6/8/2017  10:53 PM            108 Get-DCWebServer.tests.ps1
-a----         6/8/2017  10:53 PM            788 New-DCWebServer.ps1
-a----         6/8/2017  10:53 PM            108 New-DCWebServer.tests.ps1
-a----         6/8/2017  10:53 PM            791 Remove-DCWebServer.ps1
-a----         6/8/2017  10:53 PM            111 Remove-DCWebServer.tests.ps1
-a----         6/8/2017  10:53 PM            788 Set-DCWebServer.ps1
-a----         6/8/2017  10:53 PM            108 Set-DCWebServer.tests.ps1
```

Plus my new Pester tests are even working (well sort of).

![_config.yml]({{ site.baseurl }}/images/plasterNonInteractiveTests.png)

Remember you can use Plaster to create ANY kind of file and folder structure.
What could you make pulling information from somewhere, like AD or a database, and a cool Plaster Manifest?