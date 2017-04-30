---
layout: post
title: A Real World Pester Example From the PowerShell Github
---
A hobby of my mine is to peruse the PowerShell Github page for open issues and pull requests. Its a direct way to interact with the team, see what features are being worked on and actually make a difference. I understand that putting yourself out there can be scary but everyone is incredibly friendly and its a great place to get constructive feedback. Aren't that good at C#? Add some documentation or a Pester test. Anything helps and there's a ton to do. **The Good Stuff**: Go to the [PowerShell Github Page](https://github.com/PowerShell/Powershell) and start contributing!

# A Real World Pester Example 
Like I said, there's still a ton of work to be done in PowerShell. One of the most important and often most overlooked areas is test coverage. The PowerShell Team has done a good job of utilizing Pester and forcing all new commits to come with corresponding test but there's still gaps. The example used in this article is from my most recent commit, basic Pester tests for the ```Test-Connection``` cmdlet. Most of the tests are straight forward but there's some neat tricks and best practices the PowerShell team requires of its test. Before we go into those, lets take a look at the completed describe block.  
```powershell
Describe "Test-Connection" -Tags "CI" {
    BeforeAll {
        $originalDefaultParameterValues = $PSDefaultParameterValues.Clone()
        if ( ! $IsWindows )
        {
            $PSDefaultParameterValues["it:skip"] = $true
        }
        else
        {
            $countCases = @(
                @{count = 2}
                @{count = 3}
            )

            $quietTests = @(
                @{computerName = 'localhost'; message = 'online' ; result = $true}
                @{computerName = '_fake_computer_namex'; message = 'offline' ; result = $false}
            )
        }
    }
    AfterAll {
        $global:PSDefaultParameterValues = $originalDefaultParameterValues
    }
    It "Gets the right IP Address" {
        $localHost = Test-Connection -ComputerName localhost -Count 1
        $localHost.IPV4Address | Should Be '127.0.0.1'
        $localhost.IPV6Address | Should Be '::1'
    }
    
    It "The count parameter counting to <count>" -TestCases $countCases {
        param($count)
        (Test-Connection -ComputerName localhost -Count $count).Count | Should Be $count
    }
        
    It "The quiet parameter on a <message> computer" -TestCases $quietTests {
        param($computername, $result)
        Test-Connection -ComputerName $computername -Count 1 -Quiet | Should Be $result
    }
}
```
## Skipping Tests in Mass - BeforeAll and AfterAll 
 Since ```Test-Connection``` is only available on Windows, we want to skip these tests on all other platforms. In PowerShell 6 there are are couple of new variables that we can use to determine what platform we're on, ```$IsWindows```, ```$IsLinux``` and ```$IsOSX```. If ```$IsWindows``` evaluates to false, we're going to update the ```Skip``` parameter of the ```It``` statement. Just like it sounds, if ```Skip``` is ```$true```, the test is passed over. To update all of the ```It``` statements in one shot, we'll use a PowerShell default parameter. Before we do this though, we need to preserve our current value (more on this in a minute). The best place to before this type of setup is the ```BeforeAll``` and ```AfterAll``` statements as these 2 sections are the first and last things to be executed. 
```powershell
 BeforeAll {
    $originalDefaultParameterValues = $PSDefaultParameterValues.Clone()
    if ( ! $IsWindows )
    {
        $PSDefaultParameterValues["it:skip"] = $true
    }
    else
    {
... 
````
With the default parameter of ```Skip``` set, we can quickly pass over these tests on non-windows operating systems. The catch is, we need to but back the original values when we're done or else any other tests in our session will be skipped. We can easily accomplish this by resetting the ```$global:PSDefaultParameterValues``` in the ```AfterAll``` block.
```powershell
    AfterAll {
        $global:PSDefaultParameterValues = $originalDefaultParameterValues
    }
```
## Pester Test Cases
Ok, we sorted out the operating system requirement and now need to setup our tests. One test I wanted to perform was to ensure that the ```Count``` parameter was actually working. I also wanted to make sure that I ran this test twice, with two different numbers (just in case it always returned the number I selected). Thinking thru this, there's a couple of ways we could write this test. The first was is to just include to ```It``` statements.
```powershell
Describe Test-Connection {
    It "The count parameter counting to 2" {
            (Test-Connection -ComputerName localhost -Count 2).Count | Should Be 2
        }
    It "The count parameter counting to 3" {
            (Test-Connection -ComputerName localhost -Count 3).Count | Should Be 3
        }
}
```
This feels heavy handed and the duplication of work is just hard to maintain. The next obvious solution is to place the ```It``` statement in some loop. Here's an example using ```foreach``` but this could be written a ton of different ways. 
```powershell
Describe Test-Connection {
    $numbersToTest = @(2,3)
    foreach($number in $numbersToTest){
        It "the count parameter counting to $number" {
            (Test-Connection -ComputerName localhost -Count $number).Count | Should Be $number
        }
    }
}
```
 This solution works and is much cleaner, but there's an even better way. Pester has built in loop functionality with ```TestCases```. ```TestCases``` are just an array of hashtables that can be fed into an ```It``` statement. Here's that same example, but using ```TestCases```.
 ```powershell
Describe Test-Connection {
    $countCases = @(
            @{count = 2}
            @{count = 3}
        )
    
    It "The count parameter counting to <count>" -TestCases $countCases {
        param($count)
        (Test-Connection -ComputerName localhost -Count $count).Count | Should Be $count
    }
}
```
While this is a little more work to setup, it separates the data from the tests and doesn't clutter our file with unnecessary looping logic. While we could initialize the test data just before the ```It``` statement it corresponds to, the cleaner solution is to place this in the ```BeforeAll``` block. Doing this keeps our main block clean with only ```It``` statements and completely skips creating the variables if we run them on Linux or OSX. 
```powershell
BeforeAll {
    $originalDefaultParameterValues = $PSDefaultParameterValues.Clone()
    if ( ! $IsWindows )
    {
        $PSDefaultParameterValues["it:skip"] = $true
    }
    else
    {
        $countCases = @(
            @{count = 2}
            @{count = 3}
        )

        $quietTests = @(
            @{computerName = 'localhost'; message = 'online' ; result = $true}
            @{computerName = '_fake_computer_namex'; message = 'offline' ; result = $false}
        )
    }
}
```
Hashtables are used since they are splatted into the ```It``` under the covers. Each of the keys in the hashtable is converted to a variable and can be referenced inside of your ```It``` statement. The caveat here is that the syntax is slightly different depending on where you want to use it. If you want to use the variable in the actual test description, you need to surround your variable in ```<``` and ```>```, with no ```$```. To use the variable in the test scriptblock, a ```param``` section needs to be added. 
```powershell
It "The quiet parameter on a <message> computer" -TestCases $quietTests {
    param($computername, $result)
    Test-Connection -ComputerName $computername -Count 1 -Quiet | Should Be $result
}
```
# Wrapping up
I hope the examples in this article helped. For even more Pester best practices from the PowerShell team check out the [Writing Pester Tests Doc](https://github.com/PowerShell/PowerShell/blob/master/docs/testing-guidelines/WritingPesterTests.md). Of course the [Pester Wiki](https://github.com/pester/Pester/wiki) is another great resource. Finally and most importantly go to [The PoweShell Github Page](https://github.com/powershell/powershell) and get ***your*** contributor badge.