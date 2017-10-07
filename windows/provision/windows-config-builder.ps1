Set-StrictMode -Version Latest
$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
$Host.PrivateData.VerboseForegroundColor = [ConsoleColor]::DarkCyan

$script:scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

. (Join-Path -Path $script:scriptDir -ChildPath "chocolatey.ps1")
. (Join-Path -Path $script:scriptDir -ChildPath "git.ps1")

New-Item -ItemType Directory -Path ($env:USERPROFILE + "\projects") -Force | Out-Null 
Set-Location -Path ($env:USERPROFILE + "\projects")
RunConsoleCommand -command "git.exe" -parameters @("clone", "--recursive", "https://git.beercaps.ru/orlov/windows-config.git")

Set-Location -Path "./windows-config"
RunConsoleCommand -command "git.exe" -parameters @("checkout", "develop")
RunConsoleCommand -command "git.exe" -parameters @("status")
# RunConsoleCommand -command "git.exe" -parameters @("checkout", "-t", "origin/develop")