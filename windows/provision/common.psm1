Set-StrictMode -Version Latest
$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
$Host.PrivateData.VerboseForegroundColor = [ConsoleColor]::DarkCyan

$script:scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:provisionLocalTestMode = $FALSE
# Write-Host $MyInvocation.MyCommand.Path -ForegroundColor Cyan
# Write-Host ("localTest: {0}" -f $localTest.IsPresent)

function Set-VagrantProvisionLocalTestMode {
[CmdletBinding()]
param(
  [bool]$testMode
)
  $script:provisionLocalTestMode = $testMode
}

function Invoke-VagrantProvisionScript {
[CmdletBinding()]
param(
  [string]$scriptName,
  [hashtable]$scriptParams
)
  Write-Host ("provisionLocalTestMode: {0}" -f $script:provisionLocalTestMode) -ForegroundColor Cyan
  Write-Verbose ("scriptName: {0}, scriptParams: {1}" -f $scriptName, ($scriptParams | Out-String))
}

Export-ModuleMember -Function Set-VagrantProvisionLocalTestMode
Export-ModuleMember -Function Invoke-VagrantProvisionScript
