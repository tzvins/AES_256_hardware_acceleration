#include "xparameters.h"
#include "xil_io.h"
#include "xbasic_types.h"
#include "xtmrctr.h"
#include <stdio.h>
#include <inttypes.h>

// XPAR_ENCDEC_FINAL1_IP_0_S00_AXI_BASEADDR = 0x44A00000
// base addresses for hardware registers:
#define INPUT_ADDR			XPAR_ENCDEC_FINAL1_IP_0_S00_AXI_BASEADDR
#define KEY_ADDR 			XPAR_ENCDEC_FINAL1_IP_0_S00_AXI_BASEADDR + 16 	//4*4
#define OUT_ADDR 			XPAR_ENCDEC_FINAL1_IP_0_S00_AXI_BASEADDR + 48	//4*12
#define CNTL_ADDR 			XPAR_ENCDEC_FINAL1_IP_0_S00_AXI_BASEADDR + 64	//4*16 LOAD-0,RESET-1,ENC_EN-2
#define DONE_ADDR 			XPAR_ENCDEC_FINAL1_IP_0_S00_AXI_BASEADDR + 68	//4*17

#define KEY_LENGTH 8
#define KEY 0
#define PLAINTEXT 1
#define ENCYPTED_TEXT 2
#define DECRYPTED_TEXT 3

// declarations:
void printing_text(u32 *text, u32 length, int what_to_print);

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
void send_key(u32 in7, u32 in6, u32 in5, u32 in4, u32 in3, u32 in2, u32 in1, u32 in0) {
	Xil_Out32(KEY_ADDR, in0);
	Xil_Out32(KEY_ADDR + 4, in1);
	Xil_Out32(KEY_ADDR + 8, in2);
	Xil_Out32(KEY_ADDR + 12, in3);
	Xil_Out32(KEY_ADDR + 16, in4);
	Xil_Out32(KEY_ADDR + 20, in5);
	Xil_Out32(KEY_ADDR + 24, in6);
	Xil_Out32(KEY_ADDR + 28, in7);
}

// extracting the current output from the hardware
void get_output(u32* out3, u32* out2, u32* out1, u32* out0) {
	*out3 = Xil_In32(OUT_ADDR + 12);
	*out2 = Xil_In32(OUT_ADDR + 8);
	*out1 = Xil_In32(OUT_ADDR + 4);
	*out0 = Xil_In32(OUT_ADDR + 0);
}

// reset is active low for reseting the hardware registers
void reset() {
	Xil_Out32(CNTL_ADDR, 0x00000000); // enc_en = 0, reset = 0, load = 0
}

// sending control signals for encryption: enc_en =1 for encryption, reset=1 for not reseting,
// load =1 for done loading the data for the encryption
void start_enc() {
	Xil_Out32(CNTL_ADDR, 0x00000007); // enc_en = 1, reset = 1, load = 1
	Xil_Out32(CNTL_ADDR, 0x00000006); // enc_en = 1, reset = 1, load = 0
}

// sending control signals for decryption: enc_en =0 for decryption, reset=1 for not reseting,
// load =1 for done loading the data for the decryption
void start_dec() {
	Xil_Out32(CNTL_ADDR, 0x00000003); // enc_en = 0, reset = 1, load = 1
	Xil_Out32(CNTL_ADDR, 0x00000002); // enc_en = 0, reset = 1, load = 0
}

// extracting the done signal: done =1 when the hardware done its operation (encryption/decryption).
u32 get_done() {
	u32 done_signal = Xil_In32(DONE_ADDR);
	return (done_signal);
}

// key - length 256 bits, text - 128*length bits, length - size of  the text
// this function counts the time of total encryptions, sends the data to the hardware and receives the output from it.
void encryption (u32 *key, u32 *text, u32 length){
	u32 count=0;
	XTmrCtr_Start(&tI, 0);
	send_key(key[7],key[6],key[5],key[4],key[3],key[2],key[1],key[0]);  // sending key to the hardware

	//sending current input to hardware until all the input encrypted
	for (u32 block_num = 0; block_num < length; block_num+=4) {
		send_input(text[block_num+3],text[block_num+2],text[block_num+1],text[block_num]);
		start_enc();
		get_output(&text[block_num+3],&text[block_num+2],&text[block_num+1],&text[block_num]);
	}
	// extract the count and reset it
	XTmrCtr_Stop(&tI, 0);
	count = XTmrCtr_GetValue(&tI, 0);	// count holds the sum of rounds for all the input's length
	xil_printf("Encryption timer value: %0d\n\r", count);
	XTmrCtr_SetResetValue(&tI, 0, 0);

}

// key - length 256 bits, text - 128*length bits, length - size of  the text
// this function counts the time of total decoding, sends the data to the hardware and receives the output from it.
void decryption (u32 *key, u32 *text, u32 length){
	u32 count=0;
	XTmrCtr_Start(&tI, 0);
	send_key(key[7],key[6],key[5],key[4],key[3],key[2],key[1],key[0]);		// sending key to the hardware

	//sending current input to hardware until all the input decodes
	for (u32 block_num = 0; block_num < length; block_num+=4) {
		send_input(text[block_num+3],text[block_num+2],text[block_num+1],text[block_num]);
		start_dec();
		get_output(&text[block_num+3],&text[block_num+2],&text[block_num+1],&text[block_num]);
	}
	// extract the count and reset it
	XTmrCtr_Stop(&tI, 0);
	count = XTmrCtr_GetValue(&tI, 0); // count holds the sum of rounds for all the input's length
	xil_printf("Decryption timer value: %0d\n\r", count);
	XTmrCtr_SetResetValue(&tI, 0, 0);
}

// what to print = 0 for key, 1 for plain text, 2 for enc text, 3 for dec text
void printing_text(u32 *text, u32 length, int what_to_print){
	for (u32 idx=0; idx<length; idx++){
		switch (what_to_print)
		{
		case KEY:
			xil_printf("key[%lu]: %08x\n\r", idx, text[idx]);
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



////////////


int main() {
reset();
init_platform();
u32 length = 32;
u32 key[KEY_LENGTH] = {0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f};
u32 text_array[length];
u32 *text = text_array;

//printing the key:
printing_text (&key, KEY_LENGTH, KEY);

// creating the input according to the desired length:
for(u32 idx=0; idx<length; idx++) {
	text[idx] = idx;
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



