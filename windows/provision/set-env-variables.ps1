[CmdletBinding()]
param()

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

if (Test-Path -Path "c:\vagrant\temp\env_variables.txt") {
  Write-Host "Setting environment variables"
  foreach($line in Get-Content "c:\vagrant\temp\env_variables.txt") {
    $varName, $varValue = $line.split("=")
    if ($varName.trim() -ne "") {
      Write-Host ("  " + $varName)
      SetUserEnvVariable -varName $varName -varValue $varValue
    } #if
  } #foreach

  $HWND_BROADCAST = [intptr]0xFFFF;
  $WM_SETTINGCHANGE = 0x1A;
  $result = [uintptr]::zero

  # Notify all windows of environment block change
  [provision.win32]::SendMessageTimeout($HWND_BROADCAST, $WM_SETTINGCHANGE,
    [uintptr]::Zero, "Environment", 2, 5000, [ref]$result) | Out-Null
} #if

# $taskAction = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c dir c:\"
# $task = New-ScheduledTask -Action $taskAction -Settings (New-ScheduledTaskSettingsSet)
# $task | Register-ScheduledTask -TaskName "test" -User "vagrant" | Out-Null

# $dummy = Get-ScheduledTask -TaskName "test" | Get-ScheduledTaskInfo
# $dummy.LastRunTime -eq [datetime]::ParseExact("1999-11-30 00:00:00", "yyyy-MM-dd HH:mm:ss", $NULL)
# (Get-ScheduledTask -TaskName "test").State -eq [Microsoft.PowerShell.Cmdletization.GeneratedTypes.ScheduledTask.StateEnum]::Ready