---
layout: post
title: A Real World Pester Example From the PowerShell Github
---
One hobby of some of my co-workers and mine is to review the PowerShell Github page for open issues and pull requests. Its a direct way to interact with the team, see what features are being worked on and actually make a difference. I know that first post can be scary, but everyone is incredibly friendly and its a great place to get constructive feedback. Aren't that good a c#? Add some documentation or a Pester test. Anything helps and theres a ton to do. **The Good Stuff**: Go to the [PowerShell Github Page](https://github.com/PowerShell/Powershell) and start contributing!

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
## BeforeAll and AfterAll - Skipping Tests in Mass
The first interesting thing, is the ```BeforeAll``` and ```AfterAll```. These 2 sections are the first and last things to be executed. Since ```Test-Connection``` is only available on Windows, we want to skip these tests on all other platforms. The ```skip``` parameter is already a built in part of the ```It``` statement. What we'll do is set this value to true using a PowerShell default parameter. Before we do this though, we need to preserve our current value (more on this in a minute)
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
With the default parameter of ```skip``` set, we can quickly pass over these tests on non-windows operating systems. The catch is, we need to but back the original values when we're done or else any other tests in our session will be skipped. We can easily accomplish this by resetting the ```$global:PSDefaultParameterValues``` in the ```AfterAll``` block.
```powershell
    AfterAll {
        $global:PSDefaultParameterValues = $originalDefaultParameterValues
    }
```
## Pester Test Cases
Ok, we sorted out the operating system requirement and now need to setup our tests. One test I wanted to perform was to ensure that the ```Count``` parameter was actually working. I also wanted to make sure that I ran this test twice, with two different numbers (just in case it always returned the number I selected). Thinking thru this, there's a couple of ways we could right this test.
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
This feels heavy handed and the duplication of work is just hard to maintain. The next obvious solution is to place the ```it``` statement in some loop. Here's an example using ```foreach``` but this could be written a ton of different ways. 
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
 This solution works and is much cleaner, but there's an even better way. Pester has built in loop functionality with ```TestCases```. ```TestCases``` are just an array of hashtables that can be fed into an ```it``` statement. Here's that same example, but using ```TestCases```.
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
While this is a little more work to setup, it separates the data from the tests and doesn't clutter our file with unnecessary looping logic. The best place to perform this setup is in the ```BeforeAll``` block. Lets take a look.
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
Hashtables are used since they are splatted into the ```IT``` under the covers. Each of the keys in the hashtable is converted to a variable and can be referenced inside of your ```IT``` statement. The caveat here is that the syntax is slightly different depending on where you want to use it. If you want to use the variable in the actual test description, you need to surround your variable in ```<``` and ```>```, with no ```$```. To use the variable in the test scriptblock, a ```param``` section needs to be added. 
```powershell
It "The quiet parameter on a <message> computer" -TestCases $quietTests {
    param($computername, $result)
    Test-Connection -ComputerName $computername -Count 1 -Quiet | Should Be $result
}
```