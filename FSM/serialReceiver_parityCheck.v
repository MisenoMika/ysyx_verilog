module top_module(
    input clk,
    input in,
    input reset,    // Synchronous reset
    output [7:0] out_byte,
    output done
); //

    parameter IDLE = 2'b00, WRONG = 2'b01, DATA= 2'b10, DONE = 2'b11;
    reg [1:0] state, next_state; 
    reg [7:0] data;
    reg [31:0] count;
    wire odd;
    wire parity_reset;
    always@(*) begin
        case(state)
            IDLE: begin
                if(in == 0) begin
                    next_state = DATA;
                end
                else begin
                    next_state = IDLE;
                end
            end
            WRONG: begin
                if(in == 1)begin
                    next_state = IDLE;
                end
                else next_state = WRONG;
            end
            DATA: begin
                if (count < 10)begin 
                    next_state = DATA;
                end
                else begin
                    if (in) begin
                        if (odd)
                            next_state = DONE;
                        else
                            next_state = IDLE;
                    end
                    else
                        next_state = WRONG;
                end
            end
            DONE: begin
                if(in == 0) begin
                    next_state = DATA;
                end
                else begin
                    next_state = IDLE;
                end
            end
            default: next_state = IDLE;
        endcase
    end
    
    parity p1(.clk(clk), .reset(parity_reset), .in(in), .odd(odd) );   
    
    always@(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            count <= 0;
            data <= 0;
        end 
        else begin
            state <= next_state;
            if(next_state == DATA) begin
                count <= count + 1'd1;//计数逻辑一定要能够反映题目要求，即计我们需要数的一共11位数字，
                //本来写的条件是if(state == data)，但这样会有时序错误（在组合逻辑判断出即将跳出时count仍然错误执行+1）
                //Update:其实上面说的不绝对，也可以通过state==DATA来实现，总之关键是搞清楚每个状态的临界状态是不是正确的
                //不过通过next_state来判断会更直观一些（DATA期间总共需要记录10次数据(8位data,1位parity_check,1位stop_check)，count几次即记录几次），
                //不容易出错，建议以后还是这么写
            end
            else begin
                count <= 0;
            end
            if(next_state == DATA && count <= 8) begin
                data[count-1] <= in;
            end
        end
    end

    assign done = (state == DONE);
    assign out_byte = (state == DONE)? data : 8'b0;
    assign parity_reset = !(state == DATA);
endmodule

module parity (
    input clk,
    input reset,
    input in,
    output reg odd);

    always @(posedge clk)
        if (reset) odd <= 0;
        else if (in) odd <= ~odd;
endmodule

//以下这版代码为不通过next_state判断的
module top_module_(
    input clk,
    input in,
    input reset,    // Synchronous reset
    output [7:0] out_byte,
    output done
); //

    parameter IDLE = 2'b00, WRONG = 2'b01, DATA= 2'b10, DONE = 2'b11;
    reg [1:0] state, next_state; 
    reg [7:0] data;
    reg [31:0] count;
    wire odd;
    wire parity_reset;
    always@(*) begin
        case(state)
            IDLE: begin
                if(in == 0) begin
                    next_state = DATA;
                end
                else begin
                    next_state = IDLE;
                end
            end
            WRONG: begin
                if(in == 1)begin
                    next_state = IDLE;
                end
                else next_state = WRONG;
            end
            DATA: begin
                if (count < 9)begin 
                    next_state = DATA;
                end
                else begin
                    if (in) begin
                        if (odd)
                            next_state = DONE;
                        else
                            next_state = IDLE;
                    end
                    else
                        next_state = WRONG;
                end
            end
            DONE: begin
                if(in == 0) begin
                    next_state = DATA;
                end
                else begin
                    next_state = IDLE;
                end
            end
            default: next_state = IDLE;
        endcase
    end
    
    parity p1(.clk(clk), .reset(parity_reset), .in(in), .odd(odd) );   
    
    always@(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            count <= 0;
            data <= 0;
        end 
        else begin
            state <= next_state;
            if(state == DATA) begin
                count <= count + 1'd1;//计数逻辑一定要能够反映题目要求，即计我们需要数的一共11位数字，
                //本来写的条件是if(state == data)，但这样会有时序错误（在组合逻辑判断出即将跳出时count仍然错误执行+1）
            end
            else begin
                count <= 0;
            end
            if(next_state == DATA && count < 8) begin
                data[count] <= in;
            end
        end
    end

    assign done = (state == DONE);
    assign out_byte = (state == DONE)? data : 8'b0;
    assign parity_reset = !(state == DATA);
endmodule