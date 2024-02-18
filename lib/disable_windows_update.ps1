Set-StrictMode -Version Latest
$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop

Write-Output "Setting up PolicyFileEditor"

Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
Install-Module -Name "PolicyFileEditor"

$machineDir = "${ENV:SystemRoot}\system32\GroupPolicy\Machine\Registry.pol"

Write-Output "Setting group policies"

Set-PolicyFileEntry -Value "DoNotEnforceEnterpriseTLSCertPinningForUpdateDetection" `
  -Type DWord -Data 1 `
  -Key "software\policies\microsoft\windows\windowsupdate" -Path $machineDir
Set-PolicyFileEntry -Value "SetProxyBehaviorForUpdateDetection" `
  -Type DWord -Data 0 `
  -Key "software\policies\microsoft\windows\windowsupdate" -Path $machineDir
Set-PolicyFileEntry -Value "UpdateServiceUrlAlternate" `
  -Type String -Data '' `
  -Key "software\policies\microsoft\windows\windowsupdate" -Path $machineDir
Set-PolicyFileEntry -Value "WUServer" `
  -Type String -Data "127.0.0.1" `
  -Key "software\policies\microsoft\windows\windowsupdate" -Path $machineDir
Set-PolicyFileEntry -Value "WUStatusServer" `
  -Type String -Data "127.0.0.1" `
  -Key "software\policies\microsoft\windows\windowsupdate" -Path $machineDir
Set-PolicyFileEntry -Value "UseWUServer" `
  -Type Dword -Data 1 `
  -Key "software\policies\microsoft\windows\windowsupdate\au" -Path $machineDir

Write-Output "Applying group policies"
[Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8
# Apply policies
& gpupdate.exe /force
