[CmdletBinding()]
param(
  [string]$vpnGateway
)

Set-StrictMode -Version Latest
$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop

$sciptPath = $MyInvocation.MyCommand.Path

function CheckDNSServer {
param(
  $ifIndex,
  $dnsServerIP
)
  if (Compare-Object (Get-DnsClientServerAddress -InterfaceIndex $ifIndex -AddressFamily IPv4).ServerAddresses @($dnsServerIP)) {
    Write-Output ("  Setting DNS server to '{0}' on interface {1}" -f $dnsServerIP, $ifIndex)
    Set-DnsClientServerAddress -InterfaceIndex $ifIndex -ServerAddresses @($dnsServerIP)
  } #if
}

. {

  Write-Output ("{0} - {1}" -f (Get-Date -Format "dd.MM.yyyy HH:mm:ss"), $sciptPath)

  $vpnInterfaceIdx = $NULL
  $natInterfaceIdx = $NULL
  Get-NetIPAddress -AddressFamily IPv4 | ForEach-Object {
      if ($_.PrefixOrigin -eq "DHCP") {
        $natInterfaceIdx = $_.InterfaceIndex
      } elseif ($_.PrefixOrigin -eq "Manual") {
        $vpnInterfaceIdx = $_.InterfaceIndex
      } #if
    } # ForEach-Object

  # There is no way to receive IP/mask only without specifying at least one
  # DNS server entry (setting it to an empty list just doesn't change anything)
  CheckDNSServer -ifIndex $natInterfaceIdx -dnsServerIP $vpnGateway
  CheckDNSServer -ifIndex $vpnInterfaceIdx -dnsServerIP $vpnGateway

  Get-NetRoute -AddressFamily IPv4 | ForEach-Object {
    if (($_.DestinationPrefix -eq "0.0.0.0/0") -and ($_.NextHop -ne $vpnGateway)) {
      Write-Output ("  Removing default route via {0}" -f $_.NextHop)
      $_ | Remove-NetRoute -Confirm:$FALSE
    } #if
  }

  $vpnDefaultRoute = Get-NetRoute -AddressFamily IPv4 | Where-Object {
    ($_.NextHop -eq $vpnGateway) -and ($_.DestinationPrefix -eq "0.0.0.0/0")
  }
  if ($NULL -eq $vpnDefaultRoute) {
    Write-Output ("  Adding default route via {0}" -f $vpnGateway)
    New-NetRoute -DestinationPrefix "0.0.0.0/0" -NextHop $vpnGateway `
      -InterfaceIndex $vpnInterfaceIdx -PolicyStore ActiveStore | Out-Null
  } #if

} *>&1 | Tee-Object -Append -FilePath "c:\users\vagrant\desktop\scheduled_task.log"