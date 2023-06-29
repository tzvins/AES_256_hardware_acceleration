module aes_256 (clk, state_in, key_in, out_f, load, rst, done, enc_en);
    input          clk, load, rst, enc_en;
    input  [127:0] state_in;
    input  [255:0] key_in;
    output reg [127:0] out_f;
    output reg done;
 ///////// 
    wire  [127:0]  s_out;
    reg    [6:0]   cnt;
    reg    [127:0] s_in, round_key;
    reg    [255:0] k0, k0a, k1;
    wire   [255:0] k2, k3, k4, k5, k6, k7, k8,
                   k9, k10, k11, k12, k13;
    wire   [127:0] k0b, k1b, k2b, k3b, k4b, k5b, k6b, k7b, k8b,
                   k9b, k10b, k11b, k12b, k13b, k14b;
    wire   [127:0] key0, key1, key2, key3, key4, key5, key6, key7, key8,
                   key9, key10, key11, key12, key13, key14;   
    wire           final_rnd_en;           
//////////

//select round key according to cycle number
    always @(posedge clk)
    begin
        case(cnt)
            7'h46: round_key <= key1;
            7'h41: round_key <= key2;
            7'h3c: round_key <= key3;
            7'h37: round_key <= key4;
            7'h32: round_key <= key5;
            7'h2d: round_key <= key6;
            7'h28: round_key <= key7;
            7'h23: round_key <= key8;
            7'h1e: round_key <= key9;
            7'h19: round_key <= key10;
            7'h14: round_key <= key11;
            7'hf: round_key <= key12;
            7'ha: round_key <= key13;
            7'h5: round_key <= key14;
        endcase
    end
    
//update input of round according to cycle number
    always @(posedge clk)
    begin
        case(cnt)
            7'h46: s_in <= state_in ^ key0;
            7'h41: s_in <= s_out;
            7'h3c: s_in <= s_out;
            7'h37: s_in <= s_out;
            7'h32: s_in <= s_out;
            7'h2d: s_in <= s_out;
            7'h28: s_in <= s_out;
            7'h23: s_in <= s_out;
            7'h1e: s_in <= s_out;
            7'h19: s_in <= s_out;
            7'h14: s_in <= s_out;
            7'hf: s_in <= s_out;
            7'ha: s_in <= s_out;
            7'h5: s_in <= s_out;
        endcase
    end
             
//update counter
    always @ (posedge clk)
      begin
        if(!rst)    cnt <= #1 7'h0;
        else
        if(load) begin
           cnt <= #1 7'h46; //enc_en ? 7'h46 : 7'h52; no need for longer decryption time since load pulse is long
        end
        else
        if(|cnt)    cnt <= #1 cnt - 7'h1;
      end
      
//sample output when done bit rises
     always @ (posedge done)
      begin
        out_f <= s_out;
      end
      
//if counter finishes, raise done bit
     always @ (posedge clk)
     begin
       if(cnt <= 1)
       begin
            done <= #1 1;
       end
       else
       begin
            done <= #1 0;
       end
     end
      
    always @ (posedge clk)
      begin
        k0 <= key_in;
        k0a <= k0;
        k1 <= k0a;
      end

    assign k1b = k0a[127:0];
    assign k0b = k0a[255:128];

//reverse round keys if in decryption
    assign {key0,key1,key2,key3,key4,key5,key6,key7,key8,key9,key10,key11,key12,key13,key14} = enc_en ? {k0b,k1b,k2b,k3b,k4b,k5b,k6b,k7b,k8b,k9b,k10b,k11b,k12b,k13b,k14b} : {k14b,k13b,k12b,k11b,k10b,k9b,k8b,k7b,k6b,k5b,k4b,k3b,k2b,k1b,k0b};

//set round to last round if counter is less than 5
    assign final_rnd_en = (cnt <= 7'h4) ? 1'b1 : 1'b0;

    expand_key_type_A_256
        a1 (clk, k1, 8'h1, k2, k2b),
        a3 (clk, k3, 8'h2, k4, k4b),
        a5 (clk, k5, 8'h4, k6, k6b),
        a7 (clk, k7, 8'h8, k8, k8b),
        a9 (clk, k9, 8'h10, k10, k10b),
        a11 (clk, k11, 8'h20, k12, k12b),
        a13 (clk, k13, 8'h40,    , k14b);

    expand_key_type_B_256
        a2 (clk, k2, k3, k3b),
        a4 (clk, k4, k5, k5b),
        a6 (clk, k6, k7, k7b),
        a8 (clk, k8, k9, k9b),
        a10 (clk, k10, k11, k11b),
        a12 (clk, k12, k13, k13b);
    
    encryptRound
         r (clk, s_in, round_key, s_out, enc_en, final_rnd_en);
         
endmodule

/* expand k0,k1,k2,k3 for every two clock cycles */
module expand_key_type_A_256 (clk, in, rcon, out_1, out_2);
    input              clk;
    input      [255:0] in;
    input      [7:0]   rcon;
    output reg [255:0] out_1;
    output     [127:0] out_2;
    wire       [31:0]  k0, k1, k2, k3, k4, k5, k6, k7,
                       v0, v1, v2, v3;
    reg        [31:0]  k0a, k1a, k2a, k3a, k4a, k5a, k6a, k7a;
    wire       [31:0]  k0b, k1b, k2b, k3b, k4b, k5b, k6b, k7b, k8a;

    assign {k0, k1, k2, k3, k4, k5, k6, k7} = in;
    
    assign v0 = {k0[31:24] ^ rcon, k0[23:0]};
    assign v1 = v0 ^ k1;
    assign v2 = v1 ^ k2;
    assign v3 = v2 ^ k3;

    always @ (posedge clk)
        {k0a, k1a, k2a, k3a, k4a, k5a, k6a, k7a} <= {v0, v1, v2, v3, k4, k5, k6, k7};

    Substitute4
        S4_0 (clk, {k7[23:0], k7[31:24]}, k8a, 1'b1);

    assign k0b = k0a ^ k8a;
    assign k1b = k1a ^ k8a;
    assign k2b = k2a ^ k8a;
    assign k3b = k3a ^ k8a;
    assign {k4b, k5b, k6b, k7b} = {k4a, k5a, k6a, k7a};

    always @ (posedge clk)
        out_1 <= {k0b, k1b, k2b, k3b, k4b, k5b, k6b, k7b};

    assign out_2 = {k0b, k1b, k2b, k3b};
endmodule

/* expand k4,k5,k6,k7 for every two clock cycles */
module expand_key_type_B_256 (clk, in, out_1, out_2);
    input              clk;
    input      [255:0] in;
    output reg [255:0] out_1;
    output     [127:0] out_2;
    wire       [31:0]  k0, k1, k2, k3, k4, k5, k6, k7,
                       v5, v6, v7;
    reg        [31:0]  k0a, k1a, k2a, k3a, k4a, k5a, k6a, k7a;
    wire       [31:0]  k0b, k1b, k2b, k3b, k4b, k5b, k6b, k7b, k8a;

    assign {k0, k1, k2, k3, k4, k5, k6, k7} = in;
    
    assign v5 = k4 ^ k5;
    assign v6 = v5 ^ k6;
    assign v7 = v6 ^ k7;

    always @ (posedge clk)
        {k0a, k1a, k2a, k3a, k4a, k5a, k6a, k7a} <= {k0, k1, k2, k3, k4, v5, v6, v7};

    Substitute4
        S4_0 (clk, k3, k8a, 1'b1);

    assign {k0b, k1b, k2b, k3b} = {k0a, k1a, k2a, k3a};
    assign k4b = k4a ^ k8a;
    assign k5b = k5a ^ k8a;
    assign k6b = k6a ^ k8a;
    assign k7b = k7a ^ k8a;

    always @ (posedge clk)
        out_1 <= {k0b, k1b, k2b, k3b, k4b, k5b, k6b, k7b};

    assign out_2 = {k4b, k5b, k6b, k7b};
endmodule
