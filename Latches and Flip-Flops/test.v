module top_module( 
    input  [99:0]in,
    output [99:0]out );
    genvar i;
    generate
        for(i=0; i<100; i=i+1) begin : pack
            assign out[i] = in[i];
        end
    endgenerate
endmodule