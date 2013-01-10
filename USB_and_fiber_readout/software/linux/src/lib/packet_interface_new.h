#ifndef PACKET_INTERFACE__H
#define PACKET_INTERFACE__H

#include <vector>

#define MAXIMUM_PACKET_SIZE (512) //In words

#define PACKET_HEADER           (0x00BE11E2) //hex:BELLE2
#define PACKET_TYPE_COMMAND     (0x646f6974) //ascii:"doit"
#define PACKET_TYPE_ACKNOWLEDGE (0x6f6b6179) //ascii:"okay"
#define PACKET_TYPE_ERROR       (0x7768613f) //ascii:"wha?"
#define PACKET_TYPE_EVENT       (0x65766e74) //ascii:"evnt"
#define PACKET_TYPE_WAVEFORM    (0x77617665) //ascii:"wave"
#define COMMAND_TYPE_PING       (0x70696e67) //ascii:"ping"
#define COMMAND_TYPE_READ       (0x72656164) //ascii:"read"
#define COMMAND_TYPE_WRITE      (0x72697465) //ascii:"rite"

typedef unsigned int packet_word_t;
unsigned int current_command_id = 0;

class packet {
	public:
		enum CommandType  {kPING,kREAD,kWRITE,kQUIETWRITE};
		enum ResponseType {kACK,kERR};	
		////CONSTRUCTORS////
		//Default constructor, creates empty packet
		packet();
		//Creates a packet using data from initial_array[0] to array[size-1]
		packet(char *initial_array, unsigned int size); 
		//Scans for a packet header in stream starting from pos, reads 
		//a number of words based on the length field (one after the header),
		//and returns pos just after the end of the detected packet.
		//If the packet fails any checks, pos will be returned just after
		//the first detected header to allow for rescanning.
		packet(char *stream, unsigned int &pos);
		//Default destructor
		~packet();

		////////PACKET MANIPULATION//////////////////////
		//Clears the payload data and checksum of a packet
		void ClearPacket();

		//Return the total size or payload size
		int GetTotalSize();
		int GetPayloadSize();
		//Creates your packet on the heap and passes back
		//a pointer.  You are responsible for deleting it after you're
		//done with it.
		packet_word_t* AssemblePacket(int &total_size_in_words);
		/////////GENERIC COMMANDS/////////////////////////////
		void PrintPacket();
		bool CheckSumMatches();
		bool ContainsAPlausiblyValidStructure();
		void CheckPacket();
		bool CommandWasExecutedSuccessfully();
	protected:
		void RecalculateStoredChecksum();

		std::vector<packet_word_t> payload_data;
		unsigned int stored_checksum;
	private:
};

class command_packet : public packet {
	public:
		//////CONSTRUCTORS/////
		//Single command constructor
		//Defaults are scrod_id = 0 (broadcast), command_id = 0, verbosity = 0 (do not suppress response)
		//Examples:
		//	1) ping broadcast                    : command_packet a(kPING);
		//  2) ping to SCROD 32                  : command_packet a(kPING,32);
		//  3) read SCROD 32 reg 23              : command_packet a(kREAD,32,23);
		//  4) write 1027 to SCROD 32 reg 23     : command_packet a(kWRITE,32,23,1027);
		//  5) as above with response suppressed : command_packet a(kQUIETWRITE,32,23,1027);
		//  6) quiet broadcast write 1 to reg 21 : command_packet a(kQUIETWRITE,0,21,1);
		//Command IDs are taken from a global variable that increments when a new command is created
		command_packet(command_type command, unsigned int scrod_id = 0);

		/////MULTI-COMMAND SUPPORT////
		//Not implemented at the moment.
		/*
		//Add commands to the packet for multi-command use
		void AddPingToPacket();
		void AddReadToPacket(unsigned short int reg_id);
		void AddWriteToPacket(unsigned short int reg_id, 
		                      unsigned short int reg_data);
		*/
};

class response_packet : public packet {
	public:
		//Accessors for the guts of a packet
		unsigned int GetScrodId();
		unsigned int GetRegister();
		unsigned int GetValue();
		unsigned int GetResponseType();
		//Check against a single command packet 
		bool MatchesCommand(command packet);
		
};

//Still to be added... empty for now
class event_header_packet : public packet {

};
class waveform_packet : public packet {

};

#endif

