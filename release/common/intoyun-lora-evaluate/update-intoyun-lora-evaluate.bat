@echo off
::���ع���
set ST_TOOL=tools/stlink/win/st-flash.exe
set UPLOAD_RESET_TOOL=tools/upload-reset/win/upload-reset.exe
set DFU_TOOL=tools/dfu-util/win/dfu-util.exe
set DFUSUFFIX_TOOL=tools/dfu-util/win/dfu-suffix.exe

::���ز���
set UPLOAD_PORT=COM1

:start

echo -------intoyun-lora-evaluate�������--------
echo ��ѡ����������
echo 1. Ӧ�ó�������(DFU����)
echo 2. ����������(st-link����)
set select_type=0
set /p select_type=

if %select_type%==1 (
goto app_select
) else (
if %select_type%==2 (
goto app_select
) else (
exit
))

:app_select
echo ��ѡ��Ҫ��¼�ĳ���
echo 1. ���Ͷ�
echo 2. ���ն�
@set select_txrx=0
set /p select_txrx=

if %select_txrx%==1 (
set file_bin=firmware-tx.bin
set file_dfu=firmware-tx.dfu
) else (
if %select_txrx%==2 (
set file_bin=firmware-rx.bin
set file_dfu=firmware-rx.dfu
) else (
exit
))

if %select_type%==1 (
goto app_update_start
) else (
goto all_update_start
)

:app_update_start

set usart_port=%UPLOAD_PORT%
set /p usart_port=�����봮��(�س�Ĭ������COM1) ���� �ֶ��ð��ӽ���DFUģʽ:
set UPLOAD_PORT=%usart_port%

copy %file_bin% %file_dfu% >nul 2>nul
"%DFUSUFFIX_TOOL%" -v 0483 -p df11 -a %file_dfu% >nul 2>nul
set /p=����Ӧ�ó���   ... <nul
"%UPLOAD_RESET_TOOL%" -p %UPLOAD_PORT% -b 19200 -t 2000 >nul 2>nul
"%DFU_TOOL%" -d 0x0483:0xdf11 -a 0 -R -s 0x08006000:leave -D %file_dfu%
if %errorlevel%==0 (
echo �ɹ�
) else (
echo ʧ��
)
goto update_end

:all_update_start

set /p=����Bootloader ... <nul
"%ST_TOOL%" write boot-v2.bin 0x8000000
if %errorlevel%==0 (
echo �ɹ�
) else (
echo ʧ��
goto update_end
)

set /p=����Ӧ�ó���   ... <nul
:: ��ʱ1s
choice /t 1 /d y /n >nul
"%ST_TOOL%" --reset write %file_bin% 0x08006000
if %errorlevel%==0 (
echo �ɹ�
) else (
echo ʧ��
goto update_end
)

:update_end

if %errorlevel% == 0 (
    echo -------���سɹ�------
) else (
    echo -------����ʧ��------
)

pause
