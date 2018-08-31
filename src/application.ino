//lora 性能测试
#include "Adafruit_SSD1306.h"

PRODUCT_SOFTWARE_VERSION(1.2.0)

//#define SX1278_TX_EN
#define OLED_DISPLAY

#define DR_UP_KEY                       D3 //速率选择+键
#define DR_BACK_KEY                     D2 //速率选择-键
#define FEQ_UP_KEY                      A1 //频率选择+键
#define FEQ_BACK_KEY                    A0 //频率选择-键

#define KEY_EFFECT                      100
#define OLED_RESET                      A3
#define BUFFER_SIZE                     250 // Define the payload size here
#define LORA_PARAMS_NUMBER              28

#define BW125    0
#define BW250    1
#define BW500    2
#define BW62_5   3

bool resetKeyValid = false;
bool upKeyValid = false; //按键有效
bool backKeyValid = false;
bool feqUpKeyValid = false; //按键有效
bool feqBackKeyValid = false;
static uint8_t bufferSize = BUFFER_SIZE;
static bool ledFlag = false;
int8_t rssiValue = 0;
int8_t snrValue = 0;
uint32_t rfFreq = 0;        //频率
uint8_t spreadFactor = 0;   //扩频因子
uint16_t bandwidth = 0;     //带宽
uint32_t rxPacketCnt = 0;   //接收到的包数量
uint16_t txPacketCnt = 0;   //发送的包数量
uint16_t missPacketCnt = 0; //丢失的包数量
float per = 0;              //丢包率%
uint16_t dataRate = 0;      //速率
uint8_t paramsIndex = 0;    //查表用
uint32_t currentTime = 0;   //记录当前ms计数值

uint16_t keyDebounceTime;   //按键抖动时间
bool keyRelease = false;
static bool txDoneFlag = true;
static bool rxDoneFlag = false;
uint16_t lastPacketCnt = 0;    //上一次包序号
uint16_t currentPacketCnt = 0; //当前包序号
uint16_t realDataRate = 0;     //计算实际速率
uint32_t lastRxPackets = 0;    //记录上一次接收到的数据包数量
uint32_t lastMillis = 0;       //上一次ms计数值
static bool rxChangeParams = false; //接收参数已改变

uint8_t dataBuffer[BUFFER_SIZE] = {
    0,0,3,4,5,6,7,8,9,10,
    1,2,3,4,5,6,7,8,9,10,
};

typedef struct lora_params
{
    uint16_t bw;
    uint8_t sf;
    uint16_t dr;
    uint8_t size;
}lora_params_t;

const lora_params_t ParamsTable[] = {
    {125,12,250,20},
    {125,11,440,20},
    {125,10,980,64},
    {125,9,1760,64},
    {125,8,3125,64},
    {125,7,5470,200},
    {125,6,9375,200},

    {250,12,586,20},
    {250,11,1074,20},
    {250,10,1953,64},
    {250,9,3516,64},
    {250,8,6250,64},
    {250,7,10938,200},
    {250,6,18750,250},

    {500,12,1172,20},
    {500,11,2148,20},
    {500,10,3906,64},
    {500,9,7031,64},
    {500,8,12500,64},
    {500,7,21875,250},
    {500,6,37500,250},

    {625,12,146,20},
    {625,11,269,20},
    {625,10,488,64},
    {625,9,879,64},
    {625,8,1367,64},
    {625,7,2734,64},
    {625,6,4688,64},
};

const uint32_t g_FeqTable[] = {
    433000000,
    450000000,
    470000000,
    490000000,
    510000000
};

uint8_t feqIndex = 0;  //查表用
uint8_t feqMaxIndex = sizeof(g_FeqTable)/sizeof(uint32_t) - 1;

Adafruit_SSD1306 display(OLED_RESET);  // Hareware I2C

void getDR(void)
{
    for(uint8_t i=0;i<LORA_PARAMS_NUMBER;i++) {
        if(bandwidth == ParamsTable[i].bw) {
            if(spreadFactor == ParamsTable[i].sf) {
                dataRate = ParamsTable[i].dr;
                return;
            }
        }
    }
}

void getBW(void)
{
    switch(LoRa.radioGetBandwidth()) {
        case 0:
            bandwidth = 125;
            break;
        case 1:
            bandwidth = 250;
            break;
        case 2:
            bandwidth = 500;
            break;
        case 3:
            bandwidth = 625;
            break;
        default:
            break;
    }
}

void OLEDDisplay(const char *result)
{
    display.clearDisplay();
    display.setCursor(0,0);
    display.println(result);

    __disable_irq();
    display.display();
    __enable_irq();
}

void RFParameterDispaly(void)
{
    String p = "";
    char tmp[32] = {0};

#ifdef SX1278_TX_EN
    p = p+"LoRa Tx Mode";
#else
    p = p+"LoRa Rx Mode";
#endif

    sprintf(tmp,"(%d)", g_FeqTable[feqIndex]/1000);

    p = p + tmp + "\r\n";
    p = p +"\r\n";

    getDR();
    p = p+"DR";
    sprintf(tmp,"%d",paramsIndex+1);
    p = p+tmp;
    p = p+":";
    sprintf(tmp,"%d",dataRate);
    p = p+tmp;

    #ifndef SX1278_TX_EN
    p = p+"/";
    sprintf(tmp,"%d",realDataRate);
    p = p+tmp;
    #endif

    p = p+" bps";
    p = p+ "\r\n";

#ifdef SX1278_TX_EN
    p = p+ "\r\n";
#endif

    p = p+"SF:";
    sprintf(tmp,"%d",spreadFactor);
    p = p+tmp;
    if(spreadFactor > 9) {
        p = p+ "  ";
    } else {
        p = p+ "   ";
    }

    p = p+"BW:";
    if(bandwidth == 625) {
        sprintf(tmp,"%s","62.5");
    } else {
        sprintf(tmp,"%d",bandwidth);
    }
    p = p+tmp;
    p = p+"KHz";
    p = p+ "\r\n";

#ifdef SX1278_TX_EN
    p = p+ "\r\n";
#endif

#ifndef SX1278_TX_EN
    p = p+"SNR:";
    sprintf(tmp,"%d",snrValue);
    p = p+tmp;
    if(snrValue > 9) {
        p = p+ " ";
    } else {
        p = p+ "  ";
    }

    p = p + "RSSI:";
    sprintf(tmp,"%d",rssiValue);
    p = p+tmp;
    p = p+ "\r\n";
    p = p + "Packet Rx:";
    sprintf(tmp,"%d",rxPacketCnt);
    p = p+tmp;
    p = p+ "\r\n";

    p = p + "Packet Miss:";
    sprintf(tmp,"%d",missPacketCnt);
    p = p+tmp;
    p = p+ "\r\n";

    per = (float)(100*missPacketCnt)/(float)(missPacketCnt+rxPacketCnt);
    p = p + "PER:";
    p = p+String(per,2);
    p = p+"%";
    p = p+ "\r\n";
#endif

#ifdef SX1278_TX_EN
    p = p + "Packet Tx:";
    sprintf(tmp,"%d",txPacketCnt);
    p = p+tmp;
    p = p+ "\r\n";
#endif
#ifdef OLED_DISPLAY
    OLEDDisplay(p);
#endif
}

void OLEDInit(void)
{
    display.begin(SSD1306_SWITCHCAPVCC,0x3C);
    display.setTextSize(2);
    display.setTextColor(WHITE);
    display.setCursor(0,0);
    display.clearDisplay();
    display.println("LoRa Test");
    display.display();
}

static void LedBlink(void)
{
    ledFlag = !ledFlag;
    if(ledFlag) {
        RGB.color(0x0000ff);
    } else {
        RGB.off();
    }
}

void system_event_callback(system_event_t event, int param, uint8_t *data, uint16_t datalen)
{
    switch(event) {
        case event_lora_radio_status:
            switch(param) {
                case ep_lora_radio_tx_done:
                    LoRa.radioSetSleep();
                    txPacketCnt++;
                    if(txPacketCnt >= 65535) {
                        txPacketCnt = 0;
                    }
                    txDoneFlag = true;
                    break;

                case ep_lora_radio_tx_fail:
                    LoRa.radioSetSleep();
                    txDoneFlag = true;
                    break;

                case ep_lora_radio_rx_done:
                    rxPacketCnt++;

                    snrValue = LoRa.radioGetSnr();
                    rssiValue = LoRa.radioGetRssi();

                    currentPacketCnt = data[1] & 0xff;
                    currentPacketCnt = (currentPacketCnt << 8) | data[0];

                    //发射端计数复位或者溢出了
                    if(currentPacketCnt < lastPacketCnt) {
                        rxPacketCnt = 1;
                        missPacketCnt = 0;
                        lastPacketCnt = currentPacketCnt;
                        currentPacketCnt = 0;
                    } else {
                        if(rxPacketCnt >= 5) {
                            missPacketCnt = missPacketCnt + currentPacketCnt - lastPacketCnt-1;
                        } else {
                            missPacketCnt = 0;
                        }
                        lastPacketCnt = currentPacketCnt;
                    }

                    if(rxPacketCnt == 1) {
                        lastMillis = millis();
                    }

                    currentTime = millis();
                    if(currentTime - lastMillis >= 5000) {
                        realDataRate = (uint16_t)(((rxPacketCnt-lastRxPackets) * bufferSize * 8 * 1000)/(currentTime - lastMillis));
                        lastRxPackets = rxPacketCnt;
                        lastMillis = currentTime;
                    }

                    rxDoneFlag = true;
                    break;

                case ep_lora_radio_rx_timeout:
                    LoRa.radioSetSleep();
                    LoRa.radioStartRx(0);
                    break;

                case ep_lora_radio_rx_error:
                    LoRa.radioSetSleep();
                    missPacketCnt++;
                    LoRa.radioStartRx(0);
                    break;

                case ep_lora_radio_cad_done:
                    break;
                default:
                    break;
            }
            break;
        default:
            break;
    }
}

void ResetKeyHandler(void)
{
#ifdef SX1278_TX_EN
    txPacketCnt = 0;
#else
    rxPacketCnt = 0;
    missPacketCnt = 0;
    lastPacketCnt = 0;
    currentPacketCnt = 0;
    lastRxPackets = 0;
#endif
    RFParameterDispaly();
}

void UpKeyHandler(void)
{
#ifdef SX1278_TX_EN
    txPacketCnt = 0;
#else
    rxPacketCnt = 0;
    missPacketCnt = 0;
    lastPacketCnt = 0;
    currentPacketCnt = 0;
    lastRxPackets = 0;
    rxChangeParams = true;
    LoRa.radioSetSleep();
#endif

    if(paramsIndex < LORA_PARAMS_NUMBER - 1) {
        paramsIndex++;
    } else {
        paramsIndex = 0;
    }

    if(ParamsTable[paramsIndex].bw == 625) {
        LoRa.radioSetBandwidth(BW62_5);
        bandwidth = 625;
    } else if(ParamsTable[paramsIndex].bw == 125) {
        LoRa.radioSetBandwidth(BW125);
        bandwidth = 125;
    } else if(ParamsTable[paramsIndex].bw == 250) {
        LoRa.radioSetBandwidth(BW250);
        bandwidth = 250;
    } else if(ParamsTable[paramsIndex].bw == 500) {
        LoRa.radioSetBandwidth(BW500);
        bandwidth = 500;
    }
    spreadFactor = ParamsTable[paramsIndex].sf;
    LoRa.radioSetSF(spreadFactor);
    bufferSize = ParamsTable[paramsIndex].size;
    if(spreadFactor == 6) {
        LoRa.radioSetFixLenOn(true);
        LoRa.radioSetFixPayloadLen(bufferSize);
    } else {
        LoRa.radioSetFixLenOn(false);
        LoRa.radioSetFixPayloadLen(0);
    }
    RFParameterDispaly();

#ifndef SX1278_TX_EN
    LoRa.radioStartRx(0);
#endif
}

void BackKeyHandler(void)
{
#ifdef SX1278_TX_EN
    txPacketCnt = 0;
#else
    rxPacketCnt = 0;
    missPacketCnt = 0;
    lastPacketCnt = 0;
    currentPacketCnt = 0;
    lastRxPackets = 0;
    rxChangeParams = true;
    LoRa.radioSetSleep();
#endif
    if(paramsIndex > 0) {
        paramsIndex--;
    } else {
        paramsIndex = LORA_PARAMS_NUMBER-1;
    }

    if(ParamsTable[paramsIndex].bw == 625) {
        LoRa.radioSetBandwidth(BW62_5);
        bandwidth = 625;
    } else if(ParamsTable[paramsIndex].bw == 125) {
        LoRa.radioSetBandwidth(BW125);
        bandwidth = 125;
    } else if(ParamsTable[paramsIndex].bw == 250) {
        LoRa.radioSetBandwidth(BW250);
        bandwidth = 250;
    } else if(ParamsTable[paramsIndex].bw == 500) {
        LoRa.radioSetBandwidth(BW500);
        bandwidth = 500;
    }
    spreadFactor = ParamsTable[paramsIndex].sf;
    LoRa.radioSetSF(spreadFactor);
    bufferSize = ParamsTable[paramsIndex].size;
    if(spreadFactor == 6) {
        LoRa.radioSetFixLenOn(true);
        LoRa.radioSetFixPayloadLen(bufferSize);
    } else {
        LoRa.radioSetFixLenOn(false);
        LoRa.radioSetFixPayloadLen(0);
    }

    RFParameterDispaly();

#ifndef SX1278_TX_EN
    LoRa.radioStartRx(0);
#endif
}

void FeqUpKeyHandler(void)
{
#ifdef SX1278_TX_EN
    txPacketCnt = 0;
#else
    rxPacketCnt = 0;
    missPacketCnt = 0;
    lastPacketCnt = 0;
    currentPacketCnt = 0;
    lastRxPackets = 0;
    rxChangeParams = true;
    LoRa.radioSetSleep();
#endif

    if(feqIndex < feqMaxIndex) {
        feqIndex++;
    } else {
        feqIndex = 0;
    }
    LoRa.radioSetFreq(g_FeqTable[feqIndex]);

    if(ParamsTable[paramsIndex].bw == 625) {
        LoRa.radioSetBandwidth(BW62_5);
        bandwidth = 625;
    } else if(ParamsTable[paramsIndex].bw == 125) {
        LoRa.radioSetBandwidth(BW125);
        bandwidth = 125;
    } else if(ParamsTable[paramsIndex].bw == 250) {
        LoRa.radioSetBandwidth(BW250);
        bandwidth = 250;
    } else if(ParamsTable[paramsIndex].bw == 500) {
        LoRa.radioSetBandwidth(BW500);
        bandwidth = 500;
    }
    spreadFactor = ParamsTable[paramsIndex].sf;
    LoRa.radioSetSF(spreadFactor);
    bufferSize = ParamsTable[paramsIndex].size;
    if(spreadFactor == 6) {
        LoRa.radioSetFixLenOn(true);
        LoRa.radioSetFixPayloadLen(bufferSize);
    } else {
        LoRa.radioSetFixLenOn(false);
        LoRa.radioSetFixPayloadLen(0);
    }
    RFParameterDispaly();

#ifndef SX1278_TX_EN
    LoRa.radioStartRx(0);
#endif
}

void FeqBackKeyHandler(void)
{
#ifdef SX1278_TX_EN
    txPacketCnt = 0;
#else
    rxPacketCnt = 0;
    missPacketCnt = 0;
    lastPacketCnt = 0;
    currentPacketCnt = 0;
    lastRxPackets = 0;
    rxChangeParams = true;
    LoRa.radioSetSleep();
#endif

    if(feqIndex > 0) {
        feqIndex--;
    } else {
        feqIndex = feqMaxIndex;
    }
    LoRa.radioSetFreq(g_FeqTable[feqIndex]);

    if(ParamsTable[paramsIndex].bw == 625) {
        LoRa.radioSetBandwidth(BW62_5);
        bandwidth = 625;
    } else if(ParamsTable[paramsIndex].bw == 125) {
        LoRa.radioSetBandwidth(BW125);
        bandwidth = 125;
    } else if(ParamsTable[paramsIndex].bw == 250) {
        LoRa.radioSetBandwidth(BW250);
        bandwidth = 250;
    } else if(ParamsTable[paramsIndex].bw == 500) {
        LoRa.radioSetBandwidth(BW500);
        bandwidth = 500;
    }
    spreadFactor = ParamsTable[paramsIndex].sf;
    LoRa.radioSetSF(spreadFactor);
    bufferSize = ParamsTable[paramsIndex].size;
    if(spreadFactor == 6) {
        LoRa.radioSetFixLenOn(true);
        LoRa.radioSetFixPayloadLen(bufferSize);
    } else {
        LoRa.radioSetFixLenOn(false);
        LoRa.radioSetFixPayloadLen(0);
    }

    RFParameterDispaly();

#ifndef SX1278_TX_EN
    LoRa.radioStartRx(0);
#endif
}

void KeyHandler(void)
{
    if(digitalRead(DR_UP_KEY) == 0 || digitalRead(DR_BACK_KEY) == 0) {
        if(keyDebounceTime <= KEY_EFFECT) {
            keyDebounceTime++;
            if(keyDebounceTime == KEY_EFFECT) {
                if(!keyRelease) {
                    keyRelease = true;
                    if(digitalRead(DR_UP_KEY) == 0) {
                        upKeyValid = true;
                    }

                    if(digitalRead(DR_BACK_KEY) == 0) {
                        backKeyValid = true;
                    }
                }
            }
        }
    } else if(digitalRead(FEQ_UP_KEY) == 0 || digitalRead(FEQ_BACK_KEY) == 0) {
        if(keyDebounceTime <= KEY_EFFECT) {
            keyDebounceTime++;
            if(keyDebounceTime == KEY_EFFECT) {
                if(!keyRelease) {
                    keyRelease = true;
                    if(digitalRead(FEQ_UP_KEY) == 0) {
                        feqUpKeyValid = true;
                    }

                    if(digitalRead(FEQ_BACK_KEY) == 0) {
                        feqBackKeyValid = true;
                    }
                }
            }
        }
    } else {
        if(keyDebounceTime) {
            if(keyDebounceTime > 5) {
                keyDebounceTime -= 3;
            } else {
                keyDebounceTime = 0;
                if(keyRelease) {
                    if(upKeyValid) {
                        upKeyValid = false;
                        UpKeyHandler();
                    }

                    if(backKeyValid) {
                        backKeyValid = false;
                        BackKeyHandler();
                    }

                    if(feqUpKeyValid) {
                        feqUpKeyValid = false;
                        FeqUpKeyHandler();
                    }

                    if(feqBackKeyValid) {
                        feqBackKeyValid = false;
                        FeqBackKeyHandler();
                    }

                    if(resetKeyValid) {
                        resetKeyValid = false;
                        ResetKeyHandler();
                    }

                    keyRelease = false;
                }
            }
        }
    }
}

void init_before_setup(void)
{
    System.disableFeature(SYSTEM_FEATURE_LORAMAC_RUN_ENABLED); //不运行lorawan协议
    System.disableFeature(SYSTEM_FEATURE_CONFIG_SAVE_ENABLED); //设备模式不保存
}

STARTUP( init_before_setup() );

void setup()
{
    Cloud.setProtocol(PROTOCOL_P2P);              //运行P2P透传
    System.on(event_lora_radio_status, &system_event_callback);
    LoRa.radioSetFreq(g_FeqTable[feqIndex]);
    LoRa.radioSetMaxPayloadLength(BUFFER_SIZE);
    LoRa.radioSetBandwidth(BW125);
    LoRa.radioSetSF(12);
    pinMode(DR_UP_KEY,INPUT_PULLUP);
    pinMode(DR_BACK_KEY,INPUT_PULLUP);
    pinMode(FEQ_UP_KEY,INPUT_PULLUP);
    pinMode(FEQ_BACK_KEY,INPUT_PULLUP);
    RGB.control(true);
    RGB.color(0x0000ff);
    Wire.setSpeed(CLOCK_SPEED_400KHZ);

#ifndef SX1278_TX_EN
    LoRa.radioStartRx(0);
#else
    delay(500);
#endif

#ifdef OLED_DISPLAY
    OLEDInit();
    display.setTextSize(1);
    display.setCursor(0,0);
    delay(500);
#endif

    rfFreq = LoRa.radioGetFreq();
    spreadFactor = LoRa.radioGetSF();
    getBW();

#ifndef SX1278_TX_EN
    RFParameterDispaly();
#endif

    bufferSize = ParamsTable[paramsIndex].size;
}

void loop()
{
    KeyHandler();
#ifdef SX1278_TX_EN
    if(txDoneFlag) {
        txDoneFlag = false;
        LedBlink();
        dataBuffer[0] = txPacketCnt & 0xff;
        dataBuffer[1] = (txPacketCnt >> 8) & 0xff;

        LoRa.radioSend(dataBuffer,bufferSize,0);
        RFParameterDispaly();
    }
#else
    if(rxDoneFlag) {
        rxDoneFlag = false;
        LedBlink();
        if(rxChangeParams) {
            rxChangeParams = false;
            rxPacketCnt = 0;
        }
        RFParameterDispaly();
    }
#endif
}

