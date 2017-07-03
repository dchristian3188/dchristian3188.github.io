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

## How Does This Work

We start by finding the first instance of that day of week.
To do this, We'll walk the month till we find the day we're looking for.

```powershell
[datetime]$tempDate = "{0}/{1}/{2}" -f $Year, $Month, 1
while ($tempDate.DayOfWeek -ne $Day)
{
    $tempDate = $tempDate.AddDays(1)
}
```

Finding the first instance of the day in the month is the hardest part.
Once we have that, we can add a multiple of 7 to get the instance the user requested.
How do we know what to add?
The breakdown is as follows:

```powershell
$increment = switch ($Instance)
{
    'First' {0}
    'Second' {7}
    'Third' {14}
    'Fourth' {21}
    'Fifth' {28}
}
$finalDate = $tempDate.AddDays($increment)
```

# Uses

## Checking The Whole Year

Here's a trick I use when I want check something that recurs every month.
Path Tuesday is a great example of this.
We'll call the ```ToLongDateString``` method to cleanup the output.

```powershell
(1..12 | Get-SpecificDate -Instance Second -Day Tuesday).ToLongDateString()
```

## Checking Only Today

Here's a trick I use to use, combined with task scheduler.
Pretend you have a script that needs to run the third Sunday of every month.
What you could do is create a scheduled task to execute your PowerShell script every day.
The trick is, you add this snippet to the top of your script.

```powershell
$targetDate = (Get-SpecificDate -Instance Third -Day Sunday).ToShortDateString()
$today = (Get-Date).ToShortDateString()

if($targetDate -eq $today)
{
    #Your code here
}
else
{
    #Write a log message then exit
}
```

# Wrapping Up

The completed function is [here.](https://github.com/dchristian3188/Main/blob/master/Functions/Get-SpecificDate.ps1)
Leave a comment and let me know what dates you're keeping track of.
