//2012-?? Chester Lim

#include "usb.h"
#include <stdio.h>

libusb_context *ctx = NULL;		//Needed to create a libusb session
libusb_device **dev;			//List of USB devices
libusb_device_descriptor desc;		//USB Device descriptor list
libusb_device_handle *dev_handle;	//Device handle

int setup_usb(void){
	int status;				//Holds status value for functions
	ssize_t	dev_cnt;			//Holds number of devices found

	//////////////////-Create libusb session
	status = libusb_init(&ctx);		//Create a libusb session
	if(status < 0){
		cout<<"Cannot create libusb session. Error: "<<status<<endl;
		exit(-2);
	}
	libusb_set_debug(ctx,3);		//Set verbosity to lvl 3
	//////////////////

	//////////////////-Available USB devices
	dev_cnt = libusb_get_device_list(ctx, &dev);	//Get list of USB devices

#ifdef USB_DEBUG
	if(dev_cnt < 0 ){
		cout<<"No USB devices found"<<endl;
	}
	ssize_t i;				//Search through device list
	for(i = 0; i < dev_cnt; i++){
		status = libusb_get_device_descriptor(dev[i], &desc);
		if(status < 0){
			cout<<"Failed to get device descriptor"<<endl;
			exit(-2);
		}
		if(desc.idVendor == SCROD_USB_VID && desc.idProduct == SCROD_USB_PID){
			cout<<"Found SCROD USB Device"<<endl;
			printdev(dev[i]);
			list_endpoints(dev[i]);
			break;
		}
	}
	if(i == dev_cnt){
		cout<<"Could not find SCROD USB Device"<<endl;
		exit(-2);
	}
#endif
	//////////////////

	//////////////////-Open USB device
	dev_handle = libusb_open_device_with_vid_pid(ctx,SCROD_USB_VID,SCROD_USB_PID);	//Open SCROD USB Device
	if(dev_handle == NULL){
		cout<<"Could not open SCROD USB Device"<<endl;
		exit(-2);
	}
	else{
		cout<<"SCROD USB Device Opened"<<endl;
	}
	libusb_free_device_list(dev,1);		//Unreferencing devices in device list as suggested in documentation
	//////////////////

	//////////////////-Check kernel status
	status = libusb_kernel_driver_active(dev_handle,0);
	if(status == 1){
		cout<<"Kernel driver active"<<endl;
		cout<<"Trying to detach driver..."<<endl;
		status = libusb_detach_kernel_driver(dev_handle,0);
		if(status == 0){
			cout<<"Kernel driver detached"<<endl;
		}
		else{
			cout<<"Kernel driver cannot be detached"<<endl;
			exit(-3);
		}
	}
	//////////////////

	//////////////////-Claim an interface
	status = libusb_claim_interface(dev_handle,0);
	if(status < 0){
		cout<<"Could not claim an interface"<<endl;
		exit(-3);
	}
	else{
		cout<<"Interface claimed"<<endl;
	}
	//////////////////
}

///////////////////////////////////////--Code from Xin Gao
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

///////////////////////////////////////--Code from Xin Gao
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

void usb_ClearEndpnt(unsigned char endpoint, unsigned char* data, int length, unsigned int timeout){
	int xferd;
	printf("Clearing data at %.4X End Point\n",endpoint);
//	libusb_clear_halt(dev_handle,endpoint);
	libusb_bulk_transfer(dev_handle, endpoint, data, length, &xferd, timeout);
	libusb_bulk_transfer(dev_handle, endpoint, data, length, &xferd, timeout);
}

void usb_XferData(unsigned char endpoint, unsigned char* data, int length, unsigned int timeout){
	int status;
	int xferd;
	printf("Xfering at %.4X End Point\n",endpoint);
	status = libusb_bulk_transfer(dev_handle, endpoint, data, length, &xferd, timeout);
	cout<<"Transferred: "<<xferd<<" bytes"<<endl;
	if((status == 0) && (xferd == length));
	else{
		cout<<"Transferred Failed"<<endl;
	}
}

void close_usb(void){
	int status;
	fprintf(stderr,"Closing SCROD USB Device\n");
	//////////////////-Release interface
	status = libusb_release_interface(dev_handle,0);
	if(status != 0){
		cout<<"Unable to release interface"<<endl;
	}
	libusb_close(dev_handle);		//Close device handle
	libusb_exit(ctx);			//Close libusb session
}	
