$nat_interface = Get-WmiObject Win32_NetworkAdapterConfiguration -filter "ipenabled = 'true'" |
  where { -not ($_.IPAddress -contains "192.168.1.10")}
$nat_interface = Get-WmiObject Win32_NetworkAdapterConfiguration -filter "ipenabled = 'true'" |
  where { -not ($_.IPAddress -contains "192.168.1.10")}
Get-NetRoute -AddressFamily IPv4 -InterfaceIndex $nat_interface.InterfaceIndex -DestinationPrefix "0.0.0.0/0" -ErrorAction Continue

$dummy = Get-NetRoute -AddressFamily IPv4 | Where-Object { ($_.InterfaceIndex -eq $nat_interface.InterfaceIndex) -and ($_.DestinationPrefix -eq "0.0.0.0/0") }