module ADC_driver#(
    parameter CLK_FREQ = 32'd50_000_000,
              I2C_FREQ = 32'd400_000
)(
    input clk,
    input reset,

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
    localparam  DEV_ADDR = 7'b1010_100, 
                REG_ADDR = 8'b0000_0000; 
    // output declaration of module I2C_driver
    wire [7:0] rd_data;
    reg [7:0] wr_data;
    wire ack;
    reg wr_ena, rd_ena;
    wire rw_done;
    reg [1:0]state, next_state;
    reg [63:0] load_data;
    reg [3:0] byte_cnt;
    reg [3:0] msb, lsb;
    wire [7:0] adc_8bit = {msb[3:0], lsb[3:0]};
    wire [15:0] percent = adc_8bit * 100 / 255;
    wire [3:0] tens = percent / 10;
    wire [3:0] ones = percent % 10;

    localparam  FIRST_BYTE = 2'b00,
                SECOND_BYTE = 2'b01,
                IDLE = 2'b10,
                UPDATE = 2'b11;
    always @(posedge clk) begin
        if(reset) begin
            state <= 0;
        end
        else begin
            state <= next_state;
        end
    end

    always @(posedge clk) begin
        if(reset) begin
            wr_ena <= 0;
            rd_ena <= 1;
            wr_data <= 0;
            byte_cnt <= 0;
            msb <= 0;
            lsb <= 0;
        end else begin
            if(rw_done) begin
                case(state)
                    IDLE: begin
                        rd_ena <= 0;
                        wr_ena <= 0;
                    end
                    FIRST_BYTE: begin
                        rd_ena <= 1;
                        msb <= rd_data[3:0];
                    end

                    SECOND_BYTE: begin
                        rd_ena <= 1;
                        lsb <= rd_data[7:4];
                    end

                    UPDATE: begin
                        load_data <= {4'h0, tens, 4'h0, ones, {6{"-"}}}; 
                    end
                endcase
            end
        end
    end

    always @(*) begin
        case(state)
            IDLE: begin
                next_state = FIRST_BYTE;
            end

            FIRST_BYTE: begin
                if(rw_done) begin
                    next_state = SECOND_BYTE;
                end
                else begin
                    next_state = FIRST_BYTE;
                end
            end

            SECOND_BYTE: begin
                if(rw_done) begin
                    next_state = UPDATE;
                end
                else begin
                    next_state = SECOND_BYTE;
                end
            end

            
        endcase
    end
    I2C_driver #(
        .CLK_FREQ 	(CLK_FREQ  ),
        .I2C_FREQ 	(I2C_FREQ  )  
        )
    u_I2C_driver(
        .clk           	(clk            ),
        .reset         	(reset          ),
        .wr_ena        	(wr_ena         ),
        .rd_ena        	(rd_ena         ),
        ._reg_addr     	(REG_ADDR   ),
        .reg_addr_mode 	(0              ),
        .dev_addr      	({DEV_ADDR, 8'b0}    ),
        .dev_addr_mode 	(0 ),
        .wr_data       	(wr_data        ),
        .rd_data       	(rd_data        ),
        .ack           	(ack            ),
        .rw_done       	(rw_done        ),
        .i2c_scl       	(i2c_scl        ),
        .i2c_sda       	(i2c_sda        )
    );
    
    
    SegmentDecoder u_SegmentDecoder(
        .clk     	(clk      ),
        .reset   	(reset    ),
        .load    	(load_data  ),
        .DP_in   	(8'b0       ),
        .mode    	(8'hff        ),
        .graphData    (64'b0       ),
        .SEGA    	(SEGA     ),
        .SEGB    	(SEGB     ),
        .SEGC    	(SEGC     ),
        .SEGD    	(SEGD     ),
        .SEGE    	(SEGE     ),
        .SEGF    	(SEGF     ),
        .SEGG    	(SEGG     ),
        .SEGCOM1 	(SEGCOM1  ),
        .SEGCOM2 	(SEGCOM2  ),
        .SEGCOM3 	(SEGCOM3  ),
        .SEGCOM4 	(SEGCOM4  ),
        .SEGCOM5 	(SEGCOM5  ),
        .SEGCOM6 	(SEGCOM6  ),
        .SEGCOM7 	(SEGCOM7  ),
        .SEGCOM8 	(SEGCOM8  )
    );
    
endmodule