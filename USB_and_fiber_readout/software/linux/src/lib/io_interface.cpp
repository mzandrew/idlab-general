// wrappers around IO function calls for USB, PCI, etc

#include "io_interface.h"

#ifdef USE_USB
#include "idl_usb.h"
#endif

void initialize_io_interface(unsigned char *input_buffer) {
#ifdef USE_USB
#ifndef FAKE_IT
	setup_usb();
	//Clear the input buffer
	usb_ClearEndpnt((IN_ADDR | LIBUSB_ENDPOINT_IN), input_buffer, 512, TM_OUT);
#endif
#endif
}

void send_data(unsigned char *output_buffer, unsigned int size_in_bytes) {
#ifdef USE_USB
#ifndef FAKE_IT
	usb_XferData((OUT_ADDR | LIBUSB_ENDPOINT_OUT), output_buffer, size_in_bytes, TM_OUT);
#endif
#endif
}

int receive_data(unsigned char *input_buffer, unsigned int size_in_bytes) {
	int return_value = 0;
#ifdef USE_USB
#ifndef FAKE_IT
	return_value = usb_XferData((IN_ADDR | LIBUSB_ENDPOINT_IN), input_buffer, size_in_bytes, TM_OUT);
#endif
#endif
	return return_value;
}

void close_io_interface(void) {
#ifdef USE_USB
#ifndef FAKE_IT
	close_usb();
#endif
#endif
}

