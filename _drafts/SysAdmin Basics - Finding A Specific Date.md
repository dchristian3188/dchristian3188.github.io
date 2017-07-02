---
layout: post
title: SysAdmin Basics - Finding A Specific Date
---

Dates are hard, that makes scheduling hard.
Ever had someone tell you to be ready on the first Monday of the month?
Don't forget Microsoft is pushing patches on the second Tuesday.
My personal favorite is the fourth Thursday in November (Thanksgiving here in the states).
While these types of dates are easy to remember, they can be hard to build automation around.
Don't worry with a couple of tricks and my helper function, I'll make sure you never miss Mother's Day again (second Sunday in May).

 **The Good Stuff:**
[Get-SpecificDate](https://github.com/dchristian3188/Main/blob/master/Functions/Get-SpecificDate.ps1), a function to find day of week occurrences in a given month.

<!-- more -->

# Get-SpecificDate

## Parameters

Get-SpecificDate takes a couple of parameters.
The ```Instance``` parameter expects one of the following strings: first, second, third, fourth, fifth or last.
Next is the day parameter, which expects a value from the ```DayOfWeek``` enum.
What's neat about using this enum is you can use ```0``` or ```Sunday``` to specify the day.
(Actually, you just need to pass enough of the string to make it unique.
Which means we can use the short name of ```Sun```.)
The ```Month``` parameter is an integer.
If you don't specify a value, it will default to using the current month.
Same for the ```Year``` parameter.

```powershell
if ($Instance -eq 'Last')
{
    $longMonth = $tempDate.AddDays(28).Month -eq $Month
    if ($longMonth)
    {
        $finalDate = $tempDate.AddDays(28)
    }
    else 
    {
        $finalDate = $tempDate.AddDays(21)    
    }
}
else
{
    $increment = switch ($Instance)
    {
        'First' {0}
        'Second' {7}
        'Third' {14}
        'Fourth' {21}
        'Fifth' {28}
    }
    $finalDate = $tempDate.AddDays($increment)    
}
```