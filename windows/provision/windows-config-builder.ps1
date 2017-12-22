#[scriptblock]::Create(((New-Object System.Net.WebClient).DownloadString("https://git.io/vby9m"))).Invoke("windows-config-builder.ps1", $True)

#[scriptblock]::Create(((New-Object System.Net.WebClient).DownloadString(
#  "https://gist.githubusercontent.com/cheretbe/1965da139998cdc31e89759a9d33a0d4/raw/"))).Invoke(
#    "windows-config-builder.ps1", $True
#  )


# Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/cheretbe/vagrant-files/master/windows/provision/chocolatey.ps1'))
# Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/cheretbe/vagrant-files/develop/windows/provision/chocolatey.ps1'))

# Invoke-Command -ScriptBlock ([scriptblock]::Create((New-Object System.Net.WebClient).DownloadString("https://raw.githubusercontent.com/cheretbe/vagrant-files/master/windows/provision/windows-config-builder.ps1")))
# Invoke-Command -ScriptBlock ([scriptblock]::Create((New-Object System.Net.WebClient).DownloadString("https://raw.githubusercontent.com/cheretbe/vagrant-files/develop/windows/provision/windows-config-builder.ps1"))) -ArgumentList @($TRUE)

[CmdletBinding()]
param(
  [bool]$develop = $FALSE,
  [switch]$localTest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
$Host.PrivateData.VerboseForegroundColor = [ConsoleColor]::DarkCyan

$script:scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

if ($localTest.IsPresent) {
  Write-Verbose ("Local testing mode")
  Invoke-Expression ((Get-Content -Path (${Env:USERPROFILE} + '/provision/chocolatey.ps1') | Out-String))
  Invoke-Expression ((Get-Content -Path (${Env:USERPROFILE} + '/provision/git.ps1') | Out-String))
} elseif (Test-Path -Path (Join-Path -Path $script:scriptDir -ChildPath "chocolatey.ps1")) {
  . (Join-Path -Path $script:scriptDir -ChildPath "chocolatey.ps1")
  . (Join-Path -Path $script:scriptDir -ChildPath "git.ps1")
} else {
  $repoPath = "https://raw.githubusercontent.com/cheretbe/vagrant-files"
  $gitBranch = if ($develop) { "develop" } else { "master" }
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