---
layout: post
title: AWS PowerShell - EC2 Tags and Filtering
---

One of the biggest shifts in moving to the cloud is getting used to the fact that servers don't matter.
You have a workload, you build a couple of instances and it runs.
If there's an issue you're not going to troubleshoot a server.
Tear it down and spin up a new one.
With all these servers coming and going, it's important to be able to keep everything organized.
One way AWS solves this is through the use of instance tags.
Let's dive in and learn to work with them in PowerShell.

**The Good Stuff:**
Start leveraging tags to organize your AWS instances!


<!-- more -->

<!-- TOC -->

- [Creating Tags](#creating-tags)
    - [Amazon.EC2.Model.Tag](#amazonec2modeltag)
    - [A Better Tag Creation Function](#a-better-tag-creation-function)
- [Searching for Tags](#searching-for-tags)
    - [The Built-in Filters](#the-built-in-filters)
    - [A Better Filter Function](#a-better-filter-function)
- [Wrapping Up](#wrapping-up)

<!-- /TOC -->

# Creating Tags

So it's important to remember that a tag is a label.
You give your tag a name and a value.
Some common examples would be a tag for an environment or for an application that an instance is running.

## Amazon.EC2.Model.Tag

To create a tag we need instantiate a new ```Amazon.EC2.Model.Tag``` object.
Here's an example of creating a tag for the Dev environment.

```powershell
[Amazon.EC2.Model.Tag]::new("Environment","Dev")
```

Now that we know how to create tags, we can start assigning them to instances.
Here's a sample script to create a new instance and assign it our Dev tag.

```powershell
$instance = Get-EC2ImageByName  -Name WINDOWS_2016_CONTAINER |
    New-EC2Instance -InstanceType t2.micro
 
$tag = [Amazon.EC2.Model.Tag]::new("Environment","Dev")    
New-EC2Tag -Tag $tag -Resource $instance.Instances.Instanceid
```

## A Better Tag Creation Function

This works, but it seems clunky to me.
For starters, we should be able to pipe from the output of ```New-EC2Instance``` right into the tag function.
Plus why do I need to create their special hashtable object?
It would be nice if we could pass a hashtable instead and let the tag function do the heavy lifting.
To make creating tags a little more user friendly, I created the below function.

```powershell
Function Set-EC2Tag
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
        [Hashtable]
        $Tags
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
        
        $ec2Tags = foreach($key in $Tags.Keys)
        {
            [Amazon.EC2.Model.Tag]::new($key,$Tags[$key])
        }

        foreach($insID in $InstanceId)
        {
            New-EC2Tag -Resource $insID -Tag $ec2Tags
        }
    }
}
```

With our new function in place, the pipeline feels much better.
Here's what the new workflow looks like when we need to create a machine and assign it a couple of tags.

```powershell
$tags = @{
    'Environment' = "Dev"
    'App' = "WebSvc1"
}

Get-EC2ImageByName  -Name WINDOWS_2016_CONTAINER |
    New-EC2Instance -InstanceType t2.micro |
    Set-EC2Tag -Tags $tags
```

# Searching for Tags

The whole purpose of creating a tag is to be able to query for it later.
If we inspect an instance we can see what tags it has by diving into its details.

```powershell
$instance = (Get-EC2Instance -InstanceId i-0546a9b32ab6be6d7)
$instance.Instances.tags
```

Output:

![_config.yml]({{ site.baseurl }}/images/aws/taggedInstance.png)

If you notice, that's not terribly helpful since I already knew which instance I wanted.
A better solution is to search all instances by a tag filter.

## The Built-in Filters

The ```Get-EC2instance``` Cmdlet does take a filter.
Tags are key-value pairs, so let's try to pass a hashtable to them.

```powershell
$searchFor = @{
    'Environment' = "Dev"
}
Get-EC2Instance -Filter $searchFor
```

Output:

![_config.yml]({{ site.baseurl }}/images/aws/hastableFail.png)

Ok, so that was a bust... 
Time to check the documentation.
I'll save you the trouble of searching the AWS site.
It turns out that a filter needs a specific format.
The filter parameter takes an array of hashtables, even if there is going to be one value to filter on.
Moreover, these hashtables require specific keys.
One named ```name``` (all lower case) for the name of the filter value.
We also need another key named ```values``` (again case sensitive) to match against.
Another caveat is that if we are filtering on tags, we need to prefix them with ```tag:```.
Here's what that original filter would look like.

```powershell
$searchFor =@(
    @{
        name = 'tag:Environment'
        values = "Dev"
    }
)
Get-EC2Instance -Filter $searchFor
```

Output:

![_config.yml]({{ site.baseurl }}/images/aws/tagHit.png)

Now we're getting somewhere!

## A Better Filter Function

I still don't like that fact that I need to craft that special hashtable by hand.
Plus, what if we wanted to filter on multiple tags?
To make working with filters easier, I created the below function.

```powershell
Function ConvertTo-EC2Filter
{
    [CmdletBinding()]
    Param(
        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [HashTable]
        $Filter
    )
    Begin
    {
        $ec2Filter = @()    
    }
    Process
    {
        
        $ec2Filter = Foreach ($key in $Filter.Keys)
        {
            @{
                name   = $key
                values = $Filter[$key]
            }
        }
    }
    End
    {
        $ec2Filter
    }
}
```

Since this new function handles the heavy lifting of creating the filter.
We can do some cool stuff like this:

```powershell
$searchFor = @{
    'tag:Environment' = "Dev"
    'tag:App' = "WebSvc1"
}
$ec2Filter = ConvertTo-EC2Filter -Filter $searchFor
Get-EC2Instance -filter $ec2Filter
```

Output:

![_config.yml]({{ site.baseurl }}/images/aws/multitaghit.png)

Remember there's also way more things that we can filter on.
To see what I mean, try checking the help for ```Get-EC2Instance```.

```powershell
Get-Help Get-EC2Instance -Parameter filter
```

Output:

![_config.yml]({{ site.baseurl }}/images/aws/fitlerhelp.png)

For example, let's say we wanted all windows machines, that were launched with the OverPoweredShell key, in the us-west-2c availability zone, running the WebSVC2 application.

```powershell
$searchFor = @{
    'platform'          = 'windows'
    'key-name'          = 'OverPoweredShell'
    'availability-zone' = 'us-west-2c'
    'tag:App'           = "WebSvc2"

}
$ec2Filter = ConvertTo-EC2Filter -Filter $searchFor
Get-EC2Instance -filter $ec2Filter
```

# Wrapping Up

That's all for today.
Remember that tags are your friends.
I hope this new function helped and makes managing all the cattle a little easier.

For more articles about PowerShell and AWS please check out:

* [Setting up AWS Tools on PowerShell Core](https://overpoweredshell.com//AWS-PowerShell-Setting-up-AWS-Tools-on-PowerShell-Core/)
* [Finding the Right EC2 Image](https://overpoweredshell.com//AWS-PowerShell-Finding-the-Right-EC2-Image/)
* [Creating Ec2 Instances and Basic Machine Management](https://overpoweredshell.com//AWS-PowerShell-Creating-Ec2-Instances-and-Basic-Machine-Management/)
* [EC2 Key Pairs, Credentials and Connecting](https://overpoweredshell.com//AWS-PowerShell-EC2-Key-Pairs,-Credentials-and-Connecting/)
