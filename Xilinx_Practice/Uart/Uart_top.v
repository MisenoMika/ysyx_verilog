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
    output reg o_uart_tx,
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
    wire [7:0] hex_data;
    wire       rx_valid;
    reg  [63:0] data_buf;
    reg [7:0] tx_buffer [0:255];
    wire [3:0] key_out;
    wire [7:0] load_data;
    wire [7:0] read_data;
    wire tx_valid;
    wire read_ena;
    always @(*) begin
        o_uart_tx = (key_out[0]) ? 1'b0 : 1'b1; // 按键按下时发送0，松开时发送1
    end
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
    assign load_data = (MODE == 1) ? hex_data : rx_data;
    always @(posedge clk) begin
        if (reset) begin
            data_buf <= 64'h0000_0000;
        end else if (rx_valid) begin
            data_buf <= {data_buf[55:0], load_data}; 
        end
    end

    reg read_ena_reg, key_xor_0;
    always @(posedge clk) begin
        if (reset) begin
            read_ena_reg <= 0;
            key_xor_0 <= 0;
        end else begin
            key_xor_0 <= key_out[0];
            if (tx_valid && key_xor_0 ^ key_out[0]) begin
                read_ena_reg <= 1; 
            end else begin
                read_ena_reg <= 0; 
            end
        end
    end
    assign read_ena = read_ena_reg;
    FIFO #(
        .WIDTH(8),
        .DEPTH(256)
    ) fifo_inst (
        .clk(clk),
        .reset(reset),
        .i_data(load_data),
        .write_ena(rx_valid),
        .read_ena(read_ena),
        .o_valid(tx_valid),
        .o_data(read_data)
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