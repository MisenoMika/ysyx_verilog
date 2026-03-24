module EEPROM_driver#(
    parameter CLK_FREQ = 32'd50_000_000,
              I2C_FREQ = 32'd100_000,
    parameter WAIT_CYCLES = 32'd50_000 * 20
)(
    input clk,
    input reset,
    input [3:0] key_in,
    output i2c_scl,
    inout i2c_sda,

    output SEGA,
    output SEGB,
    output SEGC,
    output SEGD,
    output SEGE,
    output SEGF,
    output SEGG,
    output DP,


    output SEGCOM1,
    output SEGCOM2,
    output SEGCOM3,
    output SEGCOM4,
    output SEGCOM5,
    output SEGCOM6,
    output SEGCOM7,
    output SEGCOM8
);
    localparam  DEV_ADDR = 7'b1010_000, 
                REG_ADDR = 8'h00;
    localparam  RD_BYTE_NUM = 1,
                WR_BYTE_NUM = 1,
                REG_ADDR_BYTE = 1,
                DEV_ADDR_BYTE = 1;
    localparam  WR_DAT = 2'b01,
                RD_DAT = 2'b10,
                IDLE = 2'b00,
                ERRO = 2'b11;
    
    reg [1:0] state, next_state;

    wire [3:0] key_out;
    reg [3:0] key_out_ff;
    wire [3:0] key_pulse;
    assign key_pulse[0] = key_out[0] == 0 && key_out_ff[0] == 1;
    assign key_pulse[1] = key_out[1] == 0 && key_out_ff[1] == 1;
    assign key_pulse[2] = key_out[2] == 0 && key_out_ff[2] == 1;
    assign key_pulse[3] = key_out[3] == 0 && key_out_ff[3] == 1;


    wire i2c_ready;
    wire [RD_BYTE_NUM*8 - 1:0] rd_data;
    reg [WR_BYTE_NUM*8 - 1:0] wr_data;
    wire ack_err;
    wire rw_done;
    reg wr_ena, rd_ena;
    reg reg_addr_mode, dev_addr_mode;
    reg [7:0] reg_addr;
    wire [WR_BYTE_NUM*8 - 1:0] wr_buf;
    reg [WR_BYTE_NUM*8 - 1:0] rd_buf;
    reg [63:0] load_data;
    reg wr_buf_ena;
    reg wr_buf_mode;


    `define DEBUG
    `ifdef DEBUG
        reg[255:0] state_debug;
        always @(*) begin
            case (state)
                IDLE: state_debug = "IDLE";
                WR_DAT: state_debug = "WR_DAT";
                RD_DAT: state_debug = "RD_DAT";
                default: state_debug = "UNKNOW";
            endcase
        end   
        
    `endif

    always @(posedge clk) begin
        if(reset) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        case (state)
            IDLE: begin
                if(key_pulse[0]) begin
                    next_state = WR_DAT;
                end else if(key_pulse[1]) begin
                    next_state = RD_DAT;
                end else begin
                    next_state = IDLE;
                end
             end

             WR_DAT: begin
                if(ack_err) begin
                    next_state = ERRO;
                end
                else if(key_pulse[1]) begin
                    next_state = IDLE;
                end else begin
                    next_state = WR_DAT;
                end
             end

            RD_DAT: begin
                if(ack_err) begin
                    next_state = ERRO;
                end else if(key_pulse[0]) begin
                    next_state = IDLE;
                end else begin
                    next_state = RD_DAT;
                end
            end
            ERRO: begin
                next_state = ERRO;
            end
        endcase
    end

    always @(posedge clk) begin
        if(reset) begin
            reg_addr <= REG_ADDR;
            load_data <= 0;
            wr_ena <= 0;
            rd_ena <= 0;
            wr_buf_ena <= 0;
            wr_buf_mode <= 0;

        end else begin
            case (state)
                IDLE: begin
                    wr_ena <= 0;
                    rd_ena <= 0;
                    wr_buf_ena <= 0;
                    wr_buf_mode <= 0;
                    rd_buf <= 0;
                    //reg_addr <= REG_ADDR;
                    if(key_pulse[2]) begin
                        reg_addr <= reg_addr - 1;
                    end else if(key_pulse[3]) begin
                        reg_addr <= reg_addr + 1;
                    end
                    load_data <= {{"H"}, {"E"}, {"L"}, {"L"}, {"o"}, {"-"}, {4'h0, reg_addr[7:4]}, {4'h0, reg_addr[3:0]}};
                end

                WR_DAT: begin
                    wr_ena <= 0;
                    rd_ena <= 0;
                    wr_buf_ena <= 0;
                    load_data <= {{"A"}, {"R"}, {"-"}, {"D"}, {"a"}, {"-"}, {4'h0, wr_buf[7:4]}, {4'h0, wr_buf[3:0]}};
                    case (key_pulse)
                        4'b0001: begin
                            wr_ena <= (i2c_ready);
                            wr_data <= wr_buf;
                        end

                        4'b0100: begin
                            wr_buf_ena <= 1;
                            wr_buf_mode <= 1;
                        end
                    
                        4'b1000: begin
                            wr_buf_ena <= 1;
                            wr_buf_mode <= 0;
                        end
                    endcase
                end

                RD_DAT: begin
                    rd_ena <= 0;
                    wr_ena <= 0;
                    if(rw_done) begin
                        rd_buf <= rd_data;
                    end
                    load_data <= {{"R"}, {"D"}, {"-"}, {"D"}, {"a"}, {"-"}, {4'h0, rd_buf[7:4]}, {4'h0, rd_buf[3:0]}};
                    if(key_pulse[1]) begin
                        rd_ena <= (i2c_ready);
                    end
                    
                end

                ERRO: begin
                    wr_ena <= 0;
                    rd_ena <= 0;
                    wr_buf_ena <= 0;
                    wr_buf_mode <= 0;
                    load_data <= {{"E"}, {"R"}, {"R"}, {"O"}, {"-"}, {"-"}, {"-"}, {"-"}};
                end
            endcase
        end
    end

    counter u_counter(
        .clk(clk),
        .reset(reset),
        .ena(wr_buf_ena),
        .mode(wr_buf_mode),
        .state(state),
        .wr_buf(wr_buf)
    );

    always @(posedge clk) begin
        if(reset) begin
            key_out_ff <= 0;
        end else begin
            key_out_ff <= key_out;
        end
    end
    genvar i;
    generate
        for(i = 0; i < 4; i = i + 1) begin : gen_keydecoder
            KeyDecoder #(
                .WAIT_CYCLES(WAIT_CYCLES)
            )keydecoder_inst(
                .clk(clk),
                .reset(reset),
                .key_in(key_in[i]),
                .key_out(key_out[i])
            );
        end
    endgenerate
    

    
    wire iic_start = wr_ena | rd_ena;
    wire i2c_rw_flag = rd_ena;
    I2C_drive #(
        .P_SYS_CLK(CLK_FREQ),
        .P_IIC_SCL(I2C_FREQ),
        .P_DEVICE_ADDR(DEV_ADDR),
        .P_ADDR_BYTE_NUM(REG_ADDR_BYTE),
        .P_DATA_BYTE_NUM(RD_BYTE_NUM)
    ) 
    u_I2C_drive (
        .iic_clk(clk),
        .iic_rst(reset),
        .iic_rw_flag(i2c_rw_flag), // 1: read, 0: write
        .iic_word_addr(reg_addr),
        .iic_scl_o(i2c_scl),
        .iic_sda(i2c_sda),
        .iic_ack_error(ack_err),
        .iic_rdata(rd_data),
        .iic_rdata_valid(rd_data_valid),
        .iic_start(iic_start),
        .iic_ready(i2c_ready)
    );
    

    
    SegmentDecoder u_SegmentDecoder(
        .clk       	(clk        ),
        .reset     	(reset      ),
        .load      	(load_data  ),
        .DP_in     	(8'hff      ),
        .mode      	(8'hff      ),
        .graphData 	(64'h0      ),
        .SEGA      	(SEGA       ),
        .SEGB      	(SEGB       ),
        .SEGC      	(SEGC       ),
        .SEGD      	(SEGD       ),
        .SEGE      	(SEGE       ),
        .SEGF      	(SEGF       ),
        .SEGG      	(SEGG       ),
        .DP_out    	(DP     ),
        .SEGCOM1   	(SEGCOM1    ),
        .SEGCOM2   	(SEGCOM2    ),
        .SEGCOM3   	(SEGCOM3    ),
        .SEGCOM4   	(SEGCOM4    ),
        .SEGCOM5   	(SEGCOM5    ),
        .SEGCOM6   	(SEGCOM6    ),
        .SEGCOM7   	(SEGCOM7    ),
        .SEGCOM8   	(SEGCOM8    )
    );
    
endmodule

module counter(
    input clk,
    input reset,
    input ena,
    input mode,
    input [1:0] state,
    output reg [7:0] wr_buf
);
    localparam  WR_DAT = 2'b01,
                RD_DAT = 2'b10,
                IDLE = 2'b00;
    always @(posedge clk) begin
        if(reset) begin
            wr_buf <= 0;
        end else begin
            if(state == WR_DAT) begin
                if(mode && ena) begin
                    if(wr_buf[3:0] == 4'd9) begin
                        wr_buf[3:0] <= 0;
                        if(wr_buf[7:4] == 4'd9) begin
                            wr_buf[7:4] <= 0;
                        end else begin
                            wr_buf[7:4] <= wr_buf[7:4] + 1;
                        end
                    end else begin
                        wr_buf[3:0] <= wr_buf[3:0] + 1;
                    end
                end else if(ena) begin
                    if(wr_buf[3:0] == 0) begin
                        wr_buf[3:0] <= 4'd9;
                        if(wr_buf[7:4] == 0) begin
                            wr_buf[7:4] <= 4'd9;
                        end else begin
                            wr_buf[7:4] <= wr_buf[7:4] - 1;
                        end
                    end else begin
                        wr_buf[3:0] <= wr_buf[3:0] - 1;
                    end
                end
            end
            else begin
                wr_buf <= 0;
            end
        end
    end
endmodule