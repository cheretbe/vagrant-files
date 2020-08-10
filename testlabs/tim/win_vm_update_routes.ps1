[CmdletBinding()]
param(
  [string]$routerIP
)


Set-StrictMode -Version Latest
$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop

("{0} - {1}" -f (Get-Date -Format "dd.MM.yyyy HH:mm:ss"), $MyInvocation.MyCommand.Path) |
  Out-File -Append -FilePath "c:\users\vagrant\desktop\scheduled_task.log"

$natInterface = Get-NetIPInterface -DHCP enabled -AddressFamily IPv4
$natDefaultRoute = Get-NetRoute -AddressFamily IPv4 | Where-Object {
  ($_.InterfaceIndex -eq $natInterface.InterfaceIndex) -and ($_.DestinationPrefix -eq "0.0.0.0/0")
}
if (-not($NULL -eq $natDefaultRoute)) {
  Write-Output "Removing default route via NAT interface"
  $natDefaultRoute | Remove-NetRoute -Confirm:$FALSE
} #if

$intNetDefaultRoute = Get-NetRoute -AddressFamily IPv4 | Where-Object {
  ($_.NextHop -eq $routerIP) -and ($_.DestinationPrefix -eq "0.0.0.0/0")
}
if ($NULL -eq $intNetDefaultRoute) {
  Write-Output ("Adding default route via {0}" -f $routerIP)
  New-NetRoute -DestinationPrefix "0.0.0.0/0" -NextHop $routerIP `
    -InterfaceIndex (Get-NetIPAddress -AddressFamily IPv4 -PrefixOrigin Manual).InterfaceIndex | Out-Null
} #if