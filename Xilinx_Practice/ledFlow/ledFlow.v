module ledFlow(
    input clk,
    input reset,


    output LD1,
    output LD2,
    output LD3,
    output LD4,
    output LD5,
    output LD6,
    output LD7,
    output LD8
);
    reg clkdiv = 0;
    wire enable;
    reg [31:0] clkdivCounter = 0;
    reg [7:0] leds = 0;
    reg [3:0] drive = 0;
    always@(posedge clk) begin
        if (reset) begin
            clkdivCounter <= 32'd0;
            clkdiv <= 1'b0;
        end 
        else begin
            if(clkdivCounter == 32'd5000000)begin//50000000
                clkdivCounter <= 32'd0;
                clkdiv <= ~clkdiv;
            end
            else begin
                clkdivCounter <= clkdivCounter + 1'b1;
            end
        end
    end

    always@(posedge clk) begin
        if (reset) begin
            drive <= 4'd0;
            leds <= 8'b11111110;
        end 
        else begin
            if (drive == 4'd8) begin
                drive <= 4'd0;
                leds <= 8'b11111110;
            end
            else if(enable)begin
                drive <= drive + 1'b1;
                leds <= {leds[6:0], leds[7]};
            end
        end
    end

    assign {LD8, LD7, LD6, LD5, LD4, LD3, LD2, LD1} = leds;
    assign enable = (clkdivCounter == 32'd4999999);
endmodule