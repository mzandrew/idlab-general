#include "generic.h"
#include "packet_interface.h"
#include "DebugInfoWarningError.h"
#include <stdio.h>

using namespace std;

packet::packet() {
	packet_type_is_acknowledge = false;
}

packet::packet(unsigned int *initial_array, unsigned int length) {
	for (int i=0; i<length; i++) {
		payload_data.push_back(initial_array[i]);
	}
	packet_type_is_acknowledge = false;
}

packet::~packet() {}


void packet::ClearPacket() {
	payload_data.clear();
}

void packet::CreateCommandPacket(unsigned int base_command_id, unsigned int board_id) {
	command_id = base_command_id;
	//This is a command packet, so start adding to the payload...
	payload_data.push_back(PACKET_TYPE_COMMAND);
	payload_data.push_back(board_id);
}

void packet::AddPingToPacket() {
	unsigned int command_checksum = 0;
	payload_data.push_back(command_id);
	command_checksum += command_id;
	command_id++;
	payload_data.push_back(COMMAND_TYPE_PING);
	command_checksum += COMMAND_TYPE_PING;
	payload_data.push_back(command_checksum);
}

void packet::AddReadToPacket(unsigned short int reg_id) {
	unsigned int command_checksum = 0;
	payload_data.push_back(command_id);
	command_checksum += command_id;
	command_id++;
	payload_data.push_back(COMMAND_TYPE_READ);
	command_checksum += COMMAND_TYPE_READ;
	payload_data.push_back( (unsigned int) reg_id);
	command_checksum += (unsigned int) reg_id;
	payload_data.push_back(command_checksum);
}

void packet::AddWriteToPacket(unsigned short int reg_id, unsigned short int reg_data) {
	unsigned int command_checksum = 0;
	payload_data.push_back(command_id);
	command_checksum += command_id;
	command_id++;
	payload_data.push_back(COMMAND_TYPE_WRITE);
	command_checksum += COMMAND_TYPE_WRITE;
	unsigned int temp_word = 0;
	temp_word |= (reg_data << 16) | (reg_id);
	payload_data.push_back(temp_word);
	command_checksum += temp_word;
	payload_data.push_back(command_checksum);
}

int packet::GetTotalSize() {
	//Payload data does not include overall header or the size itself
	//or the packet checksum.
	//So we should add an extra 3 words for the data out
	return (payload_data.size() + 3);
}

int packet::GetPayloadSize() {
	//Payload data vector does not include the checksum
	//So we should add an extra word for the data out
	return (payload_data.size() + 1);
}

unsigned int *packet::AssemblePacket(int &total_size_in_words) {
	total_size_in_words = this->GetTotalSize();
	unsigned int *packet_data = new unsigned int[total_size_in_words];
	unsigned int packet_checksum = 0;
	packet_data[0] = PACKET_HEADER;
	packet_data[1] = this->GetPayloadSize();
	int counter = 2;
	for (vector<unsigned int>::iterator i = payload_data.begin();
	     i != payload_data.end(); ++i) {
		packet_data[counter] = (*i);
		counter++;
	}
	for (int i = 0; i < counter; ++i) {
		packet_checksum += packet_data[i];
	}
	packet_data[counter] = packet_checksum;
	return packet_data;
}

void packet::PrintPacket() {
	int size = 0;
	unsigned int *data = this->AssemblePacket(size);
	for (int i = 0; i < size; ++i) {
		char words[4];
		for (int j = 0; j < 4; ++j) {
			words[j] = (data[i] & (0xFF << (j*8))) >> (j*8);
		}
		printf("[%04d]: %08x\t%c%c%c%c\n", i, data[i], \
			sanitize_char(words[3]), sanitize_char(words[2]), \
			sanitize_char(words[1]), sanitize_char(words[0]));
	}
	delete [] data;
	CheckPacket();
}

bool packet::CheckSumMatches() {
	int size = 0;
	unsigned int *data = this->AssemblePacket(size);
	unsigned int packet_checksum = 0;
	for (int i = 0; i < size - 1; ++i) {
		packet_checksum += data[i];
	}
	unsigned int checksum_from_packet = data[size-1];
	delete [] data;
	if (packet_checksum == checksum_from_packet) {
		return true;
	} else {
		return false;
	}
}

unsigned int packet_type[] = { PACKET_TYPE_COMMAND, PACKET_TYPE_ACKNOWLEDGE, PACKET_TYPE_ERROR };
unsigned int number_of_packet_types = sizeof(packet_type) / sizeof(packet_type[0]);

bool packet::ContainsAPlausiblyValidStructure() {
	int errors = 0;
	bool valid_type = false;
	packet_type_is_acknowledge = false;
	int size = 0;
	unsigned int packet_checksum = 0;
	unsigned int *data = this->AssemblePacket(size);
	if (size<3) { errors++; }
	for (int i=0; i<size; i++) {
		if (i!=size-1) {
			packet_checksum += data[i];
		}
		// ------------------------------------------------------------------
		if (i==0) {
			if (data[0] != PACKET_HEADER) { errors++; }
		} else if (i==1) {
			if (data[i] > MAXIMUM_PACKET_SIZE) { errors++; }
		} else if (i==2) {
			for (int j=0; j<number_of_packet_types; j++) {
				if (data[i] == packet_type[j]) {
					valid_type = true;
					if (data[i] == PACKET_TYPE_ACKNOWLEDGE) {
						packet_type_is_acknowledge = true;
					}
				}
			}
			if (!valid_type) { errors++; }
		} else if (i>=2 && i<size-1) {
		} else if (i==size-1) {
			if (packet_checksum != data[i]) { errors++; }
			//if (!CheckSumMatches()) { errors++; } // this could be made slightly more efficient
		}
		// ------------------------------------------------------------------
	}
	delete [] data;
	return errors ? false : true;
}

void packet::CheckPacket() {
//	if (!CheckSumMatches()) {
//		fprintf(error, "ERROR:  checksum does not match!\n");
//	}
	if (!ContainsAPlausiblyValidStructure()) {
		fprintf(error, "ERROR:  packet does not seem to be valid!\n");
	}
}

bool packet::CommandWasExecutedSuccessfully() {
	ContainsAPlausiblyValidStructure();
	return packet_type_is_acknowledge ? true : false;
}

/*
things that should be done, perhaps:
	change all 512's to MAX_PACKET_SIZE
	change all unsigned int's that correspond to the basic datatype to a typedef (typedef unsigned int my_datatype; etc)
	DebugInfoWarningError should be c++'ed so that it's info << "this is my informational message" << endl; and error << "ERROR:  you didn't sanitize your inputs, did you? " << endl; with default constructors so it doesn't segfault if you don't run the init function...
*/

