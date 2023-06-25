@ECHO OFF
@SETLOCAL enabledelayedexpansion

ECHO  SVP Issue Stress Test Script v0.31

adb devices -l | find "device product:" >nul
IF !errorlevel! NEQ 0 (
        ECHO Waiting for a good adb USB connection...
        ECHO 
)

ECHO Get adb version info:
adb version

SET test_count=0
SET MAINBODY=mainbody.txt

blat3224\full\blat -install smtp.163.com motodev001@163.com
CALL :do_svp_test

:: ------------------------------------------------------------------------
:: Functions start here
:: ------------------------------------------------------------------------

:do_svp_test

:loop
set /A test_count=%test_count%+1
ECHO now start the %test_count%th test........

rmdir /s /q temp

adb shell input keyevent 82
timeout /t 1 /NOBREAK
adb shell input keyevent 82
timeout /t 1 /NOBREAK

ECHO Please wait...Do not exit...
adb shell am start -n com.google.android.exoplayer2.demo/com.google.android.exoplayer2.demo.SampleChooserActivity
timeout /t 15 /NOBREAK
adb shell input tap 300 500
timeout /t 2 /NOBREAK
adb shell input tap 300 1000
timeout /t 20 /NOBREAK

ECHO finished %test_count%th test......

adb bugreport 
mkdir temp
ECHO get log file name...
FOR /F "usebackq tokens=1" %%X in (`dir /b ^|findstr bugreport*.*`) do (
        IF NOT "%%X" == "" (
            set LOGFILE=%%X           
        )         
)
ECHO log file name: %LOGFILE%
copy !LOGFILE! .\temp

cd temp
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
rmdir /s /q temp

ECHO Now rebooting...
adb reboot
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
ECHO This mail is automatically generated by  Stress Test Script.>%MAINBODY%
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
ECHO Script Version:0.31 >>%MAINBODY%

ECHO *>>%MAINBODY%
ECHO Best Regards! >>%MAINBODY%


EXIT /b 0