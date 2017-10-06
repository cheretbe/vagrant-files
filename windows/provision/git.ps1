Set-StrictMode -Version Latest
$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
$Host.PrivateData.VerboseForegroundColor = [ConsoleColor]::DarkCyan

function RunConsoleCommand {
param(
  [string]$command,
  [string[]]$parameters
)
  & $command $parameters
  if ($LASTEXITCODE -ne 0)
    { throw ('Error calling "{0}" "{1}"' -f $command, ($parameters -join '" "')) }
}

if ((Get-Command "git.exe" -ErrorAction SilentlyContinue) -eq $NULL) {
  Write-Output "Git is not installed. Installing"
  RunConsoleCommand -command "choco.exe" -parameters @("install", "git", "-y")
  # $env:Path = $env:Path + ";ProgramFiles\Git\cmd"
} else {
  Write-Output "Git is already installed"
} #if