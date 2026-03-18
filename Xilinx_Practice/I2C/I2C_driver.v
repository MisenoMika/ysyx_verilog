module I2C_driver#(
    parameter CLK_FREQ = 32'd50_000_000,
              I2C_FREQ = 32'd400_000
)(
    input clk,
    input reset,
    input wr_ena,
    input rd_ena,
    input [15:0] _reg_addr,
    input reg_addr_mode, // 0: 7-bit address, 1: 10-bit address
    input [15:0] dev_addr,
    input dev_addr_mode, // 0: 7-bit address, 1: 10-bit address
    input [7:0] wr_data,
    output reg [7:0] rd_data,
    output reg ack,
    output reg rw_done,
    output i2c_scl,
    inout i2c_sda
);
    localparam  START = 7'b0000001,
                WR = 7'b0000010,
                RD = 7'b0000100,
                STOP = 7'b0001000,
                ACK = 7'b0010000,
                NACK = 7'b0100000;
    localparam IDLE  = 7'b0000001,
               WR_REG = 7'b0000010,
               WAIT_WR_REG = 7'b0000100,
               DONE_WR_REG = 7'b0001000,
               RD_REG  = 7'b0010000,
               WAIT_RD_REG = 7'b0100000,
               DONE_RD_REG = 7'b1000000;
    wire [15:0] reg_addr = reg_addr_mode ? _reg_addr: {reg_addr[7:0], reg_addr[15:8]};
    reg [6:0] state, next_state;
    reg task_ena;
    wire [7:0] rx_data;
    reg [7:0] tx_data;
    reg [7:0] cmd;
    reg tran_done;
    wire ack_o;
    reg [7:0] task_cnt;


    I2C_bit_shift #(
        .CLK_FREQ(CLK_FREQ),
        .I2C_FREQ(I2C_FREQ)
    ) i2c_bit_shift_inst (
        .clk(clk),
        .reset(reset),
        .wr_ena(task_ena),
        .cmd(cmd),
        .tx_data(rx_data),
        .rx_data(rd_data),
        .ack_o(ack_o),
        .tran_done(tran_done),
        .i2c_scl(i2c_scl),
        .i2c_sda(i2c_sda)
    );


    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end


    always @(*) begin
        case (state) 
            IDLE: begin
                if(wr_ena) begin
                    next_state = WR_REG;
                end else if (rd_ena) begin
                    next_state = RD_REG;
                end else begin
                    next_state = IDLE;
                end
            end

            WR_REG: begin
                next_state = WAIT_WR_REG;
            end

            WAIT_WR_REG: begin
                if (tran_done) begin
                    next_state = DONE_WR_REG;
                end else begin
                    next_state = WAIT_WR_REG;
                end
            end

            DONE_WR_REG: begin
                next_state = IDLE;
            end

            RD_REG: begin
                next_state = WAIT_RD_REG;
            end

            WAIT_RD_REG: begin
                if (tran_done) begin
                    if(task_cnt < 3) begin
                        next_state = RD_REG;
                    end else begin
                        next_state = DONE_RD_REG;
                    end
                end else begin
                    next_state = WAIT_RD_REG;
                end
            end

            DONE_RD_REG: begin
                next_state = IDLE;
            end

            default: next_state = IDLE;

        endcase
    end


    always @(posedge clk) begin
        if (reset) begin
            rd_data <= 8'b0;
            cmd <= 8'b0;
            tx_data <= 8'b0;
            task_ena <= 0;
            ack <= 0;
        end else begin
            case (state)
                IDLE:begin
                    rw_done <= 0;
                    ack <= 0;
                end
                WR_REG: begin
                    case(task_cnt)
                        0: write_byte({dev_addr[6:0], 1'b0}, START | WR);
                        1: write_byte(reg_addr[15:8], WR);
                        2: write_byte(reg_addr[7:0], WR);
                        3: write_byte(wr_data, WR | STOP);
                    endcase
                end

                WAIT_WR_REG: begin
                    if (tran_done) begin
                        case(task_cnt) 
                            0: begin
                                task_cnt <= 1;
                            end
                            1: begin
                                if(reg_addr_mode) begin
                                    task_cnt <= 2;
                                end else begin
                                    task_cnt <= 3;
                                end
                            end
                            2: begin
                                task_cnt <= 3;
                            end
                            default: begin
                                task_cnt <= task_cnt;
                            end
                        endcase
                    end
                end
            endcase
        end
    end

    task write_byte(input [7:0] data, input ctrl_cmd);
        begin
            cmd <= ctrl_cmd;
            tx_data <= data;
            task_ena <= 1;
        end
    endtask
    
    task read_byte(input ctrl_cmd);
        begin
            cmd <= ctrl_cmd;
            task_ena <= 1;
        end
    endtask
    
endmodule