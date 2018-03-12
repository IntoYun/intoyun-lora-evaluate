#! /bin/bash
# Author: chenkaiyao <chenkaiyao@molmc.com>
source ./release-version.sh

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

RELEASE_DIR=$(cd "$(dirname "$0")"; pwd)
RELEASE_PRODUCT_DIR=$RELEASE_DIR/package

# $1:产品名称 $2:产品软件版本号
release_package() {
    RELEASE_PRODUCT_ITEM_DIR=$RELEASE_PRODUCT_DIR/$1
    RELEASE_PRODUCT_VERSION_DIR=$RELEASE_PRODUCT_ITEM_DIR/$1-$2
    SERVER_HOST=prod-yun

    cd $RELEASE_PRODUCT_ITEM_DIR
    tar -czf $1-$2.tar.gz $1-$2
    scp $1-$2.tar.gz $SERVER_HOST:/var/www/downloads/terminal/modules/package/$1
}

cecho "开始上传服务器!!!" $green

release_package intoyun-lora-evaluate $PRODUCT_VERSION_STRING

cecho "发布完成!!!" $green

exit 0

