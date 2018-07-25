---
layout: post
title: AWS PowerShell - Managing Ec2
---

The AWS Tools for PowerShell let you manage all your EC2 instances with cmdlets.
With full coverage for machine creation, deletion and updating virtually all settings are configurable from the console.
Let's dive in and learn to manage EC2 from PowerShell!

**The Good Stuff:**
Check out the AWS Tools for Powershell and start managing EC2 from your shell today

<!-- more -->

# Creating EC2 Instances

Creating an EC2 instance with all the defaults couldn't be simplier.
If all you need is an instance you can pipe from one of the ```Get-EC2Image``` cmdlets to ```New-EC2Instance```.
Here's the command I could run to create a new Windows Server 2016 host, setup for docker.
Since I'm using ```Get-EC2ImageByName``` I know I'll be getting the lastest version for my region.

```powershell
Get-EC2ImageByName  -Name WINDOWS_2016_CONTAINER | 
    New-EC2Instance
```

Ok thats was easy.
But EC2 wouldn't be so popular unless we could customize our instances and tweak our settings.
Here's some of the most popular switches and settings that you will need to change.

## Instance Size

Instance type is definately one of the first things you'll want to tweak.
By default, if you don't supply an instance, it will default to ```m1.small```.
This can be a listtle pricey if we're just testing stuff out.