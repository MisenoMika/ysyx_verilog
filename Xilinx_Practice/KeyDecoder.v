module KeyDecoder #(
    parameter WAIT_CYCLES = 32'd50_000 * 20
)(
    input clk,
    input reset,
    input key_in,
    output key_out
);
    parameter IDLE = 3'b000, WAIT = 3'b010, CONFIRM = 3'b100;
    reg [2:0] state, next_state;
    reg [31:0]counter;
    reg key_ff1;
    wire key_tmp;
    always@(*) begin
        case(state)
            IDLE: begin
                if(key_tmp == 0) begin
                    next_state = WAIT;
                end
                else begin
                    next_state = IDLE;
                end
            end

            WAIT: begin
                if(key_tmp == 1) begin
                    next_state = IDLE;
                end
                else if(counter >= WAIT_CYCLES-1) begin
                    next_state = CONFIRM;
                end
                else begin
                    next_state = WAIT;
                end
            end

            CONFIRM: begin
                if(key_tmp == 1) begin
                    next_state = IDLE;
                end
                else begin
                    next_state = CONFIRM;
                end
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    always@(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            counter <= 0;
            key_ff1 <= 1'b1;
        end 
        else begin
            key_ff1 <= key_in;
            state <= next_state;
            if(state == WAIT) begin
                counter <= counter + 1'd1;
            end
            else begin
                counter <= 0;
            end
        end
    end
    assign key_out = (state == CONFIRM);
    assign key_tmp = key_ff1;
endmodule