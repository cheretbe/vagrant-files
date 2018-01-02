#. ([scriptblock]::Create(((New-Object System.Net.WebClient).DownloadString("https://git.io/vby9m")))) -scriptName "windows-config-builder.ps1"
#. ([scriptblock]::Create(((New-Object System.Net.WebClient).DownloadString("https://git.io/vby9m")))) -scriptName "windows-config-builder.ps1" -gitBranch "develop"
#. ([scriptblock]::Create(((New-Object System.Net.WebClient).DownloadString("https://git.io/vby9m")))) -scriptName "windows-config-builder.ps1" scriptParams @{"Verbose" = $TRUE} -localTest

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
$Host.PrivateData.VerboseForegroundColor = [ConsoleColor]::DarkCyan
$Host.PrivateData.VerboseBackgroundColor = $Host.UI.RawUI.BackgroundColor
$Host.PrivateData.WarningBackgroundColor = $Host.UI.RawUI.BackgroundColor
$Host.PrivateData.ErrorBackgroundColor = $Host.UI.RawUI.BackgroundColor

$script:scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module (Join-Path -Path $script:scriptDir -ChildPath "common.psm1")

Invoke-VagrantProvisionScript -scriptName "chocolatey.ps1"
Invoke-VagrantProvisionScript -scriptName "git.ps1"
Invoke-VagrantProvisionScript -scriptName "set-env-variables.ps1"

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

if (-not(Get-Module "AWSPowerShell" -ListAvailable)) {
  Write-Host "Installing NuGet package provider"
  Install-PackageProvider -Name NuGet -Force
  Write-Host "Installing AWS Tools for Windows PowerShell"
  Install-Module "AWSPowerShell" -Force
} #if

Import-Module AWSPowerShell
Get-AWSPowerShellVersion