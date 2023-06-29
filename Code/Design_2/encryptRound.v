//one round. If in final round (f_rnd_en) skip the mix columns. If in dec, set correct order of operations and use inverses
module encryptRound(clk, in, key, out, enc_en, f_rnd_en);
input [127:0] in, key;
input enc_en, clk, f_rnd_en;
output reg [127:0] out;
wire [127:0] afterSubBytes;
wire [127:0] afterShiftRows;
wire [127:0] afterMixColumns;
wire [127:0] afterShiftSub;

assign afterShiftSub = enc_en ? afterShiftRows : afterShiftRows ^ key;

Substitute4
    sub0 (clk,in[127:96],afterSubBytes[127:96], enc_en),
    sub1 (clk,in[95:64],afterSubBytes[95:64], enc_en),
    sub2 (clk,in[63:32],afterSubBytes[63:32], enc_en),
    sub3 (clk,in[31:0],afterSubBytes[31:0], enc_en);

shiftRows r(clk, afterSubBytes,afterShiftRows, enc_en);

mixColumns m(clk,afterShiftSub,afterMixColumns, enc_en);

always@(posedge clk)
    begin
        if (f_rnd_en)
            out <= enc_en ? afterShiftSub ^ key : afterShiftSub;
        else
            out <= enc_en ? afterMixColumns ^ key : afterMixColumns;
    end
endmodule