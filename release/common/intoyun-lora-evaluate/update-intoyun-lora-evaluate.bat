@echo off
::���ع���
set ST_TOOL=tools/stlink/win/st-flash.exe
set UPLOAD_RESET_TOOL=tools/upload-reset/win/upload-reset.exe
set DFU_TOOL=tools/dfu-util/win/dfu-util.exe
set DFUSUFFIX=tools/dfu-util/win/dfu-suffix.exe
set UPLOAD_PORT=COM1

:start

echo -------intoyun-lora-evaluate�������--------
echo ��ѡ����������(�س�Ĭ��ѡ��1):
echo 1. Ӧ�ó�������(DFU����)
echo 2. ����������(st-link����)

set select_type=1
set /p select_type=
if %select_type%==1 (
goto app_update
)
goto all_update_start

:app_update
echo ��ѡ��Ҫ���صĳ������ͣ��������ֺ�س�
echo 1. TX(����)
echo 2. RX(����)
@set select_type=1
set /p select_type=

set usart_port=%UPLOAD_PORT%
set /p usart_port=�����봮�ں�س�(�س�Ĭ������COM1)�����ֶ��ð��ӽ���DFUģʽ��س�:
set UPLOAD_PORT=%usart_port%

if %select_type%==2 (
goto rx_dfu_update
)
goto tx_dfu_update

:tx_dfu_update

copy intoyun-lora-evaluate-tx.bin intoyun-lora-evaluate-tx.dfu >nul 2>nul
set /p=����Ӧ�ó���   ... <nul
"%UPLOAD_RESET_TOOL%" -p %UPLOAD_PORT% -b 19200 -t 2000 >nul 2>nul
"%DFU_TOOL%" -d 0x0483:0xdf11 -a 0 -R -s 0x08006000:leave -D intoyun-lora-evaluate-tx.dfu >nul 2>nul
goto update_end

:rx_dfu_update

copy intoyun-lora-evaluate-rx.bin intoyun-lora-evaluate-rx.dfu >nul 2>nul
set /p=����Ӧ�ó���   ... <nul
"%UPLOAD_RESET_TOOL%" -p %UPLOAD_PORT% -b 19200 -t 2000 >nul 2>nul
"%DFU_TOOL%" -d 0x0483:0xdf11 -a 0 -R -s 0x08006000:leave -D intoyun-lora-evaluate-rx.dfu >nul 2>nul
goto update_end

:all_update_start
echo ��ѡ��Ҫ���صĳ������ͣ��������ֺ�س�(��ȷ������ST-LINK)
echo 1. TX(����)
echo 2. RX(����)

@set select_type=1
set /p select_type=

if %select_type%==2 (
goto rx_update
)
goto tx_update

:tx_update
echo ��ʼ����...
echo %ST_TOOL%
"%ST_TOOL%" write boot-v1.bin 0x8000000
"%ST_TOOL%" --reset write intoyun-lora-evaluate-tx.bin 0x08006000

goto update_end

:rx_update
echo ��ʼ����...
echo %ST_TOOL%
"%ST_TOOL%" write boot-v1.bin 0x8000000
"%ST_TOOL%" --reset write intoyun-lora-evaluate-rx.bin 0x08006000

:update_end

if %errorlevel% == 0 (
    echo -------���سɹ�------
) else (
    echo -------����ʧ��------
)

pause
