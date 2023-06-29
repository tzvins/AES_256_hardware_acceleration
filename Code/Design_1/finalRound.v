module finalRound(clk, in, key, out, enc_en);
input [127:0] in, key;
input enc_en, clk;
output reg [127:0] out;
wire [127:0] afterSubBytes;
wire [127:0] afterShiftRows;

Substitute4
    sub0 (clk,in[127:96],afterSubBytes[127:96], enc_en),
    sub1 (clk,in[95:64],afterSubBytes[95:64], enc_en),
    sub2 (clk,in[63:32],afterSubBytes[63:32], enc_en),
    sub3 (clk,in[31:0],afterSubBytes[31:0], enc_en);

shiftRows r(clk, afterSubBytes,afterShiftRows, enc_en);

always@(posedge clk)
    out <= afterShiftRows ^ key;
endmodule