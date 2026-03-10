`timescale 1ns/1ps

module Uart_top_tb;

    localparam integer CLK_FREQ_HZ   = 32'd50_000_000;
    localparam integer BAUD_RATE_HZ  = 32'd9600;
    localparam integer CLK_PERIOD_NS = 20;
    localparam integer BAUD_BIT_CLKS = CLK_FREQ_HZ / BAUD_RATE_HZ;

    reg clk;
    reg reset;
    reg i_uart_rx;
    wire [7:0] leds;

    Uart_top #(
        .BAUD_RATE(BAUD_RATE_HZ),
        .CHECK_BIT(1),
        .CLK_FREQ(CLK_FREQ_HZ)
    ) Uart_top_inst (
        .clk(clk),
        .reset(reset),
        .i_uart_rx(i_uart_rx),
        .leds(leds)
    );

    task send_uart_byte(input [7:0] data);
        integer i;
        reg parity_bit; 
        begin
            parity_bit = ~(^data); 

            i_uart_rx = 1'b0; // start
            #(BAUD_BIT_CLKS * CLK_PERIOD_NS);

            for(i = 0; i < 8; i = i + 1) begin
                i_uart_rx = data[i]; 
                #(BAUD_BIT_CLKS * CLK_PERIOD_NS);
            end

            i_uart_rx = parity_bit; 
            #(BAUD_BIT_CLKS * CLK_PERIOD_NS);

            i_uart_rx = 1'b1; // stop
            #(BAUD_BIT_CLKS * CLK_PERIOD_NS);
        end
    endtask

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        i_uart_rx = 1'b1;

        #100;
        reset = 1'b0;
        #100;
        // Send 8 bytes: 1,2,3,4,5,6,7,8
        send_uart_byte(8'b0000_0111); // '7'
        send_uart_byte(8'b0000_0001); // '1'
        send_uart_byte(8'b0000_0010); // '2'
        send_uart_byte(8'b0000_0011); // '3'
        send_uart_byte(8'b0000_0100); // '4'
        send_uart_byte(8'b0000_0101); // '5'
        send_uart_byte(8'b0000_0110); // '6'
        send_uart_byte(8'b0000_0111); // '7'
        send_uart_byte(8'b0000_1000); // '8'
        #1000;
        $stop;
    end
    always #(CLK_PERIOD_NS/2) clk = ~clk;
endmodule