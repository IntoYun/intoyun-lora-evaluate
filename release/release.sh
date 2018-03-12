#! /bin/bash
# Author: chenkaiyao <chenkaiyao@molmc.com>

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

cecho "------------------------------------------------" $yellow
cecho "             请选择你要进行的操作               " $yellow
cecho "------------------------------------------------" $yellow
cecho "1. 生成产品软件包                               " $yellow
cecho "2. 上传产品软件包                               " $yellow
cecho "3. 进入生产平台                                 " $yellow
cecho "其他 退出                                       " $yellow
read type

case $type in
    1 ) # 生成产品软件包
        ./release-product.sh
        ;;
    2 ) # 上传产品软件包
        ./release-package.sh
        ;;
    3 ) # 进入平台 var/www/downloads/terminal/modules/package
        ssh prod-yun
        ;;
    * )
        exit 0
        ;;
esac

exit 0

