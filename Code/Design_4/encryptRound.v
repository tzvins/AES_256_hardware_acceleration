//one round. If in final round (f_rnd_en) skip the mix columns. If in dec, set correct order of operations and use inverses
module encryptRound(clk, in, key, out, enc_en, f_rnd_en);
input [127:0] in, key;
input enc_en, clk, f_rnd_en;
output reg [127:0] out;
wire [127:0] afterShiftRows;
wire [127:0] afterMixColumns;
wire [127:0] shift_ARK_sel;

assign shift_ARK_sel = (enc_en | f_rnd_en) ? afterShiftRows : afterShiftRows ^ key;

shiftRows r(clk, in ,afterShiftRows, enc_en);

mixColumns m(clk,shift_ARK_sel,afterMixColumns, enc_en);

always@(posedge clk)
    begin
        if (f_rnd_en)
            out <= shift_ARK_sel ^ key;
        else
            out <= enc_en ? afterMixColumns ^ key : afterMixColumns;
    end
endmodule