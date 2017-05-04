#Latest edition Here.
https://www.docker.com/community-edition#/download

Computer may restart for higher v

Switch to windows containers
& $Env:ProgramFiles\Docker\Docker\DockerCli.exe -SwitchDaemon



#docker powershell
https://github.com/Microsoft/Docker-PowerShell
Register-PSRepository -Name DockerPS-Dev -SourceLocation https://ci.appveyor.com/nuget/docker-powershell-dev
Install-Module -Name Docker -Repository DockerPS-Dev -Verbose -Force

#Docker module
gcm -Module Docker
#running docker

Request-ContainerImage -All -Repository microsoft/nanoserver -Verbose



docker run -it microsoft/nanoserver cmd

