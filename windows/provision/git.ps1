Set-StrictMode -Version Latest
$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
$Host.PrivateData.VerboseForegroundColor = [ConsoleColor]::DarkCyan

function RunConsoleCommand {
param(
  [string]$command,
  [string[]]$parameters
)
  $oldErrorActionPreference = $script:ErrorActionPreference
  try {
    $script:ErrorActionPreference = [System.Management.Automation.ActionPreference]::Continue
    & $command $parameters
    if ($LASTEXITCODE -ne 0)
      { throw ('Error calling "{0}" "{1}"' -f $command, ($parameters -join '" "')) }
  } finally {
    $script:ErrorActionPreference = $oldErrorActionPreference
  }
}

if ((Get-Command "git.exe" -ErrorAction SilentlyContinue) -eq $NULL) {
  Write-Output "Git is not installed. Installing"
  RunConsoleCommand -command "choco.exe" -parameters @("install", "git", "-y", "--no-progress")
  $env:Path = $env:Path + ";" + $env:ProgramFiles + "\Git\cmd"

  RunConsoleCommand -command "choco.exe" -parameters @("install", "git-credential-manager-for-windows", "-y", "--no-progress")

  RunConsoleCommand -command "git.exe" -parameters @("config", "--global", "user.useConfigOnly", "true")
  # RunConsoleCommand -command "git.exe" -parameters @("config", "--global", "credential.helper", "store")
  RunConsoleCommand -command "git.exe" -parameters @("config", "--global", "credential.helper", "manager")
} else {
  Write-Output "Git is already installed"
} #if