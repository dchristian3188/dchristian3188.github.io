---
layout: post
title: Exploring PowerShell 6 - SpeedFreaks
---

PowerShell Core 6 is out!
Along with all the new features, there has been a ton of performance improvements.
But just really how much faster is it?
Today I'm going to revisit an old article by Dave Wyatt and see if version 6 has the numbers to back up all the claims.
So with that, let's dive into the filtering performance improvements in the latest version.

**The Good Stuff:**
PowerShell version 6, now with faster filters!
<!-- more -->

Dave Wyatt MVP put together a fantastic [article](https://powershell.org/2013/11/17/powershell-performance-filtering-collections/) over PowerShell.org a few years back.
I've referred to this article many times over the years and it's a definite must-read for any true PowerShell enthusiast.
In today's post, I'll be building off (shamelessly stealing) his script to measure different methods to filter in PowerShell.
We'll also be running this same script in both version 5 and 6 to get some good comparison data.
First off, let's meet our filtering contenders.

* Where-Object - the standard filter command that's been with us since version 1
* Simplified Where - The friendly where syntax introduced in PowerShell 3
* .Where - This method was first introduced in PowerShell 4 to filter collections
* The filter keyword - Often overlooked, hardly used and with us since version 1
* Foreach - Stanard loop built into the language
* Advanced Function - This one essentially measures the performance of the process block in PowerShell

Here's what our speed test will look like.
It will filter the Get-Process command looking for notepad.
To make things fair, we'll execute each filter a thousand times.

```powershell
$loop = 1000

$v2 = (Measure-Command {
        for ($i = 0; $i -lt $loop; $i++)
        {
            Get-Process | Where-Object { $_.Name -eq 'notepad' }
        }
    }).TotalMilliseconds

$v3 = (Measure-Command {
        for ($i = 0; $i -lt $loop; $i++)
        {
            Get-Process | Where Name -eq 'notepad'
        }
    }).TotalMilliseconds

$v4 = (Measure-Command {
        for ($i = 0; $i -lt $loop; $i++)
        {
            (Get-Process).Where( { $_.Name -eq 'notepad' })
        }
    }).TotalMilliseconds

$filter = (Measure-Command {
        filter notepadFilter { if ($_.Name -eq 'notepad') { $_ } }
    
        for ($i = 0; $i -lt $loop; $i++)
        {
            Get-Process | notepadFilter
        }
    }).TotalMilliseconds

$foreachLoop = (Measure-Command {
        for ($i = 0; $i -lt $loop; $i++)
        {
            foreach ($process in (Get-Process))
            {
                if ($process.Name -eq 'notepad')
                {
                    # Do something with $process
                    $process
                }
            }
        }
    }).TotalMilliseconds

$AdvancedFunction = (Measure-Command {

        function Get-Notepad
        {
            [CmdletBinding()]
            Param(
                [Parameter(ValueFromPipeline)]
                [PSCustomObject]
                $InputObject
            )
            process 
            {
                if ($InputObject.Name -eq 'notepad')
                {
                    $InputObject
                }
            }
        }
    
        for ($i = 0; $i -lt $loop; $i++)
        {
            Get-Process | Get-Notepad
        }
    }).TotalMilliseconds

Write-Host ("PowerShell Version: $($PSVersionTable.PSVersion.ToString())")
Write-Host ('Where-Object -FilterScript:  {0:f2} ms' -f $v2)
Write-Host ('Simplfied Where syntax:      {0:f2} ms' -f $v3)
Write-Host ('.Where() method:             {0:f2} ms' -f $v4)
Write-Host ('Using a filter:              {0:f2} ms' -f $filter)
Write-Host ('Conditional in foreach loop: {0:f2} ms' -f $foreachLoop)
Write-Host ('Advanced Function:           {0:f2} ms' -f $AdvancedFunction)

```

Moment of truth, here's what the results were in PowerShell 5.

![_config.yml]({{ site.baseurl }}/images/SpeedFreaks/powershell5.png)

And here's what that same script looks like in Powershell 6.

![_config.yml]({{ site.baseurl }}/images/SpeedFreaks/powershell6.png)

The numbers are undeniable.
Regardless of version, the fastest filters remain unchanged.

1. Foreach
1. Filter Keyword
1. Advanced functions (process block)
1. .Where
1. Simplified Where
1. Where-Object

What is the most surprising is that on average PowerShell 6 is twice as fast as the previous version!
That's pretty damn impressive.
So what do you think?
Are these speed gains enough to make you switch over?