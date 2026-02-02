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