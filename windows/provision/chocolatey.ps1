# Set-ExecutionPolicy Bypass -Scope Process; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/cheretbe/vagrant-files/develop/windows/provision/chocolatey.ps1'))

Set-StrictMode -Version Latest
$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
$Host.PrivateData.VerboseForegroundColor = [ConsoleColor]::DarkCyan

Set-ExecutionPolicy Bypass -Scope Process

if ((Get-Command "choco.exe" -ErrorAction SilentlyContinue) -eq $NULL) {
  Write-Output "Chocolatey is not installed. Installing"
  Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
} else {
  Write-Output "Chocolatey is already installed"
} #if