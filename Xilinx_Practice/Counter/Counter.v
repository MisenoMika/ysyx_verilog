module Counter(
    input clk,
    input enable,
    input reset,
    output SEGA,
    output SEGB,
    output SEGC,
    output SEGD,
    output SEGE,
    output SEGF,
    output SEGG,
    output DP,

    output [7:0] bcd,
    output reg [7:0] segcom,
    output reg [2:0] segSel,
    output reg [3:0] clkdivCounter,

    output SEGCOM1,
    output SEGCOM2,
    output SEGCOM3,
    output SEGCOM4,
    output SEGCOM5,
    output SEGCOM6,
    output SEGCOM7,
    output SEGCOM8
);
    parameter ONE = 3'b000, TWO = 3'b001, THREE = 3'b010, FOUR = 3'b011,
              FIVE = 3'b100, SIX = 3'b101, SEVEN = 3'b110, EIGHT = 3'b111;
    reg [6:0] seg;
    reg [3:0] digit1, digit2, digit3, digit4,
              digit5, digit6, digit7, digit8;
    reg [7:0] enableDigit;
    bcdcounter counter_inst (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .Q(bcd)
    );
    always@(*)begin
        case(bcd)
            4'd0: seg = 7'b0000001;
            4'd1: seg = 7'b1001111;
            4'd2: seg = 7'b0010010;
            4'd3: seg = 7'b0000110;
            4'd4: seg = 7'b1001100;
            4'd5: seg = 7'b0100100;
            4'd6: seg = 7'b0100000;
            4'd7: seg = 7'b0001111;
            4'd8: seg = 7'b0000000;
            4'd9: seg = 7'b0000100;
            default: seg = 7'b1111111; // all off
        endcase
        case(segSel)
            ONE: begin
                segcom[0] = 1'b0;
            end
            TWO: segcom[1] = 1'b0;
            THREE: segcom[2] = 1'b0;
            FOUR: segcom[3] = 1'b0;
            FIVE: segcom[4] = 1'b0;
            SIX: segcom[5] = 1'b0;
            SEVEN: segcom[6] = 1'b0;
            EIGHT: segcom[7] = 1'b0;
            default: segcom = 8'b11111111; // all off
        endcase
    end

    always@(posedge clk) begin
        if (reset) begin
            segSel <= ONE;
            clkdivCounter <= 4'd0;
        end 
        else begin
            clkdivCounter <= clkdivCounter + 1'b1;
            if(segSel == EIGHT) begin
                segSel <= ONE;
            end
            else begin
                segSel <= segSel + 1'b1;
            end
        end
    end
    
    assign {SEGA, SEGB, SEGC, SEGD, SEGE, SEGF, SEGG} = seg; 
    assign {SEGCOM1, SEGCOM2, SEGCOM3, SEGCOM4, SEGCOM5, SEGCOM6, SEGCOM7, SEGCOM8} = segcom;

endmodule

module bcdcounter(
    input clk,
    input reset,
    input enable,
    output reg [7:0] Q
);
    always@(posedge clk) begin
        if (reset) begin
            Q <= 4'd0;
        end 
        else if (enable) begin
            Q <= Q + 1'b1;
        end
    end
endmodule