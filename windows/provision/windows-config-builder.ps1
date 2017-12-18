[CmdletBinding()]
param(
  [switch]$offline,
  [switch]$develop
)

Set-StrictMode -Version Latest
$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
$Host.PrivateData.VerboseForegroundColor = [ConsoleColor]::DarkCyan

$script:scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

if ($offline.IsPresent) {
  . (Join-Path -Path $script:scriptDir -ChildPath "chocolatey.ps1")
  . (Join-Path -Path $script:scriptDir -ChildPath "git.ps1")
} else {
  $repoPath = "https://raw.githubusercontent.com/cheretbe/vagrant-files"
  $gitBranch = if ($develop.IsPresent) { "develop" } else { "master" }
  Invoke-Expression ((New-Object System.Net.WebClient).DownloadString(
    ("{0}/{1}/windows/provision/chocolatey.ps1" -f $repoPath, $gitBranch)))
  Invoke-Expression ((New-Object System.Net.WebClient).DownloadString(
    ("{0}/{1}/windows/provision/git.ps1" -f $repoPath, $gitBranch)))
} #if

New-Item -ItemType Directory -Path ($env:USERPROFILE + "\projects") -Force | Out-Null 
Set-Location -Path ($env:USERPROFILE + "\projects")
if (-not(Test-Path -Path "./windows-config")) {
  RunConsoleCommand -command "git.exe" -parameters @(
    "clone", "--recursive", "https://git.beercaps.ru/orlov/windows-config.git"
  )
} #if

Set-Location -Path "./windows-config"
RunConsoleCommand -command "git.exe" -parameters @("checkout", "develop")
RunConsoleCommand -command "git.exe" -parameters @("status")
# RunConsoleCommand -command "git.exe" -parameters @("checkout", "-t", "origin/develop")