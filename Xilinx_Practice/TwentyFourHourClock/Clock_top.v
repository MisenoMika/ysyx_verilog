module Clock_top#(
    CLK_CYCLES = 32'd50_000 * 1_00// 0.1s
)(
    input clk,
    input reset,

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
    output SEGCOM8
);
    wire [7:0] ss, mm, hh;
    wire [63:0] time_load;
    wire [63:0] graphData; 
    wire ena;
    reg [31:0]clkdivCounter;
    assign time_load = {4'd0, hh[7:4], 4'd0, hh[3:0], 
                        8'd0, 4'd0, mm[7:4], 4'd0, mm[3:0], 
                        8'd0, 4'd0, ss[7:4], 4'd0, ss[3:0]};
    assign graphData = {8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1};
    assign ena = (clkdivCounter == CLK_CYCLES-1);
    always @(posedge clk) begin
        if (reset) begin
            clkdivCounter <= 32'd0;
        end 
        else begin
            if(clkdivCounter == CLK_CYCLES)begin
                clkdivCounter <= 32'd0;
            end
            else begin
                clkdivCounter <= clkdivCounter + 1'b1;
            end
        end
    end
    TwentyFourHourClock Clock_inst (
        .clk(clk),
        .reset(reset),
        .ena(ena),
        .hh(hh),
        .mm(mm),
        .ss(ss)
    );

    SegmentDecoder SegmentDecoder_inst (
        .clk(clk),
        .reset(reset),
        .load(time_load),
        .graphData(graphData),
        .mode(8'b11011011), 
        .DP_in(8'b11111111),
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