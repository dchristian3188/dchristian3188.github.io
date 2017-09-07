---
layout: post
title: Module Tools - Folder layout
---

Next up in our series of working with Module Tools is folder layout.
In our [first post,](http://overpoweredshell.com//Module-Tools-Starting-Off/) we used Plaster to scaffold our new module.
Now let's dive into the folder structure and how this layout can simplify our development.

**The Good Stuff:**
Make your module development easier by writing small functions and keeping them in own PS1 files.

<!-- more -->

If you're brand new to modules, I highly recommend Kevin Marquette's ["Building a Module, one microstep at a time"](https://kevinmarquette.github.io/2017-05-27-Powershell-module-building-basics/) article as a primer.

The traditional approach to writing a module involves a simple layout.
For the absolute basics, all you need is a PSM1.
You define all the functions in the PSM1 and you are good to go.
The challenge with this is as your module grows, so does your PSM1.
Eventually, you can end up with a monster file with a ton of functions in them.
While this might ok for something that is packaged and deployed (something someone really shouldn't be looking at), it's a nightmare to maintain.

