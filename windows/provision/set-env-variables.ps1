[CmdletBinding()]
param(
  [switch]$SettingChangeMessageOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
$Host.PrivateData.VerboseForegroundColor = [ConsoleColor]::DarkCyan

# https://github.com/chocolatey/package-verifier/blob/master/src/chocolatey.package.verifier.host/shell/NotifyGuiAppsOfEnvironmentChanges.ps1
if (-not ("provision.win32" -as [type])) {
  Add-Type -name "win32" -namespace "provision" -MemberDefinition '
    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg,
      UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
  ' -Debug:$FALSE
}

function SetUserEnvVariable {
param(
  [string]$varName,
  $varValue
)
  New-ItemProperty -Path "HKCU:\Environment" -Name $varName -Value $varValue `
    -PropertyType ([Microsoft.Win32.RegistryValueKind]::String) -Force | Out-Null
  Set-Item -Path ("Env:\{0}" -f $varName) -value $varValue
}

  # Notifies all windows of environment block change
function SendSettingChangeMessage {
param()
  $HWND_BROADCAST = [intptr]0xFFFF;
  $WM_SETTINGCHANGE = 0x1A;
  $result = [uintptr]::zero

  [provision.win32]::SendMessageTimeout($HWND_BROADCAST, $WM_SETTINGCHANGE,
    [uintptr]::Zero, "Environment", 2, 5000, [ref]$result) | Out-Null
}

if ($SettingChangeMessageOnly.IsPresent) {
  Write-Host "Senging WM_SETTINGCHANGE message"
  SendSettingChangeMessage
  exit 0
}


if (Test-Path -Path "c:\vagrant\temp\env_variables.txt") {
  Write-Host "Setting environment variables"
  foreach($line in Get-Content "c:\vagrant\temp\env_variables.txt") {
    $varName, $varValue = $line.split("=")
    if ($varName.trim() -ne "") {
      Write-Host ("  " + $varName)
      SetUserEnvVariable -varName $varName -varValue $varValue
    } #if
  } #foreach

  SendSettingChangeMessage
  if (-not([Environment]::UserInteractive)) {
    # Running in non-interactive environment (WinRM or scheduled task)
    # This means the script runs in a separate user session, other than GUI
    # of the currently logged in user, and broadcast message is not going to
    # reach exporer process.
    # To force environment variables update in the GUI session we create a
    # temporary scheduled task that will run as currently logged in user and
    # will be able to send broadcast message

    Write-Host "Creating and running scheduled task to send WM_SETTINGCHANGE message"
    $taskAction = New-ScheduledTaskAction -Execute "powershell.exe" `
      -Argument ('-ExecutionPolicy Bypass -NoProfile -File "{0}" -SettingChangeMessageOnly' -f $MyInvocation.MyCommand.Path)
    $task = New-ScheduledTask -Action $taskAction -Settings (New-ScheduledTaskSettingsSet)
    $task | Register-ScheduledTask -TaskName "provision_env_vars_update" -User "vagrant" | Out-Null

    Start-ScheduledTask -TaskName "provision_env_vars_update"

    $emptyDate = [datetime]::ParseExact("1999-11-30 00:00:00", "yyyy-MM-dd HH:mm:ss", $NULL)
    $readyState = [Microsoft.PowerShell.Cmdletization.GeneratedTypes.ScheduledTask.StateEnum]::Ready
    do {
      $task = Get-ScheduledTask -TaskName "provision_env_vars_update"
      $taskHasFinished = ($task.State -eq $readyState) -and (($task | Get-ScheduledTaskInfo).LastRunTime -ne $emptyDate)
      Start-Sleep -Seconds 1
    } while (-not($taskHasFinished))

    Write-Host "Deleting scheduled task"
    Unregister-ScheduledTask -TaskName "provision_env_vars_update" -Confirm:$FALSE
  } #if
} #if

