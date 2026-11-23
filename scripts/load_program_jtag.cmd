@echo off
setlocal
rem Original Xilinx JTAG Loader; ISE runtime is required.
if not defined ISE_DS_ROOT set "ISE_DS_ROOT=C:\Xilinx\14.7\ISE_DS"
if not exist "%ISE_DS_ROOT%\settings64.bat" (echo Set ISE_DS_ROOT to your ISE_DS directory. & exit /b 1)
call "%ISE_DS_ROOT%\settings64.bat"
set "XILINX=%ISE_DS_ROOT%\ISE"
set "PATH=%XILINX%\lib\nt64;%XILINX%\bin\nt64;%PATH%"
pushd "%~dp0..\software"
"%~dp0..\tools\JTAG_Loader_Win7_64.exe" -d -l demo.hex
set "RESULT=%ERRORLEVEL%"
popd
exit /b %RESULT%
