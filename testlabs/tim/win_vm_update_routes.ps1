[CmdletBinding()]
param(
  [string]$intNetIP,
  [string]$routerIP
)


Set-StrictMode -Version Latest
$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop

$sciptPath = $MyInvocation.MyCommand.Path

. {

  Write-Output ("{0} - {1}" -f (Get-Date -Format "dd.MM.yyyy HH:mm:ss"), $sciptPath)

  $intNetInterfaceIdx = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -eq $intNetIP }).InterfaceIndex

  Get-NetRoute -AddressFamily IPv4 | ForEach-Object {
    if (($_.DestinationPrefix -eq "0.0.0.0/0") -and ($_.InterfaceIndex -ne $intNetInterfaceIdx)) {
      Write-Output ("  Removing default route via {0}" -f $_.NextHop)
      $_ | Remove-NetRoute -Confirm:$FALSE
    } #if
  }

  $intNetDefaultRoute = Get-NetRoute -AddressFamily IPv4 | Where-Object {
    ($_.InterfaceIndex -eq $intNetInterfaceIdx) -and ($_.DestinationPrefix -eq "0.0.0.0/0")
  }
  if ($NULL -eq $intNetDefaultRoute) {
    Write-Output ("  Adding default route via {0}" -f $routerIP)
    New-NetRoute -DestinationPrefix "0.0.0.0/0" -NextHop $routerIP `
      -InterfaceIndex $intNetInterfaceIdx | Out-Null
  } #if

} *>&1 | Tee-Object -Append -FilePath "c:\users\vagrant\desktop\scheduled_task.log"