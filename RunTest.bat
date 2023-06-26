@ECHO OFF
@SETLOCAL enabledelayedexpansion

ECHO SVP Issue Stress Test Script v0.4.0

adb devices -l | find "device product:" >nul
IF !errorlevel! NEQ 0 (
        ECHO Waiting for a good adb USB connection...
        ECHO 
)

ECHO Get adb version info:
adb version



:: ------------------------------------------------------------------------
:: Query and select device
:: ------------------------------------------------------------------------
SET /a index=0
for /f "delims= " %%a in ('adb devices -l ^| find "device product:"') do (
    ECHO !index! %%~a
    SET DEVICE_LIST[!index!]=%%~a
    SET /a index+=1
)

Set /p var=Please select the device:
ECHO The device you selected is: %var%

SET DEVICE_ID=!DEVICE_LIST[%var%]!
ECHO device id is: %DEVICE_ID%

if "%DEVICE_ID%" == "" (
    ECHO ERROR:Invalid device ID, stop.
    goto :error
)

start /min cmd /c logging.bat %DEVICE_ID%
:: ------------------------------------------------------------------------
:: Initialize
:: ------------------------------------------------------------------------
SET TEMP_FOLDER=%DEVICE_ID%
SET ADB=adb -s %DEVICE_ID%
SET test_count=0
SET MAINBODY=mainbody.txt

blat3224\full\blat -install smtp.163.com motodev001@163.com
CALL :do_svp_test

:: ------------------------------------------------------------------------
:: Test starts here
:: ------------------------------------------------------------------------

:do_svp_test

:loop
set /A test_count=%test_count%+1
ECHO now start the %test_count%th test........

if exist %TEMP_FOLDER% (
    ECHO remove temp
    rmdir /s /q %TEMP_FOLDER%
)

%ADB% shell  input keyevent 82
timeout /t 1 /NOBREAK
%ADB% shell input keyevent 82
timeout /t 1 /NOBREAK

ECHO Please wait...Do not exit...
%ADB% shell am start -n com.google.android.exoplayer2.demo/com.google.android.exoplayer2.demo.SampleChooserActivity
timeout /t 15 /NOBREAK
%ADB% shell input tap 300 500
timeout /t 2 /NOBREAK
%ADB% shell input tap 300 1300
timeout /t 10 /NOBREAK
%ADB% shell settings put system user_rotation 1
timeout /t 50 /NOBREAK
%ADB% shell settings put system user_rotation 0
timeout /t 50 /NOBREAK

ECHO finished %test_count%th test......

%ADB% bugreport 
mkdir %TEMP_FOLDER%
ECHO get log file name...
FOR /F "usebackq tokens=1" %%X in (`dir /b ^|findstr bugreport*.*`) do (
        IF NOT "%%X" == "" (
            set LOGFILE=%%X           
        )         
)
ECHO log file name: %LOGFILE%
copy !LOGFILE! .\%TEMP_FOLDER%

cd %TEMP_FOLDER%
tar -xf !LOGFILE!
FOR /F "delims=$" %%i in (../keywords.txt) do (
    set KEYWORD=%%i
    ECHO Trying keyword !KEYWORD!
    FOR /F "usebackq tokens=1" %%X in (`findstr /s /i /c:"!KEYWORD!" *.txt`) do (
        IF NOT "%%X" == "" (
            ECHO ISSUE FOUND!!! with keyword: !KEYWORD!
            cd ..
            GOTO :found
        ) 
     )
)
ECHO Remove old logs
cd ..
rmdir /s /q %TEMP_FOLDER%

ECHO force-stop

%ADB% shell am force-stop com.google.android.exoplayer2.demo

ECHO Please wait 180s...Do not exit...
timeout /t 180 /NOBREAK

GOTO :loop

:found
CALL :send_mail

PAUSE

EXIT

:: ------------------------------------------------------------------------
:: Send E-Mail to addresses in recipient.txt
:: With log as attachment
:: ------------------------------------------------------------------------
:send_mail

CALL :write_mainbody
FOR /F  %%i in (recipient.txt) do (
    blat3224\full\blat %MAINBODY% ^
        -to %%i ^
        -u motodev001@163.com ^
        -pw XEJAFNZGUHRWHVJT ^
        -subject "Motorola Stress Test Report: SVP Issue  Reproduced!" ^
        -attach %LOGFILE%
)

EXIT /b 0

:: ------------------------------------------------------------------------
:: Write main body for the mail
:: ------------------------------------------------------------------------
:write_mainbody
ECHO This mail is automatically generated by SVP Stress Test Script.>%MAINBODY%
ECHO Do not reply.>>%MAINBODY%
ECHO ******************************************************************************************* >>%MAINBODY%
ECHO Issue Description: >>%MAINBODY%
FOR /F "delims=$" %%i in (issuedescript.txt) do (
    ECHO %%i >>%MAINBODY%
)
ECHO Keyword hit: "!KEYWORD!" >>%MAINBODY%
ECHO In %test_count%th reproduce trials. >>%MAINBODY%
ECHO Please view the log as attached. >>%MAINBODY%
ECHO *******************************************************************************************>>%MAINBODY%
ECHO *>>%MAINBODY%
ECHO Script Version:v0.4.0 >>%MAINBODY%
ECHO Any suggestion? Please contact caobo3@motorola.com for details. >>%MAINBODY%
ECHO *>>%MAINBODY%
ECHO Best Regards! >>%MAINBODY%

EXIT /b 0

:error

PAUSE