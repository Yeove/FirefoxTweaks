@echo off
rem Double-click this to run the setup script.
rem (Windows' built-in "Run with PowerShell" option breaks on folder names
rem  containing an apostrophe, and may be blocked by execution policy.)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_the_cmd_file_instead.ps1"
rem If PowerShell couldn't start the script at all, keep this window open.
if errorlevel 1 pause
