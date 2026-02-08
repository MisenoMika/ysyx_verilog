module top_module(
    input clk,
    input load,
    input [255:0] data,
    output logic [255:0] q ); 
    logic [15:0][15:0] q_next, q_2d;//[i][j]
    logic [255:0]q_1d;
    always @(posedge clk)begin
        if(load)begin
            q <= data;
        end
        else if(~load)begin
            q <= q_1d;
        end
    end
    always_comb begin  
    for(int k=0; k<16; k=k+1)begin
        for(int m=0; m<16; m=m+1)begin
            q_2d[k][m] = q[k*16 + m];
        end
    end
        for(int i=0; i<16; i=i+1)begin
            for(int j=0; j<16; j++)begin
                int j_left, j_right, i_down, i_up;
                int count;
                j_left = (j + 4'b1111) & 4'b1111;
                j_right = (j + 4'b0001) & 4'b1111;
                i_down = (i + 4'b0001) & 4'b1111;
                i_up = (i + 4'b1111) & 4'b1111;
                count = q_2d[i_up][j] + q_2d[i_up][j_right] + q_2d[i][j_right] + q_2d[i_down][j_right] +
                        q_2d[i_down][j] + q_2d[i_down][j_left] + q_2d[i][j_left] + q_2d[i_up][j_left];
                case(count)
                    0: q_next[i][j] = 0;
                    1: q_next[i][j] = 0;
                    2: q_next[i][j] = q_2d[i][j];
                    3: q_next[i][j] = 1;
                    default: q_next[i][j] = 0;
                endcase 
            end 
        end
        for(int i=0; i<16; i=i+1)begin
            for(int j=0; j<16; j=j+1)begin
                q_1d[i*16 + j] = q_next[i][j];
            end
        end
    end
endmodule
