#include <iostream>
#include <libusb.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include<time.h>
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

int main(int argc, char *argv[] ){
	if ( argc != 2 ) /* argc should be 2 for correct execution */
	{
        	/* We print argv[0] assuming it is the program name */
		printf( "usage: %s controlBias", argv[0] );
		return 1;
	}
	int controlBias= atoi(argv[1]);

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

	unsigned char* outbuf=new unsigned char[OUT_SIZE]; 
	unsigned char* inbuf=new unsigned char[IN_SIZE];
	int in_addr, out_addr;					//Endpoints
	int actual;						//Number of bytes Xfered
	int loop;
	int j;
	bool out_ok = false,in_ok = false;
	int good_no=0, bad_no=0;

	//optionally clear out output FIFO
	if(0){
		//FIFO is 32 by 256 bits, 1024 bytes
		cout<<"\nClearing the in end point..."<<endl;
		r=libusb_bulk_transfer(dev_handle, (in_addr | LIBUSB_ENDPOINT_IN), inbuf, 512, &actual, 4*TM_OUT);
		r=libusb_bulk_transfer(dev_handle, (in_addr | LIBUSB_ENDPOINT_IN), inbuf, 512, &actual, 4*TM_OUT);
	}

	//Output buffer to FIFO word notes:
	//Data packets should come in groups of four 8-bit words to match internal 32 bit endpoint
	//Label packet bytes as they are written in outbuf array follows: 3 2 1 0
	//Resulting 32 bit word in FIFO is arranged as: 1 0 3 2
	
	if(1){
		//ASIC DAC control word - ABC2:
		//0x0XXX = Default
		//0x1XXX = Set Isel to XXX - default = FFE
		//0x2XXX = Set Vdly to XXX - default = FFF
		//0x3XXX = Set Vdischarge to XXX - default = 0c0
		//0x4XXX = CMPBias, default = 00C - better value 0FC
		//0x5XXX = PUBias, default = 007
		//0x6XXX = DBBias, default = FFC
		//0x7XXX = SBbias, default = 0DE
		sendControlWord(dev_handle, 0xAB, 0xC2, 0x00, 0x00);
	}

	//Trigger controls
	if(0){

		//ASIC DAC control word - ABC2:
		//0x8XXX = SGN_ASIC bit 0, Trig_type_ASIC bit 1
		//0x9XXX = Set Wbias_ASIC to XXX
		//0xAXXX = Set TRGbias_ASIC to XXX
		//0xBXXX = Set MonTRGthresh_ASIC to XXX
		sendControlWord(dev_handle, 0xAB, 0xC2, 0x80, 0x00);		
		sendControlWord(dev_handle, 0xAB, 0xC2, 0x00, 0x00);

		//Trigger threshold control - ABC6
		//0x0XXX = Default values
		//0x#XXX = set channel # trigger threshold to XXX
		sendControlWord(dev_handle, 0xAB, 0xC6, 0x10, 0xCE);
		if(0){
		sendControlWord(dev_handle, 0xAB, 0xC6, 0x00, 0x00);
		sendControlWord(dev_handle, 0xAB, 0xC6, 0x10, 0xCE);
		sendControlWord(dev_handle, 0xAB, 0xC6, 0x20, 0x00);
		sendControlWord(dev_handle, 0xAB, 0xC6, 0x30, 0x00);
		sendControlWord(dev_handle, 0xAB, 0xC6, 0x40, 0x00);
		sendControlWord(dev_handle, 0xAB, 0xC6, 0x50, 0x00);
		sendControlWord(dev_handle, 0xAB, 0xC6, 0x60, 0x00);
		sendControlWord(dev_handle, 0xAB, 0xC6, 0x70, 0x00);
		sendControlWord(dev_handle, 0xAB, 0xC6, 0x80, 0x00);
		sendControlWord(dev_handle, 0xAB, 0xC6, 0x90, 0x00);
		sendControlWord(dev_handle, 0xAB, 0xC6, 0xA0, 0x00);
		sendControlWord(dev_handle, 0xAB, 0xC6, 0xB0, 0x00);
		sendControlWord(dev_handle, 0xAB, 0xC6, 0xC0, 0x00);
		sendControlWord(dev_handle, 0xAB, 0xC6, 0xD0, 0x00);
		sendControlWord(dev_handle, 0xAB, 0xC6, 0xE0, 0x00);
		sendControlWord(dev_handle, 0xAB, 0xC6, 0xF0, 0x00);
		}
		if(0){
		for(int i = 0 ; i < 256 ; i++){
			std::cout << " i " << i << std::endl;
			sendControlWord(dev_handle, 0xAB, 0xC6, 0x10, i);
			sendControlWord(dev_handle, 0xAB, 0xC2, 0x00, 0x00);
			sleep(1);
		}
		}
	}

	//Readout control registers - ABC3
	if(0){
		//0x1 - dig offset
		//0x2 - trig_control, bit 11 toggle positive and negative clock edge trigger processes
		//0x2 - trig_control, bit 10-8 control with of strobe, bits 7-0 control delay before asserting trigger
		sendControlWord(dev_handle, 0xAB, 0xC3, 0x20, 0x00);
	}

	//xABC5 - set arbitray MPPC DACs
	if(controlBias > 0){
		//bits
		sendControlWord(dev_handle, 0xAB, 0xC5, 0x10, controlBias);
		//sleep as DAC update process is slooooow
		sleep(1);
	}
	else{
		//set MPPC DACs to specific values
		//default value is 35
		unsigned char dacValue[16];
		dacValue[0] = 45;
		dacValue[1] = 45;
		dacValue[2] = 47;
		dacValue[3] = 44;
		dacValue[4] = 43;
		dacValue[5] = 47;
		dacValue[6] = 47;
		dacValue[7] = 47;
		dacValue[8] = 49;
		dacValue[9] = 46;
		dacValue[10] = 30;
		dacValue[11] = 52;
		dacValue[12] = 52;
		dacValue[13] = 60;
		dacValue[14] = 52;
		dacValue[15] = 35;
		for(int i = 0 ; i < 16 ; i++){
			sendControlWord(dev_handle, 0xAB, 0xC5, i, dacValue[i]);
			//sleep as DAC update process is slooooow
			sleep(1);
		}
	}

	//xABC4 - control i2C DAC writer
	//Control bits: (Command word = 4 bits) & (Address words = 4 bits) & (8 MSB of 12 bit DAC = 8 bits)
	/*
	--		--Command codes
	--		constant NoOperation			: std_logic_vector(3 downto 0) := "1111";
	--		constant WriteReg			: std_logic_vector(3 downto 0) := "0000";
	--		constant UpdateReg			: std_logic_vector(3 downto 0) := "0001";
	--		constant WriteUpdateAll			: std_logic_vector(3 downto 0) := "0010";
	--		constant WriteUpdateSingle		: std_logic_vector(3 downto 0) := "0011";
	--		constant PowerDownSingle		: std_logic_vector(3 downto 0) := "0100";
	--		constant PowerDownChip			: std_logic_vector(3 downto 0) := "0101";
	--		-------------------------------------------------------------------------
	--		--Address codes no shown are reserved and should not be used.
	--		constant DAC_A				: std_logic_vector(3 downto 0) := "0000";
	--		constant DAC_B				: std_logic_vector(3 downto 0) := "0001";
	--		constant DAC_C				: std_logic_vector(3 downto 0) := "0010";
	--		constant DAC_D				: std_logic_vector(3 downto 0) := "0011";
	--		constant DAC_E				: std_logic_vector(3 downto 0) := "0100";
	--		constant DAC_F				: std_logic_vector(3 downto 0) := "0101";
	--		constant DAC_G				: std_logic_vector(3 downto 0) := "0110";
	--		constant DAC_H				: std_logic_vector(3 downto 0) := "0111";
	--		constant ALL_DACs			: std_logic_vector(3 downto 0) := "1111";
	*/
	//set arbitray LTC DACs
	if(0){
		//DAC A values: electric mode 0x004 works well, MPPC mode 0xF00
		//sendControlWord(dev_handle, 0xAB, 0xC4, 0x30, 0x08); //Write/Update DAC A to X V
		sendControlWord(dev_handle, 0xAB, 0xC4, 0x3F, 0x00); //Write/Update DAC A to X V

		//sleep as DAC update process is slooooow
		sleep(1);
	}

	//Control test board SEL signals
	if(0){
		//Control SEL0 aka DAC C
		sendControlWord(dev_handle, 0xAB, 0xC4, 0x32, 0x00); //Write/Update DAC C to X V

		//sleep as DAC update process is slooooow
		sleep(1);

		//Control SEL1 aka DAC D
		sendControlWord(dev_handle, 0xAB, 0xC4, 0x33, 0xFF); //Write/Update DAC D to X V

		//sleep as DAC update process is slooooow
		sleep(1);

		//Control SEL2 aka DAC E
		sendControlWord(dev_handle, 0xAB, 0xC4, 0x34, 0x00); //Write/Update DAC E to X V

		//sleep as DAC update process is slooooow
		sleep(1);

		//Control SEL3 aka DAC F
		sendControlWord(dev_handle, 0xAB, 0xC4, 0x35, 0x00); //Write/Update DAC F to X V
	}

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
	printf("outbuf[%d]=0x%.2X%.2X%.2X%.2X\n",0,outbuf[3],outbuf[2],outbuf[1],outbuf[0]);		
	r=libusb_bulk_transfer(dev_handle, (out_addr | LIBUSB_ENDPOINT_OUT), outbuf, 8, &actual, 4*TM_OUT);

	//write filler words
	outbuf[7] = 0x00; outbuf[6] = 0x00; outbuf[5] = 0x00; outbuf[4] = 0x00;
	outbuf[3] = 0x00; outbuf[2] = 0x00; outbuf[1] = 0x00; outbuf[0] = 0x00;
	//printf("outbuf[%d]=0x%.2X%.2X%.2X%.2X\n",0,outbuf[3],outbuf[2],outbuf[1],outbuf[0]);
	r=libusb_bulk_transfer(dev_handle, (out_addr | LIBUSB_ENDPOINT_OUT), outbuf, 8, &actual, 4*TM_OUT);	

	return;
}
