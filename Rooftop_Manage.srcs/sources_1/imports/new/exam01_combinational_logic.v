// 시간 단위 1ns / 정밀도 시간 계산시 소수점 3자리 표현, 1ps
`timescale 1ns / 1ps

module and_gate(
    input A,
    input B,
    output F
    );
    
    assign F = A & B;
endmodule

// 구조적 Modeling, Gate
module half_adder_structural(
    input A, B,
    output sum, carry
    );

    // Gate 이용해서 처리
    xor (sum, A, B);        // 출력 1, 입력은 N 가능
    and (carry, A, B);      // 출력 먼저 하고 입력 작성
endmodule

// 동작적 Modeling, always
module half_adder_behavioral(
    input A, B,
    output reg sum, carry   // 입력 값을 주려면 변수 앞에 reg, 대입연산자(=) 왼쪽 
    );
    
    // always C언어와 비슷한 방식
    // A, B 값이 변하면
    always @(A, B)begin
        case({A, B})        // { , } 각 1-bit 묶어서 2-bit 변경
            // 2'b = 2-bit Binary
            2'b00: begin sum = 0; carry = 0; end
            2'b01: begin sum = 1; carry = 0; end
            2'b10: begin sum = 1; carry = 0; end
            2'b11: begin sum = 0; carry = 1; end                        
        endcase            
    end
endmodule

// Data Flow Modeling, assign
module half_adder_dataflow(
    // 기본적으로 wire
    input A, B,
    output sum, carry
    );
    
    // assign 문에서 입력 값을 주려면 wire 설정
    wire [1:0] sum_value;
    
    // assign 문에는 수식이 들어감
    assign sum_value = A + B;
    assign sum = sum_value[0];
    assign carry = sum_value[1];
endmodule

module full_adder_behavioral(
    input A, B, Cin,
    output reg sum, carry
    );
    
    always @(A, B, Cin)begin
        case({A, B, Cin})
            // 3'b = 3-bit Binary
            3'b000: begin sum = 0; carry = 0; end
            3'b001: begin sum = 1; carry = 0; end
            3'b010: begin sum = 1; carry = 0; end
            3'b011: begin sum = 0; carry = 1; end                        
            3'b100: begin sum = 1; carry = 0; end
            3'b101: begin sum = 0; carry = 1; end
            3'b110: begin sum = 0; carry = 1; end
            3'b111: begin sum = 1; carry = 1; end
        endcase            
    end    
endmodule 

module full_adder_structural(
    input A, B, Cin,
    output sum, carry
    );
    
    wire sum_0, carry_0, carry_1;
    
    // 앞 부분은 Module 한칸 띄고 뒷 부분은 Instance, 구조체와 비슷
    // .A(A) .A는 사용 module의 변수, (A)는 현재 module의 변수  
    half_adder_structural ha0(.A(A), .B(B), .sum(sum_0), .carry(carry_0));
    half_adder_structural ha1(.A(sum_0), .B(Cin), .sum(sum), .carry(carry_1));
    
    or (carry, carry_0, carry_1);
endmodule

module full_adder_dataflow(
    input A, B, Cin,
    output sum, carry
    );
    
    wire [1:0] sum_value;
    
    assign sum_value = A + B + Cin;
    assign sum = sum_value[0];
    assign carry = sum_value[1];
endmodule

module fadder_4bit_dataflow(
    input [3:0] A, B,        // A, B 모두 4bit
    input Cin,
    output [3:0] sum,
    output carry
    );
    
    wire [4:0] sum_value;
    
    assign sum_value = A + B + Cin;
    assign sum = sum_value[3:0];
    assign carry = sum_value[4];
endmodule

module fadder_4bit_structural(
    input [3:0] A, B,
    input Cin,
    output [3:0] sum,
    output carry
    );
    
    wire [2:0] carry_w;

    full_adder_structural fa0 (.A(A[0]), .B(B[0]), .Cin(Cin), .sum(sum[0]), .carry(carry_w[0]));
    full_adder_structural fa1 (.A(A[1]), .B(B[1]), .Cin(carry_w[0]), .sum(sum[1]), .carry(carry_w[1]));
    full_adder_structural fa2 (.A(A[2]), .B(B[2]), .Cin(carry_w[1]), .sum(sum[2]), .carry(carry_w[2]));
    full_adder_structural fa3 (.A(A[3]), .B(B[3]), .Cin(carry_w[2]), .sum(sum[3]), .carry(carry));
endmodule

// Multiplexer 2 Input 1 Output
module mux_2_1_d(
    input [1:0] d,
    input s,
    output f
    );
    
    // c언어의 if문과 동일, 조건 ? 참 : 거짓;
    assign f = s ? d[1] : d[0];
endmodule

// Multiplexer 4 Input 1 Output 
module mux_4_1_d(
    input [3:0] d,
    input [1:0] s,
    output f
    );
    
//    assign f = (s == 2'b00) ? d[0] : ((s == 2'b01) ? d[1] : ((s == 2'b10) ? d[2] : d[3]));
    assign f = d[s];
endmodule

// Multiplexer 4 Input 1 Output 
module mux_8_1_d(
    input [7:0] d,
    input [2:0] s,
    output f
    );
    
    assign f = d[s];
endmodule

// Demultiplexer
module demux_1_4_d(
    input d,
    input [1:0] s,
    output [3:0] f
    );
    
    // {3'b000, d} 상위 3-bit는 0, 마지막 bit는 d
    assign f = (s == 2'b00) ? {3'b000, d} :
               (s == 2'b01) ? {2'b00, d, 1'b0} :
               (s == 2'b10) ? {1'b0, d, 2'b00} : {d, 3'b000}; 
endmodule

// MUX + DMUX, MUX에서 선택된 입력을 DMUX의 선택된 출력으로 전달 
module mux_demux_test(
    input [3:0] d,
    input [1:0] mux_s,
    input [1:0] demux_s,
    output [3:0] f
    );
    
    wire mux_f;
    
    mux_4_1_d mux_4(.d(d), .s(mux_s), .f(mux_f));
    demux_1_4_d demux_4(.d(mux_f), .s(demux_s), .f(f));
endmodule

// signal → code
module encoder_4_2(
    input [3:0] signal,
    output reg [1:0] code
    );

    // 모든 경우를 포함하지 못하는 경우 불필요한 Latch 발생    
//    assign code = (signal == 4'b1000) ? 2'b11 :
//                  (signal == 4'b0100) ? 2'b10 :
//                  (signal == 4'b0010) ? 2'b01 : 2'b00;

    // 4가지 경우 외의 입력이 있을 경우 code는 이전 값 유지
    // if문 사용할 경우 누락되는 경우 없도록 주의, else를 반드시 사용 
//    always @(signal)begin
//        if(signal == 4'b1000) code = 2'b11;
//        else if(signal == 4'b0100) code = 2'b10;
//        else if(signal == 4'b0010) code = 2'b01;
//        else if(signal == 4'b0001) code = 2'b00;    // else와 같기 때문에 생략 가능 
//        else code = 2'b00;
//    end

    // case문 사용할 경우 default 반드시 사용
    always @(signal)begin
        case(signal)
            4'b0001: code = 2'b00;  // default와 같기 때문에 생략 가능
            4'b0010: code = 2'b01;
            4'b0100: code = 2'b10;
            4'b1000: code = 2'b11;
            default: code = 2'b00;
        endcase
    end
endmodule

// code → signal
module decoder_2_4(
    input [1:0] code,
    output reg [3:0] signal
    );
    
//    assign signal = (code == 2'b00) ? 4'b0001 :
//                    (code == 2'b01) ? 4'b0010 :
//                    (code == 2'b10) ? 4'b0100 : 4'b1000;
                    
//    always @(code)begin
//        if(code == 2'b00) signal = 4'b0001;
//        else if(code == 2'b01) signal = 4'b0010;
//        else if(code == 2'b10) signal = 4'b0100;
//        else if(code == 2'b11) signal = 4'b1000;
//        else signal = 4'b0001;
//    end

    always @(code)begin
        case(code)
            2'b00: signal = 4'b0001;
            2'b01: signal = 4'b0010;
            2'b10: signal = 4'b0100;
            2'b11: signal = 4'b1000;
            default: signal = 4'b0001;
        endcase    
    end
endmodule

// 입력된 숫자를 seg 출력 변수로 수정
module seg_decoder_a (
    input [1:0] scan_count,
    input [3:0] digit_in,
    output reg [6:0] seg_out,
    output reg dp_out
    );

    always @(*) begin
        case (digit_in)     //  gfedcba
            4'd0 : seg_out = 7'b1000000;
            4'd1 : seg_out = 7'b1111001;
            4'd2 : seg_out = 7'b0100100;
            4'd3 : seg_out = 7'b0110000;
            4'd4 : seg_out = 7'b0011001;
            4'd5 : seg_out = 7'b0010010;
            4'd6 : seg_out = 7'b0000010;
            4'd7 : seg_out = 7'b1111000;
            4'd8 : seg_out = 7'b0000000;
            4'd9 : seg_out = 7'b0011000;
            4'hA : seg_out = 7'b0001000;
            4'hb : seg_out = 7'b0000011;
            4'hC : seg_out = 7'b1000110;
            4'hd : seg_out = 7'b0100001;
            4'hE : seg_out = 7'b0000110;
            4'hF : seg_out = 7'b0001110;
            default : seg_out = 7'b1111111;
        endcase
        case (scan_count)
            2'd0 : dp_out = 0;
            2'd1 : dp_out = 1;
            2'd2 : dp_out = 0;
            2'd3 : dp_out = 1;
            default : dp_out = 1;
        endcase
    end
endmodule

// 입력된 자리를 an 출력 변수로 수정
module anode_selector (
    input [1:0] scan_count,
    output reg [3:0] an_out
    );

    always @(*) begin
        case (scan_count)
            2'd0 : an_out = 4'b1110;
            2'd1 : an_out = 4'b1101;
            2'd2 : an_out = 4'b1011;
            2'd3 : an_out = 4'b0111;
            default : an_out = 4'b1111;
        endcase
    end
endmodule

// Binary → BCD 방식 → Decimal
module bin_to_dec (
    input [11:0] bin,       // 12-bit Binary Input
    output reg [15:0] bcd   // 16-bit BCD Output (4-bit X 4자리)
    );

    integer i;

    always @(bin) begin
        bcd = 0;            // Initial Value
        for (i = 0; i < 12; i = i + 1) begin
            // BCD Algorithm
            // 1st 단위 bit 자리별로 5 이상 → + 3
            if (bcd[3:0] >= 5)   bcd[3:0] = bcd[3:0] + 3;
            if (bcd[7:4] >= 5)   bcd[7:4] = bcd[7:4] + 3;
            if (bcd[11:8] >= 5)  bcd[11:8] = bcd[11:8] + 3;
            if (bcd[15:12] >= 5) bcd[15:12] = bcd[15:12] + 3;

            // 2nd 1-bit Left Shift + 새 bit Input
            bcd = {bcd[14:0], bin[11 - i]};
        end
    end
endmodule
