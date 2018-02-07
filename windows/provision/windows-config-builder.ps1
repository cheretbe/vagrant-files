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
$script:gitlabHost = "git.beercaps.ru"

Invoke-VagrantProvisionScript -scriptName "chocolatey.ps1"
Invoke-VagrantProvisionScript -scriptName "git.ps1"
Invoke-VagrantProvisionScript -scriptName "set-env-variables.ps1"

Invoke-VagrantProvisionConsoleCommand -command "choco.exe" -parameters @("install", "Nuget.CommandLine", "-y", "--no-progress")

$credentialsFile = (Join-Path -Path $env:USERPROFILE -ChildPath ".git-credentials")
if ((Test-Path "Env:\AO_DEFAULT_GITLAB_USER") -and (Test-Path "Env:\AO_DEFAULT_GITLAB_PASSWORD")) {
  if ($NULL -eq (Get-Content $credentialsFile -ErrorAction SilentlyContinue | Where-Object { $_.Contains($script:gitlabHost) })) {
    Write-Host ("Adding credentials to '{0}'" -f $credentialsFile)
    # Note Linux-style line ending. It is necessary for git to recognize the credentials
    [System.IO.File]::AppendAllText($credentialsFile, ("https://{0}:{1}@{2}`n" -f `
      $Env:AO_DEFAULT_GITLAB_USER, $Env:AO_DEFAULT_GITLAB_PASSWORD, $script:gitlabHost))
  } else {
    Write-Host ("'{0}' already contains credentials for {1}" -f $credentialsFile, $script:gitlabHost)
  } #if
} #if

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

if (Test-Path -Path $credentialsFile) {
  Invoke-VagrantProvisionConsoleCommand -command "git.exe" `
    -parameters @("config", "--global", "credential.helper", "store")
  Invoke-VagrantProvisionConsoleCommand -command "git.exe" `
    -parameters @("config", "--system", "credential.helper", "store")
}

if (-not(Get-Module "AWSPowerShell" -ListAvailable)) {
  Write-Host "Installing NuGet package provider"
  Install-PackageProvider -Name NuGet -Force
  Write-Host "Installing AWS Tools for Windows PowerShell"
  Install-Module "AWSPowerShell" -Force
} #if

Import-Module AWSPowerShell
Get-AWSPowerShellVersion