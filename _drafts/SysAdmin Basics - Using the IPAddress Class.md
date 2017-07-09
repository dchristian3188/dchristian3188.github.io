---
layout: post
title: SysAdmin Basics - Using the IPAddress Class
---

Whether you like it or not, even if your not a Network jockey, at some point in your career you will be working with IP Addresses.

**The Good Stuff:**
Making sure you're taking full advantage of the IPAddress class.

<!-- more -->

# Validating An IP Address

## Regex

I was never a big RegEx guy.
What the heck does the emoji face mean again?
That being said, I have been trying to get better at it.
I'm lucky enough to work with some really talented people, one of which who uses Regex as his go to.
While Regex is an incredibly powerfull tool, its a little hard to read.
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

While this approach works, I can never remember that pattern and always have to look it up.
Plus for anyone else reading the code, it can be hard to decipher without a good variable name.

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

## Regex

Sometimes, you only have an IP address and need to guess at the default gateway.
Usually the gateway has an address like your, IP except with the last octet of 1.
This is especially true if you have a /24 or 255.255.255.0 subnet mask.
Check this out.

```powershell
$address = '192.168.0.153'
$defaultGW = $address -replace '\d{1,3}$','1'

$defaultGW
```

# Converting To Binary String

```powershell

$address = [ipaddress]'192.168.0.153'

($address.GetAddressBytes().ForEach{[Convert]::ToString($PSItem,2)}) -Join '.'
```