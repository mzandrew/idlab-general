#include <stdio.h>
#include <time.h>
#include <unistd.h>
#include <iostream>
#include <stdlib.h> 
#include "target6ControlClass.h"

using namespace std;

int main(int argc, char* argv[]){
	if (argc != 3){
    		std::cout << "wrong number of arguments: usage ./target6Control_writeReg <reg num> <reg val>" << std::endl;
    		return 0;
  	}

  	int regNum = atoi(argv[1]);
	int regVal = atoi(argv[2]);

	if( regNum < 0 || regNum > 1024 ){
		std::cout << "Invalid register number, exiting" << std::endl;
		return 0;
	}
	if( regVal < 0 || regVal > 0xFFFF ){
		std::cout << "Invalid register value, exiting" << std::endl;
		return 0;
	}

	//create target6 interface object
	target6ControlClass *control = new target6ControlClass();

	//initialize USB interface - Mandatory
	control->initializeUSBInterface();

	//define the SCROD ID for board stack, hardcoded for now
	unsigned int board_id = 0;

	//write the register
	int regValReadback;
	if( !control->registerWriteReadback(board_id, regNum, regVal, regValReadback) )
		std::cout << "Register write failed" << std::endl;
	
	std::cout << "Register " << regNum << "\t=\t" << regValReadback << "\thex " << std::hex << regValReadback << std::dec << std::endl;
	std::cout << std::endl;

	//close USB interface
        control->closeUSBInterface();

	//delete target6 interface object
	delete control;

	return 1;
}
