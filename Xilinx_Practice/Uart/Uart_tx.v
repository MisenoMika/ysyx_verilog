module Uart_tx #(
    parameter  CLK_FREQ   = 32'd50_000_000,  
    parameter  BAUD_RATE  = 32'd9600,
    parameter  IS_PARITY  = 1,       // 0: NONE, 1: ODD, 2: EVEN
    parameter  DATA_BITS  = 8
) (
    input  reset,
    input  clk,
    input  i_valid,
    input  [DATA_BITS - 1:0]i_data,
    output reg o_uart_tx,
    output o_busy
);
    localparam BAUD_BIT = CLK_FREQ / BAUD_RATE;
    localparam IDLE = 4'd0, START = 4'd1, DATA = 4'd2, PARITY = 4'd3, STOP = 4'd4, DONE = 4'd5;
    
    reg [3:0] state, next_state; 
    reg [31:0] clk_cnt;
    reg [3:0] bit_cnt;
    reg [DATA_BITS - 1:0] data_buf;
    
    wire data_xor = ^data_buf;
    wire parity_bit = (IS_PARITY == 1) ? ~data_xor : data_xor; 

    always @(posedge clk) begin
        if (reset)
            state <= IDLE;
        else
            state <= next_state;
    end

  
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (i_valid) begin
                    next_state = START;
                end
            end
            START: begin
                if (clk_cnt == BAUD_BIT - 1) begin
                    next_state = DATA;
                end
            end
            DATA: begin
                if (clk_cnt == BAUD_BIT - 1) begin
                    if (bit_cnt == DATA_BITS - 1) begin
                        next_state = (IS_PARITY == 0) ? STOP : PARITY;
                    end
                    else begin
                        next_state = DATA;
                    end
                end
                else begin
                    next_state = DATA;
                end
            end
            PARITY: begin
                if (clk_cnt == BAUD_BIT - 1) begin
                        next_state = STOP;
                    end
            end
            STOP: begin
                if (clk_cnt == BAUD_BIT - 1) begin
                        next_state = DONE;
                end
            end
            DONE: begin
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

    always @(posedge clk) begin
        if (reset) begin
            clk_cnt    <= 32'd0;
            bit_cnt    <= 4'd0;
            data_buf   <= 8'd0;
            o_uart_tx <= 1'b1; // idle state of UART line is high
        end else begin          
            case (state)
                IDLE: begin
                    clk_cnt <= 32'd0;
                    bit_cnt <= 4'd0;
                    o_uart_tx <= 1'b1;

                    if (i_valid) begin
                        data_buf <= i_data;
                    end
                end
                START: begin
                    if (clk_cnt == BAUD_BIT - 1) begin
                        clk_cnt <= 32'd0;  
                        o_uart_tx <= 1'b0; // start bit 
                    end else begin
                        clk_cnt <= clk_cnt + 1'b1;
                    end
                end
                /*
                    START 已经等了 0.5 bit
                    再等 1 bit 正好落在下一个 bit 中心
                 */
                DATA: begin
                    if (clk_cnt == BAUD_BIT - 1) begin
                        clk_cnt <= 32'd0;
                        o_uart_tx <= data_buf[bit_cnt];
                        bit_cnt <= bit_cnt + 1'b1;
                    end else begin
                        clk_cnt <= clk_cnt + 1'b1;
                    end
                end
                PARITY: begin
                    if (clk_cnt == BAUD_BIT - 1) begin
                        clk_cnt <= 32'd0;
                        o_uart_tx <= parity_bit;
                    end else begin
                        clk_cnt <= clk_cnt + 1'b1;
                    end
                end
                STOP: begin
                    if (clk_cnt == BAUD_BIT - 1)begin
                        clk_cnt <= 32'd0;
                        o_uart_tx <= 1'b1; // stop bit 
                    end else begin
                        clk_cnt <= clk_cnt + 1'b1;
                    end
                end
                default: begin
                    clk_cnt <= 32'd0;
                    bit_cnt <= 4'd0;
                    o_uart_tx <= 1'b1;
                end
            endcase
        end
    end
    assign o_busy = (state != IDLE);
endmodule