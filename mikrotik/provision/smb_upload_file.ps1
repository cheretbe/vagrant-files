[CmdletBinding()]
param(
  [string]$filePath,
  [string]$targetName
)

Set-StrictMode -Version Latest
$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop

$vmIPAddress = & "vagrant" @("ssh", "--", ":put [/ip address get [find interface=`"host_only`"] address]")
# IP Address includes network (e.g. 172.28.128.6/24), we need to remove it
$vmIPAddress = $vmIPAddress.Split("/")[0]

$vmShare = ("\\{0}\vagrant" -f $vmIPAddress)
Write-Host ("Mapping share '{0}'" -f $vmShare)
& "net" @("use", $vmShare, "/persistent:no", "/user:vagrant", "vagrant")

# Fix Linux-style path delimiters
$filePath = $filePath.Replace("/", "\")
Write-Host ("Uploading '{0}'`n" -f $filePath)
Copy-Item -Path $filePath -Destination ($vmShare + "\" + $targetName)

Write-Host ("Removing mapping '{0}'" -f $vmShare)
& "net" @("use", $vmShare, "/d")