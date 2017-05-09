<!-- TOC -->

- [What is a Class?](#what-is-a-class)
    - [Classes and Objects](#classes-and-objects)
- [Describing the class](#describing-the-class)
    - [Properties](#properties)
        - [Property validation](#property-validation)
        - [Hidden Properties](#hidden-properties)
        - [Default Properties](#default-properties)
    - [Methods](#methods)
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
$someGuy | Get-Member


   TypeName: human

Name        MemberType Definition                    
----        ---------- ----------                    
Equals      Method     bool Equals(System.Object obj)
GetHashCode Method     int GetHashCode()             
GetType     Method     type GetType()                
ToString    Method     string ToString()             
Height      Property   int Height {get;set;}         
Name        Property   string Name {get;set;}        
Weight      Property   int Weight {get;set;}         
```
We'll thats not true. 
To view the property with ```Get-Member```, you have to include the ```-force``` switch. 
This will return all properties and methods of the object.
```powershell
$someGuy = [human]::new()
$someGuy | Get-Member -Force


   TypeName: human

Name        MemberType   Definition                                                                                                                                                                                                                              
----        ----------   ----------                                                                                                                                                                                                                              
pstypenames CodeProperty System.Collections.ObjectModel.Collection`1[[System.String, mscorlib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089]] pstypenames{get=PSTypeNames;}                                                                 
psadapted   MemberSet    psadapted {Name, Height, Weight, get_ID, set_ID, get_Name, set_Name, get_Height, set_Height, get_Weight, set_Weight, ToString, Equals, GetHashCode, GetType}                                                                            
psbase      MemberSet    psbase {Name, Height, Weight, get_ID, set_ID, get_Name, set_Name, get_Height, set_Height, get_Weight, set_Weight, ToString, Equals, GetHashCode, GetType}                                                                               
psextended  MemberSet    psextended {}                                                                                                                                                                                                                           
psobject    MemberSet    psobject {BaseObject, Members, Properties, Methods, ImmediateBaseObject, TypeNames, get_BaseObject, get_Members, get_Properties, get_Methods, get_ImmediateBaseObject, get_TypeNames, ToString, Copy, CompareTo, Equals, GetHashCode,...
Equals      Method       bool Equals(System.Object obj)                                                                                                                                                                                                          
GetHashCode Method       int GetHashCode()                                                                                                                                                                                                                       
GetType     Method       type GetType()                                                                                                                                                                                                                          
get_Height  Method       int get_Height()                                                                                                                                                                                                                        
get_ID      Method       guid get_ID()                                                                                                                                                                                                                           
get_Name    Method       string get_Name()                                                                                                                                                                                                                       
get_Weight  Method       int get_Weight()                                                                                                                                                                                                                        
set_Height  Method       void set_Height(int )                                                                                                                                                                                                                   
set_ID      Method       void set_ID(guid )                                                                                                                                                                                                                      
set_Name    Method       void set_Name(string )                                                                                                                                                                                                                  
set_Weight  Method       void set_Weight(int )                                                                                                                                                                                                                   
ToString    Method       string ToString()                                                                                                                                                                                                                       
Height      Property     int Height {get;set;}                                                                                                                                                                                                                   
ID          Property     guid ID {get;set;}                                                                                                                                                                                                                      
Name        Property     string Name {get;set;}                                                                                                                                                                                                                  
Weight      Property     int Weight {get;set;}                                                                                                                          
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
```

## Methods
Methods are things the object does. 
Sticking with our human example, methods could be jump or talk.
To define a method we first need to define what type that method will return.
For example, the method talk
```powershell
class human
{
    [int]
    $HeightInches

    [int]
    $WeightLbs

    [void]Jump()
    {
        Write-Verbose -Message "Look at that $($this.ToString()) jump!"
        Return
    }
}
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