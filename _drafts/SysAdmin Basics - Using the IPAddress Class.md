---
layout: post
title: SysAdmin Basics - Using the IPAddress Class
---

Whether you like it or not, at some point in your career you will be working with IPs.
I recently ran into a challenge at work with variable length subnet masks that inspired this post.
I needed to brush off some old networking skills and got to play with a little PowerShell along the way.

**The Good Stuff:**
A couple of tricks to make working with IPs a little less painful.

<!-- more -->

# Approach

There's two common approaches I see most people take when working with IPs.
By far the most popular is to use Regex.
I was never a big Regex guy, but I've been trying to get better.
I'm fortunate enough to work with some incredibly talented people.
One of whom, is an absolute monster when it comes to Regex.
It's damn impressive when you see the language levered to it's full potential.
My personal gripe with Regex is that its hard to read...
That said, it's capabilities are undeniable.

The next not so often talked about method is to leverage the ```[ipaddress]``` class.
This class gives us a lot of freebies since the .Net team did the hard stuff for us.
Plus if you combine that with a little bitwise math, you can recreate subnetting in PowerShell.

# Validating An IP Address

Ok let's start with the most important one.
Is this a valid IP?

## Regex

I did a quick search on Google for "IP regex".
The below pattern is the most commonly accepted answer.

```powershell
^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$
```

Obviously....
Now we could use this pattern to check if we're working with a valid IP.
Something like this.

```powershell
$ipPattern = '^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$'
$AddressToTest = '192.168.0.1'

if($AddressToTest -match $ipPattern)
{
    #Some code for a valid IP Here
}
else
{
    #Some error handling here
}
```

## IPAddress Type

I like using the ```IPAddress``` type for this one.
What you do is leverage the ```-As``` operator to cast the IP.
If the IP cast works, ```-As``` returns an ```IPaddress``` object.
Take a look at this example to see it in action.

```powershell
'192.168.0.1' -as [ipaddress]
```

Output:
```powershell
Address            : 16820416
AddressFamily      : InterNetwork
ScopeId            :
IsIPv6Multicast    : False
IsIPv6LinkLocal    : False
IsIPv6SiteLocal    : False
IsIPv6Teredo       : False
IsIPv4MappedToIPv6 : False
IPAddressToString  : 192.168.0.1
```

The best part is that if we use an invalid IP address, ```-As``` will not throw an error.
Instead it returns null.
Try running the below example in your shell, you shouldn't get anything back.

```powershell
'10000.08.x' -as [ipaddress]
```

What this means for us, is that we can rewrite the first example as follows:

```powershell
$AddressToTest = '192.168.0.1'

if($AddressToTest -as [ipaddress])
{
    #Some code for a valid IP Here
}
else
{
    #Some error handling here
}
```

# Finding The Default Gateway

The default gateway is the door from your network to the next.
Sometimes, you only have an IP address and need to guess at the default gateway.
Usually the gateway has an address like your IP except with the last octet of ```.1```.
This is especially true if you have a ```/24``` or ```255.255.255.0``` subnet mask.

If you known you need to replace the last octet with a ```1```, Regex is the perfect tool.
Take a look at the below snippet to set a default gateway using Regex.

```powershell
$address = '192.168.0.24'
$defaultGW = $address -replace '\d{1,3}$','1'

$defaultGW
```

Output:

```powershell
192.168.0.1
```

Here's where it starts getting good.
We can combine Regex and the ```IPAddress``` class to work with subnets other than ```/24```.
Let's pretend you have a ```/18``` or ```255.255.192.0```.
What we could do is leverage some bitwise math to find the network ID.
Don't worry it's not as bad as it sounds.

```powershell
$address = [ipaddress]'10.153.67.25'
$subnetMask = [ipaddress]'255.255.192.0'

[ipaddress]$network = $address.Address -band $subnetMask.Address
$network.IPAddressToString
```

Output:

```powershell
10.153.64.0
```

This address and the subnet mask together identify the entire network.
Once we know this, we can use regex to set the default gateway to the first usable IP.

# Finding The Broadcast Address

On a network, the broadcast address is a reserved IP that sends a message to the entire subnet.
We find the broadcast address again using bitwise math.
This time we are going to use the IP address and the wildcard mask.
If your unfamiliar with a wildcard mask, it's the exact inverse of a subnet mask.
Like a subnet mask identifies the network, the wildcard mask identifies the host.
Here's the snippet in PowerShell to find the broadcast address.

```powershell
$ipaddress = [ipaddress]'192.168.0.34'
$wildCardMask = [ipaddress]'0.0.0.255'

[ipaddress]$broadCast = $ipaddress.Address -bor $wildCardMask.Address
$broadCast
```

Output:

```powershell
Address            : 4278233280
AddressFamily      : InterNetwork
ScopeId            :
IsIPv6Multicast    : False
IsIPv6LinkLocal    : False
IsIPv6SiteLocal    : False
IsIPv6Teredo       : False
IsIPv4MappedToIPv6 : False
IPAddressToString  : 192.168.0.255
```

# Converting To Binary String

The first thing I wrote for this article was the [ConvertTo-BinaryAddress](https://github.com/dchristian3188/Main/blob/master/Functions/ConvertTo-BinaryAddress.ps1) function.
In school I had an amazing network instructor that really drilled the basics into us.
Thanks to this, it's still a lot easier for me to visual subnetting when I can see the binary.
Here's the function in action.

```powershell
PS > ConvertTo-BinaryAddress -Address 192.168.0.23

11000000.10101000.00000000.00010111

PS > ConvertTo-BinaryAddress -Address 255.255.255.0

11111111.11111111.11111111.00000000

PS > ConvertTo-BinaryAddress -Address 0.0.0.255

00000000.00000000.00000000.11111111
```

# Wrapping Up

That's all for today.
Got any cool tricks you use with IPs?
Leave a comment and let us know.
