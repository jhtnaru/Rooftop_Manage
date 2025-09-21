`timescale 1ns / 1ps

// FND 4-Digit Output
module fnd_cntr (
    input clk, reset_p,
    input [15:0] fnd_value,
    input hex_bcd,
    output [6:0] seg_7,
    output dp,
    output [3:0] com
    );

    wire [15:0] bcd_value;
    // Convert Input Value to BCD Format
    bin_to_dec bcd (.bin(fnd_value[11:0]), .bcd(bcd_value));

    reg [16:0] clk_div;             // Clock Divide

    always @(posedge clk) begin
        clk_div = clk_div + 1;
    end

    // Change FND Output Every 2^16 * 10ns 
    anode_selector ring_com (.scan_count(clk_div[16:15]), .an_out(com));

    reg [3:0] digit_value;          // Single-Digit Output Value

    wire [15:0] out_value;          // Hex ↔ BCD Change Format
    assign out_value = hex_bcd ? fnd_value : bcd_value;

    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin          // Single-Digit Value Reset
            digit_value = 0;
        end
        else begin
            case (com)              // Select Digit Value
                4'b1110 : digit_value = out_value[3:0];
                4'b1101 : digit_value = out_value[7:4];
                4'b1011 : digit_value = out_value[11:8];
                4'b0111 : digit_value = out_value[15:12];
                default : digit_value = 0;
            endcase
        end
    end

    seg_decoder_a dec (.scan_count(clk_div[16:15]), .digit_in(digit_value),
                    .seg_out(seg_7), .dp_out(dp));
endmodule

// 
module fnd_cntr_direct_a (
    input clk, reset_p,
    input [31:0] fnd_value,
    output reg [6:0] seg_7,
    output reg dp,
    output [3:0] com
    );

    reg [16:0] clk_div;             // Clock Divide

    always @(posedge clk) begin
        clk_div = clk_div + 1;
    end

    // Change FND Output Every 2^16 * 10ns 
    anode_selector ring_com (.scan_count(clk_div[16:15]), .an_out(com));

    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin          // Single-Digit Value Reset
            seg_7 = 7'b000_0000;    // FND Segment gfe_dcba
            dp = 0;                 // Dot Point
        end
        else begin
            case (com)              // Select Digit Value
                4'b1110 : begin
                    seg_7 = fnd_value [6:0];
                    dp = fnd_value [7];
                end
                4'b1101 : begin
                    seg_7 = fnd_value [14:8];
                    dp = fnd_value [15];
                end
                4'b1011 : begin
                    seg_7 = fnd_value [22:16];
                    dp = fnd_value [23];
                end
                4'b0111 : begin
                    seg_7 = fnd_value [30:24];
                    dp = fnd_value [31];
                end
                default : begin
                    seg_7 = 7'b000_0000;
                    dp = 0;
                end
            endcase
        end
    end
endmodule

// Button Debounce 
module button_debounce (
    input clk,
    input noise_btn,            // Raw Input Button
    output reg clean_btn        // Modify Button
    );

    reg [19:0] cnt = 1;
    reg btn_sync_0, btn_sync_1; // 2 Step Debounce
    reg btn_state;              // Button Before State

    always @(posedge clk) begin
        btn_sync_0 <= noise_btn;
        btn_sync_1 <= btn_sync_0;
    end

    always @(posedge clk) begin
        if (btn_sync_1 == btn_state) begin
            cnt <= 1;           // Input == Before State, Stable State → Counter Reset
        end
        else begin
            cnt <= cnt + 1;     // Input != Before State, Count Increase
            if (cnt >= 1_000_000) begin  // Maintain a Specific Time for Debounce, 10ns * 1,000,000 = 10ms
                btn_state <= btn_sync_1;
                clean_btn <= btn_sync_1;
                cnt <= 1;
            end
        end
    end
endmodule

// Button Debounce + Edge Detect, Switch also Available
module btn_cntr (
    input clk, reset_p,
    input btn,
    output btn_pedge, btn_ndege
    );

    wire debounced_btn;
    button_debounce btn_debounce (.clk(clk), .noise_btn(btn), .clean_btn(debounced_btn));
    edge_detector_pos btn_ed (.clk(clk), .reset_p(reset_p),
        .cp(debounced_btn), .p_edge(btn_pedge), .n_edge(btn_ndege));
endmodule

// Watch Module, Second & Minute, Set Increase & Count
module watch (
    input clk, reset_p,
    input btn_mode, inc_sec, inc_min, btn_clear,    // Input Button
    output reg [7:0] sec, min,                      // Output Time
    output reg set_watch                            // Output State
    );

    reg [26:0] cnt_sysclk;                          // Clock Division

    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin                          // Mode Reset
            set_watch = 0;                          // Start Mode
        end
        else if (btn_mode) begin
            set_watch = ~set_watch;                 // Mode Toggle, Start ↔ Set
        end
    end

    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin                          // Time Reset
            cnt_sysclk = 1;
            sec = 0;
            min = 0;
        end
        else begin
            if (set_watch) begin                    // Set Mode
                if (inc_sec) begin
                    if (sec >= 59) begin            // 0 ~ 59 Second Count
                        sec = 0;
                    end
                    else begin
                        sec = sec + 1;              // Second Increase
                    end
                end
                if (inc_min) begin
                    if (min >= 59) begin            // 0 ~ 59 Minute Count
                        min = 0;
                    end
                    else begin
                        min = min + 1;              // Minute Increase
                    end
                end
            end
            else begin                              // Start Mode
                if (cnt_sysclk >= 27'd100_000_000) begin    // 10ns x 100,000,000 = 1s
                    cnt_sysclk = 1;
                    if (sec >= 59) begin            // 0 ~ 59 Second Count
                        sec = 0;
                        if (min >= 59) begin        // 0 ~ 59 Minute Count
                            min = 0;
                        end
                        else begin
                            min = min + 1;          // Secound Count
                        end
                    end
                    else begin
                        sec = sec + 1;              // Minute Count
                    end
                end
                cnt_sysclk = cnt_sysclk + 1;        // Count for Clock Division
            end
            if (btn_clear) begin
                cnt_sysclk = 1;
                sec = 0;
                min = 0;
            end
        end
    end
endmodule

// Timer Module, Set Time & Down Count, Alarm when Time Up
module cook_timer (
    input clk, reset_p,
    input btn_mode, inc_sec, inc_min, btn_clear,
    output reg [7:0] sec, min,
    output reg start_set, alarm
    );

    reg [26:0] cnt_sysclk;                          // Clock Division Count
    reg [7:0] set_sec, set_min;
    reg set_flag;                                   // Alarm Off Flag

    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin                          // State Reset
            start_set = 0;                          // State Stop, Set Mode
            alarm = 0;                              // Alarm Off
            set_flag = 0;
        end
        // Mode Button Input & State Stop
        else if (btn_mode && start_set == 0 && alarm == 0) begin
            // Start Only when Seconds and Minutes not 0
            if (sec != 0 || min != 0) begin
                start_set = 1;                      // Mode Start
                set_sec = sec;                      // Save Previous Seconds
                set_min = min;                      // Save Previous Minutes
            end
        end
        // Mode Button Input & State Start
        else if (btn_mode && start_set && alarm == 0) begin
            start_set = 0;                          // Mode Stop
        end
        // Alarm when 0 Minutes, 0 Seconds Pass
        else if (start_set && min == 0 && sec == 0) begin
            start_set = 0;                          // Mode Start → Stop
            alarm = 1;                              // Alarm On
        end
        // Button Input → Alarm Off
        else if (alarm && (inc_sec || inc_min || btn_mode)) begin
            alarm = 0;                              // Alarm Off
            set_flag = 1;                           // Alarm Flag On
        end
        // Alarm Flag On & Seconds and Minutes not 0
        else if (set_flag && (sec != 0 || min != 0)) begin
            set_flag = 0;                           // Alarm Flag Clear
        end
        else if (btn_clear) begin
            start_set = 0;
            alarm = 0;
            set_flag = 0;
            set_sec = 0;
            set_min = 0;
        end
    end

    always @(posedge clk, posedge reset_p) begin
        // Time Reset
        if (reset_p) begin
            cnt_sysclk = 1;                         // Clock Division Count Reset
            sec = 0;                                // Second Reset
            min = 0;                                // Minute Reset
        end
        else begin
            // State Start
            if (start_set) begin
                // Clock Divide, 10ns x 100,000,000 = 1 Second
                if (cnt_sysclk >= 100_000_000) begin
                    cnt_sysclk = 1;                 // Clock Division Count Reset
                    if (sec == 0) begin             // 0 Seconds Pass
                        if (min) begin              // Minutes not 0
                            sec = 59;               // 0 ~ 59 Second Count
                            min = min - 1;          // Minute Down Count
                        end
                    end
                    else begin
                        sec = sec - 1;              // Second Down Count
                    end
                end
                else begin
                    cnt_sysclk = cnt_sysclk + 1;    // Count for Clock Division
                end
            end
            else begin                              // State Stop & Set Mode
                if (inc_sec && alarm == 0) begin    // Input Increase Second Button & Alarm Off State
                    if(sec >= 59) begin             // 0 ~ 59 Second Set
                        sec = 0;
                    end
                    else begin
                        sec = sec + 1;              // Second Increase
                    end
                end
                if (inc_min && alarm == 0) begin    // Input Increase Minute Button & Alarm Off State
                    if (min >= 59) begin            // 0 ~ 59 Minute Set
                        min = 0;
                    end
                    else begin
                        min = min + 1;              // Minute Increase
                    end
                end
                if (set_flag) begin                 // Alarm Flag On
                    sec = set_sec;                  // Previous Second Set
                    min = set_min;                  // Previous Minute Set
                end
            end
            if (btn_clear) begin
                cnt_sysclk = 1;
                sec = 0;
                min = 0;
            end
        end
    end
endmodule

// Stop Watch Module
module stop_watch (
    input clk, reset_p,
    input btn_start, btn_lap, btn_clear,
    output [7:0] fnd_csec, fnd_sec,
    output reg start_stop, lap
    );
    
    reg [26:0] cnt_sysclk;                          // Clock Division Count
    reg [7:0] sec, csec;                            // HEX Format Time, Second, Subsecond
    reg [7:0] lap_sec, lap_csec;                    // Middle Record Time

    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin
            start_stop = 0;                         // Reset, Stop Mode
        end
        else if (btn_start) begin
            start_stop = ~start_stop;               // Mode Toggle, Start ↔ Stop
        end
    end

    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin
            lap = 0;                                // Lap Clear
            lap_sec = 0;                            // Middle Record Reset
            lap_csec = 0;
        end
        else if (btn_lap && (csec != 0 || sec != 0)) begin                     // Input Lap Button
            lap = ~lap;                             // Mode Toggle, Middle Record Show ↔ Not Show
            lap_sec = sec;                          // Time Middle Record
            lap_csec = csec;
        end
        else if (btn_clear) begin                   // Input Clear Button
            lap = 0;                                // Lap Clear
            lap_sec = 0;                            // Middle Record Reset
            lap_csec = 0;
        end
    end

    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin
            cnt_sysclk = 1;                         // Clock Division Count Reset
            csec = 0;
            sec = 0;                                // Time Reset
        end
        else begin
            if (start_stop) begin
                if (cnt_sysclk >= 1_000_000) begin  // 1ns * 1,000,000 = 0.01s
                    cnt_sysclk = 1;                 // Clock Division Count Reset
                    if (csec >= 99) begin           // 0 ~ 99 Sub Second Count
                        csec = 0;
                        if (sec >= 99) begin        // 0 ~ 99 Second Count
                            sec = 0;
                        end
                        else begin
                            sec = sec + 1;          // Second Up Count
                        end
                    end
                    else begin
                        csec = csec + 1;            // Sub Second Up Count
                    end
                end
                else begin
                    cnt_sysclk = cnt_sysclk + 1;    // Count for Clock Division
                end
            end
            if (btn_clear) begin                    // Input Clear Button, Maintain Start State
                cnt_sysclk = 1;                     // Clock Division Count Reset
                csec = 0;                           // Time Reset
                sec = 0;
            end
        end
    end

    // Determine FND Output by Middle Recode Mode
    assign fnd_csec = lap ? lap_csec : csec;
    assign fnd_sec = lap ? lap_sec : sec;
endmodule

// Humidity & Temperature Sensor data read & write, FSM
module dht11_cntr (
    input clk, reset_p,
    inout dht11_data,                           // Input + Output, reg Declaration Not Possible
    output reg [7:0] humidity, temperature,     // Output Measurement
    output [15:0] led                           // for Debugging
    );

    // Change State Using Shift
    localparam S_IDLE       = 6'b00_0001;       // Standby State
    localparam S_LOW_18MS   = 6'b00_0010;       // MCU Sends Out Start Signal
    localparam S_HIGH_20US  = 6'b00_0100;       // MCU Pull Up & Wait for Sensor Response
    localparam S_LOW_80US   = 6'b00_1000;       // DHT Sends Out Response Signal
    localparam S_HIGH_80US  = 6'b01_0000;       // DHT Pull Up & Get Ready Data
    localparam S_READ_DATA  = 6'b10_0000;       // DHT Data Read

    localparam S_WAIT_PEDGE = 2'b01;            // Start to Transmit 1-bit Data
    localparam S_WAIT_NEDGE = 2'b10;            // Voltage Length Measurement


    // Clock Divide 100, 10ns x 100 = 1us
    wire clk_usec_nedge;                        // Divide Clock 1us
    clock_div_100 us_clk (.clk(clk), .reset_p(reset_p), .nedge_div_100(clk_usec_nedge));

    // us Unit Count
    reg [21:0] cnt_usec;                        // us Count
    reg cnt_usec_e;                             // us Count Enable
    always @(negedge clk, posedge reset_p) begin
        if (reset_p) cnt_usec = 0;              // Count Clear
        else if (clk_usec_nedge && cnt_usec_e) begin    // Count Start when Enable & us Negative Edge
            cnt_usec = cnt_usec + 1;            // Count During Enable
        end
        else if (!cnt_usec_e) cnt_usec = 0;     // Count Clear when Disable
    end

    // Edge Detection of DHT Signal
    wire dht_nedge, dht_pedge;
    edge_detector_pos btn_ed (.clk(clk), .reset_p(reset_p),
        .cp(dht11_data), .p_edge(dht_pedge), .n_edge(dht_nedge));

    // Input Cannot be Declared as reg, Use Buffer
    reg dht11_buffer;                           // Buffer
    reg dht11_data_out_e;                       // Write Mode Enable Output, Disable Input
    assign dht11_data = dht11_data_out_e ? dht11_buffer : 'bz; // Output dout, Input Impedance Value

    reg [5:0] state, next_state;                // Current & Next State
    assign led [5:0] = state;                   // State LED Output
    reg [1:0] read_state;                       // Data Read State
    // Change State in Negative Edge
    always @(negedge clk, posedge reset_p) begin
        if (reset_p) state = S_IDLE;            // Basic Standby State
        else state = next_state;                // Change State in Negative Edge
    end

    reg [39:0] temp_data;                       // DHT Output Data 40-bit
    reg [5:0] data_cnt;                         // Counting to 40
    assign led [11:6] = data_cnt;
    // Set Next State in Positive Edge
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin
            next_state = S_IDLE;                // Basic Stanby State
            temp_data = 0;                      // DHT Data Reset
            data_cnt = 0;                       // DHT Data Count Reset
            dht11_data_out_e = 0;               // DHT Write Disable, Input
            read_state = S_WAIT_PEDGE;          // Data Read Pull-Up High
        end
        else begin
            case (state)
                S_IDLE      : begin             // Standby State
                    if (cnt_usec < 22'd3_000_000) begin     // Real 3_000_000, Test 3_000
                        cnt_usec_e = 1;         // us Count Enable
                        dht11_data_out_e = 0;   // DHT Input Mode
                    end
                    else begin
                        cnt_usec_e = 0;         // Count Clear
                        next_state = S_LOW_18MS;// Change State S_LOW_18MS
                    end
                end
                S_LOW_18MS  : begin             // MCU Sends Out Start Signal
                    if (cnt_usec < 22'd18_000) begin    // Real 18_000, Test 18
                        cnt_usec_e = 1;         // us Count Enable
                        dht11_data_out_e = 1;   // DHT Output Mode
                        dht11_buffer = 0;       // Buffer Reset
                    end
                    else begin
                        cnt_usec_e = 0;         // us Count Disable, Clear
                        next_state = S_HIGH_20US;   // Change State S_HIGH_20US
                        dht11_data_out_e = 0;   // DHT Input Mode
                    end
                end
                // It is Supposed to Respond after 20us, but in Reality, Response Occurs before that.
                // Remove 20us Waiting Part
                S_HIGH_20US : begin             // MCU Pull Up & Wait for Sensor Response
                    cnt_usec_e = 1;             // Count for Checking Response Time
                    if (cnt_usec > 22'd100_000) begin   // No Response 100ms, Comunication Error, Etc..
                        cnt_usec_e = 0;         // us Count Disable, Clear
                        next_state = S_IDLE;    // Change State S_IDLE
                    end
                    if (dht_nedge) begin        // DHT Response, No Count
                        cnt_usec_e = 0;         // us Count Disable, Clear
                        next_state = S_LOW_80US;    // Change State S_LOW_80US
                    end
                end
                S_LOW_80US  : begin             // DHT Sends Out Response Signal
                    cnt_usec_e = 1;             // Count for Checking Response Time
                    if (cnt_usec > 22'd100_000) begin   // No Response 100ms, Comunication Error, Etc..
                        cnt_usec_e = 0;         // us Count Disable, Clear
                        next_state = S_IDLE;    // Change State S_IDLE
                    end
                    if (dht_pedge) begin
                        cnt_usec_e = 0;         // us Count Disable, Clear
                        next_state = S_HIGH_80US;    // No Need to Count, Change State
                    end
                end
                S_HIGH_80US : begin             // DHT Pull Up & Get Ready Data
                    cnt_usec_e = 1;             // Count for Checking Response Time
                    if (cnt_usec > 22'd100_000) begin   // No Response 100ms, Comunication Error, Etc..
                        cnt_usec_e = 0;         // us Count Disable, Clear
                        next_state = S_IDLE;    // Change State S_IDLE
                    end
                    if (dht_nedge) begin
                        cnt_usec_e = 0;         // us Count Disable, Clear
                        next_state = S_READ_DATA;    // No Need to Count, Change State
                    end
                end
                S_READ_DATA : begin             // DHT Data Read
                    case (read_state)
                        S_WAIT_PEDGE : begin    // Current Low, Wait High
                            // High Signal Generation
                            if (dht_pedge) read_state = S_WAIT_NEDGE;   // Change State
                            cnt_usec_e = 0;     // us Count Disable, Clear
                        end
                        S_WAIT_NEDGE : begin    // Current High, Wait Low
                            // Low Signal Generation
                            if (dht_nedge) begin
                                read_state = S_WAIT_PEDGE;              // Change State
                                data_cnt = data_cnt + 1;                // Counting to 40
                            if (cnt_usec < 50) begin        // Distinguish by Signal Length
                                    temp_data = {temp_data[38:0], 1'b0};    // Shift Left & Enter Value in LSM
                                end
                                else begin
                                    temp_data = {temp_data[38:0], 1'b1};
                                end
                            end
                            else begin
                                cnt_usec_e = 1;     // us Count Enable
                                if (cnt_usec > 22'd100_000) begin   // No Response 100ms, Comunication Error, Etc..
                                    cnt_usec_e = 0;         // us Count Disable, Clear
                                    next_state = S_IDLE;
                                    data_cnt = 0;           // DHT Data Count Reset
                                    read_state = S_WAIT_PEDGE;
                                end
                            end
                        end
                    endcase

                    if (data_cnt >= 40) begin   // 40-bit Read Completed
                        next_state = S_IDLE;    // Basic Stanby State
                        data_cnt = 0;           // DHT Data Count Reset
    // DHT11 Data = Humidity Integral 8-bit + Decimal 8-bit + Temperature Integral 8-bit + Decimal 8-bit + Check Sum 8-bit
                        // Compare Upper 32-bits of Sum with Checksum
                        if ((temp_data[39:32] + temp_data[31:24] + temp_data[23:16] + temp_data[15:8]) == temp_data[7:0]) begin
                            humidity = temp_data[39:32];        // Use only Integer Values
                            temperature = temp_data[23:16];
                        end
                    end
                end
                default : next_state = S_IDLE;  // Basic Stanby State
            endcase
        end
    end
endmodule

// Ultrasonic Sensor, FSM
module ultrasonic_cntr (
    input clk, reset_p,
    input ultra_echo,                           // Input Echo Pulse
    output reg ultra_trig,                      // Output Initiate Signal
    output reg [11:0] distance,                 // Distance Calculation
    output [15:0] led                           // for Debugging, State Output
    );
    
    // Change State Using Shift
    localparam S_IDLE   = 5'b0_0001;            // Standby State
    localparam S_TIRG_H = 5'b0_0010;            // Trig Pin High Signal Transmission
    localparam S_TIRG_L = 5'b0_0100;            // Trig Pin Low Signal Transmission
    localparam S_ECHO_H = 5'b0_1000;            // Echo Pin High Signal Reception
    localparam S_ECHO_L = 5'b1_0000;            // Echo Pin Low Signal Reception & Distance Calculation

    // Clock Divide 100, 10ns x 100 = 1us
    wire clk_usec_nedge;                        // Divide Clock 1us
    clock_div_100 us_clk (.clk(clk), .reset_p(reset_p), .nedge_div_100(clk_usec_nedge));

    // us Unit Count
    reg [21:0] cnt_usec;                        // us Count
    reg cnt_usec_e;                             // us Count Enable
    always @(negedge clk, posedge reset_p) begin
        if (reset_p) cnt_usec = 0;              // Count Clear
        else if (clk_usec_nedge && cnt_usec_e) begin    // Count Start when Enable & us Negative Edge
            cnt_usec = cnt_usec + 1;            // Count During Enable
        end
        else if (!cnt_usec_e) cnt_usec = 0;     // Count Clear when Disable
    end

    reg [21:0] div_usec_58;                     // Count for Division by 58
    reg div_usec_58_e;                          // Count Enable
    reg [11:0] cnt_dist;                        // Distance Count
    always @(negedge clk, posedge reset_p) begin
        if (reset_p) begin
            div_usec_58 = 0;                    // Count Reset
            cnt_dist = 0;                       // Distance Count Reset
        end
        else if (clk_usec_nedge && div_usec_58_e) begin    // Count Start when Enable & us Negative Edge
            if (div_usec_58 >= 57) begin        // When 58us
                div_usec_58 = 0;                // Count Reset
                cnt_dist = cnt_dist + 1;        // Distance Increase
            end
            else div_usec_58 = div_usec_58 + 1; // Count During Enable
        end
        else if (!div_usec_58_e) begin
            div_usec_58 = 0;                    // Count Reset when Disable
            cnt_dist = 0;                       // Distance Reset when Disable
        end
    end

    // Edge Detection of Ultrasonic Echo Signal
    wire ultra_nedge, ultra_pedge;
    edge_detector_pos btn_ed (.clk(clk), .reset_p(reset_p),
        .cp(ultra_echo), .p_edge(ultra_pedge), .n_edge(ultra_nedge));

    reg [4:0] state, next_state;                // Current & Next State
    assign led [4:0] = state;                   // State LED Output
    assign led [5] = ultra_trig;                // Trig Signal LED Output
    assign led [6] = ultra_echo;                // Echo Signal LED Output
    // Change State in Negative Edge
    always @(negedge clk, posedge reset_p) begin
        if (reset_p) state = S_IDLE;            // Basic Standby State
        else state = next_state;                // Change State in Negative Edge
    end

    // reg [14:0] echo_time;                       // Echo Pulse Width
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin
            next_state = S_IDLE;                // Basic Standby State
        end
        else begin
            case (state)
                S_IDLE   : begin                // Standby State
                    if (cnt_usec < 22'd200_000) begin   // Real 200_000, Test 1_000
                        cnt_usec_e = 1;         // us Count Enable
                    end
                    else begin
                        cnt_usec_e = 0;         // us Count Disable, Clear
                        next_state = S_TIRG_H;  // Change State S_TIRG_H
                    end
                end
                S_TIRG_H : begin                // Trig Pin High Signal Transmission
                    if (cnt_usec < 22'd10) begin    // Hold High Signal for 10us
                        cnt_usec_e = 1;         // us Count Enable
                        ultra_trig = 1;         // Trig Pin High Signal
                    end
                    else begin
                        cnt_usec_e = 0;         // us Count Disable, Clear
                        next_state = S_TIRG_L;  // Change State S_TIRG_L
                    end
                end
                S_TIRG_L : begin                // Trig Pin Low Signal Transmission
                    ultra_trig = 0;             // Trig Pin Low Signal
                    cnt_usec_e = 1;             // Count for Checking Response Time
                    if (cnt_usec > 22'd200_000) begin   // No Response 200ms, Error, Etc..
                        cnt_usec_e = 0;         // us Count Disable, Clear
                        next_state = S_IDLE;    // Change State S_IDLE
                    end
                    if (ultra_pedge) begin      // Check Echo High Signal
                        cnt_usec_e = 0;         // us Count Disable, Clear
                        div_usec_58_e = 1;      // Enable 58us Count
                        next_state = S_ECHO_H;  // Change State S_ECHO_H
                    end
                end
                S_ECHO_H : begin                // Echo Pin High Signal Reception
                    cnt_usec_e = 1;             // us Count Enable
                    if (cnt_usec > 22'd25_000) begin   // No Response 25ms, Error, Etc..
                        cnt_usec_e = 0;         // us Count Disable, Clear
                        div_usec_58_e = 0;      // 
                        next_state = S_IDLE;    // Change State S_IDLE
                    end
                    if (ultra_nedge) begin      // Check Echo Low Signal
                        // echo_time = cnt_usec;   // Echo Pulse Width Record, us
                        distance = cnt_dist;    // Distance Record
                        next_state = S_ECHO_L;  // Change State S_ECHO_L
                    end
                end
                S_ECHO_L : begin                // Echo Pin Low Signal Reception
                    cnt_usec_e = 0;             // us Count Disable, Clear
                    div_usec_58_e = 0;          // 58us Count Disable, Clear
                    // distance = echo_time / 58;  // Distance Calculation
                    next_state = S_IDLE;        // Change State S_IDLE
                end
                default  : next_state = S_IDLE; // Basic Stanby State
            endcase
        end
    end
endmodule

// 4 x 4 Keypad, FSM
module keypad_cntr (
    input clk, reset_p,
    input [3:0] row,                            // Input Row Values when Column is High
    output reg [3:0] col,                       // Output High Values by Changing Column
    output reg [3:0] key_value,                 // Output Values According to Row and Column Inputs
    output reg key_valid,                       // Key Input Flag
    output [15:0] led                           // for Debugging
    );

    // Change State Using Shift
    localparam SCAN_0       = 5'b00001;         // Check Row Value of 1st Column
    localparam SCAN_1       = 5'b00010;         // Check Row Value of 2nd Column
    localparam SCAN_2       = 5'b00100;         // Check Row Value of 3rd Column
    localparam SCAN_3       = 5'b01000;         // Check Row Value of 4th Column
    localparam KEY_PROCESS  = 5'b10000;         // When Key Input

    assign led[0] = key_valid;                  // Key Input LED Output
    assign led[4:1] = col;                      // Column LED Output
    assign led[8:5] = row;                      // Row LED Output

    reg [19:0] clk_10ms;                        // 2^20ns = 10_485_760ns, About 10ms
    always @(posedge clk) clk_10ms = clk_10ms + 1;

    wire clk_10ms_pedge, clk_10ms_nedge;
    // Edge Detection of 20th High-Order Clock bit
    edge_detector_pos ms_10_ed (.clk(clk), .reset_p(reset_p),
        .cp(clk_10ms[19]), .p_edge(clk_10ms_pedge), .n_edge(clk_10ms_nedge));

    // State Change Sequential Circuit
    reg [4:0] state, next_state;
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) state = SCAN_0;            // Basic Check 1st Column
        else if (clk_10ms_pedge) state = next_state;    // Change State when 10ms Positive Edge 
    end

    // State Processing Combinational Circuit
    always @* begin                             // All Variables Detection, Combinational Circuit
        case (state)
            SCAN_0      : begin                         // Check 1st Column
                if (row == 0) next_state = SCAN_1;      // Row Value 0 → Change State SCAN_1
                else next_state = KEY_PROCESS;          // Check High in Any Row → Change State KEY_PROCESS
            end
            SCAN_1      : begin                         // Check 2nd Column
                if (row == 0) next_state = SCAN_2;      // Row Value 0 → Change State SCAN_2
                else next_state = KEY_PROCESS;          // Check High in Any Row → Change State KEY_PROCESS
            end
            SCAN_2      : begin                         // Check 3rd Column
                if (row == 0) next_state = SCAN_3;      // Row Value 0 → Change State SCAN_3
                else next_state = KEY_PROCESS;          // Check High in Any Row → Change State KEY_PROCESS
            end
            SCAN_3      : begin                         // Check 4th Column
                if (row == 0) next_state = SCAN_0;      // Row Value 0 → Change State SCAN_0
                else next_state = KEY_PROCESS;          // Check High in Any Row → Change State KEY_PROCESS
            end
            KEY_PROCESS : begin                         // When Key Input
                if (row == 0) next_state = SCAN_0;      // Change Row Value 0 → Change State SCAN_0
                else next_state = KEY_PROCESS;          // Check High in Any Row → Maintain State KEY_PROCESS
            end
            default : next_state = SCAN_0;              // Basic Check 1st Column
        endcase
    end

    // Function Implementation Sequential Circuit
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin
            col = 4'b0001;                      // Basic 1st Column
            key_value = 0;                      // Key Value Reset
            key_valid = 0;                      // Key State Reset
        end
        else if (clk_10ms_nedge) begin          // Change Column of High Value when 10ms Negative Edge
            case (state)
                SCAN_0      : begin             // Check 1st Column
                    col = 4'b0001;              // 1st Column Output High
                    key_valid = 0;              // Basic Key Input Flag Clear
                end
                SCAN_1      : begin             // Check 2nd Column
                    col = 4'b0010;              // 2nd Column Output High
                    key_valid = 0;              // Basic Key Input Flag Clear
                end
                SCAN_2      : begin             // Check 3rd Column
                    col = 4'b0100;              // 3rd Column Output High
                    key_valid = 0;              // Basic Key Input Flag Clear
                end
                SCAN_3      : begin             // Check 4rd Column
                    col = 4'b1000;              // 4th Column Output High
                    key_valid = 0;              // Basic Key Input Flag Clear
                end
                KEY_PROCESS : begin             // When Key Input
                    key_valid = 1;              // Basic Key Input Flag Set
                    case ({row, col})           // Check Row and Column
                        8'b0001_0001 : key_value = 4'h0;    // S1
                        8'b0001_0010 : key_value = 4'h1;    // S2
                        8'b0001_0100 : key_value = 4'h2;    // S3
                        8'b0001_1000 : key_value = 4'h3;    // S4
                        8'b0010_0001 : key_value = 4'h4;    // S5
                        8'b0010_0010 : key_value = 4'h5;    // S6
                        8'b0010_0100 : key_value = 4'h6;    // S7
                        8'b0010_1000 : key_value = 4'h7;    // S8
                        8'b0100_0001 : key_value = 4'h8;    // S9
                        8'b0100_0010 : key_value = 4'h9;    // S10
                        8'b0100_0100 : key_value = 4'ha;    // S11
                        8'b0100_1000 : key_value = 4'hb;    // S12
                        8'b1000_0001 : key_value = 4'hc;    // S13
                        8'b1000_0010 : key_value = 4'hd;    // S14
                        8'b1000_0100 : key_value = 4'he;    // S15
                        8'b1000_1000 : key_value = 4'hf;    // S16
                    endcase
                end
            endcase
        end
    end
endmodule

// Input Address or Data, 100㎑ I2C Communication When Start-bit High
module i2c_master (
    input clk, reset_p,
    input [6:0] addr,                           // Slave Address
    input [7:0] data,                           // Transmission Data
    input rd_wr, comm_start,                    // Read & Write Select-bit, Communication Start-bit
    output reg scl, sda,                        // Serial Clock , Serial Data
                                                // Originally SDA Input + Output, but Here only Output
    output [15:0] led                           // for Debugging
    );

    // Change State Using Shift
    localparam I2C_IDLE     = 7'b000_0001;      // Standby State
    localparam COMM_START   = 7'b000_0010;      // Communication Start
    localparam SEND_ADDR    = 7'b000_0100;      // Address Transmission
    localparam READ_ACK     = 7'b000_1000;      // Read ACK-bit, Assume Read
    localparam SEND_DATA    = 7'b001_0000;      // Data Transmission
    localparam SCL_STOP     = 7'b010_0000;      // Stop Generate Serial Clock
    localparam COMM_STOP    = 7'b100_0000;      // Communication Stop

    // Clock Divide 100, 10ns x 100 = 1us
    wire clk_usec_nedge, clk_usec_pedge; // Divide Clock 1us
    clock_div_100 us_clk (.clk(clk), .reset_p(reset_p),
        .nedge_div_100(clk_usec_nedge), .pedge_div_100(clk_usec_pedge));

    // Edge Detection of Command Signal
    wire comm_start_pedge, comm_start_nedge;
    edge_detector_pos comm_start_ed (.clk(clk), .reset_p(reset_p),
        .cp(comm_start), .p_edge(comm_start_pedge), .n_edge(comm_start_nedge));

    // Edge Detection of SCL Signal
    wire scl_pedge, scl_nedge;
    edge_detector_pos scl_ed (.clk(clk), .reset_p(reset_p),
        .cp(scl), .p_edge(scl_pedge), .n_edge(scl_nedge));

    reg [2:0] cnt_usec5;                        // 5us Count
    reg scl_e;                                  // SCL Enable
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin
            cnt_usec5 = 0;                      // 5us Count Reset
            scl = 1;                            // SCL Reset, Pull-Up
        end
        else if (scl_e) begin                   // when SCL Enable
            if (clk_usec_nedge) begin           // when us Negative Edge
                if (cnt_usec5 >= 4) begin       // Every 5us 
                    cnt_usec5 = 0;              // 5us Count Reset
                    scl = ~scl;                 // Generate Serial Clock
                end
                else begin
                    cnt_usec5 = cnt_usec5 + 1;  // Count During Enable
                end
            end
        end
        else if (!scl_e) begin                  // SCL Disable
            cnt_usec5 = 0;                      // 5us Count Reset
            scl = 1;                            // SCL Reset, Pull-Up
        end
    end

    reg [6:0] state, next_state;                // Current & Next State
    always @(negedge clk, posedge reset_p) begin
        if (reset_p) state = I2C_IDLE;          // Basic Standby
        else state = next_state;                // Change State in Negative Edge
    end

    wire [7:0] addr_rd_wr;
    assign addr_rd_wr = {addr, rd_wr};          // Address + RW Select-bit
    reg [2:0] cnt_bit;                          // Count for Transmit 1-bit at a Time
    reg stop_flag;                              // Check Data Transmission
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin
            next_state = I2C_IDLE;              // Basic Standby
            scl_e = 0;                          // SCL Disable
            sda = 1;                            // SDA Reset, Pull-Up
            cnt_bit = 7;                        // bit Count Reset, from Upper bit
            stop_flag = 0;                      // Before Data Transmission
        end
        else begin
            case (state)
                I2C_IDLE   : begin              // Standby State
                    scl_e = 0;                  // SCL Disable
                    sda = 1;                    // SDA Reset, Pull-Up
                    if (comm_start_pedge) begin // Communication Start
                        next_state = COMM_START;    // Change State COMM_START
                    end
                end
                COMM_START : begin              // Communication Start
                    sda = 0;                    // SDA Start
                    scl_e = 1;                  // SCL Enable
                    next_state = SEND_ADDR;     // Change State SEND_ADDR
                end
                SEND_ADDR  : begin              // Address Transmission
                    if (scl_nedge) begin        // when SCL Negative Edge
                        sda = addr_rd_wr[cnt_bit];  // Enter Address into SDA
                    end
                    if (scl_pedge) begin        // when SCL Positive Edge
                        if (cnt_bit == 0) begin // Read to LSB
                            cnt_bit = 7;        // bit Count Reset
                            next_state = READ_ACK;  // Change State READ_ACK
                        end
                        else begin
                            cnt_bit = cnt_bit - 1;  // Read from MSB
                        end
                    end
                end
                READ_ACK   : begin              // Read ACK-bit, Assume Read
                    if (scl_nedge) begin        // when SCL Negative Edge
                        sda = 'bz; // Enter Inpedance Value into SDA, Disconnect
                    end
                    else if (scl_pedge) begin   // when SCL Positive Edge
                        if (stop_flag) begin    // Complete Data Transmission
                            stop_flag = 0;      // Data Transmission Flag Clear
                            next_state = SCL_STOP;  // Change State SCL_STOP
                        end
                        else begin              // Before Data Transmission
                            stop_flag = 1;      // Data Transmission Flag Set
                            next_state = SEND_DATA; // Change State SEND_DATA
                        end
                    end
                end
                SEND_DATA  : begin              // Data Transmission
                    if (scl_nedge) begin        // when SCL Negative Edge
                        sda = data[cnt_bit];    // Enter Data into SDA
                    end
                    if (scl_pedge) begin        // when SCL Positive Edge
                        if (cnt_bit == 0) begin // Read to LSB
                            cnt_bit = 7;        // bit Count Reset
                            next_state = READ_ACK;  // Change State READ_ACK
                        end
                        else begin
                            cnt_bit = cnt_bit - 1;  // Read from MSB
                        end
                    end
                end
                SCL_STOP   : begin              // Stop Generate Serial Clock
                    if (scl_nedge) sda = 0;     // SDA Low when SCL Negative Edge
                    if (scl_pedge) next_state = COMM_STOP;  // Change State COMM_STOP when SCL Positive Edge
                end
                COMM_STOP  : begin              // Communication Stop
                    if (cnt_usec5 >= 3) begin   // Wait 4us
                        scl_e = 0;              // SCL Disable
                        sda = 1;                // SDA Stop
                        next_state = I2C_IDLE;  // Change State I2C_IDLE
                    end
                end
                default    : begin
                    scl_e = 0;                  // SCL Disable
                    sda = 1;                    // SDA Reset, Pull-Up
                    next_state = I2C_IDLE;      // Basic Standby
                end
            endcase
        end
    end
endmodule

// Sending to LCD Using I2C Communication in Nibble(4-bit) Unit
module i2c_lcd_send_byte (
    input clk, reset_p,
    input [6:0] addr,                           // Slave Address
    input [7:0] send_buffer,                    // Transmission Data Buffer
    input send, rs,                             // Send Start-bit, Register Select
    output scl, sda,                            // Serial Clock , Serial Data
    output reg busy,                            // Communication Situation
    output [15:0] led                           // for Debugging
    );

    // Change State Using Shift
    localparam I2C_IDLE                 = 6'b00_0001;   // Standby State
    localparam SEND_HIGH_NIBBLE_DISABLE = 6'b00_0010;   // High Nibble(4-bit) Transmit in Enable Clear
    localparam SEND_HIGH_NIBBLE_ENABLE  = 6'b00_0100;   // Enable Set
    localparam SEND_LOW_NIBBLE_DISABLE  = 6'b00_1000;   // Low Nibble(4-bit) Transmit in Enable Clear
    localparam SEND_LOW_NIBBLE_ENABLE   = 6'b01_0000;   // Enable Set
    localparam SEND_DISABLE             = 6'b10_0000;   // Byte(8-bit) Transmission Complete

    reg [7:0] data;                             // 4-bit Unit Transmission, D7 ~ D4, BL, E, RW, RS
    reg comm_start;                             // Communication Start-bit

    // Clock Divide 100, 10ns x 100 = 1us
    wire clk_usec_nedge, clk_usec_pedge; // Divide Clock 1us
    clock_div_100 us_clk (.clk(clk), .reset_p(reset_p),
        .nedge_div_100(clk_usec_nedge), .pedge_div_100(clk_usec_pedge));

    // Edge Detection of Send Signal
    wire send_pedge, send_nedge;
    edge_detector_pos comm_start_ed (.clk(clk), .reset_p(reset_p),
        .cp(send), .p_edge(send_pedge), .n_edge(send_nedge));

    // us Unit Count
    reg [21:0] cnt_usec;                        // us Count
    reg cnt_usec_e;                             // us Count Enable
    always @(negedge clk, posedge reset_p) begin
        if (reset_p) cnt_usec = 0;              // Count Clear
        else if (clk_usec_nedge && cnt_usec_e) begin    // Count Start when Enable & us Negative Edge
            cnt_usec = cnt_usec + 1;            // Count During Enable
        end
        else if (!cnt_usec_e) cnt_usec = 0;     // Count Clear when Disable
    end

    // Using Module, Address & Data Transmission, I2C Communication
    i2c_master master (clk, reset_p, addr, data, 1'b0, comm_start, scl, sda);

    reg [5:0] state, next_state;                // Current & Next State
    always @(negedge clk, posedge reset_p) begin
        if (reset_p) state = I2C_IDLE;          // Basic Standby
        else state = next_state;                // Change State in Negative Edge
    end

    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin
            next_state = I2C_IDLE;              // Basic Standby
            comm_start = 0;                     // Communication Disable
            cnt_usec_e = 0;                     // us Count Disable, Clear
            data = 0;                           // Transmission Data Reset
            busy = 0;                           // Communication Available
        end
        else begin
            case (state)
                I2C_IDLE                 : begin    // Standby State
                    if (send_pedge) begin       // Send Start
                        next_state = SEND_HIGH_NIBBLE_DISABLE;  // Change State SEND_HIGH_NIBBLE_DISABLE
                        busy = 1;               // Communicating
                    end
                end
                SEND_HIGH_NIBBLE_DISABLE : begin    // High Nibble(4-bit) Transmit in Enable Clear
                    if (cnt_usec < 22'd200) begin   // About 200us Required to Complete Transmission
                        data = {send_buffer[7:4], 3'b100, rs};  // High Nibble Transmission
                        comm_start = 1;         // Communication Start
                        cnt_usec_e = 1;         // us Count Enable
                    end
                    else begin
                        cnt_usec_e = 0;         // us Count Disable, Clear
                        comm_start = 0;         // Communication Start-bit Clear
                        next_state = SEND_HIGH_NIBBLE_ENABLE;   // Change State SEND_HIGH_NIBBLE_ENABLE
                    end
                end
                SEND_HIGH_NIBBLE_ENABLE  : begin    // Enable Set
                    if (cnt_usec < 22'd200) begin   // About 200us Required to Complete Transmission
                        data = {send_buffer[7:4], 3'b110, rs};  // E Pin Enable
                        comm_start = 1;         // Communication Start
                        cnt_usec_e = 1;         // us Count Enable
                    end
                    else begin
                        cnt_usec_e = 0;         // us Count Disable, Clear
                        comm_start = 0;         // Communication Start-bit Clear
                        next_state = SEND_LOW_NIBBLE_DISABLE;   // Change State SEND_LOW_NIBBLE_DISABLE
                    end
                end
                SEND_LOW_NIBBLE_DISABLE  : begin    // Low Nibble(4-bit) Transmit in Enable Clear
                    if (cnt_usec < 22'd200) begin   // About 200us Required to Complete Transmission
                        data = {send_buffer[3:0], 3'b100, rs};  // Low Nibble Transmission
                        comm_start = 1;         // Communication Start
                        cnt_usec_e = 1;         // us Count Enable
                    end
                    else begin
                        cnt_usec_e = 0;         // us Count Disable, Clear
                        comm_start = 0;         // Communication Start-bit Clear
                        next_state = SEND_LOW_NIBBLE_ENABLE;    // Change State SEND_LOW_NIBBLE_ENABLE
                    end
                end
                SEND_LOW_NIBBLE_ENABLE   : begin    // Enable Set
                    if (cnt_usec < 22'd200) begin   // About 200us Required to Complete Transmission
                        data = {send_buffer[3:0], 3'b110, rs};  // E Pin Enable
                        comm_start = 1;         // Communication Start
                        cnt_usec_e = 1;         // us Count Enable
                    end
                    else begin
                        cnt_usec_e = 0;         // us Count Disable, Clear
                        comm_start = 0;         // Communication Start-bit Clear
                        next_state = SEND_DISABLE;  // Change State SEND_DISABLE
                    end
                end
                SEND_DISABLE             : begin    // Byte(8-bit) Transmission Complete
                    if (cnt_usec < 22'd200) begin   // About 200us Required to Complete Transmission
                        data = {send_buffer[7:4], 3'b100, rs};  // E Pin Disable
                        comm_start = 1;         // Communication Start
                        cnt_usec_e = 1;         // us Count Enable
                    end
                    else begin
                        cnt_usec_e = 0;         // us Count Disable, Clear
                        comm_start = 0;         // Communication Start-bit Clear
                        next_state = I2C_IDLE;  // Change State I2C_IDLE
                        busy = 0;               // Communication Available
                    end
                end
                default                  : begin
                    cnt_usec_e = 0;             // us Count Disable, Clear
                    comm_start = 0;             // Communication Start-bit Clear
                    next_state = I2C_IDLE;      // Basic Standby
                    busy = 0;                   // Communication Available
                end
            endcase
        end
    end
endmodule

// PWM Frequency Signal Output According to Duty Ratio
module pwm_Nstep (
    input clk, reset_p,
    input [31:0] duty,                          // PWM Duty Rate, CCR Capture Compare Register
    output reg pwm                              // PWM Duty Applied Pulse
    );

    parameter sys_clk_freq  = 100_000_000;      // System Clock Frequency
    parameter pwm_freq      = 10_000;           // PWM Frequency
    parameter duty_step_N   = 256;              // Duty Step, ARR Auto Reload Register
    parameter temp = sys_clk_freq / pwm_freq / duty_step_N / 2; // Half of Cycle

    integer cnt_sysclk;                         // System Clock Count
    reg pwm_freqXn;                             // PWM Frequency
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin
            cnt_sysclk = 0;                     // System Clock Count Reset
            pwm_freqXn = 0;                     // PWM Frequency Reset
        end
        else begin
            if (cnt_sysclk >= temp - 1) begin   // when Half of Cycle
                cnt_sysclk = 0;                 // System Clock Count Reset
                pwm_freqXn = ~pwm_freqXn;       // PWM Frequency Generation
            end
            else cnt_sysclk = cnt_sysclk + 1;   // Count System Clock
        end
    end

    // Edge Detection of PWM Frequency
    wire pwm_freqXn_nedge;                      // PWM Frequency Negative Edge
    edge_detector_pos pwm_freqXn_ed (.clk(clk), .reset_p(reset_p),
        .cp(pwm_freqXn), .n_edge(pwm_freqXn_nedge));

    integer cnt_duty;                           // PWM Frequency Count
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin
            cnt_duty = 0;                       // PWM Frequency Count Reset
            pwm = 0;                            // Pulse Reset
        end
        else if (pwm_freqXn_nedge) begin
            if (cnt_duty >= duty_step_N) cnt_duty = 0;  // Count to End of Duty
            else cnt_duty = cnt_duty + 1;       // Count PWM Frequency

            if (cnt_duty < duty) pwm = 1;       // Pulse High Until Duty
            else pwm = 0;                       // Pulse Low After Duty
        end
    end
endmodule

//
module stepper_cntr (
    input clk, reset_p,       
    input start_motor,              // 모터 구동 시작 신호, high일 때만 구동
    input motor_dir,                // 모터의 회전 방향 1'b1 = 시계 방향, 1'b0 = 반시계 방향
    output reg [3:0] motor_out,     // 모터 드라이버로 출력되는 4개의 신호 (IN1, IN2, IN3, IN4)
    output [15:0] led
    );

    reg [23:0] cnt_sysclk = 0;      //스텝 지연 시간을 제어하기 위한 카운터
    reg [2:0] step_index = 0;       //배열의 인덱스를 나타냄  0에서 7까지 반복하며 모터를 회전
    reg [3:0] half_step [7:0];      //8개의 하프 스텝 시퀀스를 배열로 정의

    initial begin
        half_step[0] = 4'b1000;
        half_step[1] = 4'b1100;
        half_step[2] = 4'b0100;
        half_step[3] = 4'b0110;
        half_step[4] = 4'b0010;
        half_step[5] = 4'b0011;
        half_step[6] = 4'b0001;
        half_step[7] = 4'b1001;
    end

    assign led[0] = start_motor;
    assign led[1] = motor_dir;
    assign led[5:2] = motor_out;
    always @(posedge clk or posedge reset_p) begin
        if (reset_p)begin
            cnt_sysclk <= 0;
            step_index <= 0;
            motor_out <= 4'b0000;
        end else begin
            if (start_motor) begin
                if (cnt_sysclk >= 200_000) begin
                    cnt_sysclk <= 0;
                    motor_out <= half_step[step_index];
                    if (motor_dir) begin // 시계 방향
                        if (step_index >= 7) step_index <= 0;
                        else step_index <= step_index + 1;
                    end
                    else begin // 반시계 방향
                        if (step_index <= 0) step_index <= 7;
                        else step_index <= step_index - 1;
                    end
                end
                else begin
                    cnt_sysclk <= cnt_sysclk + 1;
                end
            end
            else begin // 정지 동작 
                cnt_sysclk <= 0;
                step_index <= 0;
                motor_out <= 4'b0000;
            end
        end
    end
endmodule

//
module servo_cntr (
    input clk, reset_p,
    input [4:0] servo_mode,
    input servo_start,
    input [7:0] servo_angle,
    output servo,
    output reg [7:0] step,
    output [15:0] led
    );

    localparam IDLE     = 5'b00001;
    localparam ROUND    = 5'b00010;
    localparam ROUND_D  = 5'b00100;
    localparam ONEWAY_D = 5'b01000;
    localparam ONETIME  = 5'b10000;

    assign led[0] = servo_start;
    assign led[5:1] = servo_mode;

    integer cnt_servo;
    reg [3:0] cnt_delay;
    reg servo_dir = 1;
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            step <= 40;
            servo_dir <= 1;
            cnt_servo <= 0;
            cnt_delay <= 0;
        end
        else begin
            if (servo_start) begin
                if (cnt_servo >= 3_000_000) begin
                    cnt_servo <= 0;
                    case (servo_mode)
                        IDLE     : begin
                            if (step <= 40) servo_dir <= 1;
                            else step <= step - 1;
                        end
                        ROUND    : begin
                            if (servo_dir) begin
                                if (step >= (40 + servo_angle)) servo_dir <= 0;
                                else step <= step + 1;
                            end
                            else if (servo_dir == 0) begin
                                if (step <= 40) servo_dir <= 1;
                                else step <= step - 1;
                            end
                        end
                        ROUND_D  : begin
                            if (servo_dir) begin
                                if (step >= (40 + servo_angle)) servo_dir <= 0;
                                else if (step % 10 == 0) begin
                                    if (cnt_delay >= 10) begin
                                        cnt_delay <= 0;
                                        step <= step + 1;
                                    end
                                    else cnt_delay <= cnt_delay + 1;
                                end
                                else step <= step + 1;
                            end
                            else if (servo_dir == 0) begin
                                if (step <= 40) servo_dir <= 1;
                                else if (step % 10 == 0) begin
                                    if (cnt_delay >= 10) begin
                                        cnt_delay <= 0;
                                        step <= step - 1;
                                    end
                                    else cnt_delay <= cnt_delay + 1;
                                end
                                else step <= step - 1;
                            end
                        end
                        ONEWAY_D : begin
                            if (servo_dir) begin
                                if (step >= (40 + servo_angle)) servo_dir <= 0;
                                else if (step % 10 == 0) begin
                                    if (cnt_delay >= 10) begin
                                        cnt_delay <= 0;
                                        step <= step + 1;
                                    end
                                    else cnt_delay <= cnt_delay + 1;
                                end
                                else step <= step + 1;
                            end
                            else if (servo_dir == 0) begin
                                if (step <= 40) servo_dir <= 1;
                                else step <= step - 1;
                            end
                        end
                        ONETIME  : begin
                            if (step < (40 + servo_angle)) step <= step + 1;
                        end
                        default  : begin
                            if (step <= 40) servo_dir <= 1;
                            else step <= step - 1;
                        end
                    endcase
                end
                else begin
                    cnt_servo <= cnt_servo + 1;
                end
            end
            else if (!servo_start && servo_mode == ONETIME) begin
                if (cnt_servo >= 3_000_000) begin
                    cnt_servo <= 0;
                    if (step > 40) step <= step - 1;
                end
                else begin
                    cnt_servo <= cnt_servo + 1;
                end
            end
        end
    end

    pwm_Nstep #(.pwm_freq(50), .duty_step_N(1800)) pwm_servo (clk, reset_p, step, servo);
endmodule

// module rtc_read_cntr (
//     input clk, reset_p,
//     input read_req,             // 읽기 요청 신호
//     output reg rtc_clk,         // Serial Clock
//     inout wire rtc_dat,         // Serial I/O (양방향)
//     output reg rtc_rst,         // Reset/Chip Enable
//     output reg [7:0] sec, min, hour,            // Data BCD 출력
//     output reg [7:0] date, month, day, year,
//     output reg data_valid,       // 데이터 유효 신호
//     output reg busy              // 통신 중 신호
// );

//     localparam IDLE       = 8'b0000_0001;
//     localparam START      = 8'b0000_0010;
//     localparam CMD_WRITE  = 8'b0000_0100;
//     localparam TURNAROUND = 8'b0000_1000;
//     localparam DATA_READ  = 8'b0001_0000;
//     localparam STOP       = 8'b0010_0000;
//     localparam NEXT_REG   = 8'b0100_0000;
//     localparam DONE       = 8'b1000_0000;

//     // 내부 신호
//     reg [7:0] command_reg [0:6];
//     reg [2:0] reg_index;
//     reg [3:0] bit_cnt;
//     reg [7:0] shift_reg;
//     reg [7:0] read_data;
//     reg sio_dir;  // 0: input, 1: output
//     reg sio_out;
    
//     // SIO 양방향 제어
//     assign rtc_dat = sio_dir ? sio_out : 1'bz;
    
//     // 명령 레지스터 초기화
//     initial begin
//         command_reg[0] = 8'h81;     // 초 읽기 (0x81)
//         command_reg[1] = 8'h83;     // 분 읽기 (0x83)
//         command_reg[2] = 8'h85;     // 시 읽기 (0x85)
//         command_reg[3] = 8'h87;     // 일 읽기 (0x87)
//         command_reg[4] = 8'h89;     // 월 읽기 (0x89)
//         command_reg[5] = 8'h8B;     // 요일 읽기 (0x8B)
//         command_reg[6] = 8'h8D;     // 년 읽기 (0x8D)
//     end
    
//     reg [6:0] clk_div;
//     reg rtc_clk_en;
//     always @(posedge clk or posedge reset_p) begin
//         if (reset_p) begin
//             clk_div <= 0;
//             rtc_clk_en <= 0;
//         end
//         else begin
//             clk_div <= clk_div + 1;
//             rtc_clk_en <= (clk_div == 0);
//         end
//     end
    
//     reg [7:0] state, next_state;
    
//     // 상태 전이 및 제어 신호 처리 (통합 - 개선된 버전)
//     always @(posedge clk or posedge reset_p) begin
//         if (reset_p) begin
//             state <= IDLE;
//             rtc_clk <= 0;
//             rtc_rst <= 0;
//             sio_dir <= 0;
//             sio_out <= 0;
//             bit_cnt <= 0;
//             reg_index <= 0;
//             shift_reg <= 0;
//             read_data <= 0;
//             busy <= 0;
//             data_valid <= 0;
//             sec <= 0;
//             min <= 0;
//             hour <= 0;
//             date <= 0;
//             month <= 0;
//             day <= 0;
//             year <= 0;
//         end
//         else if (rtc_clk_en) begin
//             // 기본값 설정 (상태 유지)
//             next_state = state;
            
//             case (state)
//                 IDLE: begin
//                     rtc_rst <= 0;
//                     rtc_clk <= 0;
//                     sio_dir <= 0;
//                     busy <= 0;
//                     data_valid <= 0;
//                     if (read_req) begin
//                         busy <= 1;
//                         reg_index <= 0;
//                         next_state = START;
//                     end
//                 end
                
//                 START: begin
//                     rtc_rst <= 1;
//                     rtc_clk <= 0;
//                     sio_dir <= 1;
//                     bit_cnt <= 0;
//                     shift_reg <= command_reg[reg_index];
//                     next_state = CMD_WRITE;
//                 end
                
//                 CMD_WRITE: begin
//                     rtc_clk <= ~rtc_clk;
//                     if (!rtc_clk) begin  // falling edge에서 데이터 출력
//                         sio_out <= shift_reg[0];  // LSB first
//                         shift_reg <= {1'b0, shift_reg[7:1]};  // 오른쪽 시프트
//                         bit_cnt <= bit_cnt + 1;   // falling edge에서 비트 카운터 증가
//                         if (bit_cnt >= 7)  // 8비트 전송 완료 체크
//                             next_state = TURNAROUND;
//                     end
//                 end
                
//                 TURNAROUND: begin
//                     sio_dir <= 0;  // 입력 모드로 변경
//                     bit_cnt <= 0;
//                     rtc_clk <= 0;
//                     next_state = DATA_READ;
//                 end
                
//                 DATA_READ: begin
//                     rtc_clk <= ~rtc_clk;
//                     if (rtc_clk) begin   // rising edge에서 데이터 읽기
//                         read_data <= {read_data[6:0], rtc_dat};  // LSB first
//                         bit_cnt <= bit_cnt + 1;
//                         if (bit_cnt >= 7)  // 8비트 수신 완료
//                             next_state = STOP;
//                     end
//                 end
                
//                 STOP: begin
//                     rtc_rst <= 0;
//                     rtc_clk <= 0;
//                     case (reg_index)        // 읽은 데이터를 해당 레지스터에 저장
//                         0: sec <= read_data;    // 0x81: 초 읽기
//                         1: min <= read_data;    // 0x83: 분 읽기  
//                         2: hour <= read_data;   // 0x85: 시 읽기
//                         3: date <= read_data;   // 0x87: 일 읽기
//                         4: month <= read_data;  // 0x89: 월 읽기
//                         5: day <= read_data;    // 0x8B: 요일 읽기
//                         6: year <= read_data;   // 0x8D: 년 읽기
//                     endcase
//                     next_state = NEXT_REG;
//                 end
                
//                 NEXT_REG: begin
//                     reg_index <= reg_index + 1;
//                     if (reg_index >= 6)  // 마지막 레지스터(년도) 처리 후
//                         next_state = DONE;
//                     else
//                         next_state = START;
//                 end
                
//                 DONE: begin
//                     busy <= 0;
//                     data_valid <= 1;
//                     next_state = IDLE;
//                 end
                
//                 default: begin
//                     next_state = IDLE;
//                 end
//             endcase
            
//             // 상태 업데이트
//             state <= next_state;
//         end
//     end
// endmodule


module rtc_read_cntr (
    input clk, reset_p,
    input read_en,
    inout rtc_dat,
    output reg rtc_clk,
    output reg rtc_rst,
    output reg [7:0] sec, min, hour,
    output reg [7:0] date, month, day, year,
    output reg data_valid, busy
    );

    localparam IDLE       = 9'b0_0000_0001;
    localparam RST_SET    = 9'b0_0000_0010;
    localparam ADDR_IN    = 9'b0_0000_0100;
    localparam ADDR_SET   = 9'b0_0000_1000;
    localparam ADDR_RESET = 9'b0_0001_0000;
    localparam DATA_IN    = 9'b0_0010_0000;
    localparam DATA_SET   = 9'b0_0100_0000;
    localparam DATA_RESET = 9'b0_1000_0000;
    localparam RST_RESET  = 9'b1_0000_0000;

    reg rtc_dat_dir, rtc_dat_out;
    assign rtc_dat = rtc_dat_dir ? rtc_dat_out : 1'bz;

    reg [9:0] state, next_state;
    always @(negedge clk, posedge reset_p) begin
        if (reset_p) state = IDLE;
        else state = next_state;
    end

    reg [7:0] com_addr [0:6];
    initial begin
        com_addr[0] = 8'h81; // SEC
        com_addr[1] = 8'h83; // MIN
        com_addr[2] = 8'h85; // HOUR
        com_addr[3] = 8'h87; // DATE
        com_addr[4] = 8'h89; // MONTH
        com_addr[5] = 8'h8B; // DAY
        com_addr[6] = 8'h8D; // YEAR
    end

    reg [6:0] clk_div;
    reg sclk_en;
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin
            clk_div <= 0;
            sclk_en <= 0;
        end
        else begin
            clk_div <= clk_div + 1;
            sclk_en <= (clk_div == 0);
        end
    end

    reg [3:0] cnt_addr, cnt_bit;
    reg [7:0] buff_addr, buff_data;
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin
            rtc_rst = 0;
            next_state = IDLE;
            cnt_addr = 0;
            buff_addr = 0;
            buff_data = 0;
            rtc_clk = 0;
            rtc_dat_dir = 0;
            rtc_dat_out = 0;
            cnt_bit = 0;
            data_valid = 0;
            busy = 0;
        end
        else if (sclk_en) begin
            case (state)
                IDLE       : begin
                    rtc_rst = 0;
                    cnt_addr = 0;
                    rtc_clk = 0;
                    cnt_bit = 0;
                    buff_addr = 0;
                    buff_data = 0;
                    data_valid = 0;
                    if (read_en) begin
                        busy = 1;
                        next_state = RST_SET;
                    end
                end
                RST_SET    : begin
                    rtc_rst = 1;
                    rtc_clk = 0;
                    rtc_dat_dir = 1;
                    buff_addr = com_addr[cnt_addr];
                    next_state = ADDR_IN;
                end
                ADDR_IN    : begin
                    rtc_dat_out = buff_addr[0];
                    buff_addr = {1'b0, buff_addr[7:1]};
                    cnt_bit = cnt_bit + 1;
                    next_state = ADDR_SET;
                end
                ADDR_SET   : begin
                    rtc_clk = 1;
                    next_state = ADDR_RESET;
                end
                ADDR_RESET : begin
                    rtc_clk = 0;
                    if (cnt_bit >= 8) begin
                        cnt_bit = 0;
                        rtc_dat_dir = 0;
                        next_state = DATA_IN;
                    end
                    else next_state = ADDR_IN;
                end
                DATA_IN    : begin
                    buff_data = {rtc_dat, buff_data[7:1]};
                    cnt_bit = cnt_bit + 1;
                    next_state = DATA_SET;
                end
                DATA_SET   : begin
                    rtc_clk = 1;
                    next_state = DATA_RESET;
                end
                DATA_RESET : begin
                    rtc_clk = 0;
                    if (cnt_bit >= 8) begin
                        cnt_bit = 0;
                        next_state = RST_RESET;
                    end
                    else next_state = DATA_IN;
                end
                RST_RESET  : begin
                    rtc_rst = 0;
                    case (cnt_addr)
                        4'd0 : sec = buff_data;
                        4'd1 : min = buff_data;
                        4'd2 : hour = buff_data;
                        4'd3 : date = buff_data;
                        4'd4 : month = buff_data;
                        4'd5 : day = buff_data;
                        4'd6 : year = buff_data;
                    endcase
                    if (cnt_addr >= 6) begin
                        cnt_addr = 0;
                        data_valid = 1;
                        busy = 0;
                        next_state = IDLE;
                    end
                    else begin
                        cnt_addr = cnt_addr + 1;
                        next_state = RST_SET;
                    end
                end
            endcase
        end
    end
endmodule