@ECHO OFF

ECHO Starting powershell...
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%~dp0%~n0.ps1"

PATH %PATH%;%ProgramData%\chocolatey\bin;%ProgramFiles%\Git\cmd