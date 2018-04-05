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

#下载工具
sysType=`uname -s`
cecho "----您的系统是 $sysType ------" $green
if [ $sysType = "Darwin" ]; then    # osx
    UPLOAD_RESET_TOOL=./tools/upload-reset/osx/upload-reset
    ST_TOOL=./tools/stlink/osx/st-flash
    DFU_TOOL=./tools/dfu-util/osx/dfu-util
    DFUSUFFIX_TOOL=./tools/dfu-util/osx/dfu-suffix
    SUDO=
    #下载参数
    UPLOAD_PORT=/dev/cu.usbmodem14241
else
    #下载工具
    UPLOAD_RESET_TOOL=./tools/upload-reset/linux64/upload-reset
    ST_TOOL=./tools/stlink/linux64/st-flash
    DFU_TOOL=./tools/dfu-util/linux64/dfu-util
    DFUSUFFIX_TOOL=./tools/dfu-util/osx/dfu-suffix
    SUDO=sudo
    #下载参数
    UPLOAD_PORT=/dev/ttyACM0
fi

cecho "------------intoyun-lora-evaluate软件下载--------------" $yellow
cecho "-->请选择下载内容                       " $yellow
cecho "1. 应用程序下载(DFU升级)                " $yellow
cecho "2. 完整包下载(st-link升级)              " $yellow
cecho "其他退出                                " $yellow
read select_type

case "$select_type" in
    1|2)
        cecho "-->请选择要烧录的程序" $yellow
        cecho "1. 发送端         " $yellow
        cecho "2. 接收端         " $yellow
        cecho "其他退出          " $yellow
        read select_txrx
        if [ $select_txrx = "1" ]; then
            file_bin=firmware-tx.bin
            file_dfu=firmware-tx.dfu
        elif [ $select_txrx = "2" ]; then
            file_bin=firmware-rx.bin
            file_dfu=firmware-rx.dfu
        else
            exit 0
        fi
        ;;
    *)
        exit 0
        ;;
esac

case "$select_type" in
    1)
        if [ $sysType = "Darwin" ]; then    # osx
            cecho "-->请输入串口(回车默认输入/dev/cu.usbmodem1411) 或者 手动让板子进入DFU模式: " $yellow
        else
            cecho "-->请输入串口(回车默认输入/dev/ttyACM0) 或者 手动让板子进入DFU模式: " $yellow
        fi
        read usart_port
        if [ "$usart_port" != "" ];then
            UPLOAD_PORT=$usart_port
        fi
        cp $file_bin $file_dfu
        $DFUSUFFIX_TOOL -v 0483 -p df11 -a $file_dfu &>/dev/null
        cecho "下载应用程序 ... \c" $green
        $UPLOAD_RESET_TOOL -p $UPLOAD_PORT -b 19200 -t 2000 &>/dev/null
        $SUDO $DFU_TOOL -d 0x0483:0xdf11 -a 0 -R -s 0x08006000:leave -D $file_dfu &>/dev/null
        if [ $? = 0 ]; then
            result=0
            cecho "成功" $yellow
        else
            result=-1
            cecho "失败" $red
        fi
        ;;

    2)
        cecho "下载bootloader ... \c" $green
        $SUDO $ST_TOOL write boot-v1.bin 0x8000000 &>/dev/null
        if [ $? = 0 ]; then
            cecho "成功" $yellow
            sleep 1
            cecho "下载应用程序   ... \c" $green
            $SUDO $ST_TOOL --reset write $file_bin 0x08006000 &>/dev/null
            if [ $? = 0 ]; then
                result=0
                cecho "成功" $yellow
            else
                result=-1
                cecho "失败" $red
            fi
        else
            result=-1
            cecho "失败" $red
        fi
        ;;
    *)
        exit 0
        ;;
esac

if [ $result = 0 ]; then
    cecho "-------升级成功------" $yellow
else
    cecho "-------升级失败------" $red
fi

