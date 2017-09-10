---
layout: post
title: Module Tools - Folder layout
---

Next up in our series of working with Module Tools is folder layout.
In our [first post,](http://overpoweredshell.com//Module-Tools-Starting-Off/) we used Plaster to scaffold our new module.
Now let's dive into the folder structure and how this layout can simplify our development.

**The Good Stuff:**
Make your module development easier by writing small functions and keeping them in own PS1 files.

<!-- more -->

If you're brand new to modules, I highly recommend Kevin Marquette's ["Building a Module, one microstep at a time"](https://kevinmarquette.github.io/2017-05-27-Powershell-module-building-basics/) article as a primer.

The traditional approach to writing a module involves a simple layout.
For the absolute basics, all you need is a PSM1.
You define all the functions in the PSM1 and you are good to go.
The challenge with this is as your module grows, so does your PSM1.
Eventually, you can end up with a monster file with a ton of functions in them (I recently came across a project with a 32K line PSM1 with a couple hundred functions defined in it)
While this might ok for something that is packaged and deployed, it's a nightmare to maintain.

This approach to module development can also come at an additional price.
As your project grows and gains tractions, hopefully, you have multiple people contributing.
By placing all your code in one file, you increase the chance for merge conflicts.
While most source control is smart enough to figure it out, there is a much higher chance than isolating code to its own file.

Last but not least, I feel this method does not lend it self well to discovery.
When everything is defined in its own PSM1, how do you tell what functions are in the module?
I mean you can do a search for ```Function``` but that can potentially grab comments as well.
Maybe a regex like ```function \w+-\w+ \{``` but that won't grab non-standard function names.
Plus how do you know what is a private function vs. a public function?

I feel a better approach is to seperate your module into sections when working locally.
Every piece of code should be broken up into its own file.
Each function gets saved in its own PS1, with the function name as the file name.
These then get broken up futher with folders for public and internal functions.
Classes and dsc resources also follow this approach, with their own files and folders.
I usually place my all my tests in one folder.
I like to place all the tests for one function of class in it's own file.
The naming convention i follow is ```Function-Name.tests.ps1```.

For this approach to work, we need to have a speically crafted PSM1 file.
Instead of defining the functions in the PSM1, it enumerates the function folders and dot source's them into our session.
Next since we know what functions are public (thanks to our folders), we can grab the function names and run the ```Export-ModuleMember```.
Here's what the generic PSM1 will look like.

```powershell
$functionFolders = @('Public', 'Internal', 'Classes')
ForEach ($folder in $functionFolders)
{
    $folderPath = Join-Path -Path $PSScriptRoot -ChildPath $folder
    If (Test-Path -Path $folderPath)
    {
        Write-Verbose -Message "Importing from $folder"
        $functions = Get-ChildItem -Path $folderPath -Filter '*.ps1' 
        ForEach ($function in $functions)
        {
            Write-Verbose -Message "  Importing $($function.BaseName)"
            . $($function.FullName)
        }
    }
}
$publicFunctions = (Get-ChildItem -Path "$PSScriptRoot\Public" -Filter '*.ps1').BaseName
Export-ModuleMember -Function $publicFunctions
```

```powershell
C:.
│   .gitignore
│   HideWindowsExplorerDrives.build.ps1
│   HideWindowsExplorerDrives.psd1
│   HideWindowsExplorerDrives.psm1
│
├───Internal
│       Get-HiddenDriveValue.ps1
│       Get-LetterMap.ps1
│       New-LetterMap.ps1
│       Set-HiddenDriveValue.ps1
│       Test-IsAdmin.ps1
│
├───Public
│       Get-DriveStatus.ps1
│       Hide-DriveLetter.ps1
│       Show-DriveLetter.ps1
│
└───Tests
        Get-DriveStatus.tests.ps1
        Get-LetterMap.tests.ps1
        Hide-DriveLetter.tests.ps1
        HideWindowsExplorerDrives.tests.ps1
        Show-DriveLetter.tests.ps1
```
