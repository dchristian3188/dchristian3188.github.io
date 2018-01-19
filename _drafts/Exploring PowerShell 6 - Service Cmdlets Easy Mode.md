---
layout: post
title: Exploring PowerShell 6 - Service Cmdlets Easy Mode
---

Write some stuff about your post here!

**The Good Stuff:**
Is it really good though?

<!-- more -->


$cred = Get-Credential
$service = Get-CimInstance -ClassName Win32_Service -Filter "Name='MyService'"
$serviceParams = @{
    StartName = $cred.UserName
    StartPassword = $cred.GetNetworkCredential().Password
}

Invoke-CimMethod -InputObject $service -MethodName Change -Arguments $serviceParams



Invoke-CimMethod -InputObject $service -MethodName Delete -Arguments $serviceParams