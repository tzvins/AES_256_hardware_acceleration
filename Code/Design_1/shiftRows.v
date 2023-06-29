
//shift rows transformation according to enc or dec
module shiftRows (clk, in, shifted, enc_en);
    input clk, enc_en;
	input [0:127] in;
	output reg [0:127] shifted;
	
	// First row (r = 0) is not shifted
	always @(posedge clk) begin
	shifted[0+:8] <= in[0+:8];
	shifted[32+:8] <= in[32+:8];
	shifted[64+:8] <= in[64+:8];
    shifted[96+:8] <= in[96+:8];
	
	// Second row (r = 1) is cyclically left shifted by 1 offset (right for dec)
   shifted[8+:8] <= enc_en ? in[40+:8] : in[104+:8];
   shifted[40+:8] <= enc_en ? in[72+:8] : in[8+:8];
   shifted[72+:8] <= enc_en ? in[104+:8]: in[40+:8];
   shifted[104+:8] <= enc_en ? in[8+:8] : in[72+:8];
	
	// Third row (r = 2) is cyclically left shifted by 2 offsets (right for dec)
   shifted[16+:8] <= in[80+:8];
   shifted[48+:8] <= in[112+:8];
   shifted[80+:8] <= in[16+:8];
   shifted[112+:8] <= in[48+:8];
	
	// Fourth row (r = 3) is cyclically left shifted by 3 offsets (right for dec)
   shifted[24+:8] <= enc_en ? in[120+:8] : in[56+:8];
   shifted[56+:8] <= enc_en ? in[24+:8] : in[88+:8];
   shifted[88+:8] <= enc_en ? in[56+:8] : in[120+:8];
   shifted[120+:8] <= enc_en ? in[88+:8] : in[24+:8];
   end

endmodule
