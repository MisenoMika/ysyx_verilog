module I2C_driver#(
    parameter CLK_FREQ = 32'd50_000_000,
              I2C_FREQ = 32'd125_000,
              WR_BYTE_NUM = 8'd1,
              RD_BYTE_NUM = 8'd1
)(
    input clk,
    input reset,
    input wr_ena,
    input rd_ena,
    input [15:0] i_reg_addr,
    input reg_addr_mode, // 0: 7-bit address, 1: 10-bit address
    input [6:0] i_dev_addr,
    input dev_addr_mode, // 0: 7-bit address, 1: 10-bit address
    input [WR_BYTE_NUM*8 - 1:0] wr_data,
    output reg [RD_BYTE_NUM*8 - 1:0] rd_data,
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
    
    reg [7:0] byte_left;
    
    wire [15:0] reg_addr = reg_addr_mode ? i_reg_addr: {i_reg_addr[7:0], i_reg_addr[15:8]};
    reg [6:0] state, next_state;
    reg task_ena;

    reg [WR_BYTE_NUM*8 - 1:0] wr_data_buf;
    wire [7:0] rx_data;
    reg [7:0] tx_data;
    reg [6:0] cmd;
    wire tran_done;
    wire ack_o;
    reg [7:0] task_cnt;

    `define DEBUG
    `ifdef DEBUG
        reg [256:0] cmd_debug;
        reg [256:0] state_debug;
        always @(*) begin
            case(cmd)
                START: cmd_debug = "START";
                WR: cmd_debug = "WR";
                RD: cmd_debug = "RD";
                STOP: cmd_debug = "STOP";
                ACK: cmd_debug = "ACK";
                NACK: cmd_debug = "NACK";
                (WR | STOP): cmd_debug = "WR|STOP";
                (RD | ACK): cmd_debug = "RD|ACK";
                (RD | NACK | STOP): cmd_debug = "RD|NACK|STOP";
                (START | WR): cmd_debug = "START|WR";
                (START | RD): cmd_debug = "START|RD";

                default: cmd_debug = "UNDEFINED";
            endcase

            case(state)
                IDLE: state_debug = "IDLE";
                WR_REG: state_debug = "WR_REG";
                WAIT_WR_REG: state_debug = "WAIT_WR_REG";
                DONE_WR_REG: state_debug = "DONE_WR_REG";
                RD_REG: state_debug = "RD_REG";
                WAIT_RD_REG: state_debug = "WAIT_RD_REG";
                DONE_RD_REG: state_debug = "DONE_RD_REG";
                default: state_debug = "UNDEFINED";
            endcase

            
        end
    `endif

    I2C_bit_shift #(
        .CLK_FREQ(CLK_FREQ),
        .I2C_FREQ(I2C_FREQ)
    ) i2c_bit_shift_inst (
        .clk(clk),
        .reset(reset),
        .wr_ena(task_ena),
        .cmd(cmd),
        .tx_data(tx_data),
        .rx_data(rx_data),
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


    always @(posedge clk) begin
        if(reset) begin
            byte_left <= 0;
        end else begin
            if(state == IDLE) begin
                if(wr_ena) begin
                    byte_left <= WR_BYTE_NUM;
                end else if(rd_ena) begin
                    byte_left <= RD_BYTE_NUM;
                end else begin
                    byte_left <= 0;
                end
            end else begin
                if(tran_done) begin
                    if((state == WAIT_WR_REG && task_cnt == 3)
                    || (state == WAIT_RD_REG && task_cnt == 4)) begin
                        byte_left <= byte_left - 1;
                    end
                end
            end
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
                    if(task_cnt < 4) begin
                        next_state = WR_REG;
                    end else begin
                        next_state = DONE_WR_REG;
                    end
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
                    if(task_cnt < 5) begin
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
            rd_data <= 'b0;
            cmd <= 8'b0;
            tx_data <= 8'b0;
            task_ena <= 0;
            ack <= 0;
            task_cnt <= 0;
            rw_done <= 0;
        end else begin
            case (state)
                IDLE:begin
                    rw_done <= 0;
                    ack <= 0;
                    task_cnt <= 0;
                    wr_data_buf <= wr_data;
                end
                WR_REG: begin
                    case(task_cnt)
                        0: write_byte({i_dev_addr, 1'b0}, START | WR);
                        1: write_byte(reg_addr[15:8], WR);
                        2: write_byte(reg_addr[7:0], WR);
                        3: write_byte(wr_data_buf, WR);
                        4: write_byte(wr_data_buf, WR | STOP);
                        default: task_cnt <= task_cnt;
                    endcase
                end

                WAIT_WR_REG: begin
                    if (tran_done) begin
                        ack <= ack | ack_o; // 防止覆盖前一次序列可能出现的NACK
                        if(task_cnt == 4) begin
                            wr_data_buf <= wr_data_buf >> 8;
                        end
                        case(task_cnt) 
                            0: begin
                                task_cnt <= 8'd1;
                            end
                            1: begin
                                if(reg_addr_mode) begin
                                    task_cnt <= 8'd2;
                                end else begin
                                    task_cnt <= 8'd3;
                                end
                            end
                            2: begin
                                if(byte_left == 1)begin
                                    task_cnt <= 8'd4;
                                end else begin
                                    task_cnt <= 8'd3;
                                end
                            end
                            3: begin
                                if(byte_left == 1)begin
                                    task_cnt <= 8'd4;
                                end else begin
                                    task_cnt <= 8'd3;
                                end
                            end
                            default: begin
                                task_cnt <= task_cnt;
                            end
                        endcase
                    end
                end

                DONE_WR_REG: begin
                    rw_done <= 1;
                end

                RD_REG: begin
                    case(task_cnt)
                        0: write_byte({i_dev_addr, 1'b0}, START | WR);
                        1: write_byte(reg_addr[15:8], WR);
                        2: write_byte(reg_addr[7:0], WR | STOP);
                        3: write_byte({i_dev_addr, 1'b1}, START | WR);
                        4: read_byte(RD | ACK);
                        5: read_byte(RD | NACK | STOP);
                    endcase
                end

                WAIT_RD_REG: begin
                    task_ena <= 0;
                    if (tran_done) begin
                        if(task_cnt < 4) begin
                            ack <= ack | ack_o; // 防止覆盖前一次序列可能出现的NACK
                        end 
                        /*if(task_cnt == 4 || task_cnt == 5) begin
                            rd_data <= (rd_data << 8) | rx_data;
                        end*/
                        if(task_cnt == 4 || task_cnt == 5) begin
                            if(byte_left == 2)begin
                                rd_data[15:8] <= rx_data;
                            end else if(byte_left == 1)begin
                                rd_data[7:0] <= rx_data;
                            end
                        end
                        case(task_cnt)
                            0: begin
                                task_cnt <= 1;
                            end
                            1: begin
                                if(reg_addr_mode) begin
                                    task_cnt <= 8'd2;
                                end else begin
                                    task_cnt <= 8'd3;
                                end
                            end
                            2: begin
                                task_cnt <= 8'd3;
                            end
                            3: begin
                                task_cnt <= (byte_left == 1) ? 8'd5 : 8'd4;
                            end
                            4: begin
                                task_cnt <= (byte_left == 1) ? 8'd4 : 8'd5;
                            end
                            default: begin
                                task_cnt <= task_cnt;
                            end
                        endcase
                    end
                end

                DONE_RD_REG: begin
                    rw_done <= 1;
                end

            endcase
        end
    end

    task write_byte(input [7:0] data, input [6:0]ctrl_cmd);
        begin
            cmd <= ctrl_cmd;
            tx_data <= data;
            task_ena <= 1;
        end
    endtask
    
    task read_byte(input [6:0]ctrl_cmd);
        begin
            cmd <= ctrl_cmd;
            task_ena <= 1;
        end
    endtask
    
endmodule