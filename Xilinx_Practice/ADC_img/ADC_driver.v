module ADC_driver#(
    parameter CLK_FREQ = 28'd50_000_000,
              I2C_FREQ = 28'd400_000
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
            REG_ADDR = 8'b0000_0000,
            BYTE_RD_NUM = 8'd2,
            DEV_ADDR_BYTE = 8'd1,
            REG_ADDR_BYTE = 8'd1;

    reg iic_start;
    wire iic_ready;
    wire rd_data_valid;
    reg [BYTE_RD_NUM*8 - 1:0] buf_rd_data;
    wire [BYTE_RD_NUM*8 - 1:0] iic_rd_data;
    wire ack_err;
    I2C_drive #(
        .P_SYS_CLK(CLK_FREQ),
        .P_IIC_SCL(I2C_FREQ),
        .P_DEVICE_ADDR(DEV_ADDR),
        .P_ADDR_BYTE_NUM(REG_ADDR_BYTE),
        .P_DATA_BYTE_NUM(BYTE_RD_NUM)
    ) 
    u_I2C_drive (
        .iic_clk(clk),
        .iic_rst(reset),
        .iic_rw_flag(1'b1), // 1: read, 0: write
        .iic_word_addr(REG_ADDR),
        .iic_scl_o(i2c_scl),
        .iic_sda(i2c_sda),
        .iic_ack_error(ack_err),
        .iic_rdata(iic_rd_data),
        .iic_rdata_valid(rd_data_valid),
        .iic_start(iic_start),
        .iic_ready(iic_ready)
    );

    always @(posedge clk) begin
        if(reset) begin
            iic_start <= 1'b0;
        end
        else begin
            iic_start <= 1'b1; 
            if(rd_data_valid) begin
                buf_rd_data <= iic_rd_data;
            end
        end
    end
    
    wire [7:0] adc_data = buf_rd_data[11:4];
    wire [19:0] percent = adc_data * 330 / 255;
    wire [7:0] adc_unit = percent % 10;
    wire [7:0] adc_ten = (percent / 10) % 10;
    wire [7:0] adc_hundred = percent / 100;
    wire [7:0] H = "H", E = "E", L = "L", O = "O";
    wire [63:0] load = {H, E, L, L, O, adc_hundred, adc_ten, adc_unit};
    SegmentDecoder u_SegmentDecoder(
        .clk     	(clk      ),
        .reset   	(reset    ),
        .load    	(load     ),
        .DP_in  	(8'b1111_1011   ),
        .DP_out     (DP),
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