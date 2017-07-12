---
layout: post
title: SysAdmin Basics - Using the IPAddress Class
---

Whether you like it or not, at some point in your career you will be working with IP Addresses.
I recently ran into a challenge for work with variable length subnet masks and IPs that inspired this post.
So lets get into it.
Today we're going to talk about some of the common tasks admins have to do that involve IPs.

**The Good Stuff:**
Making sure you're taking full advantage of the IPAddress class.

<!-- more -->

# Approach

There's two common approaches I see most people take when working with IPs.
By far the most popular is to use Regex.
I was never a big Regex guy, but I've been trying to get better.
I'm fortunate enough to work with some incredibly talented people.
One of whom, is an absolute monster when it comes to Regex.
It's damn impressive when you see the language levered to it's full potential.
My personal gripe with Regex is that its hard to read...
That being said, it's still a perfectly valid approach and a matter of style.
The next not so often talked about method is to leverage the ```[ipaddress]``` class.
This class gives us a lot of freebies and combined with a little bit of bit math does some cool stuff.

# Validating An IP Address

Ok let's start with the most important one.
Is this a valid IP address?!?!

## Regex

I did a quick search on Google, for IP regex.
The below pattern is the most commonly accepted answer.
Take a look at this Regex pattern to verify IPs.

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

One cool use for the ```IPAddress``` type is to combine it with ```-As```.
If the value to test is a valid IP, ```-As``` return us a ```IPaddress``` object.
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

The best part is that if we use an invalid IP address, the ```-As``` will not throw an error.
Instead it returns null.
For example, consider this:

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
Usually the gateway has an address like your IP except with the last octet of 1.
This is especially true if you have a /24 or 255.255.255.0 subnet mask.

Regex just crushes excels at this.
If you known you need to replace the last octet you can use this snippet.

```powershell
$address = '192.168.0.153'
$defaultGW = $address -replace '\d{1,3}$','1'

$defaultGW
```

Here's where it starts getting good.
We can combine Regex and the ```IPAddress``` class to work with subnets other than ```/24```.
Let's pretend you have a ```/18``` or ```255.255.192.0```.
I know this is an extreme example but hey it could happen.
What we could do is leverage some bitwise math to find the network ID.
Don't worry it's not as bad as it sounds.

```powershell
[ipaddress]$address = '10.153.67.25'
[ipaddress]$subnetMask = '255.192.0.0'

[ipaddress]$network = $address.Address -band $subnetMask.Address 
$network.IPAddressToString
```


The ```IPAddress``` class takes a little more setup to get started.
There's also the requirement that you need a subnet mask if you're trying to find the gateway.
Here's what the previous example would look like.

```powershell

```

# Converting To Binary String

```powershell

$address = [ipaddress]'192.168.0.153'

($address.GetAddressBytes().ForEach{[Convert]::ToString($PSItem,2)}) -Join '.'
```