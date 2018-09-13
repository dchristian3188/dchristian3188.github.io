---
layout: post
title: AWS PowerShell - Intro to PowerShell Lambdas, Creating An Automatic Shutdown Policy for EC2 Instances
---

AWS has finally released support for PowerShell lambdas!
Lambdas are incredibly powerfull peieces of code that can be called from just about anywhere in AWS (or outside for that matter).
Even better Lambdas don't require a server to run, this means that you only pay for the compute that you actually use.
Don't worry the first 1M hits per month are free.
Let's dive in and see how we can start use our existing PowerShell skills to start building lambdas.

**The Good Stuff:**
Start writing [AWS Lambdas](https://aws.amazon.com/lambda/) in PowerShell.

<!-- more -->

# Automatic Shutdown for EC2 Instances

One cool thing about Azure is their machine autoshutdown policy.
More than once I've been bitten by accidently leaving my test machines on in AWS.
In fact, my bill for August was a *little* higher than I was execpting.
Once I saw that AWS is supporting PowerShell Lambdas, I knew that the auto shutdown policy was something I wanted to implment.
Let's go step by step and set one up


# Installing the AWS PowerShell Lambda Module
There's a couple of prerequistes needed before we can start create PowerShell Lambdas.
The first is the [Dotnet core sdk](https://www.microsoft.com/net/download).
The AWS team is actually cheating a little bit here.
What they did was find a way to wrap PowerShell core in a dot net project.
This means that our PowerShell script actually gets complied into a project (more on that in the publishing section).
Since they are wrapping our script, we need also need their ```AWSLambdaPSCore```.
This install is a little easier since they put it up on the PowerShell gallery.

```powershell
Install-Module AWSLambdaPSCore -Force -Verbose
```

# Lambda Templates

After we have the requeired software we can start creating our own Lambdas.
Once of the commands in the ```AWSLambdaPSCore``` module is ```Get-AWSPowerShellLambdaTemplate```.
This command will list all the precanned templates that we can leverage for different AWS products.

```powershell
Get-AWSPowerShellLambdaTemplate
```

output:

```powershell
Template               Description
--------               -----------
Basic                  Bare bones script
CodeCommitTrigger      Script to process AWS CodeCommit Triggers
DetectLabels           Use Amazon Rekognition service to tag image files in S3 with detected labels.
KinesisStreamProcessor Script to be process a Kinesis Stream
S3Event                Script to process S3 events
SNSSubscription        Script to be subscribed to an SNS Topic
SQSQueueProcessor      Script to be subscribed to an SQS Queue
```


# Creating A PowerShell Lambda

Since this is a learning expereince, I wanted to start with the basic template.
Below is the command that I ran to create a new script called ```ShutDownEC2``` in my ```C:\AWS``` directory.

```powershell
New-AWSPowerShellLambda -Template Basic -ScriptName ShutDownEC2 -Directory C:\aws\
```

This create a file that looked like this:

![_config.yml]({{ site.baseurl }}/images/aws/newlambda.png)

## PowerShell Lambda Inputs

Reading the help file, we can see that we get a couple of variables for free.
The first is a variable called ```$LambdaInput```.
Any JSON posted to our Lambda will be converted into a object and saved in this variable.
It's autoamatically there and will be avaialble to our code.

## EC2 Shutdown Code

I wanted my Lambda to be flexible.
So if you pass an a valid instanceID, we'll shutdown just that specific instance.
If not, I want to shutdown all of my instances.
The idea here being I can schedule the second use case to run every night and clean up after me.
Here's what my final PowerShell lambda ended up looking like.

```powershell
#Requires -Modules @{ModuleName='AWSPowerShell.NetCore';ModuleVersion='3.3.313.0'}


if ($null -ne $LambdaInput.InstanceID)
{
    $instances = Get-EC2Instance -InstanceId $LambdaInput.InstanceID | 
        Select-Object -ExpandProperty Instances
}
else
{
    #No Specific Instance passed, so let's stop all of them
    $instances = Get-EC2Instance | 
        Select-Object -ExpandProperty Instances
}

foreach ($instance in $instances)
{
    if ($instance.State.Name.Value -ne 'stopped')
    {
        Write-Host "Stopping instance id [$($instance.InstanceId)]"
        Stop-EC2instance -InstanceId $instance.InstanceId
    }
    else
    {
        Write-Host "instance id [$($instance.InstanceId)] already stopped"
    }
}
```

One little thing, that I like to point out is that the ```Write-Output``` command does not seem to work inside the context of a lambda.
However, ```Write-Host``` and ```Write-Verbose``` (or any ```-Verbose``` switch) will properly display output.

# Publishing PowerShell Lambda

Now that we have our lambda written it's time to publish it to AWS.
Remeber how I said that they are compling our script?
This means that there is now way to create a PowerShell lambda through the UI.
Don't believe me, here's the current list in the AWS console.

![_config.yml]({{ site.baseurl }}/images/aws/exsitingLam.png)

Luckily, the ```AWSLambdaPSCore``` has a function to do the compliation and publish.
Below is the command line I used for ```Publish-AWSPowerShellLambda``` to upload my new lambda.
Notice that lambdas, are region specific, so that will need to be specified. 

```powershell
Publish-AWSPowerShellLambda -Name ShutDownEC2 -ScriptPath C:\aws\ShutDownEC2.ps1 -Region us-west-2 
```

Here's part of the output where we can see the actuall complication happening.
This runs everytime we publish.

![_config.yml]({{ site.baseurl }}/images/aws/compileLambda.png)


Aslo the first time that you publish a lambda, it will ask you to create a role to use for running the lambda.
I created one called ```overpowershelledLambda```.
I also granted him full lambda access.

![_config.yml]({{ site.baseurl }}/images/aws/iamlambda.png)

After a few seconds that will complete and if we head to our console we'll see our new lambda.
Again notice, how the project is technailly a dot net core 2.1 app.

![_config.yml]({{ site.baseurl }}/images/aws/lambdaConsole.png)

# Testing the Lambda

Now that we have our lambda created, we will want to start testing.
Before we can do that we need to create tests events.
Click the drop down in the upper right hand corner to open the pop up.

![_config.yml]({{ site.baseurl }}/images/aws/testevents.png)

The first test event I want to create is an empty one to simulate our scheduled run.
For the body I'm just going to use ```{}```.

![_config.yml]({{ site.baseurl }}/images/aws/testempty.png)

The next test event is to handle use cases where we pass a specific instance.
Below is an example I created using one of my existing instances.
If you want to follow along, make sure you update your body to match something in your environemnt.

```powershell
{
  "InstanceID": "i-03a5ed219d178f53c"
}
```

![_config.yml]({{ site.baseurl }}/images/aws/testID.png)

With all of that in place, there's nothing left to do but click the test button.

![_config.yml]({{ site.baseurl }}/images/aws/permissionError.png)

Wait an error?!?!
What happened?
Well it says that we don't have permission to perform this action.
After scratching my head for a little while it hit me.
The default lambda role doesn't grant any write permissions to EC2!

# Granting The Lambda Permission To EC2

What we need to do is update the role we created as part of the wizard to grant it permission to take actions on EC2.
To do this head over to IAM -> Roles.
Once your there select the role that you created.

![_config.yml]({{ site.baseurl }}/images/aws/lambdaroledefault.png)

From here click on attach policy.
From the filter we can select which addtional policy I want to attach to my role.
To make things easy, I'm going to grant my lambda full control to EC2 (please don't do this in production)
When we're done the ```overpoweredshelllambda``` role looks like this.

![_config.yml]({{ site.baseurl }}/images/aws/lambdafull.png)

## Testing with the right permissions

Now that we have all the right access in place, let's re-run our test.
First I want to see if I can stop a specifc instance. 
To do this, I'll run my instance specific test.

![_config.yml]({{ site.baseurl }}/images/aws/lambdainstancetestresults.png)

Great that worked!
Now let's see what happens when I run the empty test.
If all goes well, we should see it stop all my instances.

![_config.yml]({{ site.baseurl }}/images/aws/lambdatestresultsall.png)

That one works too.
With our lambda working, the last thing to do is setup a schdule to have this run every night.

# Scheduling a Lambda

To schedule the lambda, we need to add a cloudwatch trigger.
From the designer on the right select cloudwatch event.
Once that is added, click on configure.
For our example, I want this to run every day.
To do this I'll use the below cron pattern.

```powershell
cron(0 4 * * ? *)
```

What's a little weird, is that the schedule is in UTC.
Also if your a little rusty on cron syntax, be sure to check out [this page](https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html) for a great reference.
Here's what my final Cloudwatch event rule looked like:

![_config.yml]({{ site.baseurl }}/images/aws/cloudwatchTrigger.png)

# Wrapping Up

That's all for today.
I can't stress how huge being able to leverage PowerShell from a lambda is.
This is a game changer for sure.
Got some cool lambda use cases? 
Please be sure to share them below.
I'm excited to see what our amazing comunity comes up with.