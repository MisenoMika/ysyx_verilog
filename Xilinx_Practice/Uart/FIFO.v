module FIFO#(
    parameter WIDTH = 8,
    parameter DEPTH = 256
)(
    input clk,
    input reset,
    input write_ena,
    input read_ena,
    input tx_busy,
    input [WIDTH - 1:0] i_data,
    output reg [WIDTH - 1:0] o_data,
    output reg tx_valid,
    output can_load
);

    reg [WIDTH - 1:0] fifo [0:DEPTH - 1];
    localparam ADDR_WIDTH = $clog2(DEPTH);
    reg [ADDR_WIDTH - 1:0] head;   // read pointer
    reg [ADDR_WIDTH - 1:0] tail;   // write pointer
    reg is_sending;            // in transmit session
    reg data_pending;       // o_data prepared, waiting to pulse tx_valid

    wire is_empty;
    wire is_full;

    assign is_empty = (head == tail);
    assign is_full  = ((tail + 1'b1) == head);
    assign can_load = !is_full;

    always @(posedge clk) begin
        if (reset) begin
            head <= 8'd0;
            tail <= 8'd0;
            o_data <= {WIDTH{1'b0}};
            tx_valid <= 1'b0;
            is_sending <= 1'b0;
            data_pending <= 1'b0;
        end else begin
            tx_valid <= 1'b0; 

            if (write_ena && !is_full) begin
                fifo[tail] <= i_data;
                tail <= tail + 1'b1;
            end

            if (read_ena && !is_empty) begin
                is_sending <= 1'b1;
            end

            if (is_sending) begin
                if (!data_pending && is_empty) begin
                    is_sending <= 1'b0;
                end
  
                else if (!data_pending && !is_empty) begin
                    o_data <= fifo[head];
                    head <= head + 1'b1;
                    data_pending <= 1'b1;
                end
     
                else if (data_pending && !tx_busy) begin
                    tx_valid <= 1'b1;
                    data_pending <= 1'b0;

                    if (o_data == "\n" || o_data == "\r") begin
                        is_sending <= 1'b0;
                    end
                end
            end
        end
    end

endmodule