#include <libusb.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <iostream>
using namespace std;

#define USB_DEBUG
#define SCROD_USB_VID (0x04B4)
#define SCROD_USB_PID (0x1004)
#define USB_IN_ENDPNT (0x88)
#define USB_OUT_ENDPNT (0x04)
#define TM_OUT  (10)  //100 ms timeout period

extern libusb_device_handle *dev_handle;

int setup_usb(void);
void printdev(libusb_device *dev);
void list_endpoints(libusb_device *desc);
void usb_ClearEndpnt(unsigned char endpoint, unsigned char* data, int length, unsigned int timeout);
int usb_XferData(unsigned char endpoint, unsigned char* data, int length, unsigned int timeout);
void close_usb(void);

