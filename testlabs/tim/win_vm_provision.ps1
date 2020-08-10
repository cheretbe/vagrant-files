[CmdletBinding()]
param(
  [string]$intNetIP,
  [string]$routerIP,
  [string]$taskUserPassword = "vagrant"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop

$cimTriggerClass = Get-CimClass -ClassName "MSFT_TaskEventTrigger" `
  -Namespace "Root/Microsoft/Windows/TaskScheduler:MSFT_TaskEventTrigger"

$taskTrigger = New-CimInstance -CimClass $cimTriggerClass `
  -ClientOnly `
  -Property @{
    Enabled = $TRUE
    Subscription = (-join @(
      '<QueryList>'
      '  <Query Id="0" Path="Microsoft-Windows-NetworkProfile/Operational">'
      '    <Select Path="Microsoft-Windows-NetworkProfile/Operational">'
      '      *[System[Provider[@Name=''Microsoft-Windows-NetworkProfile''] and EventID=10000]]'
      '    </Select>'
      '  </Query>'
      '</QueryList>'
   ))
  }

$taskAction = New-ScheduledTaskAction `
  -Execute 'C:\Windows\system32\WindowsPowerShell\v1.0\powershell.exe' `
  -Argument (-join @(
    "-NoProfile -NonInteractive -ExecutionPolicy Bypass "
    ("-File c:\users\vagrant\win_vm_update_routes.ps1 -intNetIP {0} -routerIP {1}" -f $intNetIP, $routerIP)
  ))

Write-Output "Adding scheduled task to fix default route"

$task = Register-ScheduledTask -Force -TaskName "Vagrant - Fix default route" `
  -Trigger $taskTrigger -Action $taskAction -RunLevel Highest `
  -User ([Security.Principal.WindowsIdentity]::GetCurrent().Name) `
  -Password $taskUserPassword
