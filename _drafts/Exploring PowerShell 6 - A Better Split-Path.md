---
layout: post
title: Exploring PowerShell 6 - A Better Split-Path
---
PowerShell Core 6.0 is out!
There's a ton of new features and even some old commands are getting some love.
Today we're gonna talk about some of the improvements that made it into ```Split-Path```.
Let's dive in and see what the team brought us.

**The Good Stuff:**
There's a new improved ```Split-Path``` with a couple quality of life changes, check it out!
<!-- more -->

## Getting an Extension

Finding a file extension is a pretty common task.
We had a couple of ways to do this before Powershell 6.0 was released, but none of which were straightforward.
The first way was using ```Get-Item```.
This worked because ```Get-Item``` returned a ```System.IO.FileInfo``` object with an extension property we could inspect.
Here's an example that will get the extension of our PowerShell profile (spoiler alert, it's going to be ```.ps1```).

```powershell
(Get-Item $PROFILE).Extension
```

Now if you didn't have a profile, you might have noticed the first disadvantage of this method.
For ```Get-Info``` to work, your file must exist.
As you can imagine there's plenty of scripting scenarios where this doesn't work.
To get around this, we can dive in and call the raw dot net method from ```System.IO.Path```.
Here's an example trying this on a file that doesn't exist.

```powershell
[System.IO.Path]::GetExtension('C:\temp\fakefile.txt')
```

This works but doesn't feel PowerShelly.
Well now in PowerShell 6, all we have to do is call ```Split-Path```.
There's been a new switch added, ```-Extension``` that does just this.
Here's what it looks like.
Noticed it also works for non-existent files.

```powershell
Split-Path 'C:\temp\fakefile.txt' -Extension
```

## Getting Just The Filename

Another common scenario we run into is when you have a path, and you need the filename without the extension.
Previously there were two ways to accomplish this.
The first was using ```Get-Item``` but this time using ```BaseName```.

```powershell
(Get-Item $PROFILE).BaseName
```

Remember though, this only worked if our file existed.
Again we could use dot net to work around this.

```powershell
[System.IO.Path]::GetFileNameWithoutExtension('C:\temp\fakefile.txt')
```

In PowerShell 6, we can do the same thing with ```Split-Path```, this time we'll use the ```-LeafBase```.
Here's what that looks like.

```powershell
Split-Path 'C:\temp\fakefile.txt' -LeafBase
```

## Splitting a UNC

Here's a neat one.
Previous to PowerShell 6, the ```Split-Path``` command didn't work on UNC roots.
For example, if ran ```Split-Path -Path \\server\share``` you would get a null result.
To get this info, we would need to use the Regex.
Here's what that would look like to get the server name for a UNC path.

```powershell
if("\\server\share" -match '(?<ServerName>^\\\\([a-z0-9_.$-]+))\\(?<ShareName>([a-z0-9_.$-]+))')
{
    $Matches.ServerName
}
```

Simple right...
Here's a similar approach to pick out the leaf, or share name.

```powershell
if("\\server\share" -match '(?<ServerName>^\\\\([a-z0-9_.$-]+))\\(?<ShareName>([a-z0-9_.$-]+))')
{
    $Matches.ShareName
}
```

Thankfully in PowerShell 6,```Split-Path`` just works on UNC roots.
You can use both ```-Parent``` or ```-Leaf``` and forget all about that regex gibberish.
Pretty cool right?
So what's your favorite new little feature of PowerShell 6?
