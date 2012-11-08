/* Filename: SCROD_LED_test.cpp
Simple program to send commands that cycle through
an LED pattern on SCROD.  This assumes that the 
LEDs are set to general purpose register 0, which is
the default for the USB_and_fiber_readout branch.
*/

#include "idl_usb.h"
#include <stdio.h>
#include <time.h>

//Endpoints 2 and 6 are the primary data path for this
//firmware branch.
#define IN_ADDR (0x86)          //Endpoint 6 (FPGA2USB Endpoint)
#define OUT_ADDR (0x02)         //Endpoint 2 (USB2FPGA Endpoint)
//Endpoints 4 and 8 are connected via a simple loop-back.
//#define IN_ADDR (0x88)          //Endpoint 8 (FPGA2USB Endpoint)
//#define OUT_ADDR (0x04)         //Endpoint 4 (USB2FPGA Endpoint)

#include "packet_interface.h"

void byte_reverse(unsigned int *, int);

int main(){
        setup_usb();
        unsigned int inbuf[512];
	unsigned char *p_inbuf = (unsigned char*) &inbuf[0];
        usb_ClearEndpnt((IN_ADDR | LIBUSB_ENDPOINT_IN), p_inbuf, 512, TM_OUT);    //Clear input buffer

	unsigned short int a = 0x7;
	bool increasing = true;

	int counter = 0;

	while(1) {

		if (a == 0xE000) {
			increasing = false;
		}
		if (a == 0x7) {
			increasing = true;
		}
		if (increasing) {
			a = a << 1;
		} else {
			a = a >> 1;
		}

		int size = 0;
		unsigned int *outbuf;
		packet command_stack;
		command_stack.CreateCommandPacket(12);
		command_stack.AddWriteToPacket(0, a);
		command_stack.AddReadToPacket(0);
		command_stack.PrintPacket();
		outbuf = command_stack.AssemblePacket(size);

		byte_reverse(outbuf,command_stack.GetTotalSize());
 
	        int stat_chk,j;

        	usb_XferData((OUT_ADDR | LIBUSB_ENDPOINT_OUT), (unsigned char *) outbuf, size*4, TM_OUT);


	        //RX
 	       int retval = usb_XferData((IN_ADDR | LIBUSB_ENDPOINT_IN), p_inbuf, 512*sizeof(unsigned int), TM_OUT);
		cout << "Read out " << retval << " bytes." << endl;
		while (retval > 0) {
			byte_reverse(inbuf,retval/4);
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
