module top_module(
    input clk,
    input [7:0] in,
    input reset,    // Synchronous reset
    output [23:0] out_bytes,
    output done); //

    parameter BYTE1 = 2'b00, BYTE2 = 2'b01, BYTE3= 2'b10, DONE = 2'b11;
    reg [1:0] state, next_state;
    reg [23:0]data;
    // State transition logic (combinational)
    always @(*)begin
        case(state)
            BYTE1: begin
                if(in[3])begin
                    next_state = BYTE2;
                end
                else begin
                    next_state = BYTE1;
                end
            end
            BYTE2: begin
                next_state = BYTE3;
            end
            BYTE3: begin
                next_state = DONE;
            end
            DONE: begin
                if(in[3])begin
                    next_state = BYTE2;
                end
                else begin
                    next_state = BYTE1;
                end
            end
            default: begin
                next_state = BYTE1;
            end
        endcase
    end
    // State flip-flops (sequential)
    always@(posedge clk) begin
        if (reset) begin
            // Synchronous reset logic
            state <= BYTE1;
        end 
        else begin
            // State update logic
            state <= next_state;
            case(state)
                BYTE3: data[7:0] <= in;
                BYTE2: data[15:8] <= in;
                BYTE1: data[23:16] <= in;
                DONE: data[23:16] <= in; 
                default: data <= data;
            endcase
        end
    end
    // Output logic
    assign done = (state == DONE);
    assign out_bytes = (state == DONE)? data : 24'b0;
endmodule
