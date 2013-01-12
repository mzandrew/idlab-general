// wrappers around IO function calls for USB, PCI, etc

#include "generic.h"
#include "io_interface.h"
#include "DebugInfoWarningError.h"

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
	#ifndef FAKE_IT
		fprintf(debug, "sending %u bytes...", size_in_bytes);
		#ifdef USE_USB
			usb_XferData((OUT_ADDR | LIBUSB_ENDPOINT_OUT), output_buffer, size_in_bytes, TM_OUT);
		#endif
		fprintf(debug, "\n");
	#else
		fprintf(debug, "(faking it) sending %u bytes...\n", size_in_bytes);
	#endif
}

int receive_data(unsigned char *input_buffer, unsigned int size_in_bytes) {
	int return_value = 0;
	#ifndef FAKE_IT
		#ifdef USE_USB
			return_value = usb_XferData((IN_ADDR | LIBUSB_ENDPOINT_IN), input_buffer, size_in_bytes, TM_OUT);
		#endif
	#else
	#endif
	return return_value;
}

int receive_packet(unsigned char *input_char_buffer) {
	unsigned int *input_buffer;
	input_buffer = (unsigned int *) input_char_buffer;
	int length = 0, j = 0, k = 0;
	int retval = receive_data(input_char_buffer, 512*sizeof(unsigned int));
	while (retval > 0) {
		if (0) {
			for(j=0; j<retval; j++) {
				printf("%c", sanitize_char(input_char_buffer[j]));
				k++;
				if (k%4==0) {
					printf(",");
				}
			}
		}
		length += retval;
		input_char_buffer += retval;
//		byte_reverse(input_buffer,retval/4);
		//retval = receive_data(input_char_buffer + length, 512*sizeof(unsigned int));
		retval = receive_data(input_char_buffer, 512*sizeof(unsigned int));
	}
	//cout << "Read out " << retval << " bytes." << endl;
	if (1) {
		fprintf(debug, "read %u bytes\n", length);
		//cout << "Read out " << length << " bytes." << endl;
	} else {
		//cout << "Read out " << length << " bytes:" << endl;
		fprintf(debug, "read %u bytes:\n", length);
		for(j=0; j<(length>>2); j++) {
			printf("input_buffer[%d] 0x%08x ",j,input_buffer[j]);
			for (k = 3; k >= 0; --k) {
				unsigned int mask = 0x000000FF;
				mask = mask << (k*8);
				mask = mask & input_buffer[j];
				mask = mask >> (k*8);
				char this_char = (char) mask;
				printf("%c", sanitize_char(this_char));
			}
			printf("\n");
		}
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

