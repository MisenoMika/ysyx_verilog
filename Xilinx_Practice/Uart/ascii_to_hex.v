module ascii_to_hex(
    input [7:0] c,
    output reg [7:0] hex
);
    always @(*) begin
        if (c >= "0" && c <= "9")  begin
            hex = c - "0";
        end
        else if (c >= "A" && c <= "F") begin
            hex = c - "A" + 4'd10;
        end
        else if (c >= "a" && c <= "f") begin
            hex = c - "a" + 4'd10;
        end
        else begin
            hex = 4'h0;
        end                          
    end
endmodule