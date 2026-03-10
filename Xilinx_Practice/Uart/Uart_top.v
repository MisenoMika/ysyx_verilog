module Uart_top#(
    parameter BAUD_RATE = 32'd9600,
    parameter CHECK_BIT = 1,
    parameter CLK_FREQ = 32'd50_000_000
) (
    input clk,
    input reset,
    input i_uart_rx,
    input [3:0] key_in,
    output uart_tx,
    output SEGA,
    output SEGB,
    output SEGC,
    output SEGD,
    output SEGE,
    output SEGF,
    output SEGG,
    output DP,

    output SEGCOM1,
    output SEGCOM2,
    output SEGCOM3,
    output SEGCOM4,
    output SEGCOM5,
    output SEGCOM6,
    output SEGCOM7,
    output SEGCOM8,
    output [7:0]leds
);
    wire [3:0] key_clean;
    wire [7:0] rx_data;
    wire       rx_valid;
    reg  [63:0] data_buf;
    reg [7:0] tx_buffer [0:255];

    assign uart_tx = 1'b1; // TODO: 实现uart_tx
    always @(posedge clk or posedge reset) begin
        if(reset)begin
            tx_buffer[0]<="H";
            tx_buffer[1]<="E";
            tx_buffer[2] <= "L";
            tx_buffer[3]<= "L";
            tx_buffer[4] <= "o";
        end
    end

    Uart_rx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .IS_PARITY(CHECK_BIT)
    ) Uart_rx_inst (
        .clk(clk),
        .reset(reset),
        .i_uart_rx(i_uart_rx),
        .o_data(rx_data),
        .o_valid(rx_valid)
    );

    // output declaration of module KeyDecoder
    wire key_out;
    
    KeyDecoder KeyDecoder_inst (
        .clk(clk),
        .reset(reset),
        .key_in(key_in[0]),
        .key_out(key_out)
    );
    
    assign leds = rx_data;  
    always @(posedge clk) begin
        if (reset) begin
            data_buf <= 32'h0000_0000;
        end else if (rx_valid) begin
            data_buf <= {rx_data, data_buf[63:8]}; 
        end
    end

    SegmentDecoder SegmentDecoder_inst (
        .clk(clk),
        .reset(reset),
        .load(data_buf),
        .DP_in(8'b0),
        .mode(8'b11111111), // 显示数字
        .graphData(32'b0),

        .SEGA(SEGA),
        .SEGB(SEGB),
        .SEGC(SEGC),
        .SEGD(SEGD),
        .SEGE(SEGE),
        .SEGF(SEGF),
        .SEGG(SEGG),
        .DP_out(DP),

        .SEGCOM1(SEGCOM1),
        .SEGCOM2(SEGCOM2),
        .SEGCOM3(SEGCOM3),
        .SEGCOM4(SEGCOM4),
        .SEGCOM5(SEGCOM5),
        .SEGCOM6(SEGCOM6),
        .SEGCOM7(SEGCOM7),
        .SEGCOM8(SEGCOM8)
    );
endmodule