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

int main(int argc, char *argv[]) {
	unsigned short int board_id_to_write = 34;
	//verbosity = 5;
	//setup_DebugInfoWarningError();
	while (--argc > 0) {
		int num = 0;
		if (sscanf(*++argv, "%d", &num)) {
			board_id_to_write = num;
			//fprintf(debug, "using %d for board_id\n", board_id_to_write);
			debug << "using " << board_id_to_write << " for board_id" << endl;
		}
		//fprintf(debug, "argument:  \"%s\"\n", *argv);
	}
	write_board_id(board_id_to_write);
//	unsigned short int board_id_read_back = read_board_id();
//	if (board_id_to_write != board_id_read_back) {
//		fprintf(error, "ERROR:  unable to verify that the board id was written properly\n");
//	}
	return 0;
}

unsigned short int read_board_id(void) {
	//fprintf(warning, "WARNING:  read_board_id() does nothing\n");
	warning << "WARNING:  read_board_id() does nothing" << endl;
	return 0;
}

void write_board_id(unsigned short int board_id_to_write, unsigned short int board_revision_to_write) {
	unsigned short int board_id_low_mask = 0x00FF;
	unsigned short int board_id_high_mask = 0xFF00;
	packet_word board_id = 0x00000000;  //Broadcast ID
//	packet_word board_id = 0x00A2000E;  //Try sending to your specific board
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
	packet_word command_id = 10; // a random number
	unsigned short int command_reg = 1;
//	unsigned short int read_reg = 256;
	packet_word inbuf[MAXIMUM_PACKET_SIZE_IN_WORDS];
	unsigned char *p_inbuf = (unsigned char *) inbuf;
	initialize_io_interface(p_inbuf);
	for (int i = 0; i < N_commands; ++i, command_id++) {
		packet command_stack;
		packet_word *outbuf;
		//command_stack.ClearPacket();
		command_stack.CreateCommandPacket(command_id, board_id);
		command_stack.AddWriteToPacket(command_reg, command_data[i]);
		command_stack.AddReadToPacket(command_reg);
//		command_stack.PrintPacket();
		//TX
		outbuf = command_stack.AssemblePacket(size);
//		byte_reverse(outbuf,command_stack.GetTotalSize());
		send_data( (unsigned char *) outbuf, 4*size);
		delete[] outbuf;
		//RX
		int length = receive_packet(p_inbuf);
		packet response(inbuf, length>>2);
//		response.PrintPacket();
		if (!response.CommandWasExecutedSuccessfully()) {
			//fprintf(error, "ERROR:  command was NOT executed\n");
			error << "ERROR:  command was NOT executed" << endl;
		}
//		sleep(1);
//		getchar();
	}
	close_io_interface();
}

