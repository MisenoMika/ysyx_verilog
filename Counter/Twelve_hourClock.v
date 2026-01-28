module top_module(
    input clk,
    input reset,
    input ena,
    output reg pm,
    output [7:0] hh,
    output [7:0] mm,
    output [7:0] ss
);  
    wire [2:1]en;
    assign en[1] = ss == {4'd5, 4'd9} && ena;//Minute
    assign en[2] = mm == {4'd5, 4'd9} && en[1];//Hour

    Counter60bit Scounter (clk, reset, ena, ss);//Second
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
