module Counter_top(
    input clk,
    input reset,
    output SEGA,
    output SEGB,
    output SEGC,
    output SEGD,
    output SEGE,
    output SEGF,
    output SEGG,
    //output DP,

    /*output reg [7:0] segcom,
    output reg [6:0] seg,
    output wire [31:0] result,*/

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
    wire [31:0] result;
    wire enable;
    //wire [31:0] result;
    wire [3:0] digit1, digit2, digit3, digit4,
              digit5, digit6, digit7, digit8;
    reg [31:0] clkdivCounter;//clk分频
    reg [31:0] clkdivCounter2;
    reg [3:0] segSel;//位选
    reg [3:0] curDigit;//当前位显示数字

    Counter counter_inst (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .q(result)
    );

    always @(posedge clk) begin
        if (reset) begin
            clkdivCounter <= 32'd0;
            segSel <= 4'd1;
        end 
        else begin
            if(clkdivCounter == 32'd50)begin//50000000
                clkdivCounter <= 32'd0;
            end
            else begin
                clkdivCounter <= clkdivCounter + 1'b1;
            end

            if(clkdivCounter2 == 32'd5)begin//5000（太低了会出现"鬼影"）
                clkdivCounter2 <= 32'd0;
                if(segSel == 4'd8) begin
                    segSel <= 4'd1;
                end
                else begin
                    segSel <= segSel + 1'b1;
                end
            end
            else begin
                clkdivCounter2 <= clkdivCounter2 + 1'b1;
            end
        end
    end

    always@(*)begin
        case(segSel)
            4'd1: begin
                curDigit = digit1;
                segcom = 8'b11111110;
            end
            4'd2: begin 
                curDigit = digit2;
                segcom = 8'b11111101;
            end
            4'd3: begin 
                curDigit = digit3;
                segcom = 8'b11111011;
            end
            4'd4: begin
                curDigit = digit4;
                segcom = 8'b11110111;
            end
            4'd5: begin 
                curDigit = digit5;
                segcom = 8'b11101111;
            end
            4'd6: begin
                curDigit = digit6;
                segcom = 8'b11011111;
            end
            4'd7: begin 
                curDigit = digit7;
                segcom = 8'b10111111;
            end
            4'd8: begin 
                curDigit = digit8;
                segcom = 8'b01111111;
            end
            default: begin 
                curDigit = 4'd0;
                segcom = 8'b11111111; // all off
            end
        endcase

        case (curDigit)
        4'd0: seg = 7'b1000000; 
        4'd1: seg = 7'b1111001; 
        4'd2: seg = 7'b0100100; 
        4'd3: seg = 7'b0110000; 
        4'd4: seg = 7'b0011001; 
        4'd5: seg = 7'b0010010; 
        4'd6: seg = 7'b0000010; 
        4'd7: seg = 7'b1111000; 
        4'd8: seg = 7'b0000000; 
        4'd9: seg = 7'b0010000; 
        default: seg = 7'b1111111; // all off
    endcase

    end
    assign {digit8, digit7, digit6, digit5, digit4, digit3, digit2, digit1} = {
        result[31:28], result[27:24], result[23:20], result[19:16],
        result[15:12], result[11:8], result[7:4], result[3:0]
    };
    assign {SEGCOM1, SEGCOM2, SEGCOM3, SEGCOM4, SEGCOM5, SEGCOM6, SEGCOM7, SEGCOM8} = segcom;
    assign {SEGG, SEGF, SEGE, SEGD, SEGC, SEGB, SEGA} = seg;
    assign enable = (clkdivCounter == 32'd49);//49999999
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