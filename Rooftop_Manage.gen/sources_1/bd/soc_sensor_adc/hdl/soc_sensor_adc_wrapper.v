//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2024.2 (lin64) Build 5239630 Fri Nov 08 22:34:34 MST 2024
//Date        : Sat Sep 20 17:12:54 2025
//Host        : user16-B70TV-AN5TB8W running 64-bit Ubuntu 24.04.3 LTS
//Command     : generate_target soc_sensor_adc_wrapper.bd
//Design      : soc_sensor_adc_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module soc_sensor_adc_wrapper
   (push_buttons_4bits_tri_i,
    reset,
    sys_clock,
    usb_uart_rxd,
    usb_uart_txd,
    vauxn14_0,
    vauxn6_0,
    vauxp14_0,
    vauxp6_0);
  input [3:0]push_buttons_4bits_tri_i;
  input reset;
  input sys_clock;
  input usb_uart_rxd;
  output usb_uart_txd;
  input vauxn14_0;
  input vauxn6_0;
  input vauxp14_0;
  input vauxp6_0;

  wire [3:0]push_buttons_4bits_tri_i;
  wire reset;
  wire sys_clock;
  wire usb_uart_rxd;
  wire usb_uart_txd;
  wire vauxn14_0;
  wire vauxn6_0;
  wire vauxp14_0;
  wire vauxp6_0;

  soc_sensor_adc soc_sensor_adc_i
       (.push_buttons_4bits_tri_i(push_buttons_4bits_tri_i),
        .reset(reset),
        .sys_clock(sys_clock),
        .usb_uart_rxd(usb_uart_rxd),
        .usb_uart_txd(usb_uart_txd),
        .vauxn14_0(vauxn14_0),
        .vauxn6_0(vauxn6_0),
        .vauxp14_0(vauxp14_0),
        .vauxp6_0(vauxp6_0));
endmodule
