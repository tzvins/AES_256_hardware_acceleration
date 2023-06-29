//mix columns and its inverse
module mixColumns(clk, state_in, state_out, enc_en);
input clk, enc_en;
input [127:0] state_in;
output reg [127:0] state_out;

//This function multiplies by {02} n-times
function[7:0] multiply(input [7:0]x,input integer n);
integer i;
begin
	for(i=0;i<n;i=i+1)begin
		if(x[7] == 1) x = ((x << 1) ^ 8'h1b);
		else x = x << 1; 
	end
	multiply=x;
end

endfunction


/* 
	Multiply by {0e} is done by :
	(multiplying by {02} 3 times which is equivalent to multiplication by {08}) xor
	(multiplying by {02} 2 times which is equivalent to multiplication by {04}) xor
	(multiplying by {02})
	so that 8+4+2= e. where xor is the addition of elements in finite fields
*/
function [7:0] mb0e; //multiply by {0e}
input [7:0] x;
begin
	mb0e=multiply(x,3) ^ multiply(x,2)^ multiply(x,1);
end
endfunction

/* 
	Multiply by {0d} is done by :
	(multiplying by {02} 3 times which is equivalent to multiplication by {08}) xor
	(multiplying by {02} 2 times which is equivalent to multiplication by {04}) xor
	(the original x)
	so that 8+4+1= d. where xor is the addition of elements in finite fields
*/
function [7:0] mb0d; //multiply by {0d}
input [7:0] x;
begin
	mb0d=multiply(x,3) ^ multiply(x,2)^ x;
end
endfunction


/* 
	Multiply by {0b} is done by :
	(multiplying by {02} 3 times which is equivalent to multiplication by {08}) xor
	(multiplying by {02}) xor (the original x)
	so that 8+2+1= b. where xor is the addition of elements in finite fields
*/

function [7:0] mb0b;  //multiply by {0b}
input [7:0] x;
begin
	mb0b=multiply(x,3) ^ multiply(x,1)^ x;
end
endfunction
/* 
	Multiply by {09} is done by :
	(multiplying by {02} 3 times which is equivalent to multiplication by {08}) xor (the original x)
	so that 8+1= 9. where xor is the addition of elements in finite fields
*/

function [7:0] mb09; //multiply by {09}
input [7:0] x;
begin
	mb09=multiply(x,3) ^  x;
end
endfunction

function [7:0] mb2; //multiply by 2
	input [7:0] x;
	begin 
			/* multiplication by 2 is shifting on bit to the left, and if the original 8 bits had a 1 @ MSB,
			xor the result with {1b}*/
			if(x[7] == 1) mb2 = ((x << 1) ^ 8'h1b);
			else mb2 = x << 1; 
	end 	
endfunction


/* 
	multiplication by 3 is done by:
		multiplication by {02} xor(the original x)
		so that 2+1=3. where xor is the addition of elements in finite fields
*/
function [7:0] mb3; //multiply by 3
	input [7:0] x;
	begin 
			
			mb3 = mb2(x) ^ x;
	end 
endfunction




always@(posedge clk) begin
if(enc_en) begin
	state_out[(0*32 + 24)+:8]<= mb2(state_in[(0*32 + 24)+:8]) ^ mb3(state_in[(0*32 + 16)+:8]) ^ state_in[(0*32 + 8)+:8] ^ state_in[0*32+:8];
	state_out[(0*32 + 16)+:8]<= state_in[(0*32 + 24)+:8] ^ mb2(state_in[(0*32 + 16)+:8]) ^ mb3(state_in[(0*32 + 8)+:8]) ^ state_in[0*32+:8];
	state_out[(0*32 + 8)+:8]<= state_in[(0*32 + 24)+:8] ^ state_in[(0*32 + 16)+:8] ^ mb2(state_in[(0*32 + 8)+:8]) ^ mb3(state_in[0*32+:8]);
    state_out[0*32+:8]<= mb3(state_in[(0*32 + 24)+:8]) ^ state_in[(0*32 + 16)+:8] ^ state_in[(0*32 + 8)+:8] ^ mb2(state_in[0*32+:8]);
    
    state_out[(1*32 + 24)+:8]<= mb2(state_in[(1*32 + 24)+:8]) ^ mb3(state_in[(1*32 + 16)+:8]) ^ state_in[(1*32 + 8)+:8] ^ state_in[1*32+:8];
	state_out[(1*32 + 16)+:8]<= state_in[(1*32 + 24)+:8] ^ mb2(state_in[(1*32 + 16)+:8]) ^ mb3(state_in[(1*32 + 8)+:8]) ^ state_in[1*32+:8];
	state_out[(1*32 + 8)+:8]<= state_in[(1*32 + 24)+:8] ^ state_in[(1*32 + 16)+:8] ^ mb2(state_in[(1*32 + 8)+:8]) ^ mb3(state_in[1*32+:8]);
    state_out[1*32+:8]<= mb3(state_in[(1*32 + 24)+:8]) ^ state_in[(1*32 + 16)+:8] ^ state_in[(1*32 + 8)+:8] ^ mb2(state_in[1*32+:8]);
    
    state_out[(2*32 + 24)+:8]<= mb2(state_in[(2*32 + 24)+:8]) ^ mb3(state_in[(2*32 + 16)+:8]) ^ state_in[(2*32 + 8)+:8] ^ state_in[2*32+:8];
	state_out[(2*32 + 16)+:8]<= state_in[(2*32 + 24)+:8] ^ mb2(state_in[(2*32 + 16)+:8]) ^ mb3(state_in[(2*32 + 8)+:8]) ^ state_in[2*32+:8];
	state_out[(2*32 + 8)+:8]<= state_in[(2*32 + 24)+:8] ^ state_in[(2*32 + 16)+:8] ^ mb2(state_in[(2*32 + 8)+:8]) ^ mb3(state_in[2*32+:8]);
    state_out[2*32+:8]<= mb3(state_in[(2*32 + 24)+:8]) ^ state_in[(2*32 + 16)+:8] ^ state_in[(2*32 + 8)+:8] ^ mb2(state_in[2*32+:8]);
    
    state_out[(3*32 + 24)+:8]<= mb2(state_in[(3*32 + 24)+:8]) ^ mb3(state_in[(3*32 + 16)+:8]) ^ state_in[(3*32 + 8)+:8] ^ state_in[3*32+:8];
	state_out[(3*32 + 16)+:8]<= state_in[(3*32 + 24)+:8] ^ mb2(state_in[(3*32 + 16)+:8]) ^ mb3(state_in[(3*32 + 8)+:8]) ^ state_in[3*32+:8];
	state_out[(3*32 + 8)+:8]<= state_in[(3*32 + 24)+:8] ^ state_in[(3*32 + 16)+:8] ^ mb2(state_in[(3*32 + 8)+:8]) ^ mb3(state_in[3*32+:8]);
    state_out[3*32+:8]<= mb3(state_in[(3*32 + 24)+:8]) ^ state_in[(3*32 + 16)+:8] ^ state_in[(3*32 + 8)+:8] ^ mb2(state_in[3*32+:8]);
end else begin
    state_out[(0*32 + 24)+:8]<= mb0e(state_in[(0*32 + 24)+:8]) ^ mb0b(state_in[(0*32 + 16)+:8]) ^ mb0d(state_in[(0*32 + 8)+:8]) ^ mb09(state_in[0*32+:8]);
	state_out[(0*32 + 16)+:8]<= mb09(state_in[(0*32 + 24)+:8]) ^ mb0e(state_in[(0*32 + 16)+:8]) ^ mb0b(state_in[(0*32 + 8)+:8]) ^ mb0d(state_in[0*32+:8]);
	state_out[(0*32 + 8)+:8]<= mb0d(state_in[(0*32 + 24)+:8]) ^ mb09(state_in[(0*32 + 16)+:8]) ^ mb0e(state_in[(0*32 + 8)+:8]) ^ mb0b(state_in[0*32+:8]);
    state_out[0*32+:8]<= mb0b(state_in[(0*32 + 24)+:8]) ^ mb0d(state_in[(0*32 + 16)+:8]) ^ mb09(state_in[(0*32 + 8)+:8]) ^ mb0e(state_in[0*32+:8]);
    
    state_out[(1*32 + 24)+:8]<= mb0e(state_in[(1*32 + 24)+:8]) ^ mb0b(state_in[(1*32 + 16)+:8]) ^ mb0d(state_in[(1*32 + 8)+:8]) ^ mb09(state_in[1*32+:8]);
	state_out[(1*32 + 16)+:8]<= mb09(state_in[(1*32 + 24)+:8]) ^ mb0e(state_in[(1*32 + 16)+:8]) ^ mb0b(state_in[(1*32 + 8)+:8]) ^ mb0d(state_in[1*32+:8]);
	state_out[(1*32 + 8)+:8]<= mb0d(state_in[(1*32 + 24)+:8]) ^ mb09(state_in[(1*32 + 16)+:8]) ^ mb0e(state_in[(1*32 + 8)+:8]) ^ mb0b(state_in[1*32+:8]);
    state_out[1*32+:8]<= mb0b(state_in[(1*32 + 24)+:8]) ^ mb0d(state_in[(1*32 + 16)+:8]) ^ mb09(state_in[(1*32 + 8)+:8]) ^ mb0e(state_in[1*32+:8]);
    
    state_out[(2*32 + 24)+:8]<= mb0e(state_in[(2*32 + 24)+:8]) ^ mb0b(state_in[(2*32 + 16)+:8]) ^ mb0d(state_in[(2*32 + 8)+:8]) ^ mb09(state_in[2*32+:8]);
	state_out[(2*32 + 16)+:8]<= mb09(state_in[(2*32 + 24)+:8]) ^ mb0e(state_in[(2*32 + 16)+:8]) ^ mb0b(state_in[(2*32 + 8)+:8]) ^ mb0d(state_in[2*32+:8]);
	state_out[(2*32 + 8)+:8]<= mb0d(state_in[(2*32 + 24)+:8]) ^ mb09(state_in[(2*32 + 16)+:8]) ^ mb0e(state_in[(2*32 + 8)+:8]) ^ mb0b(state_in[2*32+:8]);
    state_out[2*32+:8]<= mb0b(state_in[(2*32 + 24)+:8]) ^ mb0d(state_in[(2*32 + 16)+:8]) ^ mb09(state_in[(2*32 + 8)+:8]) ^ mb0e(state_in[2*32+:8]);
    
    state_out[(3*32 + 24)+:8]<= mb0e(state_in[(3*32 + 24)+:8]) ^ mb0b(state_in[(3*32 + 16)+:8]) ^ mb0d(state_in[(3*32 + 8)+:8]) ^ mb09(state_in[3*32+:8]);
	state_out[(3*32 + 16)+:8]<= mb09(state_in[(3*32 + 24)+:8]) ^ mb0e(state_in[(3*32 + 16)+:8]) ^ mb0b(state_in[(3*32 + 8)+:8]) ^ mb0d(state_in[3*32+:8]);
	state_out[(3*32 + 8)+:8]<= mb0d(state_in[(3*32 + 24)+:8]) ^ mb09(state_in[(3*32 + 16)+:8]) ^ mb0e(state_in[(3*32 + 8)+:8]) ^ mb0b(state_in[3*32+:8]);
    state_out[3*32+:8]<= mb0b(state_in[(3*32 + 24)+:8]) ^ mb0d(state_in[(3*32 + 16)+:8]) ^ mb09(state_in[(3*32 + 8)+:8]) ^ mb0e(state_in[3*32+:8]);
end
end

endmodule