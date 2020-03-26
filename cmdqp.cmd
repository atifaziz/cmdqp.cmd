@echo off
setlocal
chcp 1252 > nul
pushd "%~dp0"
set this_name=%~n0
set dirq=dir /od /a-d
if "%1"=="" echo Missing command specification. >&2 & exit /b 1
set cmd=%1
shift /1
call :$%cmd% 2>nul
if errorlevel 1 call :badcmd %0 & exit /b %errorlevel%

:do_parse_options
if "%1"=="" goto end_parse_options
set arg=%1
if not "%arg:~0,2%"=="--" goto end_parse_options
if "%arg:~2%"=="" goto end_parse_options
set arg=%arg:~2%
set arg=%arg:-=_%
set isbool=0
set value=%2
if "%value%"=="" set isbool=1
if %isbool%==0 if "%value:~0,2%"=="--" set isbool=1
if %isbool%==1 (
  set %arg%=1
  shift /1
) else (
  set %arg%=%value%
  shift /1
  shift /1
)
goto do_parse_options
:end_parse_options

if not defined qdir set qdir=%~dpn0.q
if not defined qerrordir set qerrordir=-

call :%cmd% %0 %1 %2 %3 %4 %5 %6 %7 %8 %9
goto :EOF

:badcmd
setlocal
echo Invalid command. For help, try: %1 help >&2
exit /b 1

:msg
setlocal
set errlvl=%errorlevel%
if defined msgcmd call %msgcmd% cmdqp %1
exit /b %errlvl%

:init
setlocal
if not exist "%qdir%" md "%qdir%"
if "%qerrordir%" neq "-" if not exist %qerrordir% md %qerrordir%
goto :EOF

:$dir
:$ls
:$list
goto :EOF
:dir
:ls
:list
setlocal
if exist "%qdir%" %dirq% "%qdir%\*.cmd"
exit /b 0

:$logs
goto :EOF
:logs
setlocal
if exist "%qdir%" %dirq% "%qdir%\*.log"
exit /b 0

:$daemon
goto :EOF
:daemon
setlocal
shift
start "Command Queue Daemon" cmd /t:1f /v /e /k %~n0 run --mode forever
exit /b 0

:$run
goto :EOF
:run
setlocal
if not defined sleep_seconds set sleep_seconds=15
shift && shift
call :init
if errorlevel 1 exit /b %errorlevel%
pushd "%qdir%"
echo Queue is %qdir%
:runloop
set count=0
set errorcount=0
set start_time=%time%
set lasterror=lasterror.log
if exist "%this_name%.halt.txt" type "%this_name%.halt.txt" & exit /b 2
for /f %%c in ('%dirq% /b *.cmd 2^>nul') do (
    if exist "%this_name%.halt.txt" type "%this_name%.halt.txt" & exit /b 2
    if exist "%this_name%.pause.txt" type "%this_name%.pause.txt" & timeout %sleep_seconds% & goto :runloop
    call :do "%%c" || goto :error
    set /a count+=1
)
if exist %lasterror% del %lasterror%
echo %count% command(s) executed
if %errorcount% gtr 0 echo %errorcount% command(s) failed
if %count% gtr 0 (call :msg %~n0 "%count% command(s) executed. Started at %start_time% and ended at %time%.")
if "%mode%" neq "forever" exit /b 0
if %count%==0 (timeout %sleep_seconds%) else (if %errorcount% gtr 0 timeout %sleep_seconds%)
goto :runloop

:error
type "%lasterror%"
echo INTERNAL ERROR & exit /b 1

:do
setlocal
echo Running %~1
set retry=0
if not defined max_lock_retries set max_lock_retries=10
if not defined lock_retry_seconds set lock_retry_seconds=2
:do_retry
set /a retry+=1
if exist "%~1.lock" goto :do_locked
:: Following line will append nothing to the file but if it is open by
:: another process then it will fail and assume to be locked.
:: Credit: https://stackoverflow.com/a/10520609/6682
(>>%1 echo off) || goto :do_locked
echo %~1 > "%~1.log"
echo ------------------------- >> "%~1.log"
type %1 >> "%~1.log"
echo ------------------------- >> "%~1.log"
call %1 >> "%~1.log"
if %errorlevel%==0 (
    ren %1 "%~1.bak" 2>nul
    del "%~1.errors.log" 2>nul
) else (
    set /a errorcount+=1
    type "%~1.log" > "%lasterror%"
    if not defined continue_on_error exit /b 1
)
exit /b 0
:do_locked
echo ...might be locked so will retry in %lock_retry_seconds% seconds! [attempt #%retry%/%max_lock_retries%]
if %retry%==10 exit /b 1
timeout %lock_retry_seconds%
goto :do_retry

:$pause
goto :EOF
:pause
setlocal
call :init || exit /b 1
if not defined message set "message=Paused by %username% on %date%, at %time%."
echo %message%>> "%qdir%\%this_name%.pause.txt"
exit /b 0

:$unpause
goto :EOF
:unpause
setlocal
set pause_file_path=%qdir%\%this_name%.pause.txt
if exist "%pause_file_path%" del "%pause_file_path%"
exit /b 0

:$halt
goto :EOF
:halt
setlocal
call :init || exit /b 1
if not defined message set "message=Halted by %username% on %date%, at %time%."
set halt_file_path=%qdir%\%this_name%.halt.txt
echo %message%>> "%qdir%\%halt_file_path%.pause.txt"
exit /b 0

:$help
goto :EOF
:help
setlocal
echo Runs command scripts in sequence on a FIFO basis.
echo.
echo Usage:
echo     %~n0 help       displays this help
echo     %~n0 run        run queued tasks once
echo     %~n0 daemon     run queued tasks forever
echo     %~n0 list       list the command files of the queue
echo     %~n0 logs       list the logs
echo     %~n0 pause      pause before next task (until unpaused)
echo     %~n0 unpause    unpause
echo     %~n0 halt       finish current task (if any) then stop
exit /b 0
