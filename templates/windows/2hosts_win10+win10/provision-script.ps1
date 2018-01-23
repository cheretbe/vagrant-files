Set-StrictMode -Version Latest
$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
$Host.PrivateData.VerboseForegroundColor = [ConsoleColor]::DarkCyan

if ($NULL -eq (Get-NetFirewallRule -DisplayName "_allow_vagrant_intnet" -ErrorAction SilentlyContinue)) {
  Write-Host "Adding firewall rule (allow vagrant-intnet)"
  New-NetFirewallRule -DisplayName "_allow_vagrant_intnet" `
    -RemoteAddress "192.168.199.0/24" -Protocol Any -Profile Any -Action Allow `
    -Enabled True | Out-Null
} else {
  Write-Host "Firewall rule is already present (allow vagrant-intnet)"
} #if

if ($Env:COMPUTERNAME -eq "host1") {
  $otherHostName = "host2"
  $otherHostIP = "192.168.199.11"
} else {
  $otherHostName = "host1"
  $otherHostIP = "192.168.199.10"
} #if

$hostsFile = Join-Path -Path $Env:windir -ChildPath "System32\drivers\etc\hosts"
if ($NULL -eq (Get-Content $hostsFile | Where-Object { $_.Contains($otherHostName) })) {
  Write-Host ("Adding {0} ({1}) to '{2}'" -f $otherHostName, $otherHostIP, $hostsFile)
  # ("{0} {1}" -f $otherHostIP, $otherHostName) | Out-File -Append $hostsFile
  Add-Content $hostsFile ("`r`n{0} {1}" -f $otherHostIP, $otherHostName)
} else {
  Write-Host ("'{0}' already contains '{1}' entry. Skipping" -f $hostsFile, $otherHostName)
} #if

Set-Item "wsman:\localhost\Client\TrustedHosts" -Value "*" -Force