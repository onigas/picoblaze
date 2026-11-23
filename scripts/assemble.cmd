@echo off
setlocal
pushd "%~dp0..\software"
if exist demo.hex del demo.hex
if exist demo.v del demo.v
"%~dp0..\tools\kcpsm6.exe" demo.psm
set "RESULT=%ERRORLEVEL%"
if not exist demo.hex set "RESULT=1"
if not exist demo.v set "RESULT=1"
popd
exit /b %RESULT%
