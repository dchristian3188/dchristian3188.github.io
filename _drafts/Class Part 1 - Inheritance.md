I have a cool idea for a few resource that I want to share with the community. 

# What is a Class?
A class is just a template for an object. 
Classes define how an object should look, what properties and methods it has and potentially what it takes to create one. 
When we create an instance of that class, it becomes an object made from that template. 
Lets go through an example of creating a human class. 
```class``` is a new keyword in version 5. 
```powershell
class human
{

}
```
## Describing the class
### Properties
Properties are things about the object.
If we were describing a human, properties might be height and weight.
We add properties to a class by adding variables inside the class.
While not required, it is a good idea to define the variable type.
```powershell
class human
{
    [int]
    $Height

    [int]
    $Weight
}
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
    $Height

    [int]
    $Weight

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
    $Weight

    [int]
    $heightInches

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