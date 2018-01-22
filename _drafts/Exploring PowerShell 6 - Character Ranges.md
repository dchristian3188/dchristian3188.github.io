---
layout: post
title: Exploring PowerShell 6 - Character Ranges
---

PowerShell Core 6.0 is now out and available for download.
Today I want to talk about a feature that may have taken PowerShell golf to a new level.
New with this release we can now enumerate character ranges, and skip the whole cast to char step!
Let's dive in and take a look.

**The Good Stuff:**
Take a look at ```"a".."z"``` and enumerate characters the easy way.

<!-- more -->

Being able to enumerate a range of letters has always been possible in PowerShell.
But before PowerShell 6, the way you did this was by casting an integer to it's ASCII equivalent.
ASCII is the standard computers use to represent all characters we see.
Remember a computer has no idea what "A" is but it can understand the number 65.
Take a look at this [chart](http://www.asciitable.com/) for a full breakdown ASCII codes to their numeric values.

Looking at the chart if we wanted to enumerate all letters from A to Z, we need to ask for the ASCII codes between 65 and 90.
The trick was we needed to cast each integer to a ```Char```.
By casting to ```Char``` we are able to see the ASCII character the integer corresponds too.
Here's what this looks like in PowerShell, leveraging the range operator, ```..```.

```powershell
65..90 | ForEach-Object {[Char]$PSItem}
```

Similarly, if we wanted all lower case letters, we could use the range 97 through 122.

```powershell
97..122 | ForEach-Object {[Char]$PSItem}
```

Now with PowerShell 6, the range operator just works with letters.
Here's what this command looks like in the new syntax.

```powershell
"A".."Z"
```

One important caveat here is that the letters must be surrounded in quotes (doesn't matter if single or double).
If you don't do this PowerShell will give you a nasty error message about the command not being recognized.
I think it's a little lame that we can't use ```A..Z``` but to be fair, you get the same message when you enter an unquoted string at the command line, so I get it.

What's interesting are some of the side effects that this new feature introduced.
What it's doing under the covers is checking if the first character is a string.
If it is, then it essentially treats that as the ASCII code and evaluates the range from there.
For example, what do you think this range does?

```powershell
"1"..45
```

Well in the previous version of PowerShell 6, it did what you would expect it too.
But if you run this command in the latest version you'll get this.

```powershell
1
0
/
.
-
```

The reason for this is that it treats the ```"1"``` as ASCII code 49, so this gets evaulated to range ```49..45```.
This means we can also step over weird ranges like this:

```powershell
(" ".."/") -join " "
```

Output:

```powershell
  ! " # $ % & ' ( ) * + , - . /
```

In closing, I want to point out a pretty serious bug with the new character range operators.
I don't believe all of the logic to convert the character range has been fully fleshed out.
Take a look at this example:


```powershell
"a".."z" | ForEach-Object {$PSItem}
```

Output:

```powershell
Cannot convert value "a" to type "System.Int32". Error: "Input string was not in a correct format."
At line:1 char:1
+ "a".."z" | ForEach-Object {$PSItem}
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+ CategoryInfo          : InvalidArgument: (:) [], RuntimeException
+ FullyQualifiedErrorId : InvalidCastFromStringToInteger
```

The team is aware of this and tracking it under Github bug number [#5519.](https://github.com/PowerShell/PowerShell/issues/5519)
I feel this is pretty unfortunate since being able to enumerate the range and then take some action on it, is kind of the whole point...
The current work around would be to save the range to a variable, then enumerate that variable since it'll be an array.
Something like this:

```powershell
$chars = "a".."z"
$chars | ForEach-Object {Write-Output "Processing $PSItem"}
```

That's all for today.
So what do you think?
Char ranges home run or swing and a miss?