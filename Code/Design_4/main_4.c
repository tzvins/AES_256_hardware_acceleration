#include "xparameters.h"
#include "xil_io.h"
#include "xbasic_types.h"
#include "xtmrctr.h"
#include <stdio.h>
#include <stdint.h>

// XPAR_ENCDEC5_2_IP_0_S00_AXI_BASEADDR = 0x44A00000
// base addresses for hardware registers:
#define INPUT_ADDR			XPAR_ENCDEC5_2_IP_0_S00_AXI_BASEADDR
#define KEY_ADDR 			XPAR_ENCDEC5_2_IP_0_S00_AXI_BASEADDR + 16 	//4*4
#define OUT_ADDR 			XPAR_ENCDEC5_2_IP_0_S00_AXI_BASEADDR + 32	//4*8
#define CNTL_ADDR 			XPAR_ENCDEC5_2_IP_0_S00_AXI_BASEADDR + 48	//4*12 ENC_EN-0, f_rnd_en - 1

#define KEY_LENGTH 32
#define KEY 0
#define PLAINTEXT 1
#define ENCYPTED_TEXT 2
#define DECRYPTED_TEXT 3

// Sbox lookup table
static const uint8_t sbox[256] = {
    0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5,
    0x30, 0x01, 0x67, 0x2b, 0xfe, 0xd7, 0xab, 0x76,
    0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 0x47, 0xf0,
    0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0,
    0xb7, 0xfd, 0x93, 0x26, 0x36, 0x3f, 0xf7, 0xcc,
    0x34, 0xa5, 0xe5, 0xf1, 0x71, 0xd8, 0x31, 0x15,
    0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05, 0x9a,
    0x07, 0x12, 0x80, 0xe2, 0xeb, 0x27, 0xb2, 0x75,
    0x09, 0x83, 0x2c, 0x1a, 0x1b, 0x6e, 0x5a, 0xa0,
    0x52, 0x3b, 0xd6, 0xb3, 0x29, 0xe3, 0x2f, 0x84,
    0x53, 0xd1, 0x00, 0xed, 0x20, 0xfc, 0xb1, 0x5b,
    0x6a, 0xcb, 0xbe, 0x39, 0x4a, 0x4c, 0x58, 0xcf,
    0xd0, 0xef, 0xaa, 0xfb, 0x43, 0x4d, 0x33, 0x85,
    0x45, 0xf9, 0x02, 0x7f, 0x50, 0x3c, 0x9f, 0xa8,
    0x51, 0xa3, 0x40, 0x8f, 0x92, 0x9d, 0x38, 0xf5,
    0xbc, 0xb6, 0xda, 0x21, 0x10, 0xff, 0xf3, 0xd2,
    0xcd, 0x0c, 0x13, 0xec, 0x5f, 0x97, 0x44, 0x17,
    0xc4, 0xa7, 0x7e, 0x3d, 0x64, 0x5d, 0x19, 0x73,
    0x60, 0x81, 0x4f, 0xdc, 0x22, 0x2a, 0x90, 0x88,
    0x46, 0xee, 0xb8, 0x14, 0xde, 0x5e, 0x0b, 0xdb,
    0xe0, 0x32, 0x3a, 0x0a, 0x49, 0x06, 0x24, 0x5c,
    0xc2, 0xd3, 0xac, 0x62, 0x91, 0x95, 0xe4, 0x79,
    0xe7, 0xc8, 0x37, 0x6d, 0x8d, 0xd5, 0x4e, 0xa9,
    0x6c, 0x56, 0xf4, 0xea, 0x65, 0x7a, 0xae, 0x08,
    0xba, 0x78, 0x25, 0x2e, 0x1c, 0xa6, 0xb4, 0xc6,
    0xe8, 0xdd, 0x74, 0x1f, 0x4b, 0xbd, 0x8b, 0x8a,
    0x70, 0x3e, 0xb5, 0x66, 0x48, 0x03, 0xf6, 0x0e,
    0x61, 0x35, 0x57, 0xb9, 0x86, 0xc1, 0x1d, 0x9e,
    0xe1, 0xf8, 0x98, 0x11, 0x69, 0xd9, 0x8e, 0x94,
    0x9b, 0x1e, 0x87, 0xe9, 0xce, 0x55, 0x28, 0xdf,
    0x8c, 0xa1, 0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68,
    0x41, 0x99, 0x2d, 0x0f, 0xb0, 0x54, 0xbb, 0x16
};


// invSbox lookup table
static const uint8_t sbox_inv[256] = {
        0x52, 0x09, 0x6a, 0xd5, 0x30, 0x36, 0xa5, 0x38, 0xbf, 0x40, 0xa3, 0x9e, 0x81, 0xf3, 0xd7, 0xfb,
        0x7c, 0xe3, 0x39, 0x82, 0x9b, 0x2f, 0xff, 0x87, 0x34, 0x8e, 0x43, 0x44, 0xc4, 0xde, 0xe9, 0xcb,
        0x54, 0x7b, 0x94, 0x32, 0xa6, 0xc2, 0x23, 0x3d, 0xee, 0x4c, 0x95, 0x0b, 0x42, 0xfa, 0xc3, 0x4e,
        0x08, 0x2e, 0xa1, 0x66, 0x28, 0xd9, 0x24, 0xb2, 0x76, 0x5b, 0xa2, 0x49, 0x6d, 0x8b, 0xd1, 0x25,
        0x72, 0xf8, 0xf6, 0x64, 0x86, 0x68, 0x98, 0x16, 0xd4, 0xa4, 0x5c, 0xcc, 0x5d, 0x65, 0xb6, 0x92,
        0x6c, 0x70, 0x48, 0x50, 0xfd, 0xed, 0xb9, 0xda, 0x5e, 0x15, 0x46, 0x57, 0xa7, 0x8d, 0x9d, 0x84,
        0x90, 0xd8, 0xab, 0x00, 0x8c, 0xbc, 0xd3, 0x0a, 0xf7, 0xe4, 0x58, 0x05, 0xb8, 0xb3, 0x45, 0x06,
        0xd0, 0x2c, 0x1e, 0x8f, 0xca, 0x3f, 0x0f, 0x02, 0xc1, 0xaf, 0xbd, 0x03, 0x01, 0x13, 0x8a, 0x6b,
        0x3a, 0x91, 0x11, 0x41, 0x4f, 0x67, 0xdc, 0xea, 0x97, 0xf2, 0xcf, 0xce, 0xf0, 0xb4, 0xe6, 0x73,
        0x96, 0xac, 0x74, 0x22, 0xe7, 0xad, 0x35, 0x85, 0xe2, 0xf9, 0x37, 0xe8, 0x1c, 0x75, 0xdf, 0x6e,
        0x47, 0xf1, 0x1a, 0x71, 0x1d, 0x29, 0xc5, 0x89, 0x6f, 0xb7, 0x62, 0x0e, 0xaa, 0x18, 0xbe, 0x1b,
        0xfc, 0x56, 0x3e, 0x4b, 0xc6, 0xd2, 0x79, 0x20, 0x9a, 0xdb, 0xc0, 0xfe, 0x78, 0xcd, 0x5a, 0xf4,
        0x1f, 0xdd, 0xa8, 0x33, 0x88, 0x07, 0xc7, 0x31, 0xb1, 0x12, 0x10, 0x59, 0x27, 0x80, 0xec, 0x5f,
        0x60, 0x51, 0x7f, 0xa9, 0x19, 0xb5, 0x4a, 0x0d, 0x2d, 0xe5, 0x7a, 0x9f, 0x93, 0xc9, 0x9c, 0xef,
        0xa0, 0xe0, 0x3b, 0x4d, 0xae, 0x2a, 0xf5, 0xb0, 0xc8, 0xeb, 0xbb, 0x3c, 0x83, 0x53, 0x99, 0x61,
        0x17, 0x2b, 0x04, 0x7e, 0xba, 0x77, 0xd6, 0x26, 0xe1, 0x69, 0x14, 0x63, 0x55, 0x21, 0x0c, 0x7d
};

// Round Constants for key expansion
static const uint8_t rcon[11] = {
		0x8d, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1b, 0x36
};

// declarations:
void printing_text(u32 *text, u32 length, int what_to_print);
void KeyExpansion(const uint8_t* key, u32* roundKeys);
void sub_bytes(u32* text);
void inv_sub_bytes(u32* text);


///// TIMER setup /////
void XTmrCtr_Start(XTmrCtr* InstancePtr, u8 TmrCtrNumber);
void XTmrCtr_Stop(XTmrCtr* InstancePtr, u8 TmrCtrNumber);
u32 XTmrCtr_GetValue(XTmrCtr* InstancePtr, u8 TmrCtrNumber);
XTmrCtr_Config* tC;
XTmrCtr tI;
void tmrInit() {
tC = XTmrCtr_LookupConfig(XPAR_AXI_TIMER_0_DEVICE_ID);
XTmrCtr_CfgInitialize(&tI, tC, XPAR_AXI_TIMER_0_BASEADDR);
}

///// IP /////
// sending the current input to the hardware
void send_input(u32 in3, u32 in2, u32 in1, u32 in0) {
	Xil_Out32(INPUT_ADDR, in0);
	Xil_Out32(INPUT_ADDR + 4, in1);
	Xil_Out32(INPUT_ADDR + 8, in2);
	Xil_Out32(INPUT_ADDR + 12, in3);
}

// sending the key to the hardware
void send_key(u32 in3, u32 in2, u32 in1, u32 in0) {
	Xil_Out32(KEY_ADDR, in0);
	Xil_Out32(KEY_ADDR + 4, in1);
	Xil_Out32(KEY_ADDR + 8, in2);
	Xil_Out32(KEY_ADDR + 12, in3);
}

// extracting the current output from the hardware
void get_output(u32* out3, u32* out2, u32* out1, u32* out0) {
	*out3 = Xil_In32(OUT_ADDR + 12);
	*out2 = Xil_In32(OUT_ADDR + 8);
	*out1 = Xil_In32(OUT_ADDR + 4);
	*out0 = Xil_In32(OUT_ADDR + 0);
}

// sending control signals for encryption: enc_en =1 for encryption,
// final round = 1 or 0 according to the current round
void start_enc(int final_round) {
	(final_round == 0) ? Xil_Out32(CNTL_ADDR, 0x00000001) : Xil_Out32(CNTL_ADDR, 0x00000003); // enc_en = 1
}

// sending control signals for encryption: enc_en =0 for decryption,
// final round = 1 or 0 according to the current round
void start_dec(int final_round) {
	(final_round == 0) ? Xil_Out32(CNTL_ADDR, 0x00000000) : Xil_Out32(CNTL_ADDR, 0x00000002); // enc_en = 0
}

// calculating the subByets in software
void sub_bytes(u32* text){
	for (int i=0; i<4; i++){
		text[i] = sbox[text[i] & 0xff] +
				(sbox[(text[i] >> 8) & 0xff] << 8) +
				(sbox[(text[i] >> 16) & 0xff] << 16) +
				(sbox[(text[i] >> 24) & 0xff] << 24);
	}
}

// calculating the inv_subByets in software
void inv_sub_bytes(u32* text){
	for (int i=0; i<4; i++){
		text[i] = sbox_inv[text[i] & 0xff] +
				(sbox_inv[(text[i] >> 8) & 0xff] << 8) +
				(sbox_inv[(text[i] >> 16) & 0xff] << 16) +
				(sbox_inv[(text[i] >> 24) & 0xff] << 24);
	}
}

// key - length 256 bits, text - 128*length bits, length - size of  the text
// this function counts the time of total encryptions, sends the data to the hardware and receives the output from it.
void encryption (u8 *key, u32 *text, u32 length){
	u32 count=0;
	u32 roundKeys[60];
	XTmrCtr_Start(&tI, 0);
	KeyExpansion(key, &roundKeys);		// calculating the expansion key in software
	for (u32 block_num = 0; block_num < length; block_num+=4) {
		text[block_num+3]^=roundKeys[3];	// updating the current key to send to the hardware
		text[block_num+2]^=roundKeys[2];
		text[block_num+1]^=roundKeys[1];
		text[block_num+0]^=roundKeys[0];
		for(int round = 1; round < 14; round++) {	// sending current data to 13 rounds
			sub_bytes(&text[block_num]);
			send_key(roundKeys[round*4 + 3], roundKeys[round*4 + 2], roundKeys[round*4 + 1], roundKeys[round*4 + 0]);
			send_input(text[block_num+3],text[block_num+2],text[block_num+1],text[block_num]);
			start_enc(0);
			get_output(&text[block_num+3],&text[block_num+2],&text[block_num+1],&text[block_num]);
		}
		sub_bytes(&text[block_num]);
		// sending current data to the final round:
		send_key(roundKeys[14*4 + 3], roundKeys[14*4 + 2], roundKeys[14*4 + 1], roundKeys[14*4 + 0]);
		send_input(text[block_num+3],text[block_num+2],text[block_num+1],text[block_num]);
		start_enc(1);
		get_output(&text[block_num+3],&text[block_num+2],&text[block_num+1],&text[block_num]);
	}
	// extract the count and reset it
	XTmrCtr_Stop(&tI, 0);
	count = XTmrCtr_GetValue(&tI, 0);
	xil_printf("Encryption timer value: %0d\n\r", count);
	XTmrCtr_SetResetValue(&tI, 0, 0);

}

// key - length 256 bits, text - 128*length bits, length - size of  the text
// this function counts the time of total decoding, sends the data to the hardware and receives the output from it.
void decryption (u8 *key, u32 *text, u32 length){
	u32 count=0;
	u32 roundKeys[60];
	XTmrCtr_Start(&tI, 0);
	KeyExpansion(key, &roundKeys);		// calculating the expansion key in software
	for (u32 block_num = 0; block_num < length; block_num+=4) {
		text[block_num+3]^=roundKeys[59];		// updating the current key to send to the hardware
		text[block_num+2]^=roundKeys[58];
		text[block_num+1]^=roundKeys[57];
		text[block_num+0]^=roundKeys[56];
		for(int round = 13; round > 0; round--) {	// sending current data to 13 rounds
			inv_sub_bytes(&text[block_num]);
			send_key(roundKeys[round*4 + 3], roundKeys[round*4 + 2], roundKeys[round*4 + 1], roundKeys[round*4 + 0]);
			send_input(text[block_num+3],text[block_num+2],text[block_num+1],text[block_num]);
			start_dec(0);
			get_output(&text[block_num+3],&text[block_num+2],&text[block_num+1],&text[block_num]);
		}
		inv_sub_bytes(&text[block_num]);
		// sending current data to the final round:
		send_key(roundKeys[3], roundKeys[2], roundKeys[1], roundKeys[0]);
		send_input(text[block_num+3],text[block_num+2],text[block_num+1],text[block_num]);
		start_dec(1);
		get_output(&text[block_num+3],&text[block_num+2],&text[block_num+1],&text[block_num]);
	}
	// extract the count and reset it
	XTmrCtr_Stop(&tI, 0);
	count = XTmrCtr_GetValue(&tI, 0);
	xil_printf("Decryption timer value: %0d\n\r", count);
	XTmrCtr_SetResetValue(&tI, 0, 0);
}

// what to print = 1 for plain text, 2 for enc text, 3 for dec text
void printing_text(u32 *text, u32 length, int what_to_print){		// what to print = 0 for key, 1 for plain text, 2 for enc text, 3 for dec text
	for (u32 idx=0; idx<length; idx++){
		switch (what_to_print)
		{
		case KEY:
			xil_printf("key[%lu]: %08x %08x %08x %08x\n\r", idx, text[idx], text[idx+1], text[idx+2], text[idx+3]);
			idx = idx+3;
			break;
		case PLAINTEXT:
			xil_printf("pt[%lu]: %lu\n\r", idx, text[idx]);
			break;
		case ENCYPTED_TEXT:
			xil_printf("ct[%lu]: %08x\n\r", idx, text[idx]);
			break;
		case DECRYPTED_TEXT:
			xil_printf("dt[%lu]: %lu\n\r", idx, text[idx]);

		}
	}
}

// printing the key:
void printing_key(u8 *key, u8 length){		// what to print = 0 for key, 1 for plain text, 2 for enc text, 3 for dec text
	for (u8 idx=0; idx<length; idx++){
		xil_printf("key[%u]: %02x\n\r", idx, key[idx]);
	}
}

// expanding the key using the Sbox lookup table,
// roundkeys array hold the calculated keys
void KeyExpansion(const uint8_t* key, u32* roundKeys)
{
	uint32_t temp;
	int i=0;

	while (i < 8)
    {
        roundKeys[i] =
            (key[4 * i] << 24) |
            (key[4 * i + 1] << 16) |
            (key[4 * i + 2] << 8) |
            (key[4 * i + 3]);
        i++;
    }

    // Generate the remaining round keys
    while (i < 60)
    {
        temp = roundKeys[i - 1];

        if (i % 8 == 0)
        {
            temp = ((temp << 8) | (temp >> 24));
            temp =
                ((uint32_t)(sbox[(temp >> 24) & 0xFF]) << 24) |
                ((uint32_t)(sbox[(temp >> 16) & 0xFF]) << 16) |
                ((uint32_t)(sbox[(temp >> 8) & 0xFF]) << 8) |
                ((uint32_t)(sbox[temp & 0xFF]));
            temp ^= (rcon[i / 8] << 24);
        }
        else if(i % 8 == 4)
        {
        	temp =
        	    ((uint32_t)(sbox[(temp >> 24) & 0xFF]) << 24) |
        	    ((uint32_t)(sbox[(temp >> 16) & 0xFF]) << 16) |
        	    ((uint32_t)(sbox[(temp >> 8) & 0xFF]) << 8) |
        	    ((uint32_t)(sbox[temp & 0xFF]));
        }

        roundKeys[i] = roundKeys[i - 8] ^ temp;
        i++;
    }
}


int main() {
init_platform();
u32 length = 32;
u8 key [KEY_LENGTH] = { 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
        0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f};
u32 text_array[length];
u32 *text = text_array;


// printing the key:
printing_key(key, KEY_LENGTH);

// creating the input according to the desired length:
for(u32 idx=0; idx<length; idx++) {
	text[idx] = idx;		//plaintext = 010203040506070809...
}
printing_text (text, length, PLAINTEXT);

// initial timer:
tmrInit();
XTmrCtr_Stop(&tI, 0);
XTmrCtr_SetResetValue(&tI, 0, 0);

//encryption//
encryption (&key, text, length);
printing_text(text, length, ENCYPTED_TEXT);

//decryption//
decryption (&key, text, length);
printing_text(text, length, DECRYPTED_TEXT);

xil_printf("done\n\n\n\n\n\r");
cleanup_platform();
return 0;
}
