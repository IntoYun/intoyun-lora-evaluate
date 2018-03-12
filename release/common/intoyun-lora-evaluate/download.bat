@echo off
::下载工具
set ST_TOOL=tools/stlink/win/st-flash.exe
set UPLOAD_RESET_TOOL=tools/upload-reset/win/upload-reset.exe
set DFU_TOOL=tools/dfu-util/win/dfu-util.exe
set DFUSUFFIX=tools/dfu-util/win/dfu-suffix.exe

::下载参数
set UPLOAD_PORT=COM1

:start

echo -------GL2000软件下载--------
echo 请选择下载内容(回车默认选择1):
echo 1. 应用程序下载(DFU升级)
echo 2. 完整包下载(st-link升级)

set select_type=1
set /p select_type=
if %select_type%==1 (
goto app_update
)
goto all_update_start

:app_update

set usart_port=%UPLOAD_PORT%
set /p usart_port=请输入串口(回车默认输入COM1):
set UPLOAD_PORT=%usart_port%

copy firmware.bin firmware.dfu >nul 2>nul
"%DFUSUFFIX%" -v 0483 -p df11 -a firmware.dfu >nul 2>nul
set /p=下载应用程序   ... <nul
"%UPLOAD_RESET_TOOL%" -p %UPLOAD_PORT% -b 19200 -t 2000 >nul 2>nul
"%DFU_TOOL%" -d 0x0483:0xdf11 -a 0 -R -s 0x08020000:leave -D firmware.dfu >nul 2>nul
if %errorlevel%==0 (
echo 成功
) else (
echo 失败
)
goto update_end

:all_update_start

set /p=下载Bootloader ... <nul
"%ST_TOOL%" write boot.bin 0x8000000 >nul 2>nul
if %errorlevel%==0 (
echo 成功
) else (
echo 失败
goto update_end
)

set /p=下载应用程序   ... <nul
:: 延时1s
choice /t 1 /d y /n >nul
"%ST_TOOL%" --reset write firmware.bin 0x08020000 >nul 2>nul
if %errorlevel%==0 (
echo 成功
) else (
echo 失败
goto update_end
)

:update_end

if errorlevel 0 (
    echo -------下载成功------
) else (
    echo -------下载失败------
)

pause

