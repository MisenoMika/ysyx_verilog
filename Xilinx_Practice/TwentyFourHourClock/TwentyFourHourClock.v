module TwentyFourHourClock(
    input clk,
    input reset,
    input ena,
    output [7:0] hh,
    output [7:0] mm,
    output [7:0] ss
);  
    wire [2:1]en;
    assign en[1] = ss == {4'd5, 4'd9} && ena;//Minute
    assign en[2] = mm == {4'd5, 4'd9} && en[1];//Hour

    Counter60bit_1 Scounter (clk, reset, ena, ss);//Second
    Counter60bit_2 Mcounter (clk, reset, en[1], mm);//Minute
    Counte24bit Hcounter0 (clk, reset, en[2], hh);//Hour

endmodule

module Counter60bit_1(
    input clk,
    input reset,
    input enable,
    output reg [7:0] Q
);
    always@(posedge clk) begin
        if(reset) Q <= /*8'd0*/ {4'd4, 4'd5};
        else if(enable) begin
            if(Q == {4'd5, 4'd9}) Q <= 8'd0;
            else if(Q[3:0] == 4'd9) Q <= {Q[7:4]+4'd1, 4'd0};
            else Q <= Q + 8'd1;
        end
    end
endmodule

module Counter60bit_2(
    input clk,
    input reset,
    input enable,
    output reg [7:0] Q
);
    always@(posedge clk) begin
        if(reset) Q <= /*8'd0*/ {4'd5, 4'd8};
        else if(enable) begin
            if(Q == {4'd5, 4'd9}) Q <= 8'd0;
            else if(Q[3:0] == 4'd9) Q <= {Q[7:4]+4'd1, 4'd0};
            else Q <= Q + 8'd1;
        end
    end
endmodule

module Counte24bit(
    input clk,
    input reset,
    input enable,
    output reg [7:0] Q
);
    always@(posedge clk) begin
        if(reset) begin 
            Q <= {4'd2, 4'd3};
        end
        else if(enable) begin
            if(Q == {4'd2, 4'd3}) begin
                Q <= 8'd0;
            end
            else if(Q[3:0] == 4'd9) Q <= {Q[7:4]+4'd1, 4'd0};
            else Q <= Q + 8'd1;
        end
    end

endmodule