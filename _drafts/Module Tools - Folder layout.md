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
Eventually, you end up with a monster of a file.
I recently came across a project that had a 32 thousand line PSM1 with a couple hundred functions defined in it.
While its ok to package our module into a combined file, managing it in this format in source is a nightmare to maintain.

One of the biggest disadvantages of the single file format is function discoverability.
When everything is defined in its own PSM1, how do you tell what functions are in the module?
I know I can run ```Get-Command -Module MyModuleName```, but what about the private functions?
This approach to module development can also come at an additional price.
As your project grows and gains tractions, hopefully, you have multiple people contributing.
By placing all your code in one file, you increase the chance for merge conflicts.
While most source control is smart enough to figure it out, there is a higher change when using this approach.

I feel a better approach is to seperate your module into sections when working locally.
Every piece of code should be broken up into its own file.
For example, each function gets saved in its own PS1, with the function name as the file name.
These then get broken up futher with folders for public and internal functions.
Classes and dsc resources also follow this pattern, with their own files and folders.
Tests, also get placed in their own folder.
The naming convention i follow is ```Function-Name.tests.ps1```.

Here's an example from the HideWindowsExplorerDrives module.

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

There's two tricks the really make this approach work.
The first is a dynamic PSM1 that loads the module in this format.
The second is using ```Invoke-Build``` to combine our files and "package up" our module for deployment.
More on this to come in an upcomming post.

Let's take a look at the dynamic PSM1.
Instead of defining the functions, it enumerates the function folders and dot source's them into the module's session.
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

With this generic PSM1 in place, we can now import our module when working locally.
This is a great way to test your work during the development process.
While I have seen some projects ship modules in this layout, I still feel it's more polished to combine them before deployment.
Stay tuned for the next article in our module series, Adding Help with PlatyPS.