module Uart_top#(
    parameter BAUD_RATE = 32'd9600,
    parameter CHECK_BIT = 1, // 0: NONE, 1: ODD, 2: EVEN
    parameter CLK_FREQ = 32'd50_000_000,
    parameter MODE = 1 // 0: HEX, 1: ASCII
) (
    input clk,
    input reset,
    input i_uart_rx,
    input [3:0] key_in,
    output o_uart_tx,
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
    wire [7:0] rx_data;
    wire [7:0] hex_data;
    reg  [63:0] data_buf;
    wire [3:0] key_out;
    wire [7:0] load_data;
    wire [7:0] read_data;
    wire tx_valid;
    wire rx_valid;
    wire read_ena, is_busy;

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

    
    ascii_to_hex u_ascii_to_hex(
        .ascii_in(rx_data),
        .o_hex 	 (hex_data  )
    );

    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : keyDecoder
            KeyDecoder keydecoder_inst(
                .clk(clk),
                .reset(reset),
                .key_in(key_in[i]),
                .key_out(key_out[i])
            );
        end
    endgenerate
        
    
    assign leds = hex_data;  
    assign load_data = (MODE == 0) ? hex_data : rx_data;
    always @(posedge clk) begin
        if (reset) begin
            data_buf <= 64'h0000_0000;
        end else if (rx_valid) begin
            data_buf <= {data_buf[55:0], hex_data}; 
        end
    end

    reg key_xor_0;
    wire can_load;
    always @(posedge clk) begin
        if (reset) begin
            key_xor_0 <= 1;
        end else begin
            key_xor_0 <= key_out[0];
        end
    end
    assign read_ena = (key_xor_0 == 1 && key_out[0] == 0); 
    FIFO #(
        .WIDTH(8),
        .DEPTH(256)
    ) fifo_inst (
        .clk(clk),
        .reset(reset),
        .i_data(load_data),
        .write_ena(rx_valid && can_load),
        .read_ena(read_ena),
        .tx_busy(is_busy),
        .o_data(read_data),
        .tx_valid(tx_valid),
        .can_load(can_load)
    );

    Uart_tx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .IS_PARITY(CHECK_BIT)
    ) uart_tx_inst(
        .reset(reset),
        .clk(clk),
        .i_valid(tx_valid),
        .i_data(read_data),
        .o_uart_tx(o_uart_tx),
        .o_busy(is_busy)
    );
    
    SegmentDecoder SegmentDecoder_inst (
        .clk(clk),
        .reset(reset),
        .load(data_buf),
        .DP_in(8'b0),
        .mode(8'b11111111), // 显示数字
        .graphData(64'b0),

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