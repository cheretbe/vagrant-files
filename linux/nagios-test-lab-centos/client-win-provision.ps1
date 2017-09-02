Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.IO.Compression.FileSystem

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

New-Item -ItemType Directory -Path 'c:\temp' -Force | Out-Null
$downloadURL = "https://exchange.nagios.org/components/com_mtree/attachment.php?link_id=550&cf_id=29"
Write-Output ("Downloading {0}" -f $downloadURL)
(New-Object -TypeName 'System.Net.WebClient').DownloadFile($downloadURL, 'c:\temp\send_nsca_win32_bin.zip')

[System.IO.Compression.ZipFile]::ExtractToDirectory('C:\temp\send_nsca_win32_bin.zip', 'c:\temp')

# (!) powershell only (to expand `n as tabs)
#echo "foo.example.com`ttest`t0`t0" | C:\temp\send_nsca_win32_bin\send_nsca.exe -H 192.168.199.10 -c c:\temp\send_nsca_win32_bin\send_nsca.cfg
# Batch version should uses something other than tab as a separator
# echo "foo.example.com#test#0#0" | C:\temp\send_nsca_win32_bin\send_nsca.exe -H 192.168.199.10 -d "#" -c c:\temp\send_nsca_win32_bin\send_nsca.cfg