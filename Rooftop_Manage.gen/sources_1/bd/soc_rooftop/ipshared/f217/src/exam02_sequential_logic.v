`timescale 1ns / 1ps

// Negative Edge 동작 D Flip-Flop
module D_flip_flop_n(
    input d, clk,
    input enable, reset_p,
    output reg q
    );
    
    // clk negedge = Negative(= Falling) Edge
    // reset posedge = Positive(= Rising) Edge
    // Sensitivity @( ) 여러개 있으면 우선순위를 정해줘야함
    always @(negedge clk or posedge reset_p) begin       // reset 우선
//    always @(negedge clk)begin                          // Clock 우선
        // begin end = { }, 여러 구문 실행
        if(reset_p) begin
            q = 1'b0;
        end
        else if(enable) begin
            q = d;
        end
    end
endmodule

// Positive Edge 동작 D Flip-Flop
module D_flip_flop_p(
    input d, clk,
    input enable, reset_p,
    output reg q
    );
    
    // clk posedge, reset posedge, reset은 보통 posedge 설정
    always @(posedge clk or posedge reset_p) begin       // reset 우선
        if(reset_p) begin
            q = 1'b0;
        end
        else if(enable) begin
            q = d;
        end
    end
endmodule

module T_flip_flop_n(
    input clk, reset_p,
    input enable,
    input t,
    output reg q
    );

    // ,와 or 같은 역할
    // 조합회로는 edge 미사용, Flip-Flop은 edge 사용
    // 문법 익숙해질때까지는 begin end 사용
    // clk negedge, reset posedge
    always @(negedge clk, posedge reset_p) begin
        if(reset_p) begin
            q = 0;
        end
        else begin
            if(enable) begin
                if(t) q = ~q;
                else q = q;         // 생략 가능
            end
        end
    end
endmodule

module T_flip_flop_p(
    input clk, reset_p,
    input enable,
    input t,
    output reg q
    );

    // clk posedge, reset posedge
    always @(posedge clk, posedge reset_p) begin
        if(reset_p) begin
            q = 0;
        end
        else begin
            if(enable) begin
                if(t) q = ~q;
                else q = q;         // 생략 가능
            end
        end
    end
endmodule

// Falling Edge 동작 T Flip-Flop으로 Counter를 만들면 Up Counter
// 비동기식 Up Counter, 다른 Clock 사용
module up_counter_asyc(
    input clk, reset_p,
    output [3:0] count 
    );
    
    // .은 T_flip_flop 변수, ( )는 현재 module 변수
    // Module Instance 선언
    T_flip_flop_n cnt0(.clk(clk), .reset_p(reset_p), .enable(1'b1), .t(1'b1), .q(count[0]));
    T_flip_flop_n cnt1(.clk(count[0]), .reset_p(reset_p), .enable(1'b1), .t(1'b1), .q(count[1]));
    T_flip_flop_n cnt2(.clk(count[1]), .reset_p(reset_p), .enable(1'b1), .t(1'b1), .q(count[2]));
    T_flip_flop_n cnt3(.clk(count[2]), .reset_p(reset_p), .enable(1'b1), .t(1'b1), .q(count[3]));
endmodule

// Rising Edge 동작 T Flip-Flop으로 Counter를 만들면 Down Counter
// 비동기식 Down Counter
module down_counter_asyc(
    input clk, reset_p,
    output [3:0] count 
    );
    
    T_flip_flop_p cnt0(.clk(clk), .reset_p(reset_p), .enable(1), .t(1), .q(count[0]));
    T_flip_flop_p cnt1(.clk(count[0]), .reset_p(reset_p), .enable(1), .t(1), .q(count[1]));
    T_flip_flop_p cnt2(.clk(count[1]), .reset_p(reset_p), .enable(1), .t(1), .q(count[2]));
    T_flip_flop_p cnt3(.clk(count[2]), .reset_p(reset_p), .enable(1), .t(1), .q(count[3]));
endmodule

// 동기식 Up Counter, Rising Edge
module up_counter_p(
    input clk, reset_p,
    output reg [3:0] count
    );
    
    // T Flip Flop 사용할 때는 Falling, Rising Edge 영향 받지만 동기식은 크게 영향 없음
    always @(posedge clk, posedge reset_p) begin
        if(reset_p) begin
            count = 0;
        end
        else begin
            count = count + 1;
        end
    end
endmodule

// 동기식 Up Counter, Falling Edge
module up_counter_n(
    input clk, reset_p,
    output reg [3:0] count
    );
    
    always @(negedge clk, posedge reset_p) begin
        if(reset_p) begin
            count = 0;
        end
        else begin
            count = count + 1;
        end
    end
endmodule

// 동기식 Down Counter, Rising Edge
module down_counter_p(
    input clk, reset_p,
    output reg [3:0] count
    );
    
    always @(posedge clk, posedge reset_p) begin
        if(reset_p) begin
            count = 0;
        end
        else begin
            count = count - 1;
        end
    end
endmodule

// 동기식 Down Counter, Falling Edge
module down_counter_n(
    input clk, reset_p,
    output reg [3:0] count
    );
    
    always @(negedge clk, posedge reset_p) begin
        if(reset_p) begin
            count = 0;
        end
        else begin
            count = count - 1;
        end
    end
endmodule

// Positive edge Ring Counter
module ring_counter_pos (
    input clk, reset_p,
    output reg [3:0] q
    );

    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            q <= 4'b0001;                   // 초기값 설정
        end
        else begin
            q = {q[2:0], q[3]};
        end
    end
endmodule

// Positive edge LED Ring Counter
module ring_counter_led (
    input clk, reset_p,
    output reg [15:0] q
    );

    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            q <= 4'b0000_0000_0000_0001;                   // 초기값 설정
        end
        else begin
            q <= {q[14:0], q[15]};
        end
    end
endmodule

// Negative edge Edge Detector
module edge_detector_neg (
    input clk, reset_p, cp,     // Clock, Reset, Input Signal 감지
    output p_edge, n_edge       // Rising, Falling 감지 출력
    );

    reg ff_cur, ff_old;         // cp 현재값과 이전값 저장할 Flip-Flop

    always @(negedge clk or posedge reset_p) begin
        if (reset_p) begin          // Reset Flip-Flop 초기화
            ff_cur <= 1'b0;
            ff_old <= 1'b0;
        end
        else begin                  // 이전값 저장하고 현재값 갱신
            ff_old <= ff_cur;
            ff_cur <= cp;
        end
    end

    // Rising 감지, 이전 0, 현재 1 이면 p_edge = 1
    assign p_edge = ({ff_cur, ff_old} == 2'b10) ? 1'b1 : 1'b0;
    // Falling 감지, 이전 1, 현재 0 이면 n_edge = 1
    assign n_edge = ({ff_cur, ff_old} == 2'b01) ? 1'b1 : 1'b0;
endmodule

// Positive edge Edge Detector
module edge_detector_pos (
    input clk, reset_p, cp,     // Clock, Reset, Input Signal 감지
    output p_edge, n_edge       // Rising, Falling 감지 출력
    );

    reg ff_cur, ff_old;         // cp 현재값과 이전값 저장할 Flip-Flop

    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin          // Reset Flip-Flop 초기화
            ff_cur <= 1'b0;
            ff_old <= 1'b0;
        end
        else begin                  // 이전값 저장하고 현재값 갱신
            ff_old <= ff_cur;
            ff_cur <= cp;
        end
    end

    // Rising 감지, 이전 0, 현재 1 이면 p_edge = 1
    assign p_edge = ({ff_cur, ff_old} == 2'b10) ? 1'b1 : 1'b0;
    // Falling 감지, 이전 1, 현재 0 이면 n_edge = 1
    assign n_edge = ({ff_cur, ff_old} == 2'b01) ? 1'b1 : 1'b0;
endmodule

module memory (
    input clk, 
    input rd_en, wr_en,
    input [3:0] wr_addr, rd_addr,
    input [7:0] i_data,
    output reg [7:0] o_data
    );

    reg [7:0] ram [0:1023];

    always @(posedge clk)begin
        if(wr_en) ram[wr_addr] = i_data;
    end

    always @(posedge clk)begin
        if(rd_en) o_data = ram[rd_addr];
    end
endmodule
