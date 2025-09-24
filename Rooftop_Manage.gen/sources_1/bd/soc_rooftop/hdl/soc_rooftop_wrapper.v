//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2024.2 (lin64) Build 5239630 Fri Nov 08 22:34:34 MST 2024
//Date        : Tue Sep 23 16:04:38 2025
//Host        : user16-B70TV-AN5TB8W running 64-bit Ubuntu 24.04.3 LTS
//Command     : generate_target soc_rooftop_wrapper.bd
//Design      : soc_rooftop_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module soc_rooftop_wrapper
   (dht11_data_0,
    fan_out_0,
    push_buttons_4bits_tri_i,
    reset,
    rtc_clk_0,
    rtc_dat_0,
    rtc_rst_0,
    scl_0,
    sda_0,
    sensor_0,
    servo_0,
    servo_1,
    servo_2,
    servo_3,
    servo_4,
    servo_5,
    servo_6,
    step_out_0,
    sys_clock,
    ultra_echo_0,
    ultra_echo_1,
    ultra_trig_0,
    ultra_trig_1,
    usb_uart_rxd,
    usb_uart_txd,
    vauxn14_0,
    vauxn6_0,
    vauxp14_0,
    vauxp6_0);
  inout dht11_data_0;
  output [1:0]fan_out_0;
  input [3:0]push_buttons_4bits_tri_i;
  input reset;
  output rtc_clk_0;
  inout rtc_dat_0;
  output rtc_rst_0;
  output scl_0;
  output sda_0;
  input sensor_0;
  output servo_0;
  output servo_1;
  output servo_2;
  output servo_3;
  output servo_4;
  output servo_5;
  output servo_6;
  output [3:0]step_out_0;
  input sys_clock;
  input ultra_echo_0;
  input ultra_echo_1;
  output ultra_trig_0;
  output ultra_trig_1;
  input usb_uart_rxd;
  output usb_uart_txd;
  input vauxn14_0;
  input vauxn6_0;
  input vauxp14_0;
  input vauxp6_0;

  wire dht11_data_0;
  wire [1:0]fan_out_0;
  wire [3:0]push_buttons_4bits_tri_i;
  wire reset;
  wire rtc_clk_0;
  wire rtc_dat_0;
  wire rtc_rst_0;
  wire scl_0;
  wire sda_0;
  wire sensor_0;
  wire servo_0;
  wire servo_1;
  wire servo_2;
  wire servo_3;
  wire servo_4;
  wire servo_5;
  wire servo_6;
  wire [3:0]step_out_0;
  wire sys_clock;
  wire ultra_echo_0;
  wire ultra_echo_1;
  wire ultra_trig_0;
  wire ultra_trig_1;
  wire usb_uart_rxd;
  wire usb_uart_txd;
  wire vauxn14_0;
  wire vauxn6_0;
  wire vauxp14_0;
  wire vauxp6_0;

  soc_rooftop soc_rooftop_i
       (.dht11_data_0(dht11_data_0),
        .fan_out_0(fan_out_0),
        .push_buttons_4bits_tri_i(push_buttons_4bits_tri_i),
        .reset(reset),
        .rtc_clk_0(rtc_clk_0),
        .rtc_dat_0(rtc_dat_0),
        .rtc_rst_0(rtc_rst_0),
        .scl_0(scl_0),
        .sda_0(sda_0),
        .sensor_0(sensor_0),
        .servo_0(servo_0),
        .servo_1(servo_1),
        .servo_2(servo_2),
        .servo_3(servo_3),
        .servo_4(servo_4),
        .servo_5(servo_5),
        .servo_6(servo_6),
        .step_out_0(step_out_0),
        .sys_clock(sys_clock),
        .ultra_echo_0(ultra_echo_0),
        .ultra_echo_1(ultra_echo_1),
        .ultra_trig_0(ultra_trig_0),
        .ultra_trig_1(ultra_trig_1),
        .usb_uart_rxd(usb_uart_rxd),
        .usb_uart_txd(usb_uart_txd),
        .vauxn14_0(vauxn14_0),
        .vauxn6_0(vauxn6_0),
        .vauxp14_0(vauxp14_0),
        .vauxp6_0(vauxp6_0));
endmodule
