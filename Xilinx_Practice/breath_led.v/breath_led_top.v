module breath_led_top#(
    CLK_FREQ = 28'd50_000_000,
    BREATH_FREQ = 24'hffff
)(
    input clk,
    input reset,
    output [7:0] leds
);
    wire [7:0] duty_cycle;
    
    breath_ctrl u_breath_ctrl(
        .clk         	(clk          ),
        .reset       	(reset        ),
        .duty_cycle  	(duty_cycle   )
    );
    
    

    genvar i;
    generate
        for(i = 0; i < 8; i = i + 1) begin: gen_pwm
            pwm pwm_inst(
                .clk(clk),
                .reset(reset),
                .duty_cycle(duty_cycle),
                .leds(leds[i])
            );
        end
    endgenerate


endmodule