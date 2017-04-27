---
layout: post
title: A Real World Pester Example From the PowerShell Github
---
One hobby of some of my co-workers and mine is to review the PowerShell Github page for open issues and pull requests. Its a direct way to interact with the team, see what features are being worked on and actually make a difference. I know that first post can be scary, but everyone is incredibly friendly and its a great place to get constructive feedback. Aren't that good a c#? Add some documentation or a Pester test. Anything helps and theres a ton to do. **The Good Stuff**: Go to the [PowerShell Github Page](https://github.com/PowerShell/Powershell) and start contributing!

# A Real World Pester Example 
Like I said, there's still a tone of work to be done in PowerShell. One of the most important and often most overlooked areas is test coverage. The PowerShell Team has done a good job of utilizing Pester and forcing all new commits to come with corresponding test but there's still gaps. The example used in this article is from my most recent commit, basic Pester tests for the ```Test-Connection``` cmdlet. Most of the tests are straight forward but there's some neat tricks and best practices the PowerShell team requires of its test. Before we go into those, lets take a look at the completed describe block.  
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
The first interesting thing, is the ```BeforeAll``` and ```AfterAll```. These 2 sections are the first and last things to be executed. Since ```Test-Connection``` is only available on Windows, we want to skip these tests on all other platforms. The skip command is already a built in part of the It statement. What we'll do is set this value to true using a PowerShell default parameter. Before we do this though, we need to preserve our current value (more on this in a minute)
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
With the default parameter of skip set, we can quickly pass over these tests on non-windows OS. The catch is, we need to but back the original values or else any other tests in our session will be skipped. We can easily accomplish this by resetting the ```$global:PSDefaultParameterValues``` in the ```AfterAll``` block.
```powershell
    AfterAll {
        $global:PSDefaultParameterValues = $originalDefaultParameterValues
    }
```