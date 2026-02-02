`timescale 1ns/1ps
module Counter_tb();

    reg clk;
    reg reset;
    reg key_in;
    wire SEGA;  
    wire SEGB;
    wire SEGC;
    wire SEGD;
    wire SEGE;
    wire SEGF;
    wire SEGG;
    wire SEGCOM1;
    wire SEGCOM2;
    wire SEGCOM3;
    wire SEGCOM4;
    wire SEGCOM5;
    wire SEGCOM6;
    wire SEGCOM7;
    wire SEGCOM8;

    Counter_top counter_top_inst (
        .clk(clk),
        .reset(reset),
        .key_in(key_in),
        .SEGA(SEGA),
        .SEGB(SEGB),
        .SEGC(SEGC),
        .SEGD(SEGD),
        .SEGE(SEGE),
        .SEGF(SEGF),
        .SEGG(SEGG),
        .SEGCOM1(SEGCOM1),
        .SEGCOM2(SEGCOM2),
        .SEGCOM3(SEGCOM3),
        .SEGCOM4(SEGCOM4),
        .SEGCOM5(SEGCOM5),
        .SEGCOM6(SEGCOM6),
        .SEGCOM7(SEGCOM7),
        .SEGCOM8(SEGCOM8)
    );
    initial begin
        clk = 0;
        reset = 1;
        key_in = 1;
        #15;
        reset = 0;
        #15;
        key_in = 0;
        #15;
        key_in = 1;
        #15;
        key_in = 0;
        #15;
        key_in = 1;
        #15;
        key_in = 0;
        #1000;
        key_in = 1;
        #1000;
        reset = 0;
        #15;
        key_in = 0;
        #15;
        key_in = 1;
        #15;
        key_in = 0;
        #15;
        key_in = 1;
        #15;
        key_in = 0;
        #1000000;
        $finish;
    end
    always #10 clk = ~clk;
endmodule