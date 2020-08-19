@echo off
:: Usage: QDIR
setlocal
chcp 1252 > nul

if "%1"=="" echo Missing queue directory specification.>&2 & exit /b 1
set qdir=%~f1

pushd "%~dp0"
set guid=
for /f "usebackq" %%i in (`powershell -NoProfile -Command "[Guid]::NewGuid().ToString('n')"`) do set guid=%%i
if not defined guid echo Error generating GUID>&2 & exit /b 1
set jobcmd_name=%~n0-%guid%
set jobcmd_temp_path=%TEMP%\%jobcmd_name%.cmd
call :gencmd %qdir% > %jobcmd_temp_path% ^
  && call qcmd %qdir% %jobcmd_temp_path% ^
  && del %jobcmd_temp_path% ^
  && echo Submitted %qdir%\%jobcmd_name%.cmd
goto :EOF

:gencmd
setlocal
echo @echo off
echo setlocal
echo chcp 1252 > nul
echo pushd "%~1"
echo for %%%%i in (*.log) do if not [%%%%~ni]==[%%~nx0] call :del %%%%i
echo goto :EOF
echo :del
echo setlocal
echo set log=%%1
echo echo dir "%%log:~0,-8%%*"
echo del "%%log:~0,-8%%*"
echo goto :EOF
