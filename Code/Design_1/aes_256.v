module aes_256 (clk, state_in, key_in, out_f, load, rst, done, enc_en);
    input          clk, load, rst, enc_en;
    input  [127:0] state_in;
    input  [255:0] key_in;
    output reg [127:0] out_f;
    output reg done;
 /////////  
    reg  [127:0]   state;
    reg  [255:0]   key;
    reg            enc_en_r;
    wire  [127:0]  out;
    reg            load_r;
    reg    [6:0]   cnt;
    reg    [127:0] s0; 
    reg    [255:0] k0, k0a, k1;
    wire   [127:0] s1, s2, s3, s4, s5, s6, s7, s8,
                   s9, s10, s11, s12, s13; 
    wire   [255:0] k2, k3, k4, k5, k6, k7, k8,
                   k9, k10, k11, k12, k13;
    wire   [127:0] k0b, k1b, k2b, k3b, k4b, k5b, k6b, k7b, k8b,
                   k9b, k10b, k11b, k12b, k13b, k14b; //round keys
    wire   [127:0] key0, key1, key2, key3, key4, key5, key6, key7, key8,
                   key9, key10, key11, key12, key13, key14;    
//////////

    //if load is high -> sample input signals
    always @ (posedge clk)
        begin 
            if(load_r) 
            begin
                state <= #1 state_in;
                key <= #1 key_in;
                enc_en_r <= enc_en;
            end
         end
    always @ (posedge clk) load_r <= #1 load;
    
    //if load is high, set counter according to number of cycles needed to complete encryption/decryption.
    //else, reduce counter by 1 each cycle. if in reset then reset counter
    always @ (posedge clk)
      begin
        if(!rst)    cnt <= #1 7'h0;
        else
        if(load_r)    cnt <= #1 enc_en_r ? 7'h38 : 7'h52;
        else
        if(|cnt)    cnt <= #1 cnt - 7'h1;
      end
      
      //counter finished, sample output 
     always @ (posedge done)
      begin
        out_f <= #1 out;
      end
      
      //if counter finished, raise done bit
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
        s0 <= state ^ key0; //initial add round key
        k0 <= key;
        k0a <= k0;
        k1 <= k0a;
      end

    assign k1b = k0a[127:0];
    assign k0b = k0a[255:128];
    //reverse round keys if in decryption
    assign {key0,key1,key2,key3,key4,key5,key6,key7,key8,key9,key10,key11,key12,key13,key14} = enc_en_r ? {k0b,k1b,k2b,k3b,k4b,k5b,k6b,k7b,k8b,k9b,k10b,k11b,k12b,k13b,k14b} : {k14b,k13b,k12b,k11b,k10b,k9b,k8b,k7b,k6b,k5b,k4b,k3b,k2b,k1b,k0b};

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
    
    //each round
    encryptRound
         r1 (clk, s0, key1, s1, enc_en_r),
         r2 (clk, s1, key2, s2, enc_en_r),
         r3 (clk, s2, key3, s3, enc_en_r),
         r4 (clk, s3, key4, s4, enc_en_r),
         r5 (clk, s4, key5, s5, enc_en_r),
         r6 (clk, s5, key6, s6, enc_en_r),
         r7 (clk, s6, key7, s7, enc_en_r),
         r8 (clk, s7, key8, s8, enc_en_r),
         r9 (clk, s8, key9, s9, enc_en_r),
        r10 (clk, s9, key10, s10, enc_en_r),
        r11 (clk, s10, key11, s11, enc_en_r),
        r12 (clk, s11, key12, s12, enc_en_r),
        r13 (clk, s12, key13, s13, enc_en_r);
    //final round
    finalRound
        rf (clk, s13, key14, out, enc_en_r);
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