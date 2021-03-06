---
layout: post
title: Finding An Available File Name
---

The last couple of weeks I've been doing a lot of reorganizing of some of my media files.
Part of this reorg has been shifting files around and consolidating folders.
One challenge I ran into was having files with conflicting names.
Since I don't want to accidentally override any files, I created this helper function to test if a file name already exists.
If it does detect a conflict, it will keep appending a number until it finds an available name.

**The Good Stuff:**
Use [Get-AvailableFileName](https://github.com/dchristian3188/Main/blob/master/Functions/Get-AvailableFileName.ps1) to help find a name that's not already in use.

<!-- more -->

The main logic of the function is pretty straightforward.
The first thing we do is test if the name already exists.
If the file doesn't it exists it will return this name since it's safe to use.
If it does exist, I break up the folder, filename, and extension into their own variables.
These variables will come in handy later when we're reconstructing the name.
We can leverage the ```IO.Path``` namespace to retrieve some of this information.

```powershell
  if (Test-Path -Path $newName)
{
    $folder = Split-Path -Path $newName -Parent
    $basename = [IO.Path]::GetFileNameWithoutExtension($newName)
    $extension = [IO.Path]::GetExtension($newName)
    $counter = 1
}
```

Since the original name was already taken, we'll try appending a number to the file.
This process repeats till we find something we can use.

```powershell
 while (Test-Path -Path $newName)
{
    $newName = "$($folder)\$($basename)($counter)$($extension)"
    $counter++
}
Write-Output -InputObject $newName
```

Like I said, not too bad.
Ok, here's a contrived example that shows the function in action.
The below PowerShell will create test a file then make 5 copies of it.
To keep the copies from stepping all over each I'll use ```Get-AvailableFileName``` to find the next increment.

```powershell
$demoRoot = 'C:\temp'
$testFile = Join-Path -Path $demoRoot -ChildPath 'TestFile.txt'
New-Item -Path $demoRoot -ItemType Directory -ErrorAction 0 > $null
New-Item -Path $testFile -ItemType File -ErrorAction 0 > $null

1.. 5 | ForEach-Object -Process {
    $dest = Get-AvailableFileName -Path $testFile
    Copy-Item -Path $testFile -Destination $dest -Verbose
}
```

Here's a screenshot of it in action.
To make sure there's nothing funny going on, I ran the script twice to see if the numbers truly are incrementing.

![_config.yml]({{ site.baseurl }}/images/GetAvailableFile.png)

That's all for today.
My plan is to create a module for all my file and folder helpers (I'm starting to build a pretty cool collection).
If you found this helpful, leave a comment with your use case.
