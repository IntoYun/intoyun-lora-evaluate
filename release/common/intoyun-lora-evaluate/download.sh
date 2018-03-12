#! /bin/bash

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
    #下载工具
    UPLOAD_RESET_TOOL=./tools/upload-reset/osx/upload-reset
    ST_TOOL=./tools/stlink/osx/st-flash
    DFU_TOOL=./tools/dfu-util/osx/dfu-util
    DFUSUFFIX=./tools/dfu-util/osx/dfu-suffix
    SUDO=
    #下载参数
    UPLOAD_PORT=/dev/cu.usbmodem1411
else    #linux
    #下载工具
    UPLOAD_RESET_TOOL=./tools/upload-reset/linux64/upload-reset
    ST_TOOL=./tools/stlink/linux64/st-flash
    DFU_TOOL=./tools/dfu-util/linux64/dfu-util
    DFUSUFFIX=./tools/dfu-util/linux64/dfu-suffix
    SUDO=sudo
    #下载参数
    UPLOAD_PORT=/dev/ttyACM0
fi

cecho "------------GL2000软件下载--------------" $yellow
cecho "-->请选择下载内容(回车默认选择1):       " $yellow
cecho "1. 应用程序下载(DFU升级)                " $yellow
cecho "2. 完整包下载(st-link升级)              " $yellow

read select_type

case "$select_type" in
    1)
        if [ $sysType = "Darwin" ]; then    # osx
            cecho "-->请输入串口(回车默认输入/dev/cu.usbmodem1411): " $yellow
        else
            cecho "-->请输入串口(回车默认输入/dev/ttyACM0): " $yellow
        fi
        read usart_port
        if [ "$usart_port" != "" ];then
            UPLOAD_PORT=$usart_port
        fi
        cp firmware.bin firmware.dfu
        $DFUSUFFIX -v 0483 -p df11 -a firmware.dfu &>/dev/null
        cecho "下载应用程序 ... \c" $green
        $UPLOAD_RESET_TOOL -p $UPLOAD_PORT -b 19200 -t 2000 &>/dev/null
        $SUDO $DFU_TOOL -d 0x0483:0xdf11 -a 0 -R -s 0x08020000:leave -D firmware.dfu &>/dev/null
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
        $SUDO $ST_TOOL write boot.bin 0x8000000 &>/dev/null
        if [ $? = 0 ]; then
            cecho "成功" $yellow
            sleep 1
            cecho "下载应用程序   ... \c" $green
            $SUDO $ST_TOOL --reset write firmware.bin 0x08020000 &>/dev/null
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

