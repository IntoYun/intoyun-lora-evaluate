#! /bin/bash

# Color-echo.
# arg $1 = message
# arg $2 = Color
cecho() {
  echo -e "${2}${1}"
  tput sgr0
  # Reset # Reset to normal.
  return
}
# Set the colours you can use
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'

SYSTESM_TYPE=`uname -s`
PROJECT_ROOT=$(cd "$(dirname "$0")"; pwd)

if [ $SYSTESM_TYPE = "Linux" ]; then
UPLOAD_PORT=/dev/ttyACM0
DFU=$PROJECT_ROOT/tools/dfu-util/linux64/dfu-util
DFUSUFFIX=$PROJECT_ROOT/tools/dfu-util/linux64/dfu-suffix
UPLOAD_RESET=$PROJECT_ROOT/tools/upload-reset/linux64/upload-reset
ST_TOOL=./tools/stlink/linux64/st-flash
SUDO=sudo
else
UPLOAD_PORT=/dev/cu.usbmodem1411
DFU=$PROJECT_ROOT/tools/dfu-util/osx/dfu-util
DFUSUFFIX=$PROJECT_ROOT/tools/dfu-util/osx/dfu-suffix
UPLOAD_RESET=$PROJECT_ROOT/tools/upload-reset/osx/upload-reset
ST_TOOL=$PROJECT_ROOT/tools/stlink/osx/st-flash
SUDO=
fi

START_DFU_FLASHER_SERIAL_SPEED=19200
USBD_VID_INTOROBOT=0x0483
USBD_PID_DFU=0xdf11
PLATFORM_APP_ADDR=0x08006000

cecho "------------intoyun-lora-evaluate软件下载--------------" $yellow
cecho "-->请选择下载内容(回车默认选择1):       " $yellow
cecho "1. 应用程序下载(DFU升级)                " $yellow
cecho "2. 完整包下载(st-link升级)              " $yellow
cecho "其他退出                                " $yellow

read select_type

case "$select_type" in
    1)
cecho "请选择要烧录的程序" $yellow
cecho "1. TX"  $yellow
cecho "2. RX"  $yellow
cecho "其他退出          " $yellow
read type

cecho "开始下载..." $yellow

if [ $SYSTESM_TYPE = "Linux" ]; then
    cecho "-->请输入串口(回车默认输入/dev/ttyACM0): " $yellow
else
    cecho "-->请输入串口(回车默认输入/dev/cu.usbmodem1411): " $yellow
fi
    read usart_port
    if [ "$usart_port" != "" ];then
        UPLOAD_PORT=$usart_port
    fi

case $type in
    1)
    cp intoyun-lora-evaluate-tx.bin intoyun-lora-evaluate-tx.dfu
    $UPLOAD_RESET -p $UPLOAD_PORT -b $START_DFU_FLASHER_SERIAL_SPEED -t 2000
    $DFU -d $USBD_VID_INTOROBOT:$USBD_PID_DFU -a 0 -R -s $PLATFORM_APP_ADDR:leave -D intoyun-lora-evaluate-tx.dfu
        ;;
    2)
    cp intoyun-lora-evaluate-rx.bin intoyun-lora-evaluate-rx.dfu
    $UPLOAD_RESET -p $UPLOAD_PORT -b $START_DFU_FLASHER_SERIAL_SPEED -t 2000
    $DFU -d $USBD_VID_INTOROBOT:$USBD_PID_DFU -a 0 -R -s $PLATFORM_APP_ADDR:leave -D intoyun-lora-evaluate-rx.dfu
        ;;
    *)
        exit 0
        ;;
esac;;

    2)
cecho "请选择要下载的程序类型，输入数字后回车" $yellow
cecho "1. TX(发射)"  $yellow
cecho "2. RX(接收)"  $yellow
cecho "其他退出   "  $yellow
read type

cecho "开始下载..." $yellow

case $type in
    1)
    $SUDO $ST_TOOL write boot-v1.bin 0x8000000
    $SUDO $ST_TOOL --reset write intoyun-lora-evaluate-tx.bin 0x08006000
        ;;
    2)
    $SUDO $ST_TOOL write ant-boot.bin 0x8000000
    $SUDO $ST_TOOL --reset write intoyun-lora-evaluate-rx.bin 0x08006000
        ;;
    *)
        exit 0
        ;;
esac;;

    *)
        exit 0
        ;;
esac


if [ $? = 0 ]; then
    cecho "-------下载成功------" $green
else
    cecho "-------下载失败------" $red
fi

exit 0

