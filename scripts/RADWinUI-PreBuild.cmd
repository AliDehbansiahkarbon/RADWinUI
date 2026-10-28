@echo off
rem Pre-build step of a RADWinUI project: XamlCodeGen turns every .xaml in the
rem project folder into its <Name>.Xaml.pas unit.
rem Usage: RADWinUI-PreBuild.cmd "<project folder>"
setlocal
set "CODEGEN=%~dp0..\bin\XamlCodeGen.exe"
if not exist "%CODEGEN%" goto NoCodeGen
"%CODEGEN%" "%~1"
exit /b %ERRORLEVEL%

:NoCodeGen
echo RADWinUI : error RW1003 : %CODEGEN% is missing. Open RADWinUI.groupproj (RADWinUI32.groupproj in the 32-bit IDE) and use Build All once.
exit /b 1
