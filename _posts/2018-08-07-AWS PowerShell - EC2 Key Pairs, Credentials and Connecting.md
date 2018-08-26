---
layout: post
title: AWS PowerShell - EC2 Key Pairs, Credentials and Connecting
---

Now that we know how to provision machines, I want to dive deeper into KeyPairs and how we can connect.
When working with on perm machines, credentials are easy.
Traditionally all you have to pass is your domain credentials and go.
While you can extend active directory to the cloud (or use a hosted version), this is becoming less and less common.
Let's dig in and see how we can use key pairs to create credentials and connect.


**The Good Stuff:**
Helper functions that speed up PsSession and RDP Creation for Windows EC2 Instances.

<!-- more -->


# Generating Key Pairs

Creating a new key pair is actually trivial.
To set up a new key pair run ```New-EC2KeyPair -KeyName myNewKeyPair```.
While this does create a key pair, all the relevant information is sent to the screen.
What we need is the private key saved to a file so we can use it.
The first thing you want to do is save the key to a variable.

```powershell
$keyPair = New-EC2KeyPair -KeyName OverPoweredShell
```

Your key pair should have 3 properties, ```KeyName```, ```KeyFingerprint```, and ```KeyMaterial```.
The property that we need to save (and you need to keep safe) is the ```KeyMaterial```.
This is your private key and what we'll use to decrypt the passwords.

![_config.yml]({{ site.baseurl }}/images/aws/keypair.png)

The last thing to do is save this private key so we can use it later.
The below command is what I use if I want to store my private key in the ```C:\AWS``` folder.

```powershell
Set-Content -Path 'C:\AWS\OverPoweredShell.pem' -Value $keyPair.KeyMaterial -Force
```

## Getting Passwords

Now that we have a new key created, let's provision a new EC2 instance using that key pair.
Below is the command I used to create a new Server 2016 image.
In this example, I pass the name to my key and a image size.

```powershell
Get-EC2ImageByName -Name WINDOWS_2016_BASE |
    New-EC2Instance -KeyName OverPoweredShell -InstanceType t2.micro
```

After a couple of minutes, your new instance will be up and running.
To get the default administrator password, we can use the builtin ```Get-EC2PasswordData``` Cmdlet.
Here I pass it my instance ID and the location of my pem file.

```powershell
Get-EC2PasswordData -InstanceId i-05b5d0777c8445761 -PemFile C:\aws\OverPoweredShell.pem
 ```

Output:

 ```powershell
V.ki.(rW@a-ptJJ4K!gcGSGBd)?DEr)r
 ```

## Creating PSCredentials

I like to point out that it's a little lame that I can't pipe from ```Get-EC2Instance```, right into ```Get-EC2PasswordData```.
I can work around it, but this command isn't very friendly...

```powershell
Get-EC2Instance | 
    Select-Object -ExpandProperty Instances |
    Where-Object KeyName -eq 'OverPoweredShell' |
    Get-EC2PasswordData -PemFile C:\aws\OverPoweredShell.pem
```

And since I'm complaining, I don't like that I get back a string.
It would be much better if this came back as a ```PSCredential```.
Here's a simple function that I came up with to make creating the credentials easier.

```powershell
Function Get-EC2Credential
{
    [CmdletBinding(DefaultParameterSetName = 'EC2Instance')]
    Param(
        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'InstanceID')]
        [String[]]
        $InstanceId,

        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'EC2Instance')]
        [PSCustomObject]
        $InputObject,

        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [ValidateScript(
            {
                if (-not(Test-Path -Path $PSItem))
                {
                    throw "Unable to find PemFile at path [$psitem]"
                }
                else
                {
                    $true
                }
            }
        )]
        [string]
        $PemFile
    )

    Process
    {
        if ($null -ne $InputObject.Instances.InstanceID)
        {
            $InstanceId = $InputObject.Instances.InstanceID
        }

        if ($null -ne $InputObject.InstanceID)
        {
            $InstanceId = $InputObject.InstanceID
        }
        
        foreach($insID in $InstanceId)
        {
            $securePassword = Get-EC2PasswordData -InstanceId $insID -PemFile $PemFile |
                ConvertTo-SecureString -AsPlainText -Force
                [PSCredential]::new('administrator', $securePassword)
        }
    }
}
```

Once you have the command loaded you can start doing cool things like the below pipeline.
This will return a PSCredential and the flow just feels more like traditional PowerShell.

```powershell
$cred = Get-EC2Instance -InstanceId i-05b5d0777c8445761  |
    Get-EC2Credential -PemFile C:\aws\OverPoweredShell.pem
```

# Connecting

## Creating PsSession

Now that we have a way to return our credential as an object, let's see if we can take it up a notch.
This is a PowerShell blog, so we'll make a PSSession using what the new cmdlet we just created.
Here's a helper function that wraps the logic needed to create PSSessions.

```powershell
Function New-EC2PSSession
{
    [CmdletBinding(DefaultParameterSetName = 'EC2Instance')]
    Param(
        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'InstanceID')]
        [String]
        $InstanceId,

        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'EC2Instance')]
        [PSCustomObject]
        $InputObject,

        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [ValidateScript(
            {
                if (-not(Test-Path -Path $PSItem))
                {
                    throw "Unable to find PemFile at path [$psitem]"
                }
                else
                {
                    $true
                }
            }
        )]
        [string]
        $PemFile
    )

    Process
    {
        if(![string]::IsNullOrEmpty($InstanceId))
        {
            $InputObject = Get-EC2Instance -InstanceId $InstanceId
        }

        foreach($instance in $InputObject.Instances)
        {
            if ($null -eq $instance)
            {
                Write-Error -Message  "Invalid EC2 Instance"
            }
    
            $publicIP = $instance.PublicIpAddress
            if([String]::IsNullOrEmpty($publicIP))
            {
                Write-Error -Message "No public IP address for instance [$($instance.InstanceId)]"
            }
            
            $cred = $instance | 
                Get-EC2Credential -PemFile $PemFile
            
            New-PSSession -ComputerName $publicIP -Credential $cred
        }
    }
}
```

With this new helper function in place, we're getting somewhere.
Here's the command I run to create a PSSession to all my machines at once!
From there ```Invoke-Command``` works like I expect.

```powershell
$sessions = Get-EC2Instance | 
    New-EC2PsSession -PemFile C:\aws\OverPoweredShell.pem 

Invoke-Command -PSSession $sessions -Scriptblock { Hostname}
```

## Wrapping RDP Sessions

Another thing I wanted to do is make an easy way to connect to RDP.
I use Jaap Brasser's [Connect-Mstsc](https://gallery.technet.microsoft.com/scriptcenter/Connect-Mstsc-Open-RDP-2064b10b) pretty heavily at work.
Using my ```Connect-EC2Mstsc``` function, we can wrap the logic needed to find the public IP, generate a credential, then call Jaap's function to connect.
Here's what the function definition looks like.

```powershell
Function Connect-EC2Mstsc
{
    [CmdletBinding(DefaultParameterSetName = 'EC2Instance')]
    Param(
        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'InstanceID')]
        [String]
        $InstanceId,

        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'EC2Instance')]
        [PSCustomObject]
        $InputObject,

        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [ValidateScript(
            {
                if (-not(Test-Path -Path $PSItem))
                {
                    throw "Unable to find PemFile at path [$psitem]"
                }
                else
                {
                    $true
                }
            }
        )]
        [string]
        $PemFile
    )

    Process
    {
        if(![string]::IsNullOrEmpty($InstanceId))
        {
            $InputObject = Get-EC2Instance -InstanceId $InstanceId
        }

        foreach($instance in $InputObject.Instances)
        {
            if ($null -eq $instance)
            {
                Write-Error -Message  "Invalid EC2 Instance"
            }

            $publicIP = $instance.PublicIpAddress
            if([String]::IsNullOrEmpty($publicIP))
            {
                Write-Error -Message "No public IP address for instance [$($instance.InstanceId)]"
            }

            $cred = $instance | 
                Get-EC2Credential -PemFile $PemFile

            Connect-Mstsc -ComputerName $publicIP -Credential $cred
        }
    }
}
```

With the function in place, connecting to the machines is pretty straightforward.
This below command will create an RDP session for each of my EC2 instances!

```powershell
Get-EC2Instance |
    Connect-EC2Mstsc -PemFile C:\aws\OverPoweredShell.pem
```

That's all for today.
I hope these functions make  connecting and managing EC2 instances feel a little more like working with on perm machines.

For more articles about PowerShell and AWS please checkout:

* [Setting up AWS Tools on PowerShell Core](https://overpoweredshell.com//AWS-PowerShell-Setting-up-AWS-Tools-on-PowerShell-Core/)
* [Finding the Right EC2 Image](https://overpoweredshell.com//AWS-PowerShell-Finding-the-Right-EC2-Image/)
* [Creating Ec2 Instances and Basic Machine Management](https://overpoweredshell.com//AWS-PowerShell-Creating-Ec2-Instances-and-Basic-Machine-Management/)
* [EC2 Key Pairs, Credentials and Connecting](https://overpoweredshell.com//AWS-PowerShell-EC2-Key-Pairs,-Credentials-and-Connecting/)
