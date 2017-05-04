
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