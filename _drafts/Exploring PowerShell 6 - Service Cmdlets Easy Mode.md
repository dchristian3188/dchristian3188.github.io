---
layout: post
title: Exploring PowerShell 6 - Service Cmdlets Easy Mode
---

I'm not sure if you guys have heard, but PowerShell Core 6.0 is out.
Today I want to talk about some of my favorite quality of life improvements.
There have been some changes to the *-Service cmdlets.
Let's dive in and take a look.

**The Good Stuff:**
Start playing with the new features on the *-Service cmdlets in PowerShell 6.

<!-- more -->

Now if you're a CIM guru like Mr. Richard Siddaway, you know all about the Win32_Service CIM class.
But if your a mere mortal like me, interacting with CIM can be a little scary.
The PowerShell team was kind enough to create the *-Service cmdlets for us, which hides the direct interaction making it much more user-friendly.
Unfortunately, there was a couple of common scenarios that weren't cover by the cmdlets and required us to dive into the CIM methods.

## Changing A Service's Credential

Any admin worth his salt has had to update a credential on a service.
Surprisingly before PowerShell 6, there was no easy way to do this without interacting with Win32_Service.
Here's a little code snippet I would use update the credential on a service.

```powershell
$cred = Get-Credential
$service = Get-CimInstance -ClassName Win32_Service -Filter "Name='MyService'"
$serviceParams = @{
    StartName = $cred.UserName
    StartPassword = $cred.GetNetworkCredential().Password
}

Invoke-CimMethod -InputObject $service -MethodName Change -Arguments $serviceParams
```

Powershell 6 makes this super easy by adding a new parameter, Credential, to the ```Set-Service``` cmdlet.
Let's take a look at what that previous command looks like in PowerShell 6.

```powershell
$cred = Get-Credential
Set-Service -Name MyService -Credential $cred
```

And that's all there is to it.
No more CIM gibberish and our script is much more legible.

## Removing a Service

This one use to always blow my mind.
The PowerShell team added support for creating and updating a service but if you wanted to delete it, you were out of luck.
This is another scenario were CIM could come to the rescue.
Here's what removing a service looked like before Version 6.

```powershell
Get-CimInstance -ClassName Win32_Service -Filter "Name='MyService'" |
    Invoke-CimMethod -MethodName Delete
```

While this method totally works, you have to know it's there to leverage it.
Starting in PowerShell 6, we finally have a ```Remove-Service``` cmdlet.
Here's the PowerShell 6 equivalent.

```powershell
Remove-Service -Name MyService
```

What I love about this is the discoverability.
Plus it gives us full CRUD Coverage (Create, Read, Update, Delete) in the cmdlets.
So what's your biggest quality of life improvement in Powershell 6?
Leave a comment and let us know.
