﻿---
layout: post
title: An Introduction to PowerShell Classes
---
This is going to be the first in a series of posts regrading classes.
I want to talk more about DSC and especially some of the cool things you can do with class based resources.
Before we get to the advance use cases, we need to cover the basics.
**The Good Stuff**: An introduction to PowerShell classes. 
<!-- TOC -->

- [Why Classes](#why-classes)
- [Class Basics](#class-basics)
    - [What Is A Class?](#what-is-a-class)
    - [Classes And Objects](#classes-and-objects)
    - [Creating A Class](#creating-a-class)
- [Describing The Class](#describing-the-class)
    - [Properties](#properties)
        - [Property validation](#property-validation)
        - [Hidden Properties](#hidden-properties)
        - [Default Properties](#default-properties)
        - [Static Properties](#static-properties)
    - [Methods](#methods)
        - [Return](#return)
        - [$This](#this)
        - [Method Overload](#method-overload)
        - [Method Signature](#method-signature)
        - [Method Property Validation](#method-property-validation)
        - [Static Methods](#static-methods)
    - [Constructors](#constructors)
- [Inheritance](#inheritance)
    - [Creating Child Classes](#creating-child-classes)
    - [Overriding Methods](#overriding-methods)
    - [Using The Base Keyword](#using-the-base-keyword)
        - [Base Constructors](#base-constructors)
        - [Calling Base Methods](#calling-base-methods)
- [Wrapping Up](#wrapping-up)

<!-- /TOC -->
# Why Classes
For me there are two big reasons to use PowerShell classes.
The first is if your creating your own modules and functions.
You can use classes to represent complex data structures. 
Once the classes are defined, they work just like any other type in PowerShell.
This is incredibly helpful when multiple functions need to pass the same data around.
You can bind the functions to the specific class type and be done with it.
The other big use case is DSC.
DSC is gaining more and more traction everyday.
With this increased adoption, there is an even larger gap for new resources.
DSC Class based resources are just easier to to develop and maintain. 
I will detail this process further in an upcoming post.
# Class Basics
## What Is A Class?
A class is just a template for an object. 
Classes define how an object should look, what is does and potentially what it takes to create a new one. 
## Classes And Objects
When we create an instance of a class, it becomes an object made from that template. 
I always found this concept confusing and want to make sure we define the terms early.
A class is a template for what an object should look like. 
It's not till we instantiate an instance of that class, do we have an object. 
For example, we are going to create a human class. 
We then use that class to create a human object.
Here ```$David``` is an instance (object) of the human class.
## Creating A Class
We can create a new class by using the new ```class``` keyword. 
```powershell
class human
{

}
```
Now that we have our class defined we can create instances of it.
There's a couple of different ways to do this. 
The first is to use ```New-Object``` with the ```-TypeName``` switch.
```powershell
$david = New-Object -TypeName human
```
Another way to instantiate a class is to call the static constructor of the class. 
If your unsure what a "static constructor" is, it's ok.
We will cover these concepts later in the article. 
For now, just familiarize yourself with the syntax below. 
```powershell
$david = [human]::New()
```
# Describing The Class
## Properties
Properties are things about an object.
If we were describing a human, properties might be height and weight.
We add properties to a class by adding variables inside the class.
While not required, it is a good idea to define the variable type.
```powershell
class human
{
    [String]
    $Name
    
    [int]
    $Height

    [int]
    $Weight
}
```
### Property validation
Classes also support property validation.
Let's add some validation to make sure we are getting good data.
```powershell
class human
{
    [ValidatePattern('^[a-z]')]
    [ValidateLength(3,15)]
    [String]
    $Name
    
    [ValidateRange(0,100)]
    [int]
    $Height

    [ValidateRange(0,1000)]
    [int]
    $Weight
}
```
**Most** of the parameter validation you are use to in functions is available to classes properties.
```powershell
[ValidateNotNull()]
[ValidateNotNullOrEmpty()]
[ValidateCount()]
[ValidateSet()]
[AllowNull()]
[AllowEmptyCollection()]
[AllowEmptyString()]
[ValidateRange()]
[ValidatePattern()]
[ValidateLength()] 
```
Interestingly enough ```[ValidateScript()]```did not work. 
Any value I tried produced the same error message, you must provide a constant.
```powershell
+     [ValidateScript({$true})]
+                     ~~~~~~~
Attribute argument must be a constant.
    + CategoryInfo          : ParserError: (:) [], ParentContainsErrorRecordException
    + FullyQualifiedErrorId : ParameterAttributeArgumentNeedsToBeConstant
 
```
### Hidden Properties
PowerShell classes also support hidden properties.
To hide a property use the ```hidden``` keyword just before the property name. 
Here we will make the ```ID``` property a ```GUID``` and have it hidden from the user.
```powershell
class human
{
    [Guid]
    hidden $ID

    [ValidatePattern('^[a-z]')]
    [ValidateLength(3,15)]
    [String]
    $Name
    
    [ValidateRange(0,100)]
    [int]
    $Height
    
    [ValidateRange(0,1000)]
    [int]
    $Weight
}
```
Now if we create a new human object and look at its properties, the ```$ID``` property will not be shown. 
```powershell
$someGuy = [human]::new()
$someGuy
```
Output:
```powershell
Name Height Weight
---- ------ ------
          0      0
```
By default not even ```Get-Member``` can see it.
```powershell
$someGuy = [human]::new()
$someGuy | Get-Member -MemberType Properties
```
Output:
```powershell
   TypeName: human

Name         MemberType Definition
----         ---------- ----------
Height       Property   int Height {get;set;}
Name         Property   string Name {get;set;}
Weight       Property   int Weight {get;set;}
   
```
To view the property with ```Get-Member```, you have to include the ```-force``` switch. 
```powershell
$someGuy = [human]::new()
$someGuy | Get-Member -MemberType Properties -Force
```
Output:
```powershell
   TypeName: human

Name         MemberType   Definition
----         ----------   ----------
pstypenames  CodeProperty System.Collections.ObjectModel.Collection`1[[System.String, mscorlib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089]] pstypenames{get=PSTypeNames;}
Height       Property     int Height {get;set;}
ID           Property     guid ID {get;set;}
Name         Property     string Name {get;set;}
Weight       Property     int Weight {get;set;}                                                                                                                 
```                                                                                         
One **important** thing to note with hidden properties is that nothing prevents a user from interacting with them.
If a user specifically calls the property it will be displayed. 
This works when called from ```Select-Object```, any of the ```Format``` commands or if the property is referenced by dot notation.
```powershell
$someGuy = [human]::new()
$someGuy.ID = (New-Guid).Guid
$someGuy.ID
```
Output:
```powershell
Guid                                
----                                
25051c08-66e8-4f7e-a283-7b960a10371a
```
### Default Properties
We can also set default values for a property. 
In the below example, we'll set a default value for the ```ID``` property.
```powershell
class human
{
    [Guid]
    hidden $ID = (New-Guid).Guid

    [ValidatePattern('^[a-z]')]
    [ValidateLength(3,15)]
    [String]
    $Name
    
    [ValidateRange(0,100)]
    [int]
    $Height
    
    [ValidateRange(0,1000)]
    [int]
    $Weight
}
```
Now if we create a new instance of our class, it will already have a value for the ```ID```.
```powershell
$someOtherGuy = [human]::new()
$someOtherGuy.ID
```
Output:
```powershell
Guid
----
ab4bdcd9-b076-4869-bdbc-dde6be724b1a
```
### Static Properties
You can also create static properties.
Static properties are properties that can be referenced from the class itself, not an instance of that class.
What this means, is that instance objects will not have this property.
While this seems counter intuitive, it can be useful for helper classes (the [math class](https://msdn.microsoft.com/en-us/library/system.math(v=vs.110).aspx) is a great example of a helper class).
To define a static property, we use the ```Static``` keyword
```powershell
class TimeUtilities
{
    static [string]$Time = "The Time is $((Get-Date).ToShortTimeString())"
}
```
Since we don't need an object, we call this property directly from the class.
```powershell
[TimeUtilities]::Time
```
## Methods
Methods are things the object does. 
Essentially a method is just a function tied to an object. 
If you have ever written a PowerShell function, you can write a class method.
### Return
When working with class methods you need to be explicit about what information the method will return.
Due to this, all methods need to be prefixed with the type of data they will return, such as ```[int]``` or ```[string]```.
Methods that do not return any data need to be prefixed with the type of ```[void]```.
After your method has finished its processing, it needs to return an object of that type.
This is done using the ```return``` keyword.
In this example, the talk method will return a string.
I'm also going to assign the ```[void]``` type to the Jump method since it won't produce output.
```powershell
class human
{
    [Guid]
    hidden $ID = (New-Guid).Guid

    [ValidatePattern('^[a-z]')]
    [ValidateLength(3,15)]
    [String]
    $Name
    
    [ValidateRange(0,100)]
    [int]
    $Height
    
    [ValidateRange(0,1000)]
    [int]
    $Weight

    [void]Jump()
    {
        Write-Output -Message "You won't see this message"
        Return
    }

    [String]SayHello()
    {
        Return "Hello, nice to meet you"
    }
}
```
### $This
When you are inside of a method, the ```$this``` variable is automatically created for you.
You use the ```$this``` variable to make a reference back to your current instance.
For example, say you have a human class with a name property. 
One of the methods in the class could echo this name to the user.
To do that, it needs to reference one of its own properties.
```powershell
class human
{
    [string]
    $Name

    [String]SayName()
    {
        Return "Hi My name is $($this.Name)"
    }
}
```
Its important to note, that you can also use the ```$this``` variable to call methods of your current instance.
This is helpful when a class has a helper method used by other methods.
### Method Overload
Methods in PowerShell classes support overload.
When we overload a method, we define that method more than once with different parameters.
This is similar to defining a function with multiple parameter sets.
Let's overload the SayHello method and add a new parameter for name.
```powershell
class human
{
    [Guid]
    hidden $ID = (New-Guid).Guid

    [ValidatePattern('^[a-z]')]
    [ValidateLength(3,15)]
    [String]
    $Name
    
    [ValidateRange(0,100)]
    [int]
    $Height
    
    [ValidateRange(0,1000)]
    [int]
    $Weight

    [void]Jump()
    {
        Write-Output -Message "You won't see this message"
        Return
    }

    [String]SayHello()
    {
        
        Return "Hello, nice to meet you"
    }

    [String]SayHello([String]$Name)
    {
            
        Return "Hey $Name. Its nice to meet you"
    }
}
```
We can inspect the different overload signatures by calling an instance of the class with the method name.
Notice there are no parenthesis after the method name so we are not actually invoking it.
```powershell
$me = New-Object -TypeName Human
$me.SayHello
```
Output:
```powershell
OverloadDefinitions                              
-------------------                              
string SayHello()                                
string SayHello(string Name)  
```
### Method Signature
If you don't provide a type for the parameters of your methods, they will default to ```System.Object```.
This can be important because while you can have an unlimited number of method overloads, they all have to have a unique signature.
This signature is determined by the number of parameters for the method, those parameter's types and the order they are passed. 
To see what I mean, try to run the below example. 
It should throw an error saying that the ```HonkHorn``` method is already defined. 
```powershell
class car 
{
    [Void]HonkHorn([string]$beep)
    {

    }

    [Void]HonkHorn([string]$boop)
    {

    }
}
```
This next example would be a valid signature since it has a unique order.
```powershell
class car 
{
    [Void]HonkHorn([string]$beep, [int]$times)
    {

    }

    [Void]HonkHorn([int]$times,[string]$beep)
    {

    }
}
```
### Method Property Validation
I wanted to include this for the sake of completeness. 
I was unable to find any type of validation modifiers for parameters to methods. 
What this means is you need to rely on your code to perform the checks. 
For example, if your method is expecting a positive number, you couldn't just add a ```[ValidateRange()]``` attribute.
### Static Methods
Just like static properties we can define a method to be static.
This again is done with the ```static``` keyword.
Let's update the ```TimeUtilities``` class to work with a new static method.
```powershell
class TimeUtilities
{
    static [string]$Time = "The Time is $((Get-Date).ToShortTimeString())"

    static [Bool]IsWeekend([DateTime]$DateToTest)
    {
        $sunday = $DateToTest.DayOfWeek -eq [DayOfWeek]::Sunday 
        $saturday = $DateToTest.DayOfWeek -eq [DayOfWeek]::Saturday
        if($sunday -or $saturday)
        {
            Return $true
        }
        else
        {
            Return $false
        }
    }   
}
```
We could then run this method without an instance of the class.
```powershell
[TimeUtilities]::IsWeekend((Get-Date))
```
You can find static methods by piping the class name into ```Get-Member``` with the ```Static``` switch.
```powershell
[TimeUtilities] | Get-Member -Static
```
Output:
```powershell
   TypeName: TimeUtilities

Name            MemberType Definition
----            ---------- ----------
Equals          Method     static bool Equals(System.Object objA, System.Object objB)
IsWeekend       Method     static bool IsWeekend(datetime DateToTest)
ReferenceEquals Method     static bool ReferenceEquals(System.Object objA, System.Object objB)
Time            Property   static string Time {get;set;}
```
## Constructors
Remember at the beginning of the article when we talked about creating a new object?
One option available to us was to call the ```New``` static constructor.
```powershell
$someGuy = [human]::New()
```
This ```New``` constructor is just a method inherited from the base class. 
Since ```New``` is a method, we can override and overload it just like anything else.
We create constructors by creating a new method with the same name as the class.
Here I'll create an overload method to assign the name property at object creation time.
```powershell
class human
{
    [Guid]
    hidden $ID = (New-Guid).Guid

    [ValidatePattern('^[a-z]')]
    [ValidateLength(3,15)]
    [String]
    $Name
    
    [ValidateRange(0,100)]
    [int]
    $Height
    
    [ValidateRange(0,1000)]
    [int]
    $Weight

    Human([String]$name)
    {
        $this.Name = $name
    }
}
```
While this works there's a catch. 
When you create your own constructor you lose the base one.
Take a look at the output from this command
```powershell
[human]::New
```
Output:
```powershell
OverloadDefinitions     
-------------------     
human new(string name)  
```
In this example, I'm going to keep the original constructor as an option.
To do this, I can include an empty human method with no parameters.
```powershell
class human
{
    [Guid]
    hidden $ID = (New-Guid).Guid

    [ValidatePattern('^[a-z]')]
    [ValidateLength(3,15)]
    [String]
    $Name
    
    [ValidateRange(0,100)]
    [int]
    $Height
    
    [ValidateRange(0,1000)]
    [int]
    $Weight

    Human()
    {
        
    }

    Human([String]$name)
    {
        $this.Name = $name
    }
}
```
With this empty constructor in place my new method shows both signatures.
```powershell
[human]::new
```
Output:
```powershell
OverloadDefinitions
-------------------
human new()
human new(string name)
```
# Inheritance
## Creating Child Classes
Inheritance allows us to define one class as a starting point for another.
This is helpful when you need multiple classes to share similar methods and properties.
Instead of duplicating the code, we can place the shared logic in a base class and then use inheritance to work out the details on the children. 
Let's first start by creating a base class for animals.
```powershell
class animal
{

    [string]
    $Name

    [int]
    $Legs

    [int]
    $Age
    
    [int]
    $WeightLbs

    [int]
    $HeightInches

    animal([string]$NewName)
    {
        $this.Name = $NewName 
    }

    animal()
    {
    
    }

    [String]Jump()
    {
       Return  "look at that $($this.ToString()) jump!"
    }

    [string]Speak()
    {
        Throw [System.NotImplementedException]::New('Speak method should be overridden in child class')
    }
}
```
I purposely left the ```Throw``` statement in the speak method of this base class.
The reason behind this, is I want to ensure that any child classes must override it if they want to use it.
Next I create a dog class that inherits from our base class of animal,
To do this we use the syntax ```class NewClass : BaseClass```. 
```powershell
class dog : animal
{
    [int]
    $TailLength
    
    [int]AgeDogYears()
    {
        return $this.Age * 7
    }
}
```
Let's create a new dog and look at its properties and methods.
```powershell
$spot = [dog]::new()
$spot | Get-Member
```
Output:
```powershell
   TypeName: dog

Name               MemberType Definition                       
----               ---------- ----------                       
AgeDogYears        Method     int AgeDogYears()                
Equals             Method     bool Equals(System.Object obj)   
GetHashCode        Method     int GetHashCode()                
GetType            Method     type GetType()                   
Jump               Method     string Jump()                    
Speak              Method     string Speak()                   
ToString           Method     string ToString()                
Age                Property   int Age {get;set;}               
HeightInchesInches Property   int HeightInchesInches {get;set;}
Legs               Property   int Legs {get;set;}              
Name               Property   string Name {get;set;}           
TailLength         Property   int TailLength {get;set;}        
WeightLbs          Property   int WeightLbs {get;set;}    
```
Thanks to inheritance the child class has all the properties and methods of its parent.
## Overriding Methods
We override methods by providing them the same method signature in the child class.
Remember how the speak method thew an error in the base class?
Let's add an override to the dog class to make this method work a little better.
```powershell
class dog : animal
{
    [int]
    $TailLength
    
    [int]AgeDogYears()
    {
        return $this.Age * 7
    }
    
    [string]Speak()
    {
        return "woof!"
    }
}    
```
## Using The Base Keyword
### Base Constructors
One thing that will not automatically be inherited is any constructors that take parameters.
Before we look at the constructors for our new dog class, let's look at its parent.
```powershell
[animal]::new
```
Output:
```powershell
OverloadDefinitions                       
-------------------                       
animal new(string NewName)                
animal new()    
```
Now let's look at the child's classes constructors.
```powershell
[dog]::new
```
Output:
```powershell
OverloadDefinitions
-------------------
dog new()          
```
To regain this functionality we can create a new constructor that matches the method signature of the parent class.
We'll then map this signature to the parent's signature using ```: base(Params,Go,Here)```
```powershell
class dog : animal
{
    [int]
    $TailLength
    
    [int]AgeDogYears()
    {
        return $this.Age * 7
    }
    
    [string]Speak()
    {
        return "woof!"
    }

    dog([string]$NewName) : base($NewName)
    {
    
    }

    dog()
    {
    
    }
   
}
```
With these new constructors in place, the below syntax should work.
```powershell
$puppy = [dog]::new("Spot")
$puppy.Name
```
### Calling Base Methods
We can also call a base method from an override if we cast ```$this``` to the parent class.
The syntax is ```([baseclass]$this).Method()```.
In this example, I'm going to create a Kangaroo class that will override the base ```Jump``` method. 
I will use this technique to be able to call the parent's jump method from inside the override. 
```powershell
class kangaroo : animal
{
    [string]Jump()
    {
        return ([animal]$this).Jump() * 2
    }
}
```
Now let's create a new kangaroo and make him jump.
```powershell
$kango = [kangaroo]::new()
$kango.Jump()
```
You should get this in your console.
```powershell
look at that kangaroo jump!look at that kangaroo jump!
```
# Wrapping Up
I hope this was helpful. 
Classes can take a while to get use to but can be incredibly powerful.
In the next post, we'll talk about how to use a class to create a DSC resource.