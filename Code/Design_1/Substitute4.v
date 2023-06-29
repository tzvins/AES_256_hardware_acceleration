/* substitue four bytes in a word */
module Substitute4 (clk, in, out, enc_en);
    input clk, enc_en;
    input [31:0] in;
    output [31:0] out;

    SubByte
        S_0 (clk, in[31:24], out[31:24], enc_en),
        S_1 (clk, in[23:16], out[23:16], enc_en),
        S_2 (clk, in[15:8],  out[15:8], enc_en),
        S_3 (clk, in[7:0],   out[7:0], enc_en);
endmodule