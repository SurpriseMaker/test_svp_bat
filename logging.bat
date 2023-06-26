@ECHO OFF
@SETLOCAL enabledelayedexpansion

ECHO Config Trace


SET DEVICE_ID=%1
SET LOG_VERSION_STR=svp trace log v0.1
SET LOG_FOLDER=logs
SET DEVICE_LOG_FOLDER=%DEVICE_ID%
SET LOG_PATH=.\%LOG_FOLDER%\%DEVICE_LOG_FOLDER%\svp_log.txt
SET ADB=adb -s %DEVICE_ID%

CALL :start_logging

:: ------------------------------------------------------------------------
:: Functions start here
:: ------------------------------------------------------------------------

:start_logging
rem set value
%ADB% root
ECHO default values are configured in test build.

if not exist %LOG_FOLDER% (
    ECHO generate %LOG_FOLDER% folder
    mkdir  %LOG_FOLDER%
)

if exist .\%LOG_FOLDER%\%DEVICE_LOG_FOLDER% (
    ECHO remove .\%LOG_FOLDER%\%DEVICE_LOG_FOLDER% folder
    rmdir /s /q .\%LOG_FOLDER%\%DEVICE_LOG_FOLDER%
)
ECHO generate .\%LOG_FOLDER%\%DEVICE_LOG_FOLDER% folder
mkdir .\%LOG_FOLDER%\%DEVICE_LOG_FOLDER%

ECHO get config values
ECHO %LOG_VERSION_STR% 
ECHO %LOG_VERSION_STR% > %LOG_PATH%
ECHO "page_ref/enable:" >> %LOG_PATH%
%ADB% shell cat /sys/kernel/tracing/instances/testsvp/events/page_ref/enable >> %LOG_PATH%
ECHO "buffer_size_kb:" >> %LOG_PATH%
%ADB% shell cat /sys/kernel/tracing/instances/testsvp/buffer_size_kb >> %LOG_PATH%

ECHO catching trace_pipe, pending..... the log is in %LOG_PATH%
%ADB% shell cat /sys/kernel/tracing/instances/testsvp/trace_pipe >> %LOG_PATH%

CALL :pull_dump

%ADB% pull /data/vendor/aplogd .\%LOG_FOLDER%\%DEVICE_LOG_FOLDER%

ECHO logging is done.
ECHO Please provide the zipped %LOG_FOLDER% folder
PAUSE

EXIT


:pull_dump
ECHO Please wait dumping finished...
timeout /t 600 /NOBREAK
mkdir %LOG_FOLDER%
%ADB% root
%ADB% pull /data/vendor/aee_exp/db.fatal.00.KE .\%LOG_FOLDER%\%DEVICE_LOG_FOLDER% >> %LOG_PATH%
ECHO dumping OK
EXIT /b 0