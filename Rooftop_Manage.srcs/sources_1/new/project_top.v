`timescale 1ns / 1ps

module servo_test_top (
    input clk, reset_p,
    input [3:0] btn,
    output servo,
    output [6:0] seg_7,
    output dp,
    output [3:0] com,
    output [15:0] led
    );

    wire [3:0] btn_pedge;
    btn_cntr btn0 (clk, reset_p, btn[0], btn_pedge[0]);
    btn_cntr btn1 (clk, reset_p, btn[1], btn_pedge[1]);
    btn_cntr btn2 (clk, reset_p, btn[2], btn_pedge[2]);
    btn_cntr btn3 (clk, reset_p, btn[3], btn_pedge[3]);

    reg [4:0] servo_mode;
    reg servo_start;
    reg [7:0] servo_angle;
    wire [7:0] step;
    servo_cntr test_servo (clk, reset_p, servo_mode, servo_start, servo_angle,
        servo, step, led);

    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin
            servo_mode <= 5'b00001;
            servo_start <= 0;
            servo_angle <= 90;
        end
        else begin
            if (btn_pedge[0]) begin
                servo_start <= ~servo_start;
            end
            else if (btn_pedge[1]) begin
                if (servo_mode == 5'b10000) servo_mode <= 5'b00001;
                else servo_mode <= servo_mode << 1;
            end
            else if (btn_pedge[2]) begin
                if (servo_angle == 180) servo_angle <= 90;
                else if (servo_angle == 90) servo_angle <= 180;
            end
        end
    end

    fnd_cntr fnd (.clk(clk), .reset_p(reset_p),
        .fnd_value(step), .hex_bcd(0), .seg_7(seg_7), .dp(dp), .com(com));
endmodule


module sensor_adc_test_top (
    input clk, reset_p,
    input sw0,
    input vauxp6, vauxn6,                       // XA1
    input vauxp14, vauxn14,                     // XA2
    output [6:0] seg_7,
    output dp,
    output [3:0] com,
    output [15:0] led
    );

    wire [11:0] adc_value1, adc_value2;
    sensor_adc_cntr adc_sensor (.clk(clk), .reset_p(reset_p),
        .vauxp6(vauxp6), .vauxn6(vauxn6), .vauxp14(vauxp14), .vauxn14(vauxn14),
        .adc_value1(adc_value1), .adc_value2(adc_value2));

    wire [11:0] fnd_value;
    assign fnd_value = sw0 ? adc_value1 : adc_value2;

        // FND 4-Digit Output
    fnd_cntr fnd (.clk(clk), .reset_p(reset_p),
        .fnd_value(fnd_value), .hex_bcd(0), .seg_7(seg_7), .dp(dp), .com(com));
endmodule

module sensor_test_top (
    input clk, reset_p,
    input sensor,
    output [15:0] led
    );
    
    wire sensor_out;
    sensor_dgt_cntr senser_d (.clk(clk), .reset_p(reset_p),
        .sensor(sensor), .sensor_out(sensor_out));

    assign led[3:0] = {4{sensor}};
    assign led[7:4] = {4{sensor_out}};
endmodule

