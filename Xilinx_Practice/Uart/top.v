module top#(
    parameter BAUD_RATE = 9600,
    parameter CHECK_BIT = "NONE"

) (
    input clk,
    input reset,
    input [3:0] key_in,
    output [3:0]data_out
);
    Uart_rx Uart_rx_inst (
        .clk(clk),
        .reset(reset)
    );
endmodule