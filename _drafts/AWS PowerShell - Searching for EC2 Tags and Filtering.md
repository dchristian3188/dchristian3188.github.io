---
layout: post
title: AWS PowerShell - Searching for EC2 Tags and Filtering
---

One of the biggest shifts in moving to the cloud is getting used to the fact that servers don't matter.
You have a workload, you build a couple of instances and then they run it.
If there's an issue you're not going to troubleshoot a server.
Tear it down and spin up some new ones!
With all these servers coming and going, it's important to be able to keep everything organized.
One way AWS solves this is through the use of instance tags.
Let's dive in and learn to work with them in PowerShell!

**The Good Stuff:**
Start leveraging tags to organize your AWS instances!

<!-- more -->

So it's important to remember that a tag is a label.
You give your tag a name and a value.
Some common examples would be a tag for an environment or for an application that instance is running.
Here's an example of an instance I've tagged with just that.

```powershell
$instance = (Get-EC2Instance -InstanceId i-0546a9b32ab6be6d7)
$instance.Instances.tags
```

Output:

![_config.yml]({{ site.baseurl }}/images/aws/taggedInstance.png)

If you notice, that's not terribly helpful since I already knew which instance I wanted.
A better solution is to search all instances by a tag filter.
The ```Get-EC2instance``` Cmdlet does take a filter.
Tags are key-value pairs, let's try to pass a hashtable to them!

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
I'll save you the trouble at searching the AWS site.
It turns out that a filter needs a specific format.
The filter parameter takes an array of hashtables.
Even if there is going to be one value to filter on.
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

![_config.yml]({{ site.baseurl }}/images/aws/hastableFail.png)

Now we're getting somewhere!
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
To see what I mean, try this.

```powershell
Get-Help Get-EC2Instance -Parameter filter
```

Output:

![_config.yml]({{ site.baseurl }}/images/aws/multitaghit.png)

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

That's all for today.
Remember that tags are your friends.
I hope this new function helped and makes managing all the cattle a little easier.