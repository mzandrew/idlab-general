// wrappers around IO function calls for USB, PCI, etc

#include "generic.h"
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

int receive_packet(unsigned char *input_char_buffer) {
	unsigned int *input_buffer;
	input_buffer = (unsigned int *) input_char_buffer;
	int length = 0;
	int retval = receive_data(input_char_buffer, 512*sizeof(unsigned int));
	cout << "Read out " << retval << " bytes." << endl;
	while (retval > 0) {
		length += retval;
//		input_char_buffer += retval;
//		byte_reverse(input_buffer,retval/4);
		for(int j=0; j<retval/4; j++) {
			printf("input_buffer[%d]=0x%.8X\t",j,input_buffer[j]);
			for (int k = 3; k >= 0; --k) {
				unsigned int mask = 0x000000FF;
				mask = mask << (k*8);
				mask = mask & input_buffer[j];
				mask = mask >> (k*8);
				char this_char = (char) mask;
				printf("%c", sanitize_char(this_char));
			}
			printf("\n");
		}
		//retval = receive_data(input_char_buffer + length, 512*sizeof(unsigned int));
		retval = receive_data(input_char_buffer, 512*sizeof(unsigned int));
	}
	return length;
}

void close_io_interface(void) {
#ifdef USE_USB
#ifndef FAKE_IT
	close_usb();
#endif
#endif
}

