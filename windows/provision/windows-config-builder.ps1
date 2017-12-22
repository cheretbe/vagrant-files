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

function RunScript {
[CmdletBinding()]
param(
  [string]$scriptName
)
  if ($localTest.IsPresent)
    { Write-Verbose ("Local testing mode") }

  $localFilePath = Join-Path -Path $script:scriptDir -ChildPath $scriptName
  if (Test-Path -Path $localFilePath) {
    Write-Host ("Executing '{0}'" -f $localFilePath)
    . $localFilePath
  } else {
    if ($localTest.IsPresent) {
      $localFilePath = Join-Path -Path ${Env:USERPROFILE} -ChildPath ('provision/' + $scriptName)
      Write-Host ("Invoking '{0}'" -f $localFilePath)
      $scriptContents = Get-Content -Path $localFilePath | Out-String
    } else {
      $gitBranch = if ($develop) { "develop" } else { "master" }
      $scriptURL = ("https://raw.githubusercontent.com/cheretbe/vagrant-files/{0}/windows/provision/{1}" -f $gitBranch, $scriptName)
      Write-Host ("Invoking '{0}'" -f $scriptURL)
      $scriptContents = (New-Object System.Net.WebClient).DownloadString($localFilePath)
    } #if
    Invoke-Expression $scriptContents
  } #if
}

RunScript -scriptName "chocolatey.ps1"
RunScript -scriptName "git.ps1"

# if ($localTest.IsPresent) {
#   Write-Verbose ("Local testing mode")
#   Invoke-Expression ((Get-Content -Path (${Env:USERPROFILE} + '/provision/chocolatey.ps1') | Out-String))
#   Invoke-Expression ((Get-Content -Path (${Env:USERPROFILE} + '/provision/git.ps1') | Out-String))
# } elseif (Test-Path -Path (Join-Path -Path $script:scriptDir -ChildPath "chocolatey.ps1")) {
#   . (Join-Path -Path $script:scriptDir -ChildPath "chocolatey.ps1")
#   . (Join-Path -Path $script:scriptDir -ChildPath "git.ps1")
# } else {
#   $repoPath = "https://raw.githubusercontent.com/cheretbe/vagrant-files"
#   $gitBranch = if ($develop) { "develop" } else { "master" }
#   Invoke-Expression ((New-Object System.Net.WebClient).DownloadString(
#     ("{0}/{1}/windows/provision/chocolatey.ps1" -f $repoPath, $gitBranch)))
#   Invoke-Expression ((New-Object System.Net.WebClient).DownloadString(
#     ("{0}/{1}/windows/provision/git.ps1" -f $repoPath, $gitBranch)))
# } #if

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