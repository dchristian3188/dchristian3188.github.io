---
layout: post
title: AWS PowerShell - Getting Started on Core
---

It's almost impossible to talk about DevOps these days without mentioning the cloud.
People get can be incredibly passionate about which service is the best and why.
What ever your opinion, it's undeniable that Amazon Web Services (AWS) is one of the most mature and feature rich providers in this space.
Best of all they treat PowerShell like a first class citzen.
Even better you can run AWS tools for Windows Powershell in PowerShell core!


**The Good Stuff:**
Check out [AWS Tools for Windows PowerShell](https://docs.aws.amazon.com/powershell/latest/userguide/pstools-using.html)

<!-- more -->

The AWS tools module is available on the PowerShell gallery.
To install them on PowerShell core, we can run the below command.

```powershell
Install-Module -Name AWSPowerShell.NetCore -Verbose -Force
```

If you're not using PowerShell Core, but Windows PowerShell instead, you can use this command:

```powershell
Install-Module -Name AWSPowerShell
```

The next thing to do is to setup your credentials used to connect to AWS.
What's a little different here, is that you don't supply a PSCredential.
Instead you create an access key inside the AWS console and use that.
To do this from the main AWS console follow these steps:

1. Click on IAM
1. Click users
1. Click the username you want to create the access key for
1. Click the security credentials tab
1. Finally click create access key

Once you have the access key created, we can run the below powershell command.
Here's an example, using my access key and secret.

```powershell
Set-AWSCredential -AccessKey 'AKIAIK4OGJRXYXEDOKZA' -SecretKey 'rLw8vTBhoH6CZqUjOOnb/1mg3gfY9gRB8TEZxdMP'
```

Now by default doing this, only setups up the credentials in your current session.
If you want to store them permantely use can use the ```-StoreAs``` switch.
If you only have one set of accounts, I recommend using the below command as it will setup 

```powershell
Set-AWSCredential -AccessKey 'AKIAIK4OGJRXYXEDOKZA' -SecretKey 'rLw8vTBhoH6CZqUjOOnb/1mg3gfY9gRB8TEZxdMP' -StoreAs default
```

This will write your credential to the default profile location.
When you do this, the AWS tools will use this credential without asking.
