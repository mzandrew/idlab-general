/* Filename: test.c
*
*
*
*
*/

#include <iostream>
#include <libusb.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include<time.h>
using namespace std;

void printdev(libusb_device *dev); //prototype of the function
void list_endpoints(libusb_device *desc);

#define LOOP (1)
#define VID /*(0x6672)*/(0x04B4)
#define PID /*(0x2920)*/(0x1004)
#define IN_SIZE	(512)		//Number of 8-bit words
#define OUT_SIZE (512)		//Number of 8-bit words
#define TM_OUT (1000)		//Timeout for Xfer
#define	 in_addr (0x88)		//Endpoint 6
#define	 out_addr (0x04)	//Endpoint 2

int main() {
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
//			printdev(devs[i]);
//			list_endpoints(devs[i]);
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
	//
	if(libusb_kernel_driver_active(dev_handle, 0) == 1)
		{
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

	unsigned char* outbuf=new unsigned char[OUT_SIZE]; 
	unsigned char* inbuf=new unsigned char[IN_SIZE];
	int in_addr, out_addr;					//Endpoints
	int actual;						//Number of bytes Xfered
	int loop;
	int j;
	bool out_ok = false,in_ok = false;
	int good_no=0, bad_no=0;
	
	//start testing
//	 in_addr=0x86;		//Endpoint 6
//	 out_addr=0x04;		//Endpoint 2

	 cout<<"\nClearing the in end point..."<<endl;
	 r=libusb_bulk_transfer(dev_handle, (in_addr | LIBUSB_ENDPOINT_IN), inbuf, 512, &actual, TM_OUT);
	 r=libusb_bulk_transfer(dev_handle, (in_addr | LIBUSB_ENDPOINT_IN), inbuf, 512, &actual, TM_OUT);

	 printf("Testing the loop between end points 0x%x and 0x%x\n",in_addr,out_addr);
	 good_no=bad_no=0;
	 for(loop=0;loop<LOOP;loop++) 
		{
		//////////////////////////////////////////-TX
		srand(time(NULL));
//		srand(rand());
		for(j=0;j<OUT_SIZE;j++){
			outbuf[j]=(unsigned char)rand();
		}
	
		r=libusb_bulk_transfer(dev_handle, (out_addr | LIBUSB_ENDPOINT_OUT), outbuf, OUT_SIZE, &actual, 2*TM_OUT);

		for(j=0;j<OUT_SIZE/4;j++){
			printf("outbuf[%d]=0x%.2X%.2X%.2X%.2X\n",j,outbuf[4*j+3],outbuf[4*j+2],outbuf[4*j+1],outbuf[4*j]);
		}

		printf("Tx Size: %d\n",actual);

		if(r==0 && actual == OUT_SIZE) 
			out_ok=true;	
		else
			out_ok=false;
		//////////////////////////////////////////

		//////////////////////////////////////////-RX
		r=libusb_bulk_transfer(dev_handle, (in_addr | LIBUSB_ENDPOINT_IN), inbuf, IN_SIZE, &actual, 2*TM_OUT);

		for(j=0;j<IN_SIZE/4;j++)
			printf("inbuf[%d]=0x%.2X%.2X%.2X%.2X\n",j,inbuf[4*j+3],inbuf[4*j+2],inbuf[4*j+1],inbuf[4*j]);

		printf("Rx Size: %d\n",actual);

		if(r==0 && actual == IN_SIZE)
			in_ok=true;
		else
			in_ok=false;
		//////////////////////////////////////////

		//////////////////////////////////////////-Check
		printf("Write Status: %d\tRead Status: %d\n",out_ok,in_ok);
		stat_chk = memcmp(outbuf,inbuf,IN_SIZE);
		printf("Status Check: %d\n",stat_chk);
		//////////////////////////////////////////

		}
	printf("\n");
	
	r=libusb_release_interface(dev_handle, 0);
	if(r!=0){
		cout<<"Cannot Release Interface"<<endl;
		return 1;
	}

	libusb_close(dev_handle);
	libusb_exit(ctx); //close the session

	return 0;
}

void list_endpoints(libusb_device *dev)
{
 libusb_config_descriptor *config;
 const libusb_interface *inter;
 const libusb_interface_descriptor *interdesc;
 const libusb_endpoint_descriptor *epdesc;
 int endpoints_no;
 int i;

 libusb_get_config_descriptor(dev, 0, &config);
 inter = &config->interface[0];
 interdesc = &inter->altsetting[0];
 endpoints_no=(int)interdesc->bNumEndpoints;
 
 cout<<"Number of endpoints: "<<endpoints_no<<endl;
 for(i=0;i<endpoints_no;i++)
	{
	 epdesc = &interdesc->endpoint[i];
	 if(epdesc->bEndpointAddress & 0x80)
		printf("found an IN End Point %d with attributes %d and address 0x%x\n",i,epdesc->bmAttributes, epdesc->bEndpointAddress);
	 else  
		printf("found an OUT End Point %d with atributes %d and address 0x%x\n",i,epdesc->bmAttributes,epdesc->bEndpointAddress);
	}
 libusb_free_config_descriptor(config);

 return;
}

void printdev(libusb_device *dev) {
	libusb_device_descriptor desc;
	int r = libusb_get_device_descriptor(dev, &desc);
	if (r < 0) {
		cout<<"failed to get device descriptor"<<endl;
		return;
	}
	cout<<"Number of possible configurations: "<<(int)desc.bNumConfigurations<<"  ";
	cout<<"Device Class: "<<(int)desc.bDeviceClass<<"  ";
	printf("VendorID: %.4X  ",desc.idVendor);
	printf("ProductID: %.4X\n",desc.idProduct);
	//cout<<"VendorID: "<<desc.idVendor<<"  ";
	//cout<<"ProductID: "<<desc.idProduct<<endl;
	libusb_config_descriptor *config;
	libusb_get_config_descriptor(dev, 0, &config);
	cout<<"Total interface number: "<<(int)config->bNumInterfaces<<" ||| ";
	const libusb_interface *inter;
	const libusb_interface_descriptor *interdesc;
	const libusb_endpoint_descriptor *epdesc;
	for(int i=0; i<(int)config->bNumInterfaces; i++) {
		inter = &config->interface[i];
		cout<<"Number of alternate settings: "<<inter->num_altsetting<<" | ";
		for(int j=0; j<inter->num_altsetting; j++) {
			interdesc = &inter->altsetting[j];
			cout<<"Interface Number: "<<(int)interdesc->bInterfaceNumber<<" | ";
			}
		}
	cout<<endl<<endl<<endl;
	libusb_free_config_descriptor(config);
}


