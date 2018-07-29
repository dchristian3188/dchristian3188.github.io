---
layout: post
title: AWS PowerShell - EC2 Key Pairs, Credentials and Connecting
---

Now that we know how to provision machines, I want to dive deeper in KeyPairs and how we can connect.
When working with on perm, credentials are easy, traditionally all you have to pass is your admin domain creds and go.
While you can extend active directory to the cloud (or use a hosted version), this is becoming less and less common.
Let's dig in and see how we can use key pairs to create credentials and connect.


**The Good Stuff:**
Is it really good though?

<!-- more -->

# Generating Key Pairs

Creating a new key pair is actually trivial.
To setup a new key pair run ```New-EC2KeyPair -KeyName myNewKeyPair```.
While this does ceate a key pair, all the relevant information is sent to the screen.
What we really need is the private key saved to a file so we can use it.
First thing you want to do is save the key to a variable

```powershell
$keyPair = New-EC2KeyPair -KeyName OverPoweredShell
```

Your key pair should have 3 properties, ```KeyName```, ```KeyFingerprint```, and ```KeyMaterial```.
The property that we need to save (and you need to keep safe) is the ```KeyMaterial``` property.
This is your private key and what will be used to decrypt the passwords.

![_config.yml]({{ site.baseurl }}/images/aws/keypair.png)

The last thing to do is save this private key so we can use it later.
The below command is what I can use, if I want to store my private key in the ```C:\AWS``` folder.

```powershell
Set-Content -Path 'C:\AWS\OverPoweredShell.pem' -Value $keyPair.KeyMaterial -Force
```