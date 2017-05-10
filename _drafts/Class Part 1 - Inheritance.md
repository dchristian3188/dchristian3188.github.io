<!-- TOC -->

- [What is a Class?](#what-is-a-class)
    - [Classes and Objects](#classes-and-objects)
- [Describing the class](#describing-the-class)
    - [Properties](#properties)
        - [Property validation](#property-validation)
        - [Hidden Properties](#hidden-properties)
        - [Default Properties](#default-properties)
        - [Static Properties](#static-properties)
    - [Methods](#methods)
        - [Return](#return)
        - [Method Overload](#method-overload)
        - [Method Property Validation](#method-property-validation)
        - [Static Methods](#static-methods)
- [Base Class](#base-class)
    - [running it](#running-it)

<!-- /TOC -->
# What is a Class?
A class is just a template for an object. 
Classes define how an object should look, what properties and methods it has and potentially what it takes to create a new instance. 
When we create an instance of that class, it becomes an object made from that template. 
Lets go through an example of creating a human class. 
## Classes and Objects
I always found this concept confusing and want to make sure we define the terms early.
A class is a template for what an object should look like. 
It's not till we instantiate an instance of that class, do we have an object. 
For example, we are going to create a human class. 
We could then use that class to create a new instance of a human (a human object)
David is a instance of the human class.
The new keyword is ```class```
```powershell
class human
{

}
```
There's a couple of ways to create a instance of a class.
The first is to use ```New-Object``` with the ```-TypeName``` switch.
```powershell
$me = New-Object -TypeName human
```
Another way to instantiate a class is to call the static constructor of the class. 
```powershell
$me = [human]::New()
```
# Describing the class
Something hre
## Properties
Properties are things about the object.
If we were describing a human, properties might be height and weight.
We add properties to a class by adding variables inside the class.
While not required, it is a good idea to define the variable type.
```powershell
class human
{
    [String]
    $Name
    
    [int]
    $HeightInchesInches

    [int]
    $WeightLbs
}
```
### Property validation
You can also add parameter validation to the properties of classes. 
Lets add some validation around our parameters to make sure we are getting good data.
```powershell
class human
{
    [ValidatePattern('^[a-z]')]
    [ValidateLength(3,15)]
    [String]
    $Name
    
    [ValidateRange(0,100)]
    [int]
    $HeightInches

    [ValidateRange(0,1000)]
    [int]
    $WeightLbs
}
```
**Most** of the parameter validation you are use to in functions is available in classes properties as well.
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
Any value i tried produced the same error message, you must provide a constant.
```powershell
+     [ValidateScript({$true})]
+                     ~~~~~~~
Attribute argument must be a constant.
    + CategoryInfo          : ParserError: (:) [], ParentContainsErrorRecordException
    + FullyQualifiedErrorId : ParameterAttributeArgumentNeedsToBeConstant
 
```
### Hidden Properties
Powershell classes also support hidden properties.
To mark a property hidden, you can use the ```hidden``` keyword, just before the property name. 
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
    $HeightInches
    
    [ValidateRange(0,1000)]
    [int]
    $WeightLbs
}
```
Now if we create a new human object, and look at the object the ```$ID``` property will not be shown. 
```powershell
$someGuy = [human]::new()
$someGuy

Name Height Weight
---- ------ ------
          0      0
```
By default not even ```Get-Member``` can see it.
```powershell

$someGuy = [human]::new()
$someGuy | Get-Member -MemberType Properties


   TypeName: human

Name         MemberType Definition
----         ---------- ----------
HeightInches Property   int HeightInches {get;set;}
Name         Property   string Name {get;set;}
WeightLbs    Property   int WeightLbs {get;set;}
   
```
We'll thats not true. 
To view the property with ```Get-Member```, you have to include the ```-force``` switch. 
This will return all properties and methods of the object.
```powershell
$someGuy = [human]::new()
$someGuy | Get-Member -MemberType Properties -Force

   TypeName: human

Name         MemberType   Definition
----         ----------   ----------
pstypenames  CodeProperty System.Collections.ObjectModel.Collection`1[[System.String, mscorlib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089]] pstypenames{get=PSTypeNames;}
HeightInches Property     int HeightInches {get;set;}
ID           Property     guid ID {get;set;}
Name         Property     string Name {get;set;}
WeightLbs    Property     int WeightLbs {get;set;}                                                                                                                 
```                                                                                         
One big important thing to note with hidden properties, is that nothing prevents a user from interacting with them.
Moreover, if a user specifically calls the property it will be displayed. This works when called from ```Select-Object```, any of the ```Format``` commands for if the property is referenced by dot notation.
```powershell
$someGuy = [human]::new()
$someGuy.ID = (New-Guid).Guid
$someGuy.ID


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
```
$someOtherGuy = [human]::new()
$someOtherGuy.ID


Guid
----
ab4bdcd9-b076-4869-bdbc-dde6be724b1a

```
### Static Properties
You can also create static properties.
Static properties are properties that can be referenced from the class itself, not an instance of an object.
What this means is that, instance objects will not have this property.
This can be useful for helper classes (the [math helper class](https://msdn.microsoft.com/en-us/library/system.math(v=vs.110).aspx) is a great example of a helper class).
To define a static property, we use the ```Static``` keyword
```powershell
class TimeUtilities
{
    static $Time = "The Time is $((Get-Date).ToShortTimeString())"
}
```
Since we don't need an instance object, we can call this property directly from the class.
```powershell
[TimeUtilities]::Time
```
## Methods
Methods are things the object does. 
Sticking with our human example, methods could be jump or talk.
### Return
When working with class methods you need to be explicit about what information the method will return.
Due to this, all methods need to be prefixed with the type of data they will return, for example: ```[int]``` or ```[string]```.
This syntax is exact to how properties are declared.
Methods that do not return any data need to be prefixed with the type of ```[void]```.
To define a method we first need to define what type that method will return.
For example, the method talk will return a string.
I'm also going to mark the jump method as void, since it won't produce output.
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
### Method Overload
We can also overload methods.
When we overload a method, we are defining that method twice, but this time with a different set of parameters.
Lets overload the SayHello method and add a new parameter for name.
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
We can inspect the different overload signatures by calling an instance of the class with the method, notice no parenthesis after the method name.
```powershell
$me = New-Object -TypeName Human
$me.SayHello



OverloadDefinitions                              
-------------------                              
string SayHello()                                
string SayHello(string Name)  
```
If you don't provide a type for the parameters of your methods, they will default to ```System.Object```.
This can be important because while you can have an unlimited number of method overloads, they all have to have a unique signature.
This signature is determined by the number of parameters for the method and their types. 
To see what I mean, try to run the below example. 
It should throw an error saying that the ```HonkHorn``` method is already defined. 
```powershell
class car {
    [Void]HonkHorn([string]$beep)
    {

    }

    [Void]HonkHorn([string]$boop)
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
This again is done with the static keyword.
Lets update the ```TimeUtilities``` class to work with a new static method.
```powershell
class TimeUtilities
{
    static $Time = "The Time is $((Get-Date).ToShortTimeString())"

    static [DateTime]Add90Days([DateTime]$StatingDate)
    {
        return $StatingDate.AddDays(90)
    }
}
```
We could then run this method without an instance of the object.
```powershell
[TimeUtilities]::Add90Days($(Get-Date))
```
# Base Class
```powershell
class animal
{
    [int]
    $Legs

    [int]
    $WeightLbs

    [int]
    $HeightInchesInches

    [String]Jump()
    {
       Return  "look at that $($this.ToString()) jump!"
    }

    [string]Speak()
    {
        Throw "not implemented"
    }

}
```
```powershell
class dog : animal
{
    [string]Speak()
    {
        Return "woof!"
    }

}
```
## running it
```powershell
$sheep = New-Object -TypeName animal
$sheep.Jump()
$sheep.Speak()

$spot = New-Object -TypeName dog
$spot.jump()
$spot.speak()
```