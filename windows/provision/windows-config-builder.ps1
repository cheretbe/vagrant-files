[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop

$script:scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module (Join-Path -Path $script:scriptDir -ChildPath "common.psm1")
$script:gitlabHost = "git.beercaps.ru"

Invoke-VagrantProvisionScript -scriptName "git.ps1" -scriptParams @{"saveGitlabCredentials" = $TRUE}

Invoke-VagrantProvisionConsoleCommand -command "choco.exe" -parameters @("install", "Nuget.CommandLine", "-y", "--no-progress")
Invoke-VagrantProvisionConsoleCommand -command "choco.exe" -parameters @("install", "putty.portable", "-y", "--no-progress")

New-Item -ItemType Directory -Path ($env:USERPROFILE + "\projects") -Force | Out-Null 
Set-Location -Path ($env:USERPROFILE + "\projects")
if (-not(Test-Path -Path "./windows-config")) {
  Invoke-VagrantProvisionConsoleCommand -command "git.exe" -parameters @(
    "clone", "--recursive", "https://git.beercaps.ru/orlov/windows-config.git"
  )
} #if

Set-Location -Path "./windows-config"
Invoke-VagrantProvisionConsoleCommand -command "git.exe" -parameters @("checkout", "develop")
Invoke-VagrantProvisionConsoleCommand -command "git.exe" -parameters @("status")

if (Test-Path "Env:\AO_DEFAULT_GITLAB_USER") {
  Write-Host ("Setting 'user.name' parameter to '{0}'" -f $Env:AO_DEFAULT_GITLAB_USER)
  Invoke-VagrantProvisionConsoleCommand -command "git.exe" `
    -parameters @("config", "user.name", $Env:AO_DEFAULT_GITLAB_USER)
} #if

if (Test-Path "Env:\AO_DEFAULT_GITLAB_EMAIL") {
  Write-Host ("Setting 'user.email' parameter to '{0}'" -f $Env:AO_DEFAULT_GITLAB_EMAIL)
  Invoke-VagrantProvisionConsoleCommand -command "git.exe" `
    -parameters @("config", "user.email", $Env:AO_DEFAULT_GITLAB_EMAIL)
} #if

if (-not(Get-Module "AWSPowerShell" -ListAvailable)) {
  Write-Host "Installing NuGet package provider"
  Install-PackageProvider -Name NuGet -Force
  Write-Host "Installing AWS Tools for Windows PowerShell"
  Install-Module "AWSPowerShell" -Force
} #if

Import-Module AWSPowerShell
Get-AWSPowerShellVersion