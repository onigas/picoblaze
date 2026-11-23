@echo off
setlocal
if not defined VIVADO_BAT set "VIVADO_BAT=C:\Xilinx\Vivado\2022.2\bin\vivado.bat"
if not exist "%VIVADO_BAT%" (echo Set VIVADO_BAT to Vivado 2022.2 bin\vivado.bat & exit /b 1)
pushd "%~dp0.."
call "%VIVADO_BAT%" -mode batch -source scripts/build.tcl -log build.log -journal build.jou
set "RESULT=%ERRORLEVEL%"
popd
exit /b %RESULT%
