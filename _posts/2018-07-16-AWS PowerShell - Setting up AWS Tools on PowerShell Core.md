---
layout: post
title: AWS PowerShell - Setting up AWS Tools on PowerShell Core
---

It's almost impossible to talk about DevOps these days without mentioning the cloud.
People are incredibly passionate about which service is the best and why.
Whatever your opinion, it's undeniable that Amazon Web Services (AWS) is one of the most mature and feature-rich providers in this space.
They treat PowerShell like a first-class citizen and best of all, you can run AWS tools for Powershell in PowerShell core!

**The Good Stuff:**
Check out [AWS Tools for Windows PowerShell](https://docs.aws.amazon.com/powershell/latest/userguide/pstools-using.html)

<!-- more -->

# Installation

The AWS tools module is available on the PowerShell gallery.
To install them on PowerShell core, we can run the below command.

```powershell
Install-Module -Name AWSPowerShell.NetCore -Verbose -Force
```

If you're not using PowerShell Core, but Windows PowerShell instead, you can use this command:

```powershell
Install-Module -Name AWSPowerShell -Verbose -Force
```

# Setting Up Our Session

Once you have the module loaded, the next thing to do is to set up the credentials used to connect to AWS.
What's a little different here, is that you don't supply a PSCredential.
Instead, you create an access key inside the AWS console and use that.
To do this from the main AWS console follow these steps:

1. Click on IAM
1. Click users
1. Click the username you want to create the access key for
1. Click the security credentials tab
1. Finally, click create access key

## Manually Setting Credentials

Once you have the access key created, we can run the below PowerShell command.
Here's an example, using my access key and secret.

```powershell
Set-AWSCredential -AccessKey 'AKIAIK4OGJRXYXEDOKZA' -SecretKey 'rLw8vTBhoH6CZqUjOOnb/1mg3gfY9gRB8TEZxdMP'
```

It's important to note that this only sets credentials in your current session.
If you want to store them permanently use the ```-StoreAs``` switch.
You can give the credential any name, but if you use ```default```, these will get loaded automatically whenever AWS tools needs a credential.

```powershell
$awsCreds = @{
    AccessKey = 'AKIAIK4OGJRXYXEDOKZA'
    SecretKey = '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'
    StoreAs   = 'default'
}

Set-AWSCredential @awsCreds
```

Another option is saving the credentials to a file.
Helpful if you are working with multiple credentials or some automated process needs to use them.
Be careful with this approach though, since the credentials and profile get stored in clear text.
Here's an example of what that looks like:

```powershell
$awsCreds = @{
    AccessKey       = 'AKIAIK4OGJRXYXEDOKZA'
    SecretKey       = 'rLw8vTBhoH6CZqUjOOnb/1mg3gfY9gRB8TEZxdMP'
    StoreAs         = 'dchristian3188'
    ProfileLocation = 'C:\AWS\demoProfile'
}

Set-AWSCredential @awsCreds
```

## Managing Credentials

Like you would expect we can also manage the credentials on our machine with PowerShell.
To get a list of saved credentials we can run ```Get-AWSCredential -ListProfileDetail```.
Here's what that looked like on my machine.

![_config.yml]({{ site.baseurl }}/images/aws/getcred.png)

To remove a credential that is no longer in use just run ```Remove-AWSCredentialProfile```.
Here's what the command I used to delete the dchristian3188 profile.

```powershell
Remove-AWSCredentialProfile -ProfileName dchristian3188 -Force -Verbose
```

I like to point out, that you cannot pipe from ```Get-AWSCredential``` to ```Remove-AWSCredentialProfile```.
I think that's so you don't accidentally remove all profiles on your machine.
This makes senses but does make removing all credentials a pain.
Here's a one-liner to get the job done.

```powershell
Get-AWSCredential -ListProfileDetail | 
    ForEach-Object { Remove-AWSCredentialProfile -ProfileName $PSItem.ProfileName -Force }
```

## Setting a Default Region

The last thing you'll probably want to do is set a default region.
Almost all of the AWS Cmdlets require that you supply a region.
If you have a region that you primarily work in, setting a default can save you a lot of time.

You'll need to use technical region name, not the friendly one.
To get a list of regions, just run ```Get-AWSRegion```.
I primarily work out of the US West Oregon.
Here's what setting that as my default would look like.

```powershell
Set-DefaultAWSRegion -Region us-west-2
```

To update the region, just run the command again.
Optionally you can clear all defaults by running ```Clear-DefaultAWSRegion```.

Alright with all this in place, your ready to get started automating AWS!

For more articles about PowerShell and AWS please check out:

* [Setting up AWS Tools on PowerShell Core](https://overpoweredshell.com//AWS-PowerShell-Setting-up-AWS-Tools-on-PowerShell-Core/)
* [Finding the Right EC2 Image](https://overpoweredshell.com//AWS-PowerShell-Finding-the-Right-EC2-Image/)
* [Creating Ec2 Instances and Basic Machine Management](https://overpoweredshell.com//AWS-PowerShell-Creating-Ec2-Instances-and-Basic-Machine-Management/)
* [EC2 Key Pairs, Credentials and Connecting](https://overpoweredshell.com//AWS-PowerShell-EC2-Key-Pairs,-Credentials-and-Connecting/)
* [EC2 Tags and Filtering](https://overpoweredshell.com//AWS-PowerShell-EC2-Tags-and-Filtering/)