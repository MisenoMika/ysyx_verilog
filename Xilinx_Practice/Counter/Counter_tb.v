`timescale 1ns/1ps

module Counter_top_tb();

    reg clk;
    reg reset;

    wire SEGA, SEGB, SEGC, SEGD, SEGE, SEGF, SEGG;
    wire [7:0] segcom;
    wire [6:0] seg;
    wire [31:0] result;

    wire SEGCOM1, SEGCOM2, SEGCOM3, SEGCOM4;
    wire SEGCOM5, SEGCOM6, SEGCOM7, SEGCOM8;

    // 实例化 DUT（Device Under Test）
    Counter_top dut (
        .clk(clk),
        .reset(reset),
        .SEGA(SEGA),
        .SEGB(SEGB),
        .SEGC(SEGC),
        .SEGD(SEGD),
        .SEGE(SEGE),
        .SEGF(SEGF),
        .SEGG(SEGG),

        .segcom(segcom),
        .seg(seg),
        .result(result),

        .SEGCOM1(SEGCOM1),
        .SEGCOM2(SEGCOM2),
        .SEGCOM3(SEGCOM3),
        .SEGCOM4(SEGCOM4),
        .SEGCOM5(SEGCOM5),
        .SEGCOM6(SEGCOM6),
        .SEGCOM7(SEGCOM7),
        .SEGCOM8(SEGCOM8)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        #100;
        reset = 0;
        #200000000;   // 200ms 
        $stop;
    end


endmodule
