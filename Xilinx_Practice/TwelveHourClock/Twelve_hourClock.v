module Clock_top(
    input clk,
    input reset,
    //input [31:0]load,

    output SEGA,
    output SEGB,
    output SEGC,
    output SEGD,
    output SEGE,
    output SEGF,
    output SEGG,
    //output DP,


    output SEGCOM1,
    output SEGCOM2,
    output SEGCOM3,
    output SEGCOM4,
    output SEGCOM5,
    output SEGCOM6,
    output SEGCOM7,
    output SEGCOM8
);
    wire [31:0] load;
    wire enable;
    reg [7:0] segcom;
    reg [6:0] seg;
    wire [3:0] digit1, digit2, digit3, digit4,
              digit5, digit6, digit7, digit8;
    reg [3:0] segSel;//位选
    reg [3:0] curDigit;//当前位显示数字
    reg [31:0] clkdivCounter;
    reg [31:0] clkdivCounter2;
    TwelvwHourClock clock_inst (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .time_load(load)
    );
    //将32位二进制数拆分为8个十六进制数
    assign digit1 = load[3:0];
    assign digit2 = load[7:4];
    assign digit3 = load[11:8];
    assign digit4 = load[15:12];
    assign digit5 = load[19:16];
    assign digit6 = load[23:20];
    assign digit7 = load[27:24];
    assign digit8 = load[31:28];

    assign enable = (clkdivCounter2 == 32'd4999999);//49999999
    always @(posedge clk) begin
        if (reset) begin
            clkdivCounter <= 32'd0;
            clkdivCounter2 <= 32'd0;
            segSel <= 4'd1;
        end 
        else begin
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

            if(clkdivCounter2 == 32'd5000000)begin//50000000
                clkdivCounter2 <= 32'd0;
            end
            else begin
                clkdivCounter2 <= clkdivCounter2 + 1'b1;
            end
        end
    end

    always @(*) begin
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
    end

    always @(*) begin
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

    assign {SEGCOM1, SEGCOM2, SEGCOM3, SEGCOM4, SEGCOM5, SEGCOM6, SEGCOM7, SEGCOM8} = segcom;
    assign {SEGG, SEGF, SEGE, SEGD, SEGC, SEGB, SEGA} = seg;



endmodule

module TwelvwHourClock(
    input clk,
    input reset,
    input enable,
    output [31:0] time_load
);  
    reg pm;
    wire [7:0] hh;
    wire [7:0] mm;
    wire [7:0] ss;
    wire [2:1]en;
    assign en[1] = ss == {4'd5, 4'd9} && enable;//Minute
    assign en[2] = mm == {4'd5, 4'd9} && en[1];//Hour

    Counter60bit Scounter (clk, reset, enable, ss);//Second
    Counter60bit Mcounter (clk, reset, en[1], mm);//Minute
    Counter12bit Hcounter0 (clk, reset, en[2], hh);//Hour

    always @(posedge clk) begin 
        if (reset) begin
            pm <= 0;
        end 
        else if(en[2] && hh == {4'd1, 4'd1}) begin
            pm <= ~pm;
        end
    end
    assign time_load = {hh, mm, ss};
endmodule

module Counter60bit(
    input clk,
    input reset,
    input enable,
    output reg [7:0] Q
);
    always@(posedge clk) begin
        if(reset) Q <= 8'd0;
        else if(enable) begin
            if(Q == {4'd5, 4'd9}) Q <= 8'd0;
            else if(Q[3:0] == 4'd9) Q <= {Q[7:4]+4'd1, 4'd0};
            else Q <= Q + 8'd1;
        end
    end
endmodule

module Counter12bit(
    input clk,
    input reset,
    input enable,
    output reg [7:0] Q
);
    always@(posedge clk) begin
        if(reset) begin 
            Q <= {4'd1, 4'd2};
        end
        else if(enable) begin
            if(Q == {4'd1, 4'd2}) begin
                Q <= 8'd1;
            end
            else if(Q[3:0] == 4'd9) Q <= {Q[7:4]+4'd1, 4'd0};
            else Q <= Q + 8'd1;
        end
    end

endmodule