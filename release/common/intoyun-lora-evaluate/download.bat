@echo off
::���ع���
set ST_TOOL=tools/stlink/win/st-flash.exe
set UPLOAD_RESET_TOOL=tools/upload-reset/win/upload-reset.exe
set DFU_TOOL=tools/dfu-util/win/dfu-util.exe
set DFUSUFFIX=tools/dfu-util/win/dfu-suffix.exe

::���ز���
set UPLOAD_PORT=COM1

:start

echo -------GL2000�������--------
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

set usart_port=%UPLOAD_PORT%
set /p usart_port=�����봮��(�س�Ĭ������COM1):
set UPLOAD_PORT=%usart_port%

copy firmware.bin firmware.dfu >nul 2>nul
"%DFUSUFFIX%" -v 0483 -p df11 -a firmware.dfu >nul 2>nul
set /p=����Ӧ�ó���   ... <nul
"%UPLOAD_RESET_TOOL%" -p %UPLOAD_PORT% -b 19200 -t 2000 >nul 2>nul
"%DFU_TOOL%" -d 0x0483:0xdf11 -a 0 -R -s 0x08020000:leave -D firmware.dfu >nul 2>nul
if %errorlevel%==0 (
echo �ɹ�
) else (
echo ʧ��
)
goto update_end

:all_update_start

set /p=����Bootloader ... <nul
"%ST_TOOL%" write boot.bin 0x8000000 >nul 2>nul
if %errorlevel%==0 (
echo �ɹ�
) else (
echo ʧ��
goto update_end
)

set /p=����Ӧ�ó���   ... <nul
:: ��ʱ1s
choice /t 1 /d y /n >nul
"%ST_TOOL%" --reset write firmware.bin 0x08020000 >nul 2>nul
if %errorlevel%==0 (
echo �ɹ�
) else (
echo ʧ��
goto update_end
)

:update_end

if errorlevel 0 (
    echo -------���سɹ�------
) else (
    echo -------����ʧ��------
)

pause

