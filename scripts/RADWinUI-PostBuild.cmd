@echo off
rem Post-build step of a RADWinUI project: copies the Windows App SDK bootstrap
rem DLL next to the exe, and builds resources.pri from the project's
rem Strings\<language>\*.resw. The SDK release comes from build\WindowsAppSDK.json.
rem Usage: RADWinUI-PostBuild.cmd "<exe output folder>" ["<project folder>"]
setlocal
set "ROOT=%~dp0.."
set "RELEASE="
for /f tokens^=4^ delims^=^" %%v in ('findstr /c:"\"release\"" "%ROOT%\build\WindowsAppSDK.json"') do set "RELEASE=%%v"
set "DLL=%ROOT%\third_party\WindowsAppSDK\%RELEASE%\Microsoft.WindowsAppSDK.Foundation\runtimes\win-x64\native\Microsoft.WindowsAppRuntime.Bootstrap.dll"
if "%RELEASE%"=="" goto NoSdk
if not exist "%DLL%" goto NoSdk
if not exist "%~1" mkdir "%~1"
copy /Y "%DLL%" "%~1" >nul
if errorlevel 1 exit /b %ERRORLEVEL%
rem A project made before the second argument: the exe is in <project>\Win64\<config>
set "PROJECT=%~2"
if "%PROJECT%"=="" set "PROJECT=%~1\..\.."
if not exist "%PROJECT%\Strings" exit /b 0
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Make-Pri.ps1" -ProjectDir "%PROJECT%" -OutDir "%~1"
exit /b %ERRORLEVEL%

:NoSdk
echo RADWinUI : error RW1001 : Windows App SDK files are missing. Run scripts\Get-WindowsAppSDK.ps1 once - see docs\GETTING-STARTED.md, step 0.
exit /b 1
