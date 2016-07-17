Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$adapterConfigs = Get-WmiObject win32_networkadapterconfiguration -filter "ipenabled = 'true'"

foreach ($config in $adapterConfigs) {
  if ($NULL -eq $config.DefaultIPGateway) {
    Write-Output $config.Description
    Write-Output "Setting IP address to 192.168.199.12/24"
    $config.EnableStatic("192.168.199.12", "255.255.255.0") | Out-Null
    break
  } #if
} #foreach

# $wmi.SetGateways(“10.0.0.1”, 1)
# $wmi.SetDNSServerSearchOrder(“10.0.0.100”)