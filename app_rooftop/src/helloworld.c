/******************************************************************************
* Copyright (C) 2023 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/
/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdint.h>
#include <stdio.h>
#include <sys/_intsup.h>
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "sleep.h"
#include "xgpio.h"
#include "xintc.h"
#include "xil_exception.h"
#include "xuartlite.h"

#define BTN_ADDR XPAR_AXI_BTN_GPIO_0_BASEADDR
#define BTN_CHANNEL 1
#define UART_ADDR XPAR_AXI_UARTLITE_0_BASEADDR
#define INTC_ADDR XPAR_XINTC_0_BASEADDR
#define BTN_VEC_ID XPAR_FABRIC_AXI_BTN_GPIO_0_INTR
#define UART_VEC_ID XPAR_FABRIC_AXI_UARTLITE_0_INTR

#define ULTRA_ADDR_0 XPAR_MYIP_ULTRASONIC_0_BASEADDR
#define ULTRA_ADDR_1 XPAR_MYIP_ULTRASONIC_1_BASEADDR
#define SERVO_ADDR_0 XPAR_MYIP_SERVO180_0_BASEADDR
#define SERVO_ADDR_1 XPAR_MYIP_SERVO180_1_BASEADDR
#define SERVO_ADDR_2 XPAR_MYIP_SERVO180_2_BASEADDR
#define SERVO_ADDR_3 XPAR_MYIP_SERVO180_3_BASEADDR
#define SERVO_ADDR_4 XPAR_MYIP_SERVO180_4_BASEADDR
#define SERVO_ADDR_5 XPAR_MYIP_SERVO180_5_BASEADDR
#define SERVO_ADDR_6 XPAR_MYIP_SERVO180_6_BASEADDR
#define RTC_ADDR XPAR_MYIP_RTC_READ_0_BASEADDR
#define DHT11_ADDR XPAR_MYIP_DHT11_0_BASEADDR
#define SENSOR_ADC_ADDR XPAR_MYIP_SENSOR_ADC_0_BASEADDR
#define SENSOR_DGT_ADDR XPAR_MYIP_SENSOR_DGT_0_BASEADDR
#define STEPPER_ADDR XPAR_MYIP_STEPPER_0_BASEADDR
#define FAN_ADDR XPAR_MYIP_FAN_0_BASEADDR
#define TXTLCD_ADDR XPAR_MYIP_IIC_TXTLCD_0_BASEADDR

XGpio btn_inst;
XIntc intc_inst;
XUartLite uart_inst;

volatile unsigned int *ultra_inst_0 = (volatile unsigned int *)ULTRA_ADDR_0;
volatile unsigned int *ultra_inst_1 = (volatile unsigned int *)ULTRA_ADDR_1;
volatile unsigned int *servo_inst_0 = (volatile unsigned int *)SERVO_ADDR_0;
volatile unsigned int *servo_inst_1 = (volatile unsigned int *)SERVO_ADDR_1;
volatile unsigned int *servo_inst_2 = (volatile unsigned int *)SERVO_ADDR_2;
volatile unsigned int *servo_inst_3 = (volatile unsigned int *)SERVO_ADDR_3;
volatile unsigned int *servo_inst_4 = (volatile unsigned int *)SERVO_ADDR_4;
volatile unsigned int *servo_inst_5 = (volatile unsigned int *)SERVO_ADDR_5;
volatile unsigned int *servo_inst_6 = (volatile unsigned int *)SERVO_ADDR_6;
volatile unsigned int *rtc_inst = (volatile unsigned int *)RTC_ADDR;
volatile unsigned int *dht11_inst = (volatile unsigned int *)DHT11_ADDR;
volatile unsigned int *sensor_adc_inst = (volatile unsigned int *)SENSOR_ADC_ADDR;
volatile unsigned int *sensor_dgt_inst = (volatile unsigned int *)SENSOR_DGT_ADDR;
volatile unsigned int *stepper_inst = (volatile unsigned int *)STEPPER_ADDR;
volatile unsigned int *fan_inst = (volatile unsigned int *)FAN_ADDR;
volatile unsigned int *txtlcd_inst = (volatile unsigned int *)TXTLCD_ADDR;

void btn_isr(void *CallBackRef);
void RecvHandler(void *CallBackRef, unsigned int EventData);
void SendHandler(void *CallBackRef, unsigned int EventData);

void lcdCommand(uint8_t command, volatile unsigned int *txtlcd_inst);
void lcdData(uint8_t data, volatile unsigned int *txtlcd_inst);
void i2cLCD_Init(volatile unsigned int *txtlcd_inst);
void lcdString(char *str, volatile unsigned int *txtlcd_inst);
void moveCursor(uint8_t row, uint8_t col, volatile unsigned int *txtlcd_inst);
void lcdClear(volatile unsigned int *txtlcd_inst);

uint8_t bcd_to_dec(uint8_t bcd);

char* rtcDays[8] = {"Day", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"};

volatile uint8_t btn_value;
volatile uint8_t btn_valid = 0;

int main () {
    init_platform();
    print("Success Start Rooftop Manage\n");

    // Button, UART, Interrupt 초기화 및 활성화
    XGpio_Initialize(&btn_inst, BTN_ADDR);
    XGpio_SetDataDirection(&btn_inst, BTN_CHANNEL, 0b1111);
    XIntc_Initialize(&intc_inst, INTC_ADDR);
    XUartLite_Initialize(&uart_inst, UART_ADDR);

    XIntc_Connect(&intc_inst, BTN_VEC_ID,
        (XInterruptHandler)btn_isr, (void *)&btn_inst);
    XIntc_Connect(&intc_inst, UART_VEC_ID,
        (XInterruptHandler)XUartLite_InterruptHandler, (void *)&uart_inst);
    XIntc_Enable(&intc_inst, BTN_VEC_ID);
    XIntc_Enable(&intc_inst, UART_VEC_ID);
    XIntc_Start(&intc_inst, XIN_REAL_MODE);

    XGpio_InterruptEnable(&btn_inst, BTN_CHANNEL);
    XGpio_InterruptGlobalEnable(&btn_inst);

    XUartLite_SetRecvHandler(&uart_inst, RecvHandler, &uart_inst);
    XUartLite_SetSendHandler(&uart_inst, SendHandler, &uart_inst);
    XUartLite_EnableInterrupt(&uart_inst);

    Xil_ExceptionInit();
    Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,
        (Xil_ExceptionHandler)XIntc_InterruptHandler, &intc_inst);
    Xil_ExceptionEnable();

    i2cLCD_Init(txtlcd_inst);               // TXTLCD 초기화
    // char lcd_r1[20];
    // char lcd_r2[20];

    // uint8_t sec, min, hour;
    // uint8_t date, month, day, year;

    stepper_inst[0] = 0b00001;
    stepper_inst[1] = 0;
    stepper_inst[2] = 360;
    stepper_inst[3] = 1;

    fan_inst[0] = 0b001;
    fan_inst[1] = 0;
    fan_inst[2] = 1;
    fan_inst[3] = 200;

    servo_inst_0[0] = 0b00100;
    servo_inst_0[1] = 0;
    servo_inst_0[2] = 180;

    servo_inst_1[0] = 0b01000;
    servo_inst_1[1] = 0;
    servo_inst_1[2] = 180;

    servo_inst_2[0] = 0b10000;
    servo_inst_2[1] = 0;
    servo_inst_2[2] = 40;

    servo_inst_3[0] = 0b10000;
    servo_inst_3[1] = 0;
    servo_inst_3[2] = 130;

    servo_inst_4[0] = 0b10000;
    servo_inst_4[1] = 0;
    servo_inst_4[2] = 90;

    servo_inst_5[0] = 0b10000;
    servo_inst_5[1] = 0;
    servo_inst_5[2] = 90;

    servo_inst_6[0] = 0b10000;
    servo_inst_6[1] = 0;
    servo_inst_6[2] = 60;

    uint8_t step_out = 0;

    moveCursor(0, 0, txtlcd_inst);
    lcdString("2000-00-00(   )", txtlcd_inst);
    moveCursor(1, 0, txtlcd_inst);
    lcdString("00:00:00", txtlcd_inst);

    while (1) {
        // printf("Flame %d\n", sensor_dgt_inst[0]);
        // printf("Dist1 %3d, Dist2 %3d\n", ultra_inst_0[0], ultra_inst_1[0]);
        // printf("HMDT %2d, TMPR %2d\n", dht11_inst[0], dht11_inst[1]);
        // printf("Sensor1 %d, Sensor2 %d\n", sensor_adc_inst[0], sensor_adc_inst[1]);

        // if (rtc_inst[9] == 0 && rtc_inst[0] == 0) rtc_inst[0] = 1;
        // msleep(1);
        // rtc_inst[0] = 0;
        // sec   = bcd_to_dec(rtc_inst[1]);
        // min   = bcd_to_dec(rtc_inst[2]);
        // hour  = bcd_to_dec(rtc_inst[3]);
        // date  = bcd_to_dec(rtc_inst[4]);
        // month = bcd_to_dec(rtc_inst[5]);
        // day   = bcd_to_dec(rtc_inst[6]);
        // year  = bcd_to_dec(rtc_inst[7]);

        // sprintf(lcd_r1, "%02d-%02d-%02d(%s)", year, month, date, rtcDays[day]);
        // sprintf(lcd_r2, "%02d:%02d:%02d", hour, min, sec);
        // // printf("20%02d-%02d-%02d(%s) %02d:%02d:%02d\n", year, month, date, rtcDays[day], hour, min, sec);
        // moveCursor(0, 2, txtlcd_inst);
        // lcdString(lcd_r1, txtlcd_inst);
        // moveCursor(1, 0, txtlcd_inst);
        // lcdString(lcd_r2, txtlcd_inst);

        if (btn_valid) {
            if (btn_value == 0b0001) {
                servo_inst_0[1] = servo_inst_0[1] ^ 0b1;
                servo_inst_1[1] = servo_inst_1[1] ^ 0b1;
                servo_inst_2[1] = servo_inst_2[1] ^ 0b1;
                servo_inst_3[1] = servo_inst_3[1] ^ 0b1;
                servo_inst_4[1] = servo_inst_4[1] ^ 0b1;
                servo_inst_5[1] = servo_inst_5[1] ^ 0b1;
                servo_inst_6[1] = servo_inst_6[1] ^ 0b1;
                if (servo_inst_0[1]) print("Servo Start\n");
                else if (servo_inst_0[1] == 0) print("Servo Stop\n");
            }
            btn_value = 0;
            btn_valid = 0;
        }

        if (servo_inst_0[3] % 10 == 0 && step_out == 0) {
            printf("Servo Step %d\n", servo_inst_0[3]);
            step_out = 1;
        }
        else if (servo_inst_0[3] % 10) {
            step_out = 0;
        }

        // msleep(500);
    }

    cleanup_platform();
    return 0;
}

void btn_isr(void *CallBackRef) {
    XGpio *Gpio_ptr = (XGpio *)CallBackRef;
    // Interrupt 발생 Pin 확인, 상태 읽기
    btn_value = XGpio_DiscreteRead(Gpio_ptr, BTN_CHANNEL);

    if (btn_value) btn_valid = 1;
    else if (btn_value == 0) btn_valid = 0;

    // Clear 않으면 ISR 계속 재실행
    XGpio_InterruptClear(&btn_inst, BTN_CHANNEL);
}

void RecvHandler(void *CallBackRef, unsigned int EventData) {
    uint8_t rxData;
    // 받은 Data를 사용하지 않더라도 Recv 해줘야 Interrupt 해제
    XUartLite_Recv(CallBackRef, &rxData, 1);
    printf("recv %c\n", rxData);
    return;
}

void SendHandler(void *CallBackRef, unsigned int EventData) {
    return;
}

void lcdCommand(uint8_t command, volatile unsigned int *txtlcd_inst) {
    while (txtlcd_inst[3]);
    txtlcd_inst[0] = 0x27;      // addr
    txtlcd_inst[1] = command;   // send_buffer
    txtlcd_inst[2] = 0x01;      // send = 1, rs = 0;
    while (txtlcd_inst[3]);
    txtlcd_inst[2] = 0;         // send = 0, rs = 0;
}

void lcdData(uint8_t data, volatile unsigned int *txtlcd_inst) {
    while (txtlcd_inst[3]);
    txtlcd_inst[0] = 0x27;
    txtlcd_inst[1] = data;
    txtlcd_inst[2] = 0x03;      // send = 1, rs = 1;
    while (txtlcd_inst[3]);
    txtlcd_inst[2] = 0;         // send = 0, rs = 0;
}

void i2cLCD_Init(volatile unsigned int *txtlcd_inst) {
	msleep(50);
	lcdCommand(0x33, txtlcd_inst);
    msleep(5);
	lcdCommand(0x32, txtlcd_inst);
    msleep(5);
	lcdCommand(0x28, txtlcd_inst);
    msleep(5);
	lcdCommand(0x0c, txtlcd_inst);
    msleep(5);
	lcdCommand(0x06, txtlcd_inst);
    msleep(5);
	lcdCommand(0x01, txtlcd_inst);
    msleep(2);
}

void lcdString(char *str, volatile unsigned int *txtlcd_inst) {
	while(*str)lcdData(*str++, txtlcd_inst);
}

void moveCursor(uint8_t row, uint8_t col, volatile unsigned int *txtlcd_inst) {
	lcdCommand(0x80 | row << 6 | col, txtlcd_inst);
}

void lcdClear(volatile unsigned int *txtlcd_inst) {
    lcdCommand(0x01, txtlcd_inst);
}

uint8_t bcd_to_dec(uint8_t bcd) {
    return ((bcd >> 4) * 10) + (bcd & 0x0F);
}
