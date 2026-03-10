module Parity (
    input clk,
    input reset,
    input [7:0] in,
    output reg odd);

    always @(posedge clk)
        if (reset) odd <= 0;
        else if (in) odd <= ^in; // 奇偶校验
endmodule