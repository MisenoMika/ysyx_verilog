module Counter_top#(
    parameter WAIT_CYCLES = 32'd50_000 * 20 // 20ms
)(
    input clk,
    input reset,
    input key_in,
    output SEGA,
    output SEGB,
    output SEGC,
    output SEGD,
    output SEGE,
    output SEGF,
    output SEGG,
    output DP,

    output SEGCOM1,
    output SEGCOM2,
    output SEGCOM3,
    output SEGCOM4,
    output SEGCOM5,
    output SEGCOM6,
    output SEGCOM7,
    output SEGCOM8
);
    wire key_clean;
    wire [31:0] result;
    reg key_input;
    wire key_ena;
    always @(posedge clk) begin
        if(reset) begin
            key_input <= 1'b0;
        end
        else begin
            key_input <= key_clean;
        end
    end
    assign key_ena = (key_clean == 1'b1) && (key_input == 1'b0);
    Counter counter_inst (
        .clk(clk),
        .reset(reset),
        .enable(key_ena),
        .q(result)
    );
    SegmentDecoder segmentDecoder_inst (
        .clk(clk),
        .reset(reset),
        .load(result),
        .DP_in({ {6{1'b1}}, 1'b0, 1'b1 }), 
        .mode({8{1'b1}}), 
        .graphData(32'd0),
        .SEGA(SEGA),
        .SEGB(SEGB),
        .SEGC(SEGC),
        .SEGD(SEGD),
        .SEGE(SEGE),
        .SEGF(SEGF),
        .SEGG(SEGG),
        .DP_out(DP),
        .SEGCOM1(SEGCOM1),
        .SEGCOM2(SEGCOM2),
        .SEGCOM3(SEGCOM3),
        .SEGCOM4(SEGCOM4),
        .SEGCOM5(SEGCOM5),
        .SEGCOM6(SEGCOM6),
        .SEGCOM7(SEGCOM7),
        .SEGCOM8(SEGCOM8)
    );

    KeyDecoder #(
        .WAIT_CYCLES(WAIT_CYCLES)
    ) key_inst (
        .clk(clk),
        .reset(reset),
        .key_in(key_in),
        .key_out(key_clean)
    );
endmodule

module Counter (
    input clk,
    input reset,   // Synchronous active-high 
    input enable,
    output [31:0] q
    );

    wire [7:1] ena;
    bcdcount_4dig icounter0 (clk, reset, enable, q[3:0]);
    bcdcount_4dig icounter1 (clk, reset, ena[1], q[7:4]);
    bcdcount_4dig icounter2 (clk, reset, ena[2], q[11:8]);
    bcdcount_4dig icounter3 (clk, reset, ena[3], q[15:12]);
    bcdcount_4dig icounter4 (clk, reset, ena[4], q[19:16]);
    bcdcount_4dig icounter5 (clk, reset, ena[5], q[23:20]);
    bcdcount_4dig icounter6 (clk, reset, ena[6], q[27:24]);
    bcdcount_4dig icounter7 (clk, reset, ena[7], q[31:28]);

    assign ena[1] = (q[3:0] == 4'd9) && enable;
    assign ena[2] = (q[7:4] == 4'd9) && ena[1];
    assign ena[3] = (q[11:8] == 4'd9) && ena[2];
    assign ena[4] = (q[15:12] == 4'd9) && ena[3];
    assign ena[5] = (q[19:16] == 4'd9) && ena[4];
    assign ena[6] = (q[23:20] == 4'd9) && ena[5];
    assign ena[7] = (q[27:24] == 4'd9) && ena[6];
    //假设周期为1时，q==8，则下个周期ena==1，q==9，再下一个周期ena==0,q==0，因此ena变化的条件为最低位的q==8
    //Update: 其实ena最好用assign驱动
endmodule

module bcdcount_4dig (
	input clk,
	input reset,
	input enable,
	output reg [3:0] Q
);
    always @(posedge clk)begin
        if (reset)begin
            Q <= 4'd0;
        end
        else if (enable) begin
            if (Q == 4'd9)
                Q <= 4'd0;
            else
                Q <= Q + 4'd1;
        end

    end
endmodule

module SegmentDecoder(
    input clk,
    input reset,
    input [31:0]load,
    input [7:0] DP_in,
    input [7:0] mode, // 1显示数字，0显示图形
    input [31:0] graphData,

    output SEGA,
    output SEGB,
    output SEGC,
    output SEGD,
    output SEGE,
    output SEGF,
    output SEGG,
    output reg DP_out,


    output SEGCOM1,
    output SEGCOM2,
    output SEGCOM3,
    output SEGCOM4,
    output SEGCOM5,
    output SEGCOM6,
    output SEGCOM7,
    output SEGCOM8
);
    reg [7:0] segcom;
    reg [6:0] seg;
    wire [3:0] digit1, digit2, digit3, digit4,
              digit5, digit6, digit7, digit8;
    reg [3:0] segSel;//位选
    reg [3:0] curDigit;//当前位显示数字
    reg [31:0] clkdivCounter;
    //将32位二进制数拆分为8个十六进制数
    assign digit1 = (mode[0])? load[3:0] : graphData[3:0];
    assign digit2 = (mode[1])? load[7:4] : graphData[7:4];
    assign digit3 = (mode[2])? load[11:8] : graphData[11:8];         
    assign digit4 = (mode[3])? load[15:12] : graphData[15:12];   
    assign digit5 = (mode[4])? load[19:16] : graphData[19:16];
    assign digit6 = (mode[5])? load[23:20] : graphData[23:20];
    assign digit7 = (mode[6])? load[27:24] : graphData[27:24];
    assign digit8 = (mode[7])? load[31:28] : graphData[31:28];

    always @(posedge clk) begin
        if(clkdivCounter == 32'd5000)begin//5000（太低了会出现"鬼影"）
            clkdivCounter <= 32'd0;
            if(segSel == 4'd8) begin
                segSel <= 4'd1;
            end
            else begin
                segSel <= segSel + 1'b1;
            end
        end
        else begin
            clkdivCounter <= clkdivCounter + 1'b1;
        end
    end
    // 驱动数码管显示（哪一位）
    always @(*) begin
        case(segSel)
            4'd1: begin
                DP_out = DP_in[0];
                curDigit = digit1;
                segcom = 8'b11111110;
            end
            4'd2: begin 
                DP_out = DP_in[1];
                curDigit = digit2;
                segcom = 8'b11111101;
            end
            4'd3: begin 
                DP_out = DP_in[2];
                curDigit = digit3;
                segcom = 8'b11111011;
            end
            4'd4: begin
                DP_out = DP_in[3];
                curDigit = digit4;
                segcom = 8'b11110111;
            end
            4'd5: begin 
                DP_out = DP_in[4];
                curDigit = digit5;
                segcom = 8'b11101111;
            end
            4'd6: begin
                DP_out = DP_in[5];
                curDigit = digit6;
                segcom = 8'b11011111;
            end
            4'd7: begin 
                DP_out = DP_in[6];
                curDigit = digit7;
                segcom = 8'b10111111;
            end
            4'd8: begin 
                DP_out = DP_in[7];
                curDigit = digit8;
                segcom = 8'b01111111;
            end
            default: begin 
                DP_out = 1'b1;
                curDigit = 4'd0;
                segcom = 8'b11111111; // all off
            end
        endcase
    end
    // 驱动数码管显示（显示内容）
    always @(*) begin
        if(reset) begin
            seg = 7'b1000000; // 0
        end
        else begin
            if(mode[segSel-1] == 1'b1) begin
                case (curDigit)
                    4'd0: seg = 7'b1000000; // 0
                    4'd1: seg = 7'b1111001; // 1
                    4'd2: seg = 7'b0100100; // 2
                    4'd3: seg = 7'b0110000; // 3
                    4'd4: seg = 7'b0011001; // 4
                    4'd5: seg = 7'b0010010; // 5
                    4'd6: seg = 7'b0000010; // 6
                    4'd7: seg = 7'b1111000; // 7
                    4'd8: seg = 7'b0000000; // 8
                    4'd9: seg = 7'b0010000; // 9
                    4'd10: seg = 7'b0001000; // A
                    4'd11: seg = 7'b0000011; // b
                    4'd12: seg = 7'b1000110; // C
                    4'd13: seg = 7'b0100001; // d
                    4'd14: seg = 7'b0000110; // E
                    4'd15: seg = 7'b0001110; // F
                    default: seg = 7'b1111111; // all off
                endcase
            end
            else begin
                case(curDigit)
                    4'd0: seg = 7'b1111111; // off
                    4'd1: seg = 7'b0111111; // "--"
                    4'd2: seg = 7'b1111111; // off
                    4'd3: seg = 7'b1111111; // off
                    4'd4: seg = 7'b1111111; // off
                    4'd5: seg = 7'b1111111; // off
                    4'd6: seg = 7'b1111111; // off
                    4'd7: seg = 7'b1111111; // off
                    4'd8: seg = 7'b1111111; // off
                    4'd9: seg = 7'b1111111; // off
                    4'd10: seg = 7'b1111111; // off
                    4'd11: seg = 7'b1111111; // off
                    4'd12: seg = 7'b1111111; // off
                    4'd13: seg = 7'b1111111; // off
                    4'd14: seg = 7'b1111111; // off
                    4'd15: seg = 7'b1111111; // off
                    default: seg = 7'b1111111; // all off
                endcase
            end
        end
    end

    assign {SEGCOM1, SEGCOM2, SEGCOM3, SEGCOM4, SEGCOM5, SEGCOM6, SEGCOM7, SEGCOM8} = segcom;
    assign {SEGG, SEGF, SEGE, SEGD, SEGC, SEGB, SEGA} = seg;

endmodule


module KeyDecoder #(
    parameter WAIT_CYCLES = 32'd50_000 * 20
)(
    input clk,
    input reset,
    input key_in,
    output key_out
);
    parameter IDLE = 3'b000, WAIT = 3'b010, CONFIRM = 3'b100;
    reg [2:0] state, next_state;
    reg [31:0]counter;
    always@(*) begin
        case(state)
            IDLE: begin
                if(key_in == 0) begin
                    next_state = WAIT;
                end
                else begin
                    next_state = IDLE;
                end
            end

            WAIT: begin
                if(key_in == 1) begin
                    next_state = IDLE;
                end
                else if(counter >= WAIT_CYCLES-1) begin
                    next_state = CONFIRM;
                end
                else begin
                    next_state = WAIT;
                end
            end

            CONFIRM: begin
                if(key_in == 1) begin
                    next_state = IDLE;
                end
                else begin
                    next_state = CONFIRM;
                end
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    always@(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            counter <= 0;
        end 
        else begin
            state <= next_state;
            if(state == WAIT) begin
                counter <= counter + 1'd1;
            end
            else begin
                counter <= 0;
            end
        end
    end
    assign key_out = (state == CONFIRM);
endmodule