---
layout: post
title: Exploring PowerShell 6 - ValidateRange Enhancements
---

PowerShell Core 6.0 is here!
One of the new features is some enhancements to the ValidateRange attribute.
As part of the update, you can now pass predefined ranges making common scenarios a little easier.
Let's dive in and take a look.

**The Good Stuff:**
ValidateRange now has predefined shortcuts that you can leverage in PowerShell 6.

<!-- more -->

A common scenario when using parameter validation was ensuring that your incoming parameter was a positive number.
Here are the two most common ways I would see this accomplished before PowerShell 6.

You could use ValidateRange:

```powershell
Function Test-ParameterIsPositive
{
    Param(
        [ValidateRange(1, [int]::MaxValue)]
        $MyParam
    )
    Write-Output -InputObject $MyParam
}
```

This worked in most scenarios, but had some limitations.
What if the user passed in .00001?
What if the user passed in a gigantic number like a ```[double]::MaxValue```?

Here's a little more robust solution using ValidateScript:

```powershell
Function Test-ParameterIsPositive
{
    Param(
        [ValidateScript({$PSItem -gt 0})]
        [int]
        $MyParam
    )
    Write-Output -InputObject $MyParam
}
```

This worked, but didn't provide the best error messages.
Here's what the user would see if they passed in an incorrect value.

![_config.yml]({{ site.baseurl }}/images/ValidateRange/ValidateScript1.png)

Ok, not the end of the world.
By expanding our script block, we could make this a little more user-friendly.

```powershell
Function Test-ParameterIsPositive
{
    Param(
        [ValidateScript( {
            If ($PSItem -gt 0)
            {
                $true
            }
            Else
            {
                Throw "MyParam must be greater than 0"
            }
        })]
        [int]
        $MyParam
    )
    Write-Output -InputObject $MyParam
}
```

Now this is much better.
Here's what our user would see.

![_config.yml]({{ site.baseurl }}/images/ValidateRange/ValidateScript2.png)

This got the job done but was kind of a lot of work.
Now in PowerShell 6, we have an even better way to do this.
By leveraging the built-in shortcuts to ValidateRange we can simplify our code.
Here's the Positive shortcut in action.

```powershell
Function Test-ParameterIsPositive
{
    Param(
        [ValidateRange('Positive')]
        [int]
        $MyParam
    )
    Write-Output -InputObject $MyParam
}
```

This syntax is much easier.
Plus it comes with a understandable error message right out of the box.

![_config.yml]({{ site.baseurl }}/images/ValidateRange/ValidateRange.png)

Not too shabby.
Even better, there are 4 new predefined ranges we can take advantage of.
Here's the breakdown:

* Positive - ```$PSItem -gt 0```
* NonNegative - ```$PSItem -ge 0```
* Negative - ```$PSItem -lt 0```
* NonPositive - ```$PSItem -le 0```

What do you think?
Will you be refactoring your old scripts to take advantage of the shortcuts?