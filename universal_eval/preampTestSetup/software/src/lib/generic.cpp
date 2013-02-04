// General purpose utilities

#include "generic.h"

void byte_reverse(unsigned int *input, int size) {
	for (int i = 0; i < size; ++i) {
		input[i] = ((input[i] & 0x0000FFFF) << 16) | ((input[i] & 0xFFFF0000) >> 16);
	}
}

char sanitize_char(char mychar) {
	if ('A' <= mychar && mychar <= 'Z') { }
	else if ('a' <= mychar && mychar <= 'z') { }
	else if ('0' <= mychar && mychar <= '9') { }
	else { mychar = ' '; }
	return mychar;
}

