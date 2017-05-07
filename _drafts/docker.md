# Latest edition Here.
[Docker CE](https://www.docker.com/community-edition#/download)

Computer may restart for higher v

Switch to windows containers
```powershell
& $Env:ProgramFiles\Docker\Docker\DockerCli.exe -SwitchDaemon
```
# docker powershell
[Docker-PowerShell](https://github.com/Microsoft/Docker-PowerShell)
```powershell
Register-PSRepository -Name DockerPS-Dev -SourceLocation https://ci.appveyor.com/nuget/docker-powershell-dev
Install-Module -Name Docker -Repository DockerPS-Dev -Verbose -Force
```

# Docker module
Get-Command -Module Docker
# running docker
Request-ContainerImage -All -Repository microsoft/nanoserver -Verbose



docker run -it microsoft/nanoserver cmd

