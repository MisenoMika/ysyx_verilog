`timescale 1ns/1ps

module I2C_driver_tb();
    reg clk;
    reg reset;
    reg wr_ena;
    reg rd_ena;
    reg [15:0] i_reg_addr;
    reg reg_addr_mode; // 0: 7-bit address, 1: 10-bit address
    reg [6:0] i_dev_addr;
    reg dev_addr_mode; // 0: 7-bit address, 1: 10-bit address
    reg [7:0] wr_data;

    wire [7:0] rd_data;
    wire ack;
    wire rw_done;
    wire i2c_scl;
    wire i2c_sda;
    wire byte_cnt_pulse;

    localparam    CLK_FREQ = 32'd50_000_000,
              I2C_FREQ = 32'd400_000,
              CLK_PERIOD = 20,
              I2C_BIT_CLK = CLK_FREQ / I2C_FREQ;

    pullup(i2c_sda);

    reg sda_slave;     // 从机驱动
    wire sda_wire;
    reg [7:0] rd_bytes;

    assign sda_wire = (sda_slave == 0) ? 0 : 1'bz;
    assign i2c_sda = sda_wire;

    I2C_driver #(
        .CLK_FREQ 	(CLK_FREQ  ),
        .I2C_FREQ 	(I2C_FREQ  ),
        .WR_BYTE_NUM(8'd1),
        .RD_BYTE_NUM(8'd1)
    ) dut (
        .clk(clk),
        .reset(reset),
        .wr_ena(wr_ena),
        .rd_ena(rd_ena),
        .i_reg_addr(i_reg_addr),
        .reg_addr_mode(reg_addr_mode),
        .i_dev_addr(i_dev_addr),
        .dev_addr_mode(dev_addr_mode),
        .wr_data(wr_data),
        .rd_data(rd_data),
        .ack(ack),
        .rw_done(rw_done),
        .i2c_scl(i2c_scl),
        .i2c_sda(i2c_sda)
    );
    task read_msg(input [7:0] data);
        integer i;
        begin
            for(i = 0; i < 8; i = i + 1) begin
                sda_slave <= data[7 - i];
                #(I2C_BIT_CLK * CLK_PERIOD);
            end
        end
    endtask
    initial begin
        clk = 0;
        reset = 1;
        wr_ena = 0;
        rd_ena = 0;
        i_reg_addr = {8'b0000_0000, 8'b0};
        reg_addr_mode = 0; 
        i_dev_addr = 7'b1010_100; 
        dev_addr_mode = 0; // 使用7-bit地址
        wr_data = 0;
        sda_slave = 1;  // 初始时从机不驱动SDA线


        #100 reset = 0; 

        
        #100 
        wr_ena = 1; 
        wr_data = 8'hAB;
        @(posedge rw_done);
        #20 wr_ena = 0; 

       
        #50
        rd_ena = 1;
        rd_bytes = 8'd1;
        read_msg(8'hCD);
        @(posedge rw_done);
        #20 rd_ena = 0; 

        
        #1000 
        $stop;
    end

    always #10 clk = ~clk; // 时钟周期为20ns


endmodule