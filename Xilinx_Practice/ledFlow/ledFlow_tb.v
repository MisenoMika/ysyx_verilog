`timescale 1ns/1ps
module ledFlow_tb();
    reg clk;
    reg reset;
    wire LD1;
    wire LD2;
    wire LD3;
    wire LD4;
    wire LD5;
    wire LD6;
    wire LD7;
    wire LD8;

    ledFlow ledFlow_inst (
        .clk(clk),
        .reset(reset),
        .LD1(LD1),
        .LD2(LD2),
        .LD3(LD3),
        .LD4(LD4),
        .LD5(LD5),
        .LD6(LD6),
        .LD7(LD7),
        .LD8(LD8)
    );

    initial begin
        clk = 0;
        reset = 1;
        #20;         
        reset = 0;
        #1000000;       
        $finish;
    end

    always #5 clk = ~clk;
endmodule
