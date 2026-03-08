module Uart_rx #(
    parameter  CLK_FREQ  = 50_000_000,  
    parameter  BAUD_RATE = 9600,       // Unit : Hz
    parameter  PARITY    = "NONE"       // "NONE", "ODD", or "EVEN"
    //parameter  FIFO_EA   = 0             // 0:no fifo   1,2:depth=4   3:depth=8   4:depth=16  ...  10:depth=1024   11:depth=2048  ...
) (
    input  reset,
    input  clk,
    input  i_uart_rx,
    input  o_tready,
    output reg  [7:0] o_tdata,
    // report whether there's a overflow
    output reg         o_overflow
);


endmodule