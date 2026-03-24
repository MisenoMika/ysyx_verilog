module pwm#(
    parameter CLK_FREQ = 28'd50_000_000,
    parameter PWM_FREQ = 28'd2_000, // pwm频率
    parameter DUTY_WIDTH = 8
)(
    input clk,
    input reset,
    input [DUTY_WIDTH - 1:0] duty_cycle,
    output reg leds
);  
    localparam CLK_DIV_M = CLK_FREQ / (PWM_FREQ * (1<<DUTY_WIDTH));
    reg [31:0] clk_cnt;
    wire [15:0] duty_map = duty_cycle * duty_cycle;

    always @(posedge clk) begin
        if(reset) begin
            clk_cnt <= 0;
        end else begin
            if(clk_cnt == CLK_DIV_M - 1) begin
                clk_cnt <= 0;
            end else begin
                clk_cnt <= clk_cnt + 1;
            end
        end
    end

    reg [7:0] counter;
    wire pwm_pulse = (clk_cnt == CLK_DIV_M - 1);
    always @(posedge clk) begin
        if(reset) begin
            counter <= 0;
            leds <= 0;
        end else begin
            counter <= (pwm_pulse) ? counter + 1 : counter;
            leds <= (counter < duty_map[15:8]);  
        end
    end
endmodule