`timescale 1ns/1ps

module breath_led_tb();
    reg clk;
    reg reset;
    wire [7:0] leds;

    breath_led_top u_breath_led_top(
        .clk     	(clk      ),
        .reset   	(reset    ),
        .leds    	(leds     )
    );

    always #10 clk = ~clk; 
    initial begin
        clk = 0;
        reset = 1;
        
        #100 reset = 0;
        #100000 $finish;
        
    end
endmodule