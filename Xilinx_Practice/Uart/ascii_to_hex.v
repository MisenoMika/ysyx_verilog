module ascii_to_hex(
    input [7:0] ascii_in,
    output reg [7:0] o_hex
);

    always @(*) begin
        if (ascii_in >= "0" && ascii_in <= "9")  begin
            o_hex = ascii_in - "0"; // 0 < o_hex < 9
        end
        else if (ascii_in >= "A" && ascii_in <= "Z") begin
            o_hex = ascii_in - "A" + 8'd10;
        end
        else if (ascii_in >= "a" && ascii_in <= "z") begin
            o_hex = ascii_in - "a" + 8'd10;
        end
        else begin
            o_hex = ascii_in; // 非法输入直接输出原值
        end                          
    end
endmodule