#ifndef PACKET_INTERFACE__H
#define PACKET_INTERFACE__H

#include <vector>

typedef unsigned int packet_word;
#define NUMBER_OF_BYTES_PER_WORD (sizeof(packet_word))
#define MAXIMUM_PACKET_SIZE_IN_WORDS (512)
#define MAXIMUM_PACKET_SIZE_IN_BYTES (MAXIMUM_PACKET_SIZE_IN_WORDS*NUMBER_OF_BYTES_PER_WORD)

#define PACKET_HEADER           (0x00BE11E2) //hex:BELLE2
#define PACKET_TYPE_COMMAND     (0x646f6974) //ascii:"doit"
#define PACKET_TYPE_ACKNOWLEDGE (0x6f6b6179) //ascii:"okay"
#define PACKET_TYPE_ERROR       (0x7768613f) //ascii:"wha?"
#define COMMAND_TYPE_PING       (0x70696e67) //ascii:"ping"
#define COMMAND_TYPE_READ       (0x72656164) //ascii:"read"
#define COMMAND_TYPE_WRITE      (0x72697465) //ascii:"rite"

//enum packet_type {COMMAND,ACKNOWLEDGE,ERROR} asdf;
//enum command_type {PING,READ,WRITE} blah;

class packet {
	public:
		packet();
		packet(packet_word *initial_array, unsigned int length);
		~packet();
		////////COMMANDS TO CREATE PACKETS//////////////////////
		//Create a skeleton command packet with no commands
		//The default arguments set command ID to 0 and the board_id to 0x0000
		//Reset the current packet
		void ClearPacket();
		//So the first command will have ID = 1 and be a broadcast command
		void CreateCommandPacket(packet_word base_command_id = 0, packet_word board_id = 0);
		//Add a command to the packet
		void AddPingToPacket();
		void AddReadToPacket(unsigned short int reg_id);
		void AddWriteToPacket(unsigned short int reg_id, 
		                      unsigned short int reg_data);
		//Return the total size or payload size
		int GetTotalSize();
		int GetPayloadSize();
		//Creates your packet on the heap and passes back
		//a pointer.  You are responsible for deleting it after you're
		//done with it.
		packet_word* AssemblePacket(int &total_size_in_words);
		/////////GENERIC COMMANDS/////////////////////////////
		void PrintPacket();
		bool CheckSumMatches();
		bool ContainsAPlausiblyValidStructure();
		void CheckPacket();
		bool CommandWasExecutedSuccessfully();
		/////////COMMANDS TO READ PACKETS////////////////////
		void ReadPacket(packet_word *data);
	private:
		bool NakedPacket; // whether we are building a packet (=false) or parsing a packet (=true)
		std::vector<packet_word> payload_data;
		packet_word command_id;
		bool packet_type_is_acknowledge;
};

#endif

