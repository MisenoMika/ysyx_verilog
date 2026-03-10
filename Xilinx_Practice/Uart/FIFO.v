module FIFO#(
    parameter WIDTH = 8,
    parameter DEPTH = 256
)(
    input clk,
    input reset,
    input write_ena,
    input read_ena,
    input [WIDTH - 1:0] i_data,
    output reg [WIDTH - 1:0] o_data,
    output reg o_valid,
    output reg o_full,
    output reg o_empty
);
    reg [WIDTH - 1:0] fifo [DEPTH - 1:0];
    reg [7:0] head, tail;
    reg is_sending;

    always @(posedge clk) begin
        if(reset) begin
            head <= 0;
            tail <= 0;
            o_valid <= 0;
            o_full <= 0;
            o_empty <= 1;
        end else begin
            if (write_ena && !o_full) begin
                fifo[head] <= i_data;
                head <= head + 1'b1;

                if (i_data == "\n") begin
                    is_sending <= 1;
                end
            end

            if (is_sending && !o_empty) begin
                o_data <= fifo[tail];
                o_valid <= 1;
                tail <= tail + 1'b1;

                if (fifo[tail] == "\n") begin
                    is_sending <= 0;
                end
            end
        end
    end
endmodule