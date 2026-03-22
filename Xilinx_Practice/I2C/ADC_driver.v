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
    
    localparam  FIRST_BYTE = 2'b00,
                SECOND_BYTE = 2'b01,
                IDLE = 2'b10,
                UPDATE = 2'b11;
    
    wire [15:0] rd_data;
    reg [7:0] wr_data;
    wire ack;
    reg wr_ena, rd_ena;
    wire rw_done;
    reg [63:0] load_data;
    reg [3:0] byte_cnt;

    reg [15:0] adc_16bit;
    wire [7:0] adc_8bit = adc_16bit[11:4];
    wire [15:0] percent = adc_8bit * 100 / 255;
    wire [7:0] hundreds = percent / 100;
    wire [7:0] tens = (percent / 10) % 10;
    wire [7:0] ones = percent % 10;
    wire byte_cnt_pulse;
    wire i_valid;
    reg loading;
    reg ack_buf;

    always @(posedge clk) begin
        if(reset) begin
            wr_ena <= 0;
            rd_ena <= 0;
            wr_data <= 0;
            byte_cnt <= 0;
            loading <= 0;
            load_data <= 0;
            ack_buf <= 0;
        end else begin
            rd_ena <= 1;
            if(rw_done) begin
                loading <= 1;
                adc_16bit <= rd_data;
                ack_buf <= ack;
            end 

            if(loading) begin
                if(ack_buf == 0) begin
                    load_data <= {{5{"-"}}, hundreds, tens, ones};
                end else begin
                    load_data <= {{"E"}, {"r"}, {"r"}, {"o"}, {4{"-"}}}; 
                end
                loading <= 0;
            end
        end
    end

    I2C_driver #(
        .CLK_FREQ 	(CLK_FREQ  ),
        .I2C_FREQ 	(I2C_FREQ  ),
        .WR_BYTE_NUM(8'd1),
        .RD_BYTE_NUM(8'd2)
        )
    u_I2C_driver(
        .clk           	(clk            ),
        .reset         	(reset          ),
        .wr_ena        	(wr_ena         ),
        .rd_ena        	(rd_ena         ),
        .i_reg_addr     ({REG_ADDR, 8'b0}   ),
        .reg_addr_mode 	(0              ),
        .i_dev_addr     (DEV_ADDR       ),
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
        .DP_in   	(8'b1111_1111    ),   
        .DP_out     (DP        ),
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
        .SEGCOM8 	(SEGCOM8  ),
        .i_valid    (i_valid    )
    );
    
endmodule