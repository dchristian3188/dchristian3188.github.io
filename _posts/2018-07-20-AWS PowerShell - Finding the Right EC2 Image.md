---
layout: post
title: AWS PowerShell - Finding the Right EC2 Image
---

Now that we have the AWS Tools installed and our shell setup, it's time to start creating machines.
The most basic and probably most used feature of AWS is EC2.
There are literally thousands of different images to choose from.
With so many options and settings to tweak, finding the right image and starting a machine can sometimes feel overwhelming.
Luckily with the AWS tools for PowerShell, we'll have everything we need to find the right image.

**The Good Stuff:**
Learn how to find and start an EC2 Image with PowerShell.

<!-- more -->

The first command we need to learn is ```Get-EC2Image```.
When I ran this command with no parameters in us-west-2 this returned over 84,000 images.
That's not going to work, so let's see if we can narrow down our choices a little.
{: .highlight .nb}

A helpful command to use if we're trying to find a Window's image is ```Get-EC2ImageByName```.
When this command is run with no parameters, it will output all of the code names for the Windows images.
{: blue}

Output:

```
WINDOWS_2016_BASE
WINDOWS_2016_NANO
WINDOWS_2016_CORE
WINDOWS_2016_CONTAINER
WINDOWS_2016_SQL_SERVER_ENTERPRISE_2016
WINDOWS_2016_SQL_SERVER_STANDARD_2016
WINDOWS_2016_SQL_SERVER_WEB_2016
WINDOWS_2016_SQL_SERVER_EXPRESS_2016
WINDOWS_2012R2_BASE
WINDOWS_2012R2_CORE
WINDOWS_2012R2_SQL_SERVER_EXPRESS_2016
WINDOWS_2012R2_SQL_SERVER_STANDARD_2016
WINDOWS_2012R2_SQL_SERVER_WEB_2016
WINDOWS_2012R2_SQL_SERVER_EXPRESS_2014
WINDOWS_2012R2_SQL_SERVER_STANDARD_2014
WINDOWS_2012R2_SQL_SERVER_WEB_2014
WINDOWS_2012_BASE
WINDOWS_2012_SQL_SERVER_EXPRESS_2014
WINDOWS_2012_SQL_SERVER_STANDARD_2014
WINDOWS_2012_SQL_SERVER_WEB_2014
WINDOWS_2012_SQL_SERVER_EXPRESS_2012
WINDOWS_2012_SQL_SERVER_STANDARD_2012
WINDOWS_2012_SQL_SERVER_WEB_2012
WINDOWS_2012_SQL_SERVER_EXPRESS_2008
WINDOWS_2012_SQL_SERVER_STANDARD_2008
WINDOWS_2012_SQL_SERVER_WEB_2008
WINDOWS_2008R2_BASE
WINDOWS_2008R2_SQL_SERVER_EXPRESS_2012
WINDOWS_2008R2_SQL_SERVER_STANDARD_2012
WINDOWS_2008R2_SQL_SERVER_WEB_2012
WINDOWS_2008R2_SQL_SERVER_EXPRESS_2008
WINDOWS_2008R2_SQL_SERVER_STANDARD_2008
WINDOWS_2008R2_SQL_SERVER_WEB_2008
WINDOWS_2008RTM_BASE
WINDOWS_2008RTM_SQL_SERVER_EXPRESS_2008
WINDOWS_2008RTM_SQL_SERVER_STANDARD_2008
WINDOWS_2008_BEANSTALK_IIS75
WINDOWS_2012_BEANSTALK_IIS8
VPC_NAT
```

Now, that we know these code names, let's run the same command using that for the ```Name``` parameter.
This time we should get the image details.
Here's what that looks like when I query for the Windows Server 2016 Base image.

```powershell
Get-EC2ImageByName -Name WINDOWS_2016_BASE
```

Output:

```
Architecture        : x86_64
BlockDeviceMappings : {/dev/sda1, xvdca, xvdcb, xvdcc...}
CreationDate        : 2018-07-11T22:51:13.000Z
Description         : Microsoft Windows Server 2016 with Desktop Experience Locale English AMI provided by Amazon
EnaSupport          : True
Hypervisor          : xen
ImageId             : ami-6d336015
ImageLocation       : amazon/Windows_Server-2016-English-Full-Base-2018.07.11
ImageOwnerAlias     : amazon
ImageType           : machine
KernelId            :
Name                : Windows_Server-2016-English-Full-Base-2018.07.11
OwnerId             : 801119661308
Platform            : Windows
ProductCodes        : {}
Public              : True
RamdiskId           :
RootDeviceName      : /dev/sda1
RootDeviceType      : ebs
SriovNetSupport     : simple
State               : available
StateReason         :
Tags                : {}
VirtualizationType  : hvm
```

There's a couple of reasons this command is so helpful.
The first is that we create EC2 images by referencing the ```ImageID```, not a name.
These images ID's can change depending on the region, or when Amazon makes a change to the OS, for example, applying the latest patches.
By using the above command, we can ensure that we have the most up to date and the appropriate image ID for the OS we're looking for.

Ok, now that we know the basics, let's take a second look at ```Get-EC2Image```.
One of the few parameters on this cmdlet is ```Filter```.
The ```Filter``` parameter takes an ```Amazon.EC2.Model.Filter[]``` type.
What's neat is that we can actually create a hashtable with some special keys and the cmdlet will cast it to the correct object under the hood.
This hashtable should have 2 entries.
The first is a key named ```name```.
This is the field that we want to search.
The second key is ```value```.
This is, you guessed it, the value to search for in the name field.
To get a list of available filter options run this command.

```powershell
Get-Help Get-EC2Image -Parameter filter
```

Let's say, I was looking for a Red Hat image.
I could use this command to search the description and return all images with "Red Hat" in the description.

```powershell
$filter = @{
    Name   = 'description' 
    Values = 'Red Hat *'
}
Get-EC2Image -Filter $filter | 
    Select-Object Name, Description, ImageId
```

It's important to point out that both the name parameter and the values are case sensitive.
For example, if you try using ```Name = 'Description'``` you would get an invalid filter error.
Here's a neat experiment that will demonstrate what I mean.
Try running the below two commands and see how different the output is.

```powershell
$filter = @{
    Name   = 'name' 
    Values = 'Red*'
}

Get-EC2Image -Filter $filter | 
    Select-Object ImageId, Name
```

```powershell
$filter = @{
    Name   = 'name' 
    Values = 'red*'
}

Get-EC2Image -Filter $filter | 
    Select-Object ImageId, Name
```

Once you finally find the image, starting a new instance (with all default parameters) really couldn't be easier.
Simply pipe you image into ```New-Ec2Instance```.
Here's what launching a new Windows Server 2016 Container host would look like.

```powershell
Get-EC2ImageByName  -Name WINDOWS_2016_CONTAINER | 
    New-EC2Instance
```

And just like, in a few minutes, we'll have a new instance ready to use!
Stay tuned for a follow-up article where we'll dive deep into some of the ```New-Ec2Instance``` parameters, learn to manage existing instances and cleanup old machines.