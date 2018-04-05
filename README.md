# intoyun-lora-evaluate

## 1. 概述

该项目是LoRa性能评估工程，用户可以通过按键调整测试参数测试不同带宽和扩频因子参数下的SNR和RSSI值，
发送和接收到的包数量，丢失包的数量，丢包率、数据速率以及距离。

## 2. 工程结构

工程结构如下：

```
|-- lib             : 工程依赖库
|-- release         : 编译和发布脚本
|-- src             : 工程代码
|-- intoyuniot.ini  : 编译配置文件
 -- README.md
```

## 3. 编译与调试

工程采取intoyuniot编译，具体如下：

```
intoyuniot run -e intoyun-lora-evaluate-tx -t clean   # 清除发送端程序临时文件
intoyuniot run -e intoyun-lora-evaluate-rx -t clean   # 清除接收端程序临时文件

intoyuniot run -e intoyun-lora-evaluate-tx -t upload  # 编译和下载发送端程序
intoyuniot run -e intoyun-lora-evaluate-rx -t upload  # 编译和下载接收端程序

```

## 4. 发布

进入release, 运行./release.sh

```
1. 生成产品软件包
2. 上传产品软件包
3. 进入生产平台

```


