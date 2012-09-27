/* Filename: test2.cpp
* Notes
* EP    Type            Work?
* 2     USB2FPGA        n
* 4     USB2FPGA        y
* 6     FPGA2USB
* 8     FPGA2USB        y
*
*
*/

#include "idl_usb.h"
#include <stdio.h>
#include <time.h>

#define OUT_SIZE (32)
#define IN_SIZE (32)
#define TM_OUT (100)
#define LOOP (1)
#define in_addr (0x86)          //Endpoint 6 (FPGA2USB Endpoint)
#define out_addr (0x02)         //Endpoint 2 (USB2FPGA Endpoint)
//#define in_addr (0x88)          //Endpoint 8 (FPGA2USB Endpoint)
//#define out_addr (0x04)         //Endpoint 4 (USB2FPGA Endpoint)

int main(){
        setup_usb();

	int bad_transmissions = 0;

for (int i = 0; i < LOOP; ++i) {

        unsigned char* outbuf=new unsigned char[OUT_SIZE]; 
        unsigned char* inbuf=new unsigned char[IN_SIZE];
        int in_addr, out_addr;                          //Endpoints
        int stat_chk,j;

        usb_ClearEndpnt((in_addr | LIBUSB_ENDPOINT_IN), inbuf, 512, TM_OUT);    //Clear input buffer

        //TX
        srand(time(NULL));
        for(j=0;j<OUT_SIZE;j++){
                outbuf[j]=(unsigned char)rand();
        }

        usb_XferData((out_addr | LIBUSB_ENDPOINT_OUT), outbuf, OUT_SIZE, TM_OUT);

       for(j=0;j<OUT_SIZE/4;j++)
               printf("outbuf[%d]=0x%.2X%.2X%.2X%.2X\n",j,outbuf[4*j+1],outbuf[4*j+0],outbuf[4*j+3],outbuf[4*j+2]);

        //RX
        usb_XferData((in_addr | LIBUSB_ENDPOINT_IN), inbuf, IN_SIZE, TM_OUT);
       for(j=0;j<IN_SIZE/4;j++)
                printf("inbuf[%d]=0x%.2X%.2X%.2X%.2X\n",j,inbuf[4*j+1],inbuf[4*j+0],inbuf[4*j+3],inbuf[4*j+2]);

        //Check
        stat_chk = memcmp(outbuf,inbuf,IN_SIZE);
//        printf("Status Check: %d\n",stat_chk);
	if (stat_chk != 0) {
		bad_transmissions++;
	}
}
        close_usb();
	printf("Bad transmissions: %d out of %d (%f%)\n",bad_transmissions,LOOP,float(bad_transmissions)/float(LOOP)*100.);
}

