[CmdletBinding()]
param(
  [switch]$saveGitlabCredentials
)
Set-StrictMode -Version Latest
$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop

$script:gitlabHost = "git.beercaps.ru"

$script:scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module (Join-Path -Path $script:scriptDir -ChildPath "common.psm1")

Invoke-VagrantProvisionScript -scriptName "chocolatey.ps1"
Invoke-VagrantProvisionScript -scriptName "set-env-variables.ps1"

if ((Get-Command "git.exe" -ErrorAction SilentlyContinue) -eq $NULL) {
  Write-Output "Git is not installed. Installing"
  Invoke-VagrantProvisionConsoleCommand -command "choco.exe" `
    -parameters @("install", "git", "-y", "--no-progress")
  $env:Path = $env:Path + ";" + $env:ProgramFiles + "\Git\cmd"

  Invoke-VagrantProvisionConsoleCommand -command "choco.exe" `
    -parameters @("install", "git-credential-manager-for-windows", "-y", "--no-progress")

  Invoke-VagrantProvisionConsoleCommand -command "git.exe" `
    -parameters @("config", "--global", "user.useConfigOnly", "true")
  # Invoke-VagrantProvisionConsoleCommand -command "git.exe" `
  #   -parameters @("config", "--global", "credential.helper", "store")
  Invoke-VagrantProvisionConsoleCommand -command "git.exe" `
    -parameters @("config", "--global", "credential.helper", "manager")
} else {
  Write-Output "Git is already installed"
} #if


if ($saveGitlabCredentials.IsPresent) {
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

  Invoke-VagrantProvisionConsoleCommand -command "git.exe" `
    -parameters @("config", "--global", "credential.helper", "store")
  Invoke-VagrantProvisionConsoleCommand -command "git.exe" `
    -parameters @("config", "--system", "credential.helper", "store")
} #if