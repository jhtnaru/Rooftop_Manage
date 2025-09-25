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

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "sleep.h"
#include "xgpio.h"
#include "xintc.h"
#include "xil_exception.h"

#define BTN_ADDR XPAR_AXI_BTN_GPIO_0_BASEADDR
#define BTN_CHANNEL 1
#define INTC_ADDR XPAR_XINTC_0_BASEADDR
#define BTN_VEC_ID XPAR_FABRIC_AXI_BTN_GPIO_0_INTR

#define ULTRA_ADDR_0 XPAR_MYIP_ULTRASONIC_0_BASEADDR
#define ULTRA_ADDR_1 XPAR_MYIP_ULTRASONIC_1_BASEADDR
#define SERVO_ADDR_0 XPAR_MYIP_SERVO_0_BASEADDR
#define SERVO_ADDR_1 XPAR_MYIP_SERVO_1_BASEADDR
#define SERVO_ADDR_2 XPAR_MYIP_SERVO_2_BASEADDR
#define SERVO_ADDR_3 XPAR_MYIP_SERVO_3_BASEADDR
#define SERVO_ADDR_4 XPAR_MYIP_SERVO_4_BASEADDR
#define SERVO_ADDR_5 XPAR_MYIP_SERVO_5_BASEADDR
#define SERVO_ADDR_6 XPAR_MYIP_SERVO_6_BASEADDR
#define RTC_ADDR XPAR_MYIP_RTC_READ_0_BASEADDR
#define DHT11_ADDR XPAR_MYIP_DHT11_0_BASEADDR
#define SENSOR_ADC_ADDR XPAR_MYIP_SENSOR_ADC_0_BASEADDR
#define SENSOR_DGT_ADDR XPAR_MYIP_SENSOR_DGT_0_BASEADDR
#define STEPPER_ADDR XPAR_MYIP_STEPPER_0_BASEADDR
#define FAN_ADDR XPAR_MYIP_FAN_0_BASEADDR
#define TXTLCD_ADDR XPAR_MYIP_IIC_TXTLCD_0_BASEADDR

XGpio btn_inst;
XIntc intc_inst;

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

void lcdCommand(uint8_t command, volatile unsigned int *txtlcd_inst);
void lcdData(uint8_t data, volatile unsigned int *txtlcd_inst);
void i2cLCD_Init(volatile unsigned int *txtlcd_inst);
void lcdString(char *str, volatile unsigned int *txtlcd_inst);
void moveCursor(uint8_t row, uint8_t col, volatile unsigned int *txtlcd_inst);
void lcdClear(volatile unsigned int *txtlcd_inst);

uint8_t bcd_to_dec(uint8_t bcd);

volatile uint8_t btn_value;
volatile uint8_t btn_valid = 0;

int main () {
    init_platform();
    print("Success Start Rooftop\n");

    XGpio_Initialize(&btn_inst, BTN_ADDR);
    XGpio_SetDataDirection(&btn_inst, BTN_CHANNEL, 0b1111);
    XIntc_Initialize(&intc_inst, INTC_ADDR);

    XIntc_Connect(&intc_inst, BTN_VEC_ID,
        (XInterruptHandler)btn_isr, (void *)&btn_inst);
    XIntc_Enable(&intc_inst, BTN_VEC_ID);
    XIntc_Start(&intc_inst, XIN_REAL_MODE);

    XGpio_InterruptEnable(&btn_inst, BTN_CHANNEL);
    XGpio_InterruptGlobalEnable(&btn_inst);

    Xil_ExceptionInit();
    Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,
        (Xil_ExceptionHandler)XIntc_InterruptHandler, &intc_inst);
    Xil_ExceptionEnable();

    i2cLCD_Init(txtlcd_inst); // TXTLCD 초기화

    char* rtcDays[8] = {"Day", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"};

    char lcd_r1[20], lcd_r2[20];

    uint8_t sec = 0, min = 0, hour = 0;
    uint8_t date = 0, month = 0, day = 0, year = 0;

    uint8_t d_index;
    char ultra_sting_0[50], ultra_sting_1[50];
    char* direction_0[19] = { " N", " N", " N", "NW", "NW", "NW", "NW", " W", " W", " W", " W", 
        " W", "SW", "SW", "SW", "SW", " S", " S", " S"};
    char* direction_1[19] = {" S", " S", " S", "SE", "SE", "SE", "SE", " E", " E", " E", " E",
        " E", "NE", "NE", "NE", "NE", " N", " N", " N"};

    uint8_t adc_detect_0 = 0, adc_detect_1 = 0;
    uint16_t adc_angle_0 = 0, adc_angle_1 = 0;
    uint32_t adc_value_0 = 1200, adc_value_1 = 3000;

    uint8_t ultra_dout_0 = 0, ultra_dout_1 = 0;
    uint8_t adc_dout = 0, flame_out = 0, air_out = 0, stepper_out = 0;

    servo_inst_0[0] = 0b00100;
    servo_inst_0[1] = 1;
    servo_inst_0[2] = 180;
    servo_inst_1[0] = 0b01000;
    servo_inst_1[1] = 1;
    servo_inst_1[2] = 180;
    servo_inst_2[0] = 0b10000;
    servo_inst_2[1] = 1;
    servo_inst_2[2] = 90;
    servo_inst_3[0] = 0b10000;
    servo_inst_3[1] = 1;
    servo_inst_3[2] = 90;
    servo_inst_4[0] = 0b10000;
    servo_inst_4[1] = 0;
    servo_inst_4[2] = 90;
    servo_inst_5[0] = 0b10000;
    servo_inst_5[1] = 0;
    servo_inst_5[2] = 90;
    servo_inst_6[0] = 0b10000;
    servo_inst_6[1] = 0;
    servo_inst_6[2] = 60;

    stepper_inst[0] = 0b01000;
    stepper_inst[1] = 0;
    stepper_inst[2] = 2160;
    stepper_inst[3] = 1;

    fan_inst[0] = 0b001;
    fan_inst[1] = 0;
    fan_inst[2] = 1;
    fan_inst[3] = 200;

    moveCursor(0, 0, txtlcd_inst);
    lcdString("00-00-00    H   ", txtlcd_inst);
    moveCursor(1, 0, txtlcd_inst);
    lcdString("00:00:00    T   ", txtlcd_inst);

    while (1) {
        if (btn_valid) {
            if (btn_value == 0b0001) {
                servo_inst_0[1] = servo_inst_0[1] ^ 0b1;
                servo_inst_1[1] = servo_inst_1[1] ^ 0b1;
                servo_inst_2[1] = servo_inst_2[1] ^ 0b1;
                servo_inst_3[1] = servo_inst_3[1] ^ 0b1;
                if (servo_inst_0[1]) {
                    print("Start\n");
                    servo_inst_0[0] = 0b00100;
                    servo_inst_1[0] = 0b01000;
                }
                else if (servo_inst_0[1] == 0) {
                    print("Stop\n");
                    servo_inst_0[0] = 0b10000;
                    servo_inst_1[0] = 0b10000;
                    servo_inst_2[2] = 90;
                    servo_inst_3[2] = 90;
                }
            }
            else if (btn_value == 0b0010) {
                print("Flame Clear\n");
                servo_inst_4[1] = 0;
                servo_inst_5[1] = 0;
                servo_inst_6[1] = 0;
                fan_inst[0] = 0b001;
                fan_inst[1] = 0;
                stepper_inst[1] = 0;
                flame_out = 0;
                air_out = 0;
                stepper_out = 0;
            }
            else if (btn_value == 0b0100) {
            }
            else if (btn_value == 0b1000) {
                
            }
            btn_value = 0;
            btn_valid = 0;
        }

        if ((servo_inst_0[3] % 10) == 0 && servo_inst_0[1]) {
            d_index = (servo_inst_0[3] / 10) - 4;
            if (ultra_inst_0[0] <= 10 && ultra_dout_0 == 0) {
                sprintf(ultra_sting_0, "No1 %02d:%02d:%02d Direction %s %3d Distance %2dm",
                    hour, min, sec, direction_0[d_index], servo_inst_0[3] - 40, ultra_inst_0[0]);
                printf("%s\n",  ultra_sting_0);
                ultra_dout_0 = 1;
            }
            if (ultra_inst_1[0] <= 10 && ultra_dout_1 == 0) {
                sprintf(ultra_sting_1, "No2 %02d:%02d:%02d Direction %s %3d Distance %2dm",
                    hour, min, sec, direction_1[d_index], servo_inst_0[3] + 140, ultra_inst_1[0]);
                printf("%s\n",  ultra_sting_1);
                ultra_dout_1 = 1;
            }
        }
        else if (servo_inst_0[3] % 10) {
            ultra_dout_0 = 0;
            ultra_dout_1 = 0;
        }

        if (servo_inst_1[3] == 40) {
            adc_detect_0 = 0;
            adc_detect_1 = 0;
            adc_value_0 = 1200;
            adc_value_1 = 3500;
        }
        else if (servo_inst_1[3] == 220 && adc_dout == 0) {
            adc_dout = 1;
            if (adc_detect_0) {
                servo_inst_3[2] = adc_angle_0;
                printf("Wind Power Angle %3d\n", adc_angle_0);
            }
            if (adc_detect_1) {
                servo_inst_2[2] = adc_angle_1;
                printf("Solar Power Angle %3d\n", adc_angle_1);
            }
        }
        else if ((servo_inst_1[3] % 10) == 0 && adc_dout == 0) {
            adc_dout = 1;
            // printf("Servo1 %3d Sound %4d Photo %4d\n", servo_inst_1[3], sensor_adc_inst[0], sensor_adc_inst[1]);
            if (sensor_adc_inst[0] < 1000) {
                adc_detect_0 = 1;
                if (adc_value_0 > sensor_adc_inst[0]) {
                    adc_value_0 = sensor_adc_inst[0];
                    adc_angle_0 = servo_inst_1[3] - 40;
                    printf("Sound %4d Angle %3d\n", adc_value_0, adc_angle_0);
                }
            }
            if (sensor_adc_inst[1] < 2000) {
                adc_detect_1 = 1;
                if (adc_value_1 > sensor_adc_inst[1]) {
                    adc_value_1 = sensor_adc_inst[1];
                    adc_angle_1 = servo_inst_1[3] - 40;
                    printf("Photo %4d Angle %3d\n", adc_value_1, adc_angle_1);
                }
            }
        }
        else if (servo_inst_1[3] % 10) {
            adc_dout = 0;
        }

        if (sensor_dgt_inst[0] && flame_out == 0) {
            flame_out = 1;
            print("Flame Detect\n");
            servo_inst_5[1] = 1;
            servo_inst_6[1] = 1;
        }
        if (servo_inst_5[3] == 130 && air_out == 0 && flame_out) {
            air_out = 1;
            print("Air Mattress On\n");
            fan_inst[0] = 0b010;
            fan_inst[1] = 1;
            servo_inst_4[1] = 1;
        }
        if (servo_inst_4[3] == 130 && stepper_out == 0 && flame_out) {
            stepper_out = 1;
            print("Auxiliary Escape Line On\n");
            stepper_inst[1] = 1;
        }

        if (rtc_inst[9] == 0 && rtc_inst[0] == 0) rtc_inst[0] = 1;
        if (servo_inst_0[3] % 10 == 5) rtc_inst[0] = 0;

        sec   = bcd_to_dec(rtc_inst[1]);
        min   = bcd_to_dec(rtc_inst[2]);
        hour  = bcd_to_dec(rtc_inst[3]);
        date  = bcd_to_dec(rtc_inst[4]);
        month = bcd_to_dec(rtc_inst[5]);
        day   = bcd_to_dec(rtc_inst[6]);
        year  = bcd_to_dec(rtc_inst[7]);
        sprintf(lcd_r1, "%02d-%02d-%02d%s H %2d", year, month, date, rtcDays[day], dht11_inst[0]);
        sprintf(lcd_r2, "%02d:%02d:%02d    T %2d", hour, min, sec, dht11_inst[1]);
        moveCursor(0, 0, txtlcd_inst);
        lcdString(lcd_r1, txtlcd_inst);
        moveCursor(1, 0, txtlcd_inst);
        lcdString(lcd_r2, txtlcd_inst);
    }

    cleanup_platform();
    return 0;
}

void btn_isr(void *CallBackRef) {
    XGpio *Gpio_ptr = (XGpio *)CallBackRef;
    btn_value = XGpio_DiscreteRead(Gpio_ptr, BTN_CHANNEL); // Interrupt 발생 Pin 확인, 상태 읽기

    if (btn_value) btn_valid = 1;
    else if (btn_value == 0) btn_valid = 0;

    XGpio_InterruptClear(&btn_inst, BTN_CHANNEL);// Clear 않으면 ISR 계속 재실행
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