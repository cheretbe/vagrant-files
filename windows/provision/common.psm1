Set-StrictMode -Version Latest
$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
$Host.PrivateData.VerboseForegroundColor = [ConsoleColor]::DarkCyan

$script:scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$global:provisionLocalTestMode = $FALSE

function Set-VagrantProvisionLocalTestMode {
[CmdletBinding()]
param(
  [bool]$testMode
)
  $global:provisionLocalTestMode = $testMode
}

function Invoke-VagrantProvisionScript {
[CmdletBinding()]
param(
  [string]$scriptName,
  [string]$gitBranch = "master",
  [hashtable]$scriptParams = @{}
)
  # if ($global:provisionLocalTestMode)
  #   { Write-Host ("Local testing mode") -ForegroundColor Cyan }

  $localFilePath = Join-Path -Path $script:scriptDir -ChildPath $scriptName
  if ((Test-Path -Path $localFilePath) -and (-not ($global:provisionLocalTestMode))) {
    Write-Host ("Dot-sourcing '{0}'" -f $localFilePath)
    . $localFilePath @scriptParams
  } else {
    if ($global:provisionLocalTestMode) {
      $localSource = Join-Path -Path ${Env:USERPROFILE} -ChildPath ('provision/' + $scriptName)
      Write-Host ("Copying '{0}'" -f $localSource)
      $scriptContents = Get-Content -Path $localSource | Out-String
    } else {
      $scriptURL = ("https://raw.githubusercontent.com/cheretbe/vagrant-files/{0}/windows/provision/{1}" -f $gitBranch, $scriptName)
      Write-Host ("Downloading '{0}'" -f $scriptURL)
      $scriptContents = (New-Object System.Net.WebClient).DownloadString($scriptURL)
    } #if
    $scriptContents | Out-File -FilePath $localFilePath -Force
    Write-Host ("Dot-sourcing '{0}'" -f $localFilePath)
    . $localFilePath @scriptParams
  } #if
}

Export-ModuleMember -Function Set-VagrantProvisionLocalTestMode
Export-ModuleMember -Function Invoke-VagrantProvisionScript
