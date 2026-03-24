`timescale 1ns / 1ps

module EEPROM_driver_tb;


    localparam WAIT_CYCLES = 32'd50 * 20;
    localparam WAIT_X2 = WAIT_CYCLES * 2 * 20;
    // output declaration of module EEPROM_driver
    reg clk;
    reg reset;
    reg [3:0] key_in;
    wire i2c_sda;
    wire i2c_scl;
    wire SEGA;
    wire SEGB;
    wire SEGC;
    wire SEGD;
    wire SEGE;
    wire SEGF;
    wire SEGG;
    wire DP;
    wire SEGCOM1;
    wire SEGCOM2;
    wire SEGCOM3;
    wire SEGCOM4;
    wire SEGCOM5;
    wire SEGCOM6;
    wire SEGCOM7;
    wire SEGCOM8;
    
    EEPROM_driver #(
        .CLK_FREQ 	(32'd50_000_000  ),
        .I2C_FREQ 	(32'd400_000     ),
        .WAIT_CYCLES(WAIT_CYCLES    )
    )
    u_EEPROM_driver(
        .clk     	(clk      ),
        .reset   	(reset    ),
        .key_in  	(key_in   ),
        .i2c_scl 	(i2c_scl  ),
        .i2c_sda 	(i2c_sda  ),
        .SEGA    	(SEGA     ),
        .SEGB    	(SEGB     ),
        .SEGC    	(SEGC     ),
        .SEGD    	(SEGD     ),
        .SEGE    	(SEGE     ),
        .SEGF    	(SEGF     ),
        .SEGG    	(SEGG     ),
        .DP      	(DP       ),
        .SEGCOM1 	(SEGCOM1  ),
        .SEGCOM2 	(SEGCOM2  ),
        .SEGCOM3 	(SEGCOM3  ),
        .SEGCOM4 	(SEGCOM4  ),
        .SEGCOM5 	(SEGCOM5  ),
        .SEGCOM6 	(SEGCOM6  ),
        .SEGCOM7 	(SEGCOM7  ),
        .SEGCOM8 	(SEGCOM8  )
    );
    
    always #10 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        key_in = 4'b1111;
        #WAIT_X2;
        reset = 0;
        #WAIT_X2;
        //WR_DATA
        key_in = 4'b1110; 
        #WAIT_X2;
        key_in = 4'b1111; 
        #WAIT_X2;
        key_in = 4'b1011;
        #WAIT_X2;
        key_in = 4'b1111;
        #WAIT_X2;
        key_in = 4'b0111;
        #WAIT_X2;
        key_in = 4'b1111;
        #WAIT_X2;
        key_in = 4'b1110;
        #WAIT_X2;
        key_in = 4'b1111;
        #WAIT_X2;

        //RD_DATA
        key_in = 4'b1101;
        #WAIT_X2;
        key_in = 4'b1111;
        #WAIT_X2;
        key_in = 4'b1011;
        #WAIT_X2;
        key_in = 4'b1111;
        #WAIT_X2;
        key_in = 4'b0111;
        #WAIT_X2;
        key_in = 4'b1111;
        #WAIT_X2;

        //WR_ADDR
        key_in = 4'b1011;
        #WAIT_X2;
        key_in = 4'b1111;
        #WAIT_X2;
        key_in = 4'b0111;
        #WAIT_X2;
        key_in = 4'b1111;
        #WAIT_X2;
        #1000;
        $stop;

    end

endmodule