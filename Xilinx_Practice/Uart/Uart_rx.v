module Uart_rx #(
    parameter  CLK_FREQ   = 32'd50_000_000,  
    parameter  BAUD_RATE  = 32'd9600,
    parameter  IS_PARITY  = 1,       // 0: NONE, 1: ODD, 2: EVEN
    parameter  DATA_BITS  = 8
) (
    input  reset,
    input  clk,
    input  i_uart_rx,
    output reg [DATA_BITS - 1:0] o_data,
    output reg o_valid
);
    localparam BAUD_BIT = CLK_FREQ / BAUD_RATE;
    localparam IDLE = 4'd0, START = 4'd1, DATA = 4'd2, PARITY = 4'd3, STOP = 4'd4, DONE = 4'd5;
    
    reg [3:0] state, next_state; 
    reg [31:0] clk_cnt;
    reg [3:0] bit_cnt;
    reg [DATA_BITS - 1:0] data_buf;
    reg rx_d0, rx_d1;
    
    wire data_xor = ^data_buf;
    wire parity_ok = (IS_PARITY == 0) ? 1'b1 : 
                     (IS_PARITY == 1) ? (rx_d1 ^ data_xor) :  // ODD
                                        ~(rx_d1 ^ data_xor);  // EVEN
    // 两级寄存器同步输入信号，消除亚稳态
    always @(posedge clk) begin
        if (reset) begin
            rx_d0 <= 1'b1;
            rx_d1 <= 1'b1;
        end else begin
            rx_d0 <= i_uart_rx;
            rx_d1 <= rx_d0;
        end
    end

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
                if (rx_d1 == 1'b0)
                    next_state = START;
            end
            START: begin
                if (clk_cnt == BAUD_BIT/2 - 1) begin
                    if (rx_d1 == 1'b0)
                        next_state = DATA;
                    else
                        next_state = IDLE;  
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
                    if (parity_ok) begin
                        next_state = STOP;
                    end
                    else begin
                        next_state = IDLE;  
                    end
                end
            end
            STOP: begin
                if (clk_cnt == BAUD_BIT - 1) begin
                    if (rx_d1 == 1'b1) begin
                        next_state = DONE;
                    end else begin
                        next_state = IDLE;  
                    end
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
            o_data     <= 8'd0;
            o_valid    <= 1'b0;
        end else begin
            o_valid <= 1'b0;  
            
            case (state)
                IDLE: begin
                    clk_cnt <= 32'd0;
                    bit_cnt <= 4'd0;
                    data_buf <= 8'd0;
                end
                START: begin
                    if (clk_cnt == BAUD_BIT/2 - 1)
                        clk_cnt <= 32'd0;  
                    else
                        clk_cnt <= clk_cnt + 1'b1;
                end
                /*
                    START 已经等了 0.5 bit
                    再等 1 bit 正好落在下一个 bit 中心
                 */
                DATA: begin
                    if (clk_cnt == BAUD_BIT - 1) begin
                        data_buf[bit_cnt] <= rx_d1;
                        bit_cnt <= bit_cnt + 1'b1;
                        clk_cnt <= 32'd0;
                    end else begin
                        clk_cnt <= clk_cnt + 1'b1;
                    end
                end
                PARITY: begin
                    if (clk_cnt == BAUD_BIT - 1)
                        clk_cnt <= 32'd0;
                    else
                        clk_cnt <= clk_cnt + 1'b1;
                end
                STOP: begin
                    if (clk_cnt == BAUD_BIT - 1)
                        clk_cnt <= 32'd0;
                    else
                        clk_cnt <= clk_cnt + 1'b1;
                end
                DONE: begin
                    o_data  <= data_buf;
                    o_valid <= 1'b1;
                end
            endcase
        end
    end
endmodule