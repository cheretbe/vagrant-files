Set-StrictMode -Version Latest
$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop

# Avoid registering unwanted NIC(s) in DNS on a Mulithomed Domain Controller
# https://support.microsoft.com/en-us/help/2023004/steps-to-avoid-registering-unwanted-nic-s-in-dns-on-a-mulithomed-domai

# Step 2. Remove unnecessary listening addresses

$dns_settings = Get-DnsServerSetting -All
if ($dns_settings.ListeningIPAddress -ne @("192.168.199.10")) {
  Write-Output "Setting DNS server to listen on 192.168.199.10 only"
  $dns_settings.ListeningIPAddress = @("192.168.199.10")
  Set-DnsServerSetting -InputObject $dns_settings
} #if

# Purely cosmetic setting: Change DNS server on NAT interface from 127.0.0.1
# to DHCP-assigned. This fixes network status icon in tray showing "No internet access"
$nat_interface = Get-WmiObject Win32_NetworkAdapterConfiguration -filter "ipenabled = 'true'" |
  where { -not ($_.IPAddress -contains "192.168.199.10")}
if ((Get-DnsClientServerAddress -InterfaceIndex $nat_interface.InterfaceIndex -AddressFamily IPv4).ServerAddresses -eq "127.0.0.1") {
  $nat_interface_name = (Get-NetIPAddress -InterfaceIndex $nat_interface.InterfaceIndex -AddressFamily IPv4).InterfaceAlias
  Write-Output ("Setting '{0}' interface to use DHCP for DNS server" -f $nat_interface_name)
  Set-DnsClientServerAddress -InterfaceIndex $nat_interface.InterfaceIndex -ResetServerAddresses
}
