---
layout: post
title: Exploring PowerShell 6 - Backgrounding Pipelines
---

PowerShell Core 6.0 is here and with it are a ton of new features.
I've been going through some of the release notes and Github pages trying to find cool stuff to play with.
On the docket for today is backgrounding the pipeline.


**The Good Stuff:**
Check out background pipes using ```&``` in PowerShell 6.0.

<!-- more -->

Background jobs are one of the ways we can execute long running tasks in PowerShell.
If you never played with PowerShell jobs, I recommend you go read [PowerShell background job basics
](https://4sysops.com/archives/powershell-background-job-basics/) by Timothy Warner as a primer.
While the underlying job structure and cmdlets still work in version 6 we got a new way to launch jobs.

Traditionally to start a job we would need to use the ```Start-Job``` cmdlet with a scriptblock.

```powershell
Start-Job -ScriptBlock { Get-Service }
```

Now we can kick off a job using the ```&``` character at the end of our pipeline.

```powershell
 Get-Service &
```

Regardless of the syntax, the output of the above commands is a job object.
What takes the new syntax to the next level for me, is how the new way handles variables.
When you use the ```&``` syntax any variables in your session automatically get copied into the job.
Consider the below examples.

Traditional way

```powershell
$name = 'David'
$job = Start-Job -ScriptBlock {Write-Output "Hello $name"}
$job | Receive-Job -Wait
```

Output:

```powershell
Hello
```

New Way

```powershell
$name = 'David'
$job = Write-Output "Hello $name" &
$job | Receive-Job -Wait
```

Output

```powershell
Hello David
```

The next enhancement provided by the ```&``` syntax is how it handles the *working directory* of the job.
When you launch a job using the traditional syntax, the job always starts in your user home directory.
Using the ```&``` will start the job in your current directory.
Let's take a look at this behavior.
I'm going to run all commands from my Github root folder, ```C:\github```.

Traditional way

```powershell
$job = Start-Job -ScriptBlock {Get-Location}
$job | Receive-Job -Wait
```

Output:

```powershell
Path
----
C:\Users\David\Documents
```

New Way

```powershell
$job = Get-Location &
$job | Receive-Job -Wait
```

Output

```powershell
Path
----
C:\github
```

Pretty cool right?
Got any neat uses for background jobs or other new features you want to talk about?
Leave a comment and let us know.