module breath_ctrl#(
    parameter CLK_FREQ = 50_000_000,
    parameter DUTY_WIDTH = 8,
    parameter PERIOD_NS = 2_000_000_000 // led灯呼吸周期
)(
    input clk,
    input reset,
    output reg [DUTY_WIDTH - 1:0] duty_cycle
);
    localparam STEP_NUM = (1 << DUTY_WIDTH) * 2;
    localparam [63:0] CLK_DIV_M = ((64'd1*PERIOD_NS)*CLK_FREQ)/(STEP_NUM*64'd1_000_000_000);

    reg dir;
    reg [31:0] clk_cnt;

    always @(posedge clk) begin
        if(reset) begin
            clk_cnt <= 0;
            dir <= 1;
            duty_cycle <= 0;
        end else begin
            if(clk_cnt == CLK_DIV_M - 1) begin
                clk_cnt <= 0;
                if(dir) begin
                    if(duty_cycle < (1<<DUTY_WIDTH) - 1)
                        duty_cycle <= duty_cycle + 1;
                    else
                        dir <= 0;
                end else begin
                    if(duty_cycle > 0) begin
                        duty_cycle <= duty_cycle - 1;
                    end
                    else begin
                        dir <= 1;
                    end
                end
            end else begin
                clk_cnt <= clk_cnt + 1;
            end

            
        end
        
    end
endmodule