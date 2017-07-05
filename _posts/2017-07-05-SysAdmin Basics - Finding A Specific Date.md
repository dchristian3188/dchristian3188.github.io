---
layout: post
title: SysAdmin Basics - Finding A Specific Date
---

Dates are hard, that makes scheduling hard.
Ever had someone tell you to be ready on the first Monday of the month?
Don't forget patches come out on the second Tuesday.
My personal favorite is the fourth Thursday in November (Thanksgiving here in the states).
While these types of dates are easy to remember, they can be hard to build automation around.
Don't worry with a couple of tricks and my helper function, I'll make sure you never miss Mother's Day again (second Sunday in May).

 **The Good Stuff:**
[Get-SpecificDate](https://github.com/dchristian3188/Main/blob/master/Functions/Get-SpecificDate.ps1), a function to find day of week occurrences in a given month.

<!-- more -->

# Get-SpecificDate

## Parameters

The ```Get-SpecificDate``` function takes a couple of parameters.
The ```Instance``` parameter expects one of the following strings: ```First```, ```Second```, ```Third```, ```Fourth```, ```Fifth``` or ```Last```.
Next is the ```Day``` parameter, which expects a value from the ```DayOfWeek``` enum.
What's neat about using this enum is you can use either a integer or string to specify the day.
For example ```0``` or ```Sunday```.
Better still, you only really need to specify enough of the string to make it unique (```Sun``` or ```F``` would work fine).
Next is the ```Month``` parameter, specified as an integer.
If you don't specify a value, it will default to using the current month.
Same for the ```Year``` parameter.

## How Does This Work

We start by finding the first instance of that day in the month.
To do this, we'll start on the first and walk the month till we find the day we're looking for.

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
Patch Tuesday is a great example a recurring event most administrators plan for.
Since ```Get-SpecificDate``` accepts pipeline input, one thing we can do is pipe our months into the function.
Also since the output is a ```DateTime``` object, we can use the ```ToLongDateString``` method to cleanup the output.

```powershell
(1..12 | Get-SpecificDate Second Tuesday).ToLongDateString()
```

Output:

```powershell
Tuesday, January 10, 2017
Tuesday, February 14, 2017
Tuesday, March 14, 2017
Tuesday, April 11, 2017
Tuesday, May 9, 2017
Tuesday, June 13, 2017
Tuesday, July 11, 2017
Tuesday, August 8, 2017
Tuesday, September 12, 2017
Tuesday, October 10, 2017
Tuesday, November 14, 2017
Tuesday, December 12, 2017
```

## Checking Only Today

Here's a cool one to use combined with task scheduler.
Pretend you have a script that needs to run the third Sunday of every month.
What you could do is create a scheduled task to execute your PowerShell script every day.
The trick is, you add this snippet to the top of your script.

```powershell
# We use short date string since we don't care about the time
$today = (Get-Date).ToShortDateString()
$targetDate = (Get-SpecificDate -Instance Third -Day Sunday).ToShortDateString()

if($today -eq $targetDate)
{
    #Your code goes here
}
else
{
    #Write a log message then exit
}
```

# Wrapping Up

The completed function is [here.](https://github.com/dchristian3188/Main/blob/master/Functions/Get-SpecificDate.ps1)
Leave a comment and let me know what dates you're keeping track of.
