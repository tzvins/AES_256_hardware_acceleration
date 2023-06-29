`timescale 1ns / 1ps

module test_aes_256;

	// Inputs
	reg clk, rst, enc_en;
	reg  load;
	reg [127:0] state;
	reg [255:0] key;

	// Outputs
	wire [127:0] out;
	wire    done;

	// Instantiate the Unit Under Test (UUT)
	aes_256 uut (
		.clk(clk), 
		.state_in(state), 
		.key_in(key), 
		.out_f(out),
		.rst(rst),
		.done(done),
		.load(load),
		.enc_en(enc_en)
	);

	initial begin
		clk = 0;
		state = 0;
		key = 0;
		load = 0;
		rst = 1;
		enc_en = 1;
		

		#100;
         @ (negedge clk);
         #2;
         state = 128'h3243f6a8885a308d313198a2e0370734;
         key   = 256'h2b7e151628aed2a6abf7158809cf4f3c762e7160f38b4da56a784d9045190cfe;
         #10
         load = 1;
         #300;
         load = 0;
         #800;
         enc_en = 0;
         state = 128'h1a6e6c2c662e7da6501ffb62bc9e93f3;
         key   = 256'h2b7e151628aed2a6abf7158809cf4f3c762e7160f38b4da56a784d9045190cfe;
         #10
         load = 1;
         #300;
         load = 0;
         #800;
         
         enc_en = 0;
         state = 128'h00112233445566778899aabbccddeeff;
         key   = 256'h1111ffffacac7654abfe158809cf4f3c762e7160f38b4da56a784d9077774444;
         #10
         load = 1;
         #300;
         load = 0;
         #800;
         enc_en = 1;
         state = 128'h790b275d3a9ba2c859eabd4fd45a603a;
         key   = 256'h1111ffffacac7654abfe158809cf4f3c762e7160f38b4da56a784d9077774444;
         #10;
         load = 1;
         #300;
         load = 0;
         #800;
        
        #1000;
        $finish;
	end
      
    always #5 clk = ~clk;
endmodule

