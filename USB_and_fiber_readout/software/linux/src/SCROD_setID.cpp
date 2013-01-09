/* 
Sends a command to the SCROD EEPROM to write two bytes, 
as supplied by the user.
Address 0,1: SCROD ID (matched to sticker on SCROD)
             (e.g., SCROD w/ sticker 14 should be 0x000E)
Address 2: SCROD revision (e.g., Revision A2 is denoted 0xA2)
*/

#include <stdio.h>
#include <time.h>
#include <iostream>
#include "generic.h"
#include "io_interface.h"
#include "packet_interface.h"
#include "DebugInfoWarningError.h"
using namespace std;

void write_board_id(unsigned short int board_id_to_write, unsigned short int board_revision_to_write=0x00a2);
unsigned short int read_board_id(void);

int main(){
	verbosity = 3;
	setup_DebugInfoWarningError();
	unsigned short int board_id_to_write = 14;
	write_board_id(board_id_to_write);
	unsigned short int board_id_read_back = read_board_id();
	if (board_id_to_write != board_id_read_back) {
		fprintf(error, "ERROR:  unable to verify that the board id was written properly\n");
	}
	return 0;
}

unsigned short int read_board_id(void) {
	fprintf(warning, "WARNING:  read_board_id() does nothing\n");
	return 0;
}

void write_board_id(unsigned short int board_id_to_write, unsigned short int board_revision_to_write) {
	unsigned short int board_id_low_mask = 0x00FF;
	unsigned short int board_id_high_mask = 0xFF00;
	unsigned int board_id = 0x00000000;  //Broadcast ID
//	unsigned int board_id = 0x00A2000E;  //Try sending to your specific board
	//I2C command stack here
	unsigned short int command_data[14]= {0x0100,  //1. start
	                                      0x00A0,  //2. setup send
	                                      0x02A0,  //   send addr + write
	                                      0x0000,  //3. setup send
	                                      0x0200,  //   send addr HIGH
	                                      0x0000,  //4. setup send
	                                      0x0200,  //   send addr LOW
	                                      (board_id_to_write & board_id_low_mask),  //5. setup send
	                                      0x0200 | (board_id_to_write & board_id_low_mask),  //   send data byte 1
	                                      ((board_id_to_write & board_id_high_mask) >> 8),  //6. setup send
	                                      0x0200 | ((board_id_to_write & board_id_high_mask) >> 8),  //   send data byte 2
	                                      board_revision_to_write,  //7. setup send
	                                      0x0200 | board_revision_to_write,  //   send data byte 3
	                                      0x1000}; //8. stop
	int N_commands = sizeof(command_data) / sizeof(command_data[0]);
	//printf("%d\n", N_commands);
	//fflush(stdout);
	int size = 0;
	unsigned int command_id = 10; // a random number
	unsigned short int command_reg = 1;
//	unsigned short int read_reg = 256;
	unsigned int inbuf[512];
	unsigned char *p_inbuf = (unsigned char *) &inbuf[0];
	initialize_io_interface(p_inbuf);
	for (int i = 0; i < N_commands; ++i, command_id++) {
		packet command_stack;
		unsigned int *outbuf;
		//command_stack.ClearPacket();
		command_stack.CreateCommandPacket(command_id, board_id);
		command_stack.AddWriteToPacket(command_reg, command_data[i]);
		command_stack.AddReadToPacket(command_reg);
		command_stack.PrintPacket();
		//TX
		outbuf = command_stack.AssemblePacket(size);
//		byte_reverse(outbuf,command_stack.GetTotalSize());
		send_data( (unsigned char *) outbuf, 4*size);
		delete[] outbuf;
		//RX
		int length = receive_packet(p_inbuf);
		packet response(&inbuf[0], length>>2);
		if (!response.CommandWasExecutedSuccessfully()) {
			fprintf(error, "ERROR:  command was NOT executed\n");
		}
//		sleep(1);
//		getchar();
	}
	close_io_interface();
}

