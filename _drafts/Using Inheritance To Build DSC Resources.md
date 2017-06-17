---
layout: post
title: Using Inheritance To Build DSC Resources
---

Today we are going to use inheritance to create multiple resource from a base class.
I'm the first to admit I'm lazy and always trying to get the most bang for my lines of code.
Inheritance is a great way to reduce code duplication and pretty easy once you wrap your head around it.

**The Good Stuff:**
My DSC [FileWatcher module](https://github.com/dchristian3188/FileWatcher) and an example of building resources with inheritance.

<!-- more -->

I'm going to be building off my SmartServiceRestart resource from [this](http://overpoweredshell.com/DSC-Classes-Using-Helper-Methods/) post.
This resource watched a file path and a service.
It would then compare the start time of the service against the last write time of the file.
If the file has a later last write time, the service gets restarted.
Its a great tool for services that are not smart enough to automatically reload their configurations.

I liked the idea of having a file watcher that would reload the service and wanted to see if I could apply this logic anywhere else.
I thought it would be cool to have a similar resource to manage processes and websites.
Before we look at the new resources, lets examine the original class.

The original resource contained the following methods:

- **GetLastWriteTime** - A helper method to get the last write time of the file(s)
- **GetProcessStartTime** - A helper method to get the start time of the process
- **Get** - Ran all helper methods and return an instance
- **Test** - Compared the to helper methods to determine who was older
- **Set** - Restarted a service

Looking over the list of methods, the only ones that are specific to a service are the ```GetProcessStartTime``` and the ```Set```.
What that means is we can move the rest of the methods to a base class.
This new base class will have the ```Get```, ```Test``` and ```GetLastWriteTime```.

Now that I have my base defined, I know I only need to create the ```Set``` and ```GetProcessStartTime``` methods for each resource.
The idea is final class will come together like this

![stuff](https://github.com/dchristian3188/dchristian3188.github.io/blob/master/images/DSCInheritance/FileWatcherInheritance.png)

![_config.yml]({{ site.baseurl }}/images/DSCInheritance/FileWatcherInheritance.png)

We also have to perform this same inventory the properties / parameters.
All of the resources will be sharing the below properties.

- **Path** - Path to the folder or files to check
- **Filter** - A filter to apply to the files
- **LastWriteTime** - Date time property to store last write time of the file
- **ProcessStartTime** - Date time property to store the process start time

However, the specifcs parameters for each resource will be quite different.
Here's a breakdown of the final structure.

s![stuff](https://github.com/dchristian3188/dchristian3188.github.io/blob/master/images/DSCInheritance/FIleWatcherInheritanceProperties.png)

![_config.yml]({{ site.baseurl }}/images/DSCInheritance/FIleWatcherInheritanceProperties.png)