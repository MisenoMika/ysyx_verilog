`timescale 1ns/1ps

module Clock_top_tb();

    reg clk;
    reg reset;
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

    Clock_top #(
        .CLK_CYCLES(32'd50_000 * 1_0)
    )Clock_top_inst (
        .clk(clk),
        .reset(reset),
        .SEGA(SEGA),
        .SEGB(SEGB),
        .SEGC(SEGC),
        .SEGD(SEGD),
        .SEGE(SEGE),
        .SEGF(SEGF),
        .SEGG(SEGG),
        .DP(DP),
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
        #15;
        reset = 0;
        #1000000;
        $stop;
    end

    always #10 clk = ~clk;

endmodule