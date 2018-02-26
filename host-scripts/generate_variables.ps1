[CmdletBinding()]
param(
  [string]$resultFile
)

Set-StrictMode -Version Latest
$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
$Host.PrivateData.VerboseForegroundColor = [ConsoleColor]::DarkCyan

$envVarNames= @("AO_DEFAULT_GITHUB_USER", "AO_DEFAULT_GITHUB_TOKEN",
  "AO_DEFAULT_GITHUB_EMAIL", "AO_DEFAULT_GITLAB_USER", "AO_DEFAULT_GITLAB_EMAIL",
  "AO_DEFAULT_GITLAB_PASSWORD", "AO_CHOCO_SERVER_API_TOKEN", "AO_PUBLISH_SSH_PORT"
)
$outputLines = @()

foreach ($envVarName in $envVarNames) {
  if (Test-Path ("Env:\{0}" -f $envVarName)) {
    $outputLines += ("{0}={1}" -f $envVarName, (Get-Item -Path ("Env:\{0}" -f $envVarName)).Value)
  } #if
} #foreach

$resultFileDir = Split-Path -Parent $resultFile
New-Item -ItemType "Directory" -Path $resultFileDir -Force | Out-Null
$outputLines | Out-File -FilePath $resultFile -Force