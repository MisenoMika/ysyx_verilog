`timescale 1ns/1ps

module I2C_bit_shift_tb;
localparam   START = 7'b0000001,
                WR = 7'b0000010,
                RD = 7'b0000100,
                STOP = 7'b0001000,
                ACK = 7'b0010000,
                NACK = 7'b0100000;

localparam    CLK_FREQ = 32'd50_000_000,
              I2C_FREQ = 32'd400_000,
              CLK_PERIOD = 20,
              I2C_BIT_CLK = CLK_FREQ / I2C_FREQ;

reg clk;
reg reset;
reg tx_ena;
reg [6:0] cmd;
reg [7:0] tx_data;

wire [7:0] rx_data;
wire ack_o;
wire tran_done;
wire i2c_scl;
wire i2c_sda;
pullup(i2c_sda);

reg sda_slave;     // 从机驱动
wire sda_wire;


assign sda_wire = (sda_slave == 0) ? 0 : 1'bz;
assign i2c_sda = sda_wire;

I2C_bit_shift dut(
    .clk(clk),
    .reset(reset),
    .wr_ena(tx_ena),
    .cmd(cmd),
    .tx_data(tx_data),
    .rx_data(rx_data),
    .ack_o(ack_o),
    .tran_done(tran_done),
    .i2c_scl(i2c_scl),
    .i2c_sda(i2c_sda)
);


initial clk = 0;
always #(CLK_PERIOD/2) clk = ~clk;   

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
    reset = 1;
    tx_ena = 0;
    cmd = 0;
    tx_data = 8'hA5;
    sda_slave = 1;  

    #100;
    reset = 0;

    #50;
    tx_ena = 1;
    tx_data = 8'b1010_1000;
    cmd = START | WR;  
    @(posedge tran_done);

    tx_ena = 0;
    #110;
    tx_ena = 1;
    cmd = WR;
    tx_data = 8'b0000_0000;
    @(posedge tran_done);

    tx_ena = 0;
    #110;
    tx_ena = 1;
    cmd = WR|STOP;
    tx_data = 8'b1111_1111;
    @(posedge tran_done);  

    tx_ena = 0;
    #110;
    tx_ena = 1;
    cmd = START | WR;
    tx_data = 8'b1010_1001;
    @(posedge tran_done);

    tx_ena = 0;
    #110;
    tx_ena = 1;
    cmd = WR;
    tx_data = 8'b0000_0000;
    @(posedge tran_done);

    tx_ena = 0;
    #110;
    tx_ena = 1;
    cmd = START | WR;
    tx_data = 8'b1010_1001;
    @(posedge tran_done);

    tx_ena = 0;
    #110;
    tx_ena = 1;
    cmd = RD;
    read_msg(8'b1100_1100);
    @(posedge tran_done);

    #100;

    #200;
    $stop;
end

endmodule