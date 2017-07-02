---
layout: post
title: SysAdmin Basics - Finding A Specific Date
---

Dates are hard, that makes scheduling hard.
Ever had someone tell you to be ready on the first Monday of the month?
Don't forget Microsoft is pushing patches on the second Tuesday.
My personal favorite is the fourth Thursday in November (Thanksgiving here in the states).
While these types of dates are easy to remember, they can be hard to build automation around.
Don't worry with a bit of math and my helper function, I'll make sure you never miss Mother's Day again (second Sunday in May).

 **The Good Stuff:**
[Get-SpecificDate](https://github.com/dchristian3188/Main/blob/master/Functions/Get-SpecificDate.ps1), a function to find day of week occurrences in a given month.

<!-- more -->

Here's the gist.
<script src="https://gist.github.com/dchristian3188/dabfa9d1f2dd1b4ae0ab8b55bcd6af4f.js"></script>

My Code block

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