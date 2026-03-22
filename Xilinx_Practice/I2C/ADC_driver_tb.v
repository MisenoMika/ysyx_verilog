`timescale 1ns/1ps
module ADC_driver_tb();
    reg clk;
    reg reset;

    wire i2c_scl;
    wire i2c_sda;

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


    localparam CLK_FREQ = 32'd50_000_000;
    localparam I2C_FREQ = 32'd40_000_00; 
    pullup(i2c_sda);
    pullup(i2c_scl);
    ADC_driver #(
        .CLK_FREQ 	(CLK_FREQ),
        .I2C_FREQ 	(I2C_FREQ)
        )
    u_ADC_driver(
        .clk     	(clk      ),
        .reset   	(reset    ),
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
        reset = 1;
        clk = 0;
        #100
        reset = 0;
        //wait_for_byte_rd_debug();
        @(posedge u_ADC_driver.rw_done);
        @(posedge u_ADC_driver.rw_done);
        @(posedge u_ADC_driver.rw_done);
        @(posedge u_ADC_driver.rw_done);
        @(posedge u_ADC_driver.rw_done);
        @(posedge u_ADC_driver.rw_done);
        @(posedge u_ADC_driver.rw_done);
        #1000
        $stop;
        
    end
endmodule