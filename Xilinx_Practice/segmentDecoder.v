module SegmentDecoder(
    input clk,
    input reset,
    input [63:0]load,
    input [7:0] DP_in,
    input [7:0] mode, // 1显示数字，0显示图形
    input [63:0] graphData,

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
    wire [7:0] digit1, digit2, digit3, digit4,
              digit5, digit6, digit7, digit8;
    reg [3:0] segSel;//位选
    reg [7:0] curDigit;//当前位显示数字
    reg [31:0] clkdivCounter;
    //将32位二进制数拆分为8个十六进制数
    assign digit1 = (mode[0] == 1'b1) ? load[7:0] : graphData[7:0];
    assign digit2 = (mode[1] == 1'b1) ? load[15:8] : graphData[15:8];
    assign digit3 = (mode[2] == 1'b1) ? load[23:16] : graphData[23:16];
    assign digit4 = (mode[3] == 1'b1) ? load[31:24] : graphData[31:24];
    assign digit5 = (mode[4] == 1'b1) ? load[39:32] : graphData[39:32];
    assign digit6 = (mode[5] == 1'b1) ? load[47:40] : graphData[47:40];
    assign digit7 = (mode[6] == 1'b1) ? load[55:48] : graphData[55:48];
    assign digit8 = (mode[7] == 1'b1) ? load[63:56] : graphData[63:56];

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
                segcom = 8'b11111111; // off
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
                    8'd0: seg = 7'b1000000; // 0
                    8'd1: seg = 7'b1111001; // 1
                    8'd2: seg = 7'b0100100; // 2
                    8'd3: seg = 7'b0110000; // 3
                    8'd4: seg = 7'b0011001; // 4
                    8'd5: seg = 7'b0010010; // 5
                    8'd6: seg = 7'b0000010; // 6
                    8'd7: seg = 7'b1111000; // 7
                    8'd8: seg = 7'b0000000; // 8
                    8'd9: seg = 7'b0010000; // 9
                    8'd10: seg = 7'b0001000; // A
                    8'd11: seg = 7'b0000011; // b
                    8'd12: seg = 7'b1000110; // C
                    8'd13: seg = 7'b0100001; // d
                    8'd14: seg = 7'b0000110; // E
                    8'd15: seg = 7'b0001110; // F
                    
                    8'd16: seg = 7'b0001001; // H
                    8'd17: seg = 7'b0000111; // L
                    8'd19: seg = 7'b1000111; // P
                    8'd20: seg = 7'b0001100; // U
                    
                    default: seg = 7'b1111111; // all off
                endcase
            end
            else begin
                case(curDigit)
                    8'd0: seg = 7'b1111111; // off
                    8'd1: seg = 7'b0111111; // "--"
                    8'd2: seg = 7'b1111111; // off
                    8'd3: seg = 7'b1111111; // off
                    8'd4: seg = 7'b1111111; // off
                    8'd5: seg = 7'b1111111; // off
                    8'd6: seg = 7'b1111111; // off
                    8'd7: seg = 7'b1111111; // off
                    8'd8: seg = 7'b1111111; // off
                    8'd9: seg = 7'b1111111; // off
                    8'd10: seg = 7'b1111111; // off
                    8'd11: seg = 7'b1111111; // off
                    8'd12: seg = 7'b1111111; // off
                    8'd13: seg = 7'b1111111; // off
                    8'd14: seg = 7'b1111111; // off
                    8'd15: seg = 7'b1111111; // off
                    default: seg = 7'b1111111; // all off
                endcase
            end
        end
    end

    assign {SEGCOM1, SEGCOM2, SEGCOM3, SEGCOM4, SEGCOM5, SEGCOM6, SEGCOM7, SEGCOM8} = segcom;
    assign {SEGG, SEGF, SEGE, SEGD, SEGC, SEGB, SEGA} = seg;

endmodule