/* 
Sends a command to the SCROD temperature sensor to read from
register 0x00.  This has the upper bits of the temperature.
*/

#include "idl_usb.h"
#include <stdio.h>
#include <time.h>

#define IN_ADDR (0x86)          //Endpoint 6 (FPGA2USB Endpoint)
#define OUT_ADDR (0x02)         //Endpoint 2 (USB2FPGA Endpoint)

#include "packet_interface.h"

void byte_reverse(unsigned int *, int);

int main(){
        setup_usb();
        unsigned int inbuf[512];
	unsigned char *p_inbuf = (unsigned char*) &inbuf[0];
	//Clear the input buffer
        usb_ClearEndpnt((IN_ADDR | LIBUSB_ENDPOINT_IN), p_inbuf, 512, TM_OUT);

	int stat_chk,j;

	int size = 0;
	unsigned int *outbuf;
	packet command_stack;
	unsigned int command_id  = 10;
//	unsigned int board_id = 0x00000000;  //Broadcast ID
	unsigned int board_id = 0x00A2000E;  //Try sending to your specific board
	unsigned short int command_reg = 1;
	unsigned short int read_reg = 256;
	//I2C command stack here
	int N_commands = 10;
	unsigned short int command_data[10]= {0x0100,  //1. start
	                                      0x0094,  //2. setup send
	                                      0x0294,  //   send addr + write
	                                      0x0000,  //3. setup send
	                                      0x0200,  //   send register addr
	                                      0x0100,  //4. repeat start
	                                      0x0095,  //5. setup send
	                                      0x0295,  //   send addr + read
	                                      0x0400,  //6. read w/ no ack
	                                      0x1000}; //7. stop
	//Send the I2C commands
	for (int i = 0; i < N_commands; ++i) {
		command_stack.ClearPacket();
		command_stack.CreateCommandPacket(command_id,board_id);
		command_id++;
		command_stack.AddWriteToPacket(command_reg, command_data[i]);
		command_stack.AddReadToPacket(command_reg);
		command_stack.PrintPacket();

		outbuf = command_stack.AssemblePacket(size);
//		byte_reverse(outbuf,command_stack.GetTotalSize());

	        usb_XferData((OUT_ADDR | LIBUSB_ENDPOINT_OUT), (unsigned char *) outbuf, size*4, TM_OUT);
		delete[] outbuf;

		//RX
	 	int retval = usb_XferData((IN_ADDR | LIBUSB_ENDPOINT_IN), p_inbuf, 512*sizeof(unsigned int), TM_OUT);
		cout << "Read out " << retval << " bytes." << endl;
		while (retval > 0) {
//			byte_reverse(inbuf,retval/4);
			for(j=0;j<retval/4;j++) {
				printf("inbuf[%d]=0x%.8X\t",j,inbuf[j]);
				for (int k = 3; k >= 0; --k) {
					unsigned int mask = 0x000000FF;
					mask = mask << (k*8);
					mask = mask & inbuf[j];
					mask = mask >> (k*8);
					char this_char= (char) mask;
					printf("%c",this_char);
				}
				printf("\n");
			}
	       		retval = usb_XferData((IN_ADDR | LIBUSB_ENDPOINT_IN), p_inbuf, 512*sizeof(unsigned int), TM_OUT);
		}
//		sleep(1);
//		getchar();
	}
	//Read back what's on the I2C bus after the last read command
	for (int i = 0; i < 1; ++i) {
		command_stack.ClearPacket();
		command_stack.CreateCommandPacket(command_id,board_id);
		command_id++;
		command_stack.AddReadToPacket(read_reg);
		command_stack.PrintPacket();

		outbuf = command_stack.AssemblePacket(size);
//		byte_reverse(outbuf,command_stack.GetTotalSize());

	        usb_XferData((OUT_ADDR | LIBUSB_ENDPOINT_OUT), (unsigned char *) outbuf, size*4, TM_OUT);
		delete[] outbuf;

		//RX
	 	int retval = usb_XferData((IN_ADDR | LIBUSB_ENDPOINT_IN), p_inbuf, 512*sizeof(unsigned int), TM_OUT);
		cout << "Read out " << retval << " bytes." << endl;
		while (retval > 0) {
//			byte_reverse(inbuf,retval/4);
			for(j=0;j<retval/4;j++) {
				printf("inbuf[%d]=0x%.8X\t",j,inbuf[j]);
				for (int k = 3; k >= 0; --k) {
					unsigned int mask = 0x000000FF;
					mask = mask << (k*8);
					mask = mask & inbuf[j];
					mask = mask >> (k*8);
					char this_char= (char) mask;
					printf("%c",this_char);
				}
				printf("\n");
			}
	       		retval = usb_XferData((IN_ADDR | LIBUSB_ENDPOINT_IN), p_inbuf, 512*sizeof(unsigned int), TM_OUT);
		}
	}
        close_usb();
}

void byte_reverse(unsigned int *input, int size) {
	for (int i = 0; i < size; ++i) {
		input[i] = ((input[i] & 0x0000FFFF) << 16) | ((input[i] & 0xFFFF0000) >> 16);
	}
}
