# Set-ExecutionPolicy Bypass; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/cheretbe/vagrant-files/develop/windows/provision/chocolatey.ps1'))

Set-StrictMode -Version Latest
$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
$Host.PrivateData.VerboseForegroundColor = [ConsoleColor]::DarkCyan

Write-Host "There you go" -ForegroundColor Cyan