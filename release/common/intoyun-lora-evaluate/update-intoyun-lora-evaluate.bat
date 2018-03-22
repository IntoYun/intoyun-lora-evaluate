@echo off
::下载工具
set ST_TOOL=tools/stlink/win/st-flash.exe
set UPLOAD_RESET_TOOL=tools/upload-reset/win/upload-reset.exe
set DFU_TOOL=tools/dfu-util/win/dfu-util.exe
set DFUSUFFIX=tools/dfu-util/win/dfu-suffix.exe
set UPLOAD_PORT=COM1

:start

echo -------intoyun-lora-evaluate软件下载--------
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
echo 请选择要下载的程序类型，输入数字后回车
echo 1. TX(发射)
echo 2. RX(接收)
@set select_type=1
set /p select_type=

set usart_port=%UPLOAD_PORT%
set /p usart_port=请输入串口后回车(回车默认输入COM1)或者手动让板子进入DFU模式后回车:
set UPLOAD_PORT=%usart_port%

if %select_type%==2 (
goto rx_dfu_update
)
goto tx_dfu_update

:tx_dfu_update

copy intoyun-lora-evaluate-tx.bin intoyun-lora-evaluate-tx.dfu >nul 2>nul
set /p=下载应用程序   ... <nul
"%UPLOAD_RESET_TOOL%" -p %UPLOAD_PORT% -b 19200 -t 2000 >nul 2>nul
"%DFU_TOOL%" -d 0x0483:0xdf11 -a 0 -R -s 0x08006000:leave -D intoyun-lora-evaluate-tx.dfu >nul 2>nul
goto update_end

:rx_dfu_update

copy intoyun-lora-evaluate-rx.bin intoyun-lora-evaluate-rx.dfu >nul 2>nul
set /p=下载应用程序   ... <nul
"%UPLOAD_RESET_TOOL%" -p %UPLOAD_PORT% -b 19200 -t 2000 >nul 2>nul
"%DFU_TOOL%" -d 0x0483:0xdf11 -a 0 -R -s 0x08006000:leave -D intoyun-lora-evaluate-rx.dfu >nul 2>nul
goto update_end

:all_update_start
echo 请选择要下载的程序类型，输入数字后回车(请确保连接ST-LINK)
echo 1. TX(发射)
echo 2. RX(接收)

@set select_type=1
set /p select_type=

if %select_type%==2 (
goto rx_update
)
goto tx_update

:tx_update
echo 开始下载...
echo %ST_TOOL%
"%ST_TOOL%" write boot-v1.bin 0x8000000
"%ST_TOOL%" --reset write intoyun-lora-evaluate-tx.bin 0x08006000

goto update_end

:rx_update
echo 开始下载...
echo %ST_TOOL%
"%ST_TOOL%" write boot-v1.bin 0x8000000
"%ST_TOOL%" --reset write intoyun-lora-evaluate-rx.bin 0x08006000

:update_end

if %errorlevel% == 0 (
    echo -------下载成功------
) else (
    echo -------下载失败------
)

pause
