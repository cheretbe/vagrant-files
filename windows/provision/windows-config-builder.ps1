Set-StrictMode -Version Latest
$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
$Host.PrivateData.VerboseForegroundColor = [ConsoleColor]::DarkCyan

$script:scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

. (Join-Path -Path $script:scriptDir -ChildPath "chocolatey.ps1")
. (Join-Path -Path $script:scriptDir -ChildPath "git.ps1")

