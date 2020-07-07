Set-StrictMode -Version Latest
$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop

$intnet_interface = (Get-NetIPAddress | Where-Object { $_.IPAddress -eq "192.168.199.10" })
if ((Get-DnsClientServerAddress -InterfaceIndex $intnet_interface.InterfaceIndex -AddressFamily IPv4).ServerAddresses -ne "192.168.199.10") {
  Write-Output ("Setting 192.168.199.10 as DNS server for '{0}' interface" -f $intnet_interface.InterfaceAlias)
  Set-DnsClientServerAddress -InterfaceIndex $intnet_interface.InterfaceIndex `
    -ServerAddresses @("192.168.199.10")
}
# Avoid registering unwanted NIC(s) in DNS on a Mulithomed Domain Controller
# https://support.microsoft.com/en-us/help/2023004/steps-to-avoid-registering-unwanted-nic-s-in-dns-on-a-mulithomed-domai

# Step 1. Disable "Register this connectionss addresses in DNS" for NAT interface

$nat_interface = Get-WmiObject Win32_NetworkAdapterConfiguration -filter "ipenabled = 'true'" |
  where { -not ($_.IPAddress -contains "192.168.199.10")}

if ($nat_interface.FullDNSRegistrationEnabled) {
  $interface_name = (Get-WmiObject Win32_NetworkAdapter -Filter ('GUID = "{0}"' -f $nat_interface.SettingID)).NetConnectionID
  Write-Output ("Disabling address registration in DNS for '{0}' interface" -f $interface_name)
  # https://docs.microsoft.com/en-us/windows/win32/cimwin32prov/setdynamicdnsregistration-method-in-class-win32-networkadapterconfiguration
  $result = $nat_interface.SetDynamicDNSRegistration($FALSE, $FALSE)
  if ($result.ReturnValue -gt 1)
    { throw "SetDynamicDNSRegistration call failed. Error code: {0}" -f $result.ReturnValue}
} #if
