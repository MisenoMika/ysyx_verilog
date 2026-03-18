module I2C_bit_shift#(
    parameter CLK_FREQ = 32'd50_000_000,
              I2C_FREQ = 32'd400_000,
    
    parameter   START = 7'b0000001,
                WR = 7'b0000010,
                RD = 7'b0000100,
                STOP = 7'b0001000,
                ACK = 7'b0010000,
                NACK = 7'b0100000
              
)(
    input clk,
    input reset,
    input wr_ena,
    input [6:0] cmd,
    input [7:0] tx_data,
    output reg [7:0] rx_data,
    output reg ack_o,
    output reg tran_done,
    output i2c_scl,
    inout i2c_sda
);
    localparam CLK_CNT_M = CLK_FREQ / (I2C_FREQ * 4) - 1;
    localparam IDLE  = 7'b0000001,
               GEN_STAR = 7'b0000010,
               WR_DAT = 7'b0000100,
               ACK_RX= 7'b0001000,
               GEN_STOP  = 7'b0010000,
               RD_DAT  = 7'b0100000,
               ACK_TX= 7'b1000000;

    //reg [7:0] reg_shift;
    reg [31:0] clk_cnt;
    reg clk_cnt_en;
    reg [6:0] state, next_state;
    reg sda_oena;
    reg sda_o;
    reg scl_o;
    wire clk_pulse = (clk_cnt == CLK_CNT_M);
    reg [5:0]pulse_cnt;


    reg [128:0] STATE;
    reg [128:0] CMD;
    `define DEBUG
    `ifdef DEBUG
        always @(*) begin
            case (state)
                IDLE: STATE = "IDLE";
                GEN_STAR: STATE = "GEN_STAR";
                WR_DAT: STATE = "WR_DAT";
                ACK_RX: STATE = "ACK_RX";
                GEN_STOP: STATE = "GEN_STOP";
                RD_DAT: STATE = "RD_DAT";
                ACK_TX: STATE = "ACK_TX";
                default: STATE = "UNKNOW";
            endcase

            if (cmd & START) CMD = "START";
            else if (cmd & WR) CMD = "WR";
            else if (cmd & RD) CMD = "RD";
            else if (cmd & STOP) CMD = "STOP";
            else if (cmd & ACK) CMD = "ACK";
            else if (cmd & NACK) CMD = "NACK";
            else CMD = "UNKNOW";
        end
        
        reg [7:0] tx_data_debug;
        reg ack_o_debug;
        always @(posedge clk) begin
            case(state)
                WR_DAT: begin
                    if(pulse_cnt[1:0] == 2'b00)tx_data_debug[7 - pulse_cnt[4:2]] <= tx_data[7 - pulse_cnt[4:2]];
                end
                RD_DAT: begin
                    if(pulse_cnt[1:0] == 2'b10)tx_data_debug[7 - pulse_cnt[4:2]] <= i2c_sda;
                end
                default: tx_data_debug <= 0;
            endcase
        end
    `endif


    always @(posedge clk) begin
        if(reset)begin
            state <= IDLE;
        end
        else begin
            state <= next_state;
        end
    end
    

    always @(posedge clk) begin
        if(reset) begin
            clk_cnt <= 0;
        end else if(clk_cnt_en) begin
            if(clk_cnt == CLK_CNT_M)begin
                clk_cnt <= 0;
            end else begin
                clk_cnt <= clk_cnt + 32'd1;
            end
        end else begin
            clk_cnt <= 0;
        end
    end

    always @(posedge clk) begin
        if(reset) begin
            pulse_cnt <= 0;
        end else if(state != next_state) begin
            pulse_cnt <= 0;
        end else if(clk_pulse) begin
            pulse_cnt <= pulse_cnt + 1'b1;
        end else begin
            pulse_cnt <= pulse_cnt;
        end
    end

    always @(*) begin
        case (state)
            IDLE: begin
                if(wr_ena) begin
                    if(cmd & START)begin
                        next_state = GEN_STAR;
                    end else if(cmd & WR)begin
                        next_state = WR_DAT;
                    end else if(cmd & RD)begin
                        next_state = RD_DAT;
                    end else begin
                        next_state = IDLE;
                    end
                end
                else begin
                    next_state = IDLE;
                end
            end
            GEN_STAR: begin
                if(pulse_cnt == 3) begin
                    if(cmd & WR)begin
                        next_state = WR_DAT;
                    end else if(cmd & RD)begin
                        next_state = RD_DAT;
                    end else begin
                        next_state = IDLE;
                    end
                end
                else begin
                    next_state = GEN_STAR;
                end
            end
            WR_DAT: begin
                if(pulse_cnt == 5'd31)begin
                    next_state = ACK_RX;
                end else begin
                    next_state = WR_DAT;
                end
            end
            ACK_RX: begin
                if(pulse_cnt == 5'd3)begin
                    if(cmd & STOP) begin
                        next_state = GEN_STOP;
                    end else begin
                        next_state = IDLE;
                    end
                end
                else begin
                    next_state = ACK_RX;
                end
            end

            RD_DAT: begin
                if(pulse_cnt == 5'd31)begin
                    next_state = ACK_TX;
                end else begin
                    next_state = RD_DAT;
                end
            end

            ACK_TX: begin
                if(pulse_cnt == 5'd3)begin
                    if(cmd & STOP) begin
                        next_state = GEN_STOP;
                    end else begin
                        next_state = IDLE;
                    end
                end else begin
                    next_state = ACK_TX;
                end
            end

            GEN_STOP: begin
                if(pulse_cnt == 5'd3)begin
                    next_state = IDLE;
                end else begin
                    next_state = GEN_STOP;
                end
            end
            default: next_state = IDLE;
        endcase
    end

    
    always @(posedge clk) begin
        if(reset) begin
            clk_cnt_en <= 0;
            //reg_shift <= 0;
            tran_done <= 0;
            sda_oena <= 0;
            pulse_cnt <= 0;
            rx_data <= 0;
            ack_o <= 0;
        end else begin
            case (state)
                IDLE: begin
                    tran_done <= 0;
                    pulse_cnt <= 0;
                    if(wr_ena) begin
                        clk_cnt_en <= 1'b1;
                    end else begin
                        clk_cnt_en <= 1'b0;
                    end
                end

                GEN_STAR: begin
                    //pulse_cnt <= (pulse_cnt == 5'd3) ? 0 : pulse_cnt + 1'b1;
                    /*
                     * 设pulse_cnt为0时,SCL为低电平-> 可更改数据
                     * 设pulse_cnt为1时,posedge
                     * 设pulse_cnt为2时,SCL为高电平-> 数据被从机采样   
                     */
                    case (pulse_cnt[1:0]) 
                        2'd0: begin
                            sda_oena <= 1'b1;
                            sda_o <= 1'b1;
                        end
                        2'd1: begin
                            scl_o <= 1'b1;
                        end
                        2'd2: begin
                            scl_o <= 1'b1;
                            sda_o <= 1'b0;
                        end
                        2'd3: begin
                            scl_o <= 1'b0;    
                        end
                        default: begin
                            sda_oena <= 1'b0;
                            sda_o <= 1'b1;
                            scl_o <= 1'b1;
                        end
                    endcase
                end

                WR_DAT: begin
                    if (clk_pulse) begin
                        //pulse_cnt <= (pulse_cnt == 5'd31) ? 0 : pulse_cnt + 1'b1;
                        case (pulse_cnt[1:0])
                            2'b00: begin
                                sda_o  <= tx_data[7 - pulse_cnt[4:2]];
                                sda_oena <= 1'b1;     
                            end
                            2'b01: begin
                                scl_o <= 1;           
                            end
                            2'b10: begin
                                scl_o <= 1;           
                            end
                            2'b11: begin
                                scl_o <= 0;           
                            end
                            default: begin
                                sda_o <= 1'b1;     
                                sda_oena <= 1'b0;
                                scl_o <= 1'b1;
                            end
                        endcase
                    end

                end

                ACK_RX: begin
                    //pulse_cnt <= (pulse_cnt == 5'd3) ? 0 : pulse_cnt + 1'b1;
                    case (pulse_cnt[1:0])
                        2'b00: begin
                            sda_oena <= 1'b0;  
                            scl_o <= 0;   
                        end
                        2'b01: begin
                            scl_o <= 1;           
                        end
                        2'b10: begin
                            scl_o <= 1;          
                            ack_o <= i2c_sda;
                        end
                        2'b11: begin
                            scl_o <= 0;           
                        end
                        default: begin
                            sda_o <= 1'b1;     
                            scl_o <= 1'b1;
                        end
                    endcase
                    if(pulse_cnt == 5'd3 && !(cmd & STOP))begin
                        tran_done <= 1'b1;
                    end else begin
                        tran_done <= 1'b0;
                    end
                end

                RD_DAT: begin
                    //pulse_cnt <= (pulse_cnt == 5'd31) ? 0 : pulse_cnt + 1'b1;
                    case (pulse_cnt[1:0])
                        2'b00: begin
                            sda_oena <= 1'b0;  
                            scl_o <= 0;   
                        end
                        2'b01: begin
                            scl_o <= 1;           
                        end
                        2'b10: begin
                            scl_o <= 1;          
                            rx_data[7 - pulse_cnt[4:2]] <= i2c_sda;
                        end
                        2'b11: begin
                            scl_o <= 0;           
                        end
                        default: begin
                            sda_o <= 1'b1;     
                            scl_o <= 1'b1;
                        end
                    endcase
                end

                ACK_TX: begin
                    pulse_cnt <= (pulse_cnt == 5'd3) ? 0 : pulse_cnt + 1'b1;
                    case (pulse_cnt[1:0])
                        2'b00: begin
                            scl_o <= 1'b0;
                            sda_o  <= (cmd & NACK) ? 1'b1 : 1'b0;  
                            sda_oena <= 1'b1;     
                        end
                        2'b01: begin
                            scl_o <= 1;           
                        end
                        2'b10: begin
                            scl_o <= 1;          
                        end
                        2'b11: begin
                            scl_o <= 0;           
                        end
                        default: begin
                            sda_o <= 1'b1;     
                            sda_oena <= 1'b0;
                            scl_o <= 1'b1;
                        end
                    endcase
                    if(pulse_cnt == 5'd3 && !(cmd & STOP))begin
                        tran_done <= 1'b1;
                    end else begin
                        tran_done <= 1'b0;
                    end
                end
                GEN_STOP: begin
                    pulse_cnt <= (pulse_cnt == 5'd3) ? 0 : pulse_cnt + 1'b1;
                    case (pulse_cnt[1:0])
                        2'b00: begin
                            sda_oena <= 1'b1;  
                            sda_o <= 1'b0;  
                            scl_o <= 0;   
                        end
                        2'b01: begin
                            scl_o <= 1;           
                        end
                        2'b10: begin
                            scl_o <= 1;          
                            sda_o <= 1'b1;
                        end
                        2'b11: begin
                            scl_o <= 0;           
                        end
                        default: begin
                            sda_o <= 1'b1;     
                            scl_o <= 1'b1;
                        end
                    endcase 
                    if(pulse_cnt == 5'd3)begin
                        tran_done <= 1'b1;
                    end else begin
                        tran_done <= 1'b0;
                    end
                end
            endcase
        end
    end

    assign i2c_scl = (scl_o) ? 1'bz : 1'b0;
    assign i2c_sda = sda_oena ? (sda_o ? 1'bz : 1'b0) : 1'bz;
endmodule