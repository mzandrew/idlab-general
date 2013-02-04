#include <iostream>
#include <libusb.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include<time.h>
#include <unistd.h>
using namespace std;

#define LOOP (1)
#define VID /*(0x6672)*/(0x04B4)
#define PID /*(0x2920)*/(0x1004)
#define IN_SIZE	(512)		//Number of 8-bit words
#define OUT_SIZE (512)		//Number of 8-bit words
#define TM_OUT (1000)		//Timeout for Xfer
#define	 in_addr (0x88)		//Endpoint 6 = DATA, 8 = CS
#define	 out_addr (0x04)	//Endpoint 2 = DATA, 4 = CS

void sendControlWord(libusb_device_handle *dev_handle, 
	unsigned char w3, unsigned char w2, unsigned char w1, unsigned char w0);
void readChannelData(libusb_device_handle *dev_handle, FILE *ofp, int chan, int numLoop);

int main ( int argc, char *argv[] ){
	if ( argc != 5 ) /* argc should be 2 for correct execution */
	{
        	/* We print argv[0] assuming it is the program name */
		printf( "usage: %s controlMode controlBoardType controlChan controlNumEvents", argv[0] );
		return 1;
	}
	int controlMode = atoi(argv[1]);
	int controlBoardType = atoi(argv[2]);
	int controlChan = atoi(argv[3]);
	int controlNumEvents = atoi(argv[4]);
	std::cout << "NEWRUN";
	std::cout << "\tmode " << controlMode;
	std::cout << "\tboard " << controlBoardType;
	std::cout << "\tchan " << controlChan;
	std::cout << std::endl;

	//BEGIN USB INITIALIZATION -------------------------------------------------
	libusb_device **devs; //pointer to pointer of device, used to retrieve a list of devices
	libusb_device_descriptor desc;
	libusb_context *ctx = NULL; //a libusb session
	int r; //for return values
	int stat_chk;
	ssize_t cnt; //holding number of devices in list
	r = libusb_init(&ctx); //initialize a library session
	if(r < 0) {
		cout<<"Init Error "<<r<<endl; //there was an error
		return 1;
	}
	libusb_set_debug(ctx, 3); //set verbosity level to 3, as suggested in the documentation
	cnt = libusb_get_device_list(ctx, &devs); //get the list of devices
	if(cnt < 0) {
		cout<<"Get Device Error"<<endl; //there was an error
	}
	cout<<cnt<<" Devices in list."<<endl; //print total number of usb devices
	ssize_t i; //for iterating through the list
	for(i = 0; i < cnt; i++) {
		r = libusb_get_device_descriptor(devs[i], &desc);
		if(r<0){
			cout<<"failed to get device descriptor"<<endl;
			return 1;
		 }
		if(desc.idVendor==VID && desc.idProduct==PID)
		{
			cout<<"found the target Cypress USB chip"<<endl;
			//printdev(devs[i]);
			//list_endpoints(devs[i]);
			break;
		}
	}
	if(i==cnt){
		cout<<"ERROR: the target Cypress USB Chip has not been detected"<<endl;
	}
	//open device
	libusb_device_handle *dev_handle; 
	dev_handle = libusb_open_device_with_vid_pid(ctx,VID,PID); 

	if(dev_handle == NULL)
		cout<<"Cannot open device"<<endl;
	else
		cout<<"Device Opened"<<endl;

	libusb_free_device_list(devs, 1); //free the list, unref the devices in it
	if(libusb_kernel_driver_active(dev_handle, 0) == 1){
		 cout<<"Kernel Driver Active"<<endl;
		 if(libusb_detach_kernel_driver(dev_handle, 0) == 0)
			cout<<"Kernel Driver Detached!"<<endl;
	}
	r=libusb_claim_interface(dev_handle, 0);
	if(r<0) {
		cout<<"Cannot Claim Interface"<<endl;
		 return 1;
	}
	else
		cout<<"Interface claimed"<<endl;
	//END USB INITIALIZATION -------------------------------------------------

	//define output file
	FILE *ofp;
	char outputFilename[] = "testOutput64Samples.dat";
	ofp = fopen(outputFilename, "w");
	if (ofp == NULL) {
  		fprintf(stderr, "Can't open output file %s!\n",outputFilename);
  		exit(1);
	}

	unsigned char* outbuf=new unsigned char[OUT_SIZE]; 
	unsigned char* inbuf=new unsigned char[IN_SIZE];
	int in_addr, out_addr;					//Endpoints
	int actual;						//Number of bytes Xfered
	int loop;
	int j;
	bool out_ok = false,in_ok = false;
	int good_no=0, bad_no=0;
	
	//initialize REF DAC A - PULSER voltage DAC
	sendControlWord(dev_handle, 0xAB, 0xC4, 0x30, 0x00); //Write/Update DAC A to 0 V

	//control strobe delay register
	if(1){
		if( controlBoardType == 0 ) //electric board
			sendControlWord(dev_handle, 0xAB, 0xC3, 0x24, 0x09); //electric board
		else{	//mppc board
			sendControlWord(dev_handle, 0xAB, 0xC3, 0x24, 0x06); //delay strobe wrt sft trigger, set length of strobe, pos/neg 
			sendControlWord(dev_handle, 0xAB, 0xC3, 0x30, 0x00); //delay sampling process wrt sft trigger
		}
	}

	//loop over all 16 channels
	for(int ch = controlChan ; ch < controlChan + 1 ; ch++){

		std::cout << "READING OUT CHANNEL " << ch << std::endl;

		//write REF DAC A - PULSER voltage DAC
		if( controlMode == 0 ){ //pedestal run
			sendControlWord(dev_handle, 0xAB, 0xC4, 0x30, 0x00); //Write/Update DAC A to 0 V
		}
		else{ //regular run
			if( controlBoardType == 0 ) //electric board
				sendControlWord(dev_handle, 0xAB, 0xC4, 0x30, 0x08); //Write/Update DAC A to ~0.07 V
			else //MPPC board
				sendControlWord(dev_handle, 0xAB, 0xC4, 0x30, 0xFF); //Write/Update DAC A to ~1.9 V
		}
		sleep(1);

		//control SEL lines depending on channel read out, bit pattern sets SEL on/off
		int test = ch;
		//Control SEL0 aka DAC C
		if( (test >> 0) & 0x1 == 1 )
			sendControlWord(dev_handle, 0xAB, 0xC4, 0x32, 0xFF); //Write/Update DAC C to X V
		else
			sendControlWord(dev_handle, 0xAB, 0xC4, 0x32, 0x00); //Write/Update DAC C to X V
		
		//sleep as DAC update process is slooooow
		sleep(1);

		test = ch;
		//Control SEL1 aka DAC D
		if( (test >> 1) & 0x1 == 1 )
			sendControlWord(dev_handle, 0xAB, 0xC4, 0x33, 0xFF); //Write/Update DAC C to X V
		else
			sendControlWord(dev_handle, 0xAB, 0xC4, 0x33, 0x00); //Write/Update DAC C to X V

		//sleep as DAC update process is slooooow
		sleep(1);

		test = ch;
		//Control SEL2 aka DAC E
		if( (test >> 2) & 0x1 == 1 )
			sendControlWord(dev_handle, 0xAB, 0xC4, 0x34, 0xFF); //Write/Update DAC C to X V
		else
			sendControlWord(dev_handle, 0xAB, 0xC4, 0x34, 0x00); //Write/Update DAC C to X V

		//sleep as DAC update process is slooooow
		sleep(1);

		test = ch;
		//Control SEL3 aka DAC F
		if( (test >> 3) & 0x1 == 1 )
			sendControlWord(dev_handle, 0xAB, 0xC4, 0x35, 0xFF); //Write/Update DAC C to X V
		else
			sendControlWord(dev_handle, 0xAB, 0xC4, 0x35, 0x00); //Write/Update DAC C to X V

		sleep( 1 );

		//read out certain number of events
		readChannelData(dev_handle, ofp, ch,controlNumEvents);

	}

	//close output file
	fclose(ofp);

	//close the interface
	r=libusb_release_interface(dev_handle, 0);
	if(r!=0){
		cout<<"Cannot Release Interface"<<endl;
		return 1;
	}
	libusb_close(dev_handle);
	libusb_exit(ctx); //close the session

	return 0;
}

void sendControlWord(libusb_device_handle *dev_handle, 
	unsigned char w3, unsigned char w2, unsigned char w1, unsigned char w0){
	int r;
	unsigned char* outbuf=new unsigned char[OUT_SIZE]; 
	unsigned char* inbuf=new unsigned char[IN_SIZE];
	int in_addr, out_addr;					//Endpoints
	int actual;						//Number of bytes Xfered
	int loop;
	int j;
	bool out_ok = false,in_ok = false;
	int good_no=0, bad_no=0;
	
	//clear outbuf
	memset(outbuf,0,sizeof(outbuf));

	//START SAMPLING PROCESS
	outbuf[7] = 0x00; outbuf[6] = 0x00; outbuf[5] = 0x00; outbuf[4] = 0x00;
	outbuf[3] = w3; outbuf[2] = w2; outbuf[1] = w1; outbuf[0] = w0;
	//printf("outbuf[%d]=0x%.2X%.2X%.2X%.2X\n",0,outbuf[3],outbuf[2],outbuf[1],outbuf[0]);		
	r=libusb_bulk_transfer(dev_handle, (out_addr | LIBUSB_ENDPOINT_OUT), outbuf, 8, &actual, 4*TM_OUT);

	//write filler words
	outbuf[7] = 0x00; outbuf[6] = 0x00; outbuf[5] = 0x00; outbuf[4] = 0x00;
	outbuf[3] = 0x00; outbuf[2] = 0x00; outbuf[1] = 0x00; outbuf[0] = 0x00;
	//printf("outbuf[%d]=0x%.2X%.2X%.2X%.2X\n",0,outbuf[3],outbuf[2],outbuf[1],outbuf[0]);
	r=libusb_bulk_transfer(dev_handle, (out_addr | LIBUSB_ENDPOINT_OUT), outbuf, 8, &actual, 4*TM_OUT);	

	return;
}

void readChannelData(libusb_device_handle *dev_handle, FILE *ofp, int chan, int numLoop){
	int r;
	unsigned char* outbuf=new unsigned char[OUT_SIZE]; 
	unsigned char* inbuf=new unsigned char[IN_SIZE];
	int in_addr, out_addr;					//Endpoints
	int actual;						//Number of bytes Xfered
	int loop;
	int j;
	bool out_ok = false,in_ok = false;
	int good_no=0, bad_no=0;
	
	//Clear out internal output endpoint FIFO
	//FIFO is 32 by 256 bits, 1024 bytes
	//cout<<"\nClearing the in end point..."<<endl;
	//r=libusb_bulk_transfer(dev_handle, (in_addr | LIBUSB_ENDPOINT_IN), inbuf, 512, &actual, 4*TM_OUT);
	//r=libusb_bulk_transfer(dev_handle, (in_addr | LIBUSB_ENDPOINT_IN), inbuf, 512, &actual, 4*TM_OUT);

	//run through trigger word, readout process X times
	for(int i = 0 ; i < numLoop ; i++){
		if(1 && j % 500 == 0) std::cout << "Readout # " << i << std::endl;
		
		//clear out FIFO
		//libusb_bulk_transfer(dev_handle, (in_addr | LIBUSB_ENDPOINT_IN), inbuf, IN_SIZE, &actual, 4*TM_OUT);
		//clear outbuf
		memset(outbuf,0,sizeof(outbuf));

		//START SAMPLING PROCESS
		sendControlWord(dev_handle, 0xAB, 0xC0, 0x00, 0x00);

		//Digitize and serial read out specific sample - sample 0
		sendControlWord(dev_handle, 0xAB, 0xC1, 0x80, 0+chan);

		//Digitize and serial read out specific sample - sample 1
		sendControlWord(dev_handle, 0xAB, 0xC1, 0x80, 16+chan);

		//read out X bytes
		libusb_bulk_transfer(dev_handle, (in_addr | LIBUSB_ENDPOINT_IN), inbuf, IN_SIZE, &actual, 4*TM_OUT);
		//for(j=0;j<IN_SIZE/4;j++)
		if(0 && i % 100 == 0)
			printf("NEWEVENT\n");

		fprintf(ofp,"NEWEVENT\n");
		for(j=0;j<=252/4;j++){ //
			fprintf(ofp,"%.2X%.2X%.2X%.2X\n",inbuf[4*j+3],inbuf[4*j+2],inbuf[4*j+1],inbuf[4*j]);				
		}//end readout buffer loop
		//pause after each readout
		usleep(10000);
		//sleep(1);
	}//end sampling loop

}

/*
			//parse each line
			int tokenId = *(signed char *)(&inbuf[4*j+3]);
			tokenId = tokenId & 0xC0;
			tokenId = tokenId >> 6;

			int chan = *(signed char *)(&inbuf[4*j+3]);
			chan = chan & 0x3C;
			chan = chan >> 2;

			int col = *(signed char *)(&inbuf[4*j+2]);
			col = col & 0XF0;
			col = col >> 4;
			col |= (inbuf[4*j+3] << 4);
			col = col & 0x3F;

			int row = *(signed char *)(&inbuf[4*j+2]);
			row = row & 0X0E;
			row = row >> 1;

			int cell = *(signed char *)(&inbuf[4*j+2]);
			cell = cell & 0xFE;
			cell = cell >> 1;
			cell |= (inbuf[4*j+3] << 7);
			cell = cell & 0x1FF;

			int sample = *(signed char *)(&inbuf[4*j+1]);
			sample = sample & 0xF0;
			sample = sample >> 4;
			sample |= (inbuf[4*j+2] << 4);
			sample = sample & 0x1F;

			int val = *(signed char *)(&inbuf[4*j+1]);
			val = val & 0xF;
			val *= 1 << 8;
			val |= inbuf[4*j];
			
			//print sample to terminal and file
			if(0 && i % 100 == 0){
				printf("inbuf[%d]=0x%.2X%.2X%.2X%.2X",j,inbuf[4*j+3],inbuf[4*j+2],inbuf[4*j+1],inbuf[4*j]);
				//printf("SAMPLE");
				printf("\t%d",tokenId);
				printf("\t%d",chan);
				printf("\t%d",col);
				printf("\t%d",row);
				printf("\t%d",cell);
				printf("\t%d",sample);
				printf("\t%d",val);
				printf("\n");
			}
*/
