[CmdletBinding()]
param(
  [string]$vagrantPassword = "vagrant"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop

$schTask = Get-ScheduledTask -TaskName "Vagrant - Fix default route" -ErrorAction SilentlyContinue
# [enum]::GetValues([Microsoft.PowerShell.Cmdletization.GeneratedTypes.ScheduledTask.StateEnum])
if ($schTask) {
  if ($schTask.State -ne "Running") {
    Write-Output "Executing scheduled task 'Vagrant - Fix default route'"
    Start-ScheduledTask -TaskName "Vagrant - Fix default route"
  }
}
if (Test-Path -Path "C:\\Users\\vagrant\\AppData\\Local\\Programs\\vpn-tools\\PsExec64.exe") {
  # -d  Don't wait for process to terminate (non-interactive).
  # -i  Run the program so that it interacts with the desktop of the specified
  #     session on the remote system

  & "C:\\Users\\vagrant\\AppData\\Local\\Programs\\vpn-tools\\PsExec64.exe" `
    -accepteula `
    -d -i 1 -u vagrant -p $vagrantPassword `
    "c:\\users\\vagrant\\Desktop\\Get IP info.bat"
}
