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
Eventually, you can end up with a monster file with a ton of functions in them (I recently came across a project with a 32K line PSM1 with a couple hundred functions defined in it)
While this might ok for something that is packaged and deployed, it's a nightmare to maintain.

This approach to module development can also come at an additional price.
As your project grows and gains tractions, hopefully, you have multiple people contributing.
By placing all your code in one file, you increase the chance for merge conflicts.
While most source control is smart enough to figure it out, there is a much higher chance than isolating code to its own file.

Last but not least, I feel this method does not lend it self well to discovery.
When everything is defined in its own PSM1, how do you tell what functions are in the module?
I mean you can do a search for ```Function``` but that can potentially grab comments as well.
Maybe a regex like ```function \w+-\w+ \{``` but that won't grab non-standard function names.
Plus how do you know what is a private function vs. a public function?

