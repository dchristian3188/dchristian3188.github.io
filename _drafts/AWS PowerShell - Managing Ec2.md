---
layout: post
title: AWS PowerShell - Managing Ec2
---

The AWS Tools for PowerShell let you manage all your EC2 instances with cmdlets.
With full coverage for machine creation, deletion and updating, virtually all settings are configurable from the PowerShell console.
Let's dive in and learn to manage EC2 from PowerShell!

**The Good Stuff:**
Check out the AWS Tools for Powershell and start managing EC2 from your shell today

<!-- more -->

<!-- TOC -->

- [Creating EC2 Instances](#creating-ec2-instances)
    - [Instance Size](#instance-size)
    - [Choosing a key pair](#choosing-a-key-pair)
    - [Passing User Data](#passing-user-data)
    - [Choosing Security Groups](#choosing-security-groups)
    - [So Many More Options](#so-many-more-options)
- [EC2 Lifecycle](#ec2-lifecycle)

<!-- /TOC -->

# Creating EC2 Instances

Creating an EC2 instance with all the defaults couldn't be simpler.
If all you need is an instance you can pipe from one of the ```Get-EC2Image``` cmdlets to ```New-EC2Instance```.
Here's the command I could run to create a new Windows Server 2016 host, setup for docker.
Since I'm using ```Get-EC2ImageByName``` I know I'll be getting the latest version for my region.

```powershell
Get-EC2ImageByName  -Name WINDOWS_2016_CONTAINER | 
    New-EC2Instance
```

Ok, that was easy.
But EC2 wouldn't be so popular unless we could customize our instances and tweak our settings.
Here are some of the most popular switches and settings that you will need to change.

## Instance Size

Instance type is definitely one of the first things you'll want to tweak.
By default, if you don't supply an instance, it will default to ```m1.small```.
This can be a little pricey if we're testing things out.
To change your instance size, use the ```InstanceType``` parameter.
Here's an example setting the size to ```t2.micro```

```powershell
Get-EC2ImageByName  -Name WINDOWS_2016_CONTAINER | 
    New-EC2Instance -InstanceType t2.micro
```

I'm always too lazy to look up all the possible sizes.
This is one place PowerShell and the PSReadLine module really come in handy.
When working at the shell you can type ```-InstanceType``` and then press ```ctrl``` + ```space```.
This will pop the autocomplete and show you a list of all available sizes.
Take a look at this to see it in action.

![_config.yml]({{ site.baseurl }}/images/aws/ec2Instance.gif)

## Choosing a key pair

One of the neat things about AWS is its key pairs and the ability to generate admin passwords at machine creation.
If you've been following best practices and using multiple key pairs for different purposes, this is something you often need to pass at machine provisioning.
To select a different key pair, use the ```KeyName``` parameter.
Here's what that would look like if I wanted to use a key pair named "dscKey"

```powershell
Get-EC2ImageByName  -Name WINDOWS_2016_CONTAINER | 
    New-EC2Instance -InstanceType t2.micro -KeyName dscKey
```

## Passing User Data

User data is a way for you to pass instance-specific information into the machine.
In the past as part of a deployment workflow, I've used this to tag a machine with the information it would need to connect to a DSC pull server.
To use user data, pass your PowerShell script inside ```<powershell>``` tags.
The instance also requires you to base64 encode the script.
To get around this, make sure you pass both the ```UserData``` parameter with the ```EncodeUserData``` switch.
Here's a super simple example.

```powershell
$userData = @'
<powershell>
$file = "C:\TestFile-$((Get-Date).ToString("MM-dd-yy-hh-mm")).txt"
Set-Content -Path $file -Value "Hi from OverPowerShell!" -Force
</powershell>
'@

Get-EC2ImageByName  -Name WINDOWS_2016_CONTAINER | 
    New-EC2Instance -InstanceType t2.micro -UserData $userData -EncodeUserData
```

## Choosing Security Groups

There are two ways to assign a security group when creating an EC2 instance.
We could either use the ```SecurityGroup``` or ```SecurityGroupId``` parameters.
Let's keep things simple and use the friendly group names in our example.
Here's what it looks like assigning a new instance to both the "SoCalPoshDSCDemo" and "AdminAccess" group.

```powershell
Get-EC2ImageByName  -Name WINDOWS_2016_CONTAINER | 
    New-EC2Instance -InstanceType t2.micro -
```

## So Many More Options

At the time of this writing, there are 61 different parameters you can pass to ```New-EC2Instance```.
If you don't believe me, run ```(Get-Command New-EC2Instance).Parameters.Count```.
With so many parameters we could spend weeks diving into each one.
Chances are if you can set it in the AWS console, you can set in the command line.
Remember, ```Get-Help New-EC2Instance``` and the online AWS Tools documentation is your best friend.

# EC2 Lifecycle

When it comes to general care and feeding of EC2 Instances, the AWS tools module has plenty of options.
If you want to generate this list yourself, run ```Get-Command -Noun EC2Instance```.

```powershell
CommandType     Name                                               Version    Source
-----------     ----                                               -------    ------
Cmdlet          Get-EC2Instance                                    3.3.313.0  AWSPowerShell.NetCore
Cmdlet          New-EC2Instance                                    3.3.313.0  AWSPowerShell.NetCore
Cmdlet          Remove-EC2Instance                                 3.3.313.0  AWSPowerShell.NetCore
Cmdlet          Restart-EC2Instance                                3.3.313.0  AWSPowerShell.NetCore
Cmdlet          Start-EC2Instance                                  3.3.313.0  AWSPowerShell.NetCore
Cmdlet          Stop-EC2Instance                                   3.3.313.0  AWSPowerShell.NetCore
```

Since all of these use common verbs, it is trivial to tell what each command does.
If you've been following along in this article, you now have a bunch of machines sitting in your console.
Here's a simple way (and very PowerShell way) to clean them all up.
Be careful as this will **remove all** your instances.

```powershell
Get-EC2Instance | 
    Remove-EC2Instance -Verbose -Force
```