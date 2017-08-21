---
layout: post
title: Hiding Windows Explorer Drives
---

In my previous post, I talked about what tools module authors should leverage.
Now that we know what we should be looking at, lets step through a real world example of how these all come together to form a module.
Over the next couple of posts, we will be looking at my HideWindowsExplorerDrives module.
The module itself is pretty straightforward, it takes a drive letter and lets you hide it from Windows Explorer.
With a couple of functions, it should give us enough to talk.
Before we get to the tools, let's look at the final product.

**The Good Stuff:**
Check out the  [HideWindowsExplorerDrives](https://www.powershellgallery.com/packages/HideWindowsExplorerDrives) module today.

<!-- more -->

# Installation

The latest version of HideWindowsExplorerDrives is available PowerShell Gallery.
Here's what the full installation command looks like.

```powershell
Install-Module -Name HideWindowsExplorerDrives -Verbose
```

# Functions

## Get-DriveStatus

The ```Get-DriveStatus```