# $nat_interface = Get-WmiObject Win32_NetworkAdapterConfiguration -filter "ipenabled = 'true'" |
#   where { -not ($_.IPAddress -contains "192.168.1.10")}
# $nat_interface = Get-WmiObject Win32_NetworkAdapterConfiguration -filter "ipenabled = 'true'" |
#   where { -not ($_.IPAddress -contains "192.168.1.10")}
# Get-NetRoute -AddressFamily IPv4 -InterfaceIndex $nat_interface.InterfaceIndex -DestinationPrefix "0.0.0.0/0" -ErrorAction Continue

# $dummy = Get-NetRoute -AddressFamily IPv4 | Where-Object { ($_.InterfaceIndex -eq $nat_interface.InterfaceIndex) -and ($_.DestinationPrefix -eq "0.0.0.0/0") }

$natInterface = Get-NetIPInterface -DHCP enabled -AddressFamily IPv4
$natDefaultRoute = Get-NetRoute -AddressFamily IPv4 | Where-Object {
  ($_.InterfaceIndex -eq $natInterface.InterfaceIndex) -and ($_.DestinationPrefix -eq "0.0.0.0/0")
}
if (-not($NULL -eq $natDefaultRoute)) {
  Write-Output "Removing default route via NAT interface"
  $natDefaultRoute | Remove-NetRoute -Confirm:$FALSE
} #if

$intNetDefaultRoute = Get-NetRoute -AddressFamily IPv4 | Where-Object {
  ($_.NextHop -eq "192.168.1.1") -and ($_.DestinationPrefix -eq "0.0.0.0/0")
}
if ($NULL -eq $intNetDefaultRoute) {
  Write-Output "Adding default route via internal network"
  New-NetRoute -DestinationPrefix "0.0.0.0/0" -NextHop "192.168.1.1" `
    -InterfaceIndex (Get-NetIPAddress -IPAddress "192.168.1.10").InterfaceIndex | Out-Null
} #if