#include <stdio.h>
#include <time.h>
#include <unistd.h>
#include <iostream>
#include <stdlib.h>
#include "target6ControlClass.h"

using namespace std;

int main(int argc, char* argv[]){
	if (argc != 2){
    		std::cout << "wrong number of arguments: usage ./target6Control_readReg <reg num>" << std::endl;
    		return 0;
  	}

	//make sure register value is OK
  	int regNum = atoi(argv[1]);
	if( regNum < 0 || regNum > 1024 ){
		std::cout << "Invalid register number, exiting" << std::endl;
		return 0;
	}

	//create target6 interface object
	target6ControlClass *control = new target6ControlClass();

	//initialize USB interface - Mandatory
	control->initializeUSBInterface();

	//define the SCROD ID for board stack, hardcoded for now
	unsigned int board_id = 0;

	//read the register
	int regValReadback;
	if( !control->registerRead(board_id, regNum, regValReadback) )
		std::cout << "Register read failed, exiting" << std::endl;
	
	std::cout << "Register " << regNum << "\t=\t" << regValReadback << "\thex " << std::hex << regValReadback << std::dec << std::endl;
	std::cout << std::endl;

	//close USB interface
        control->closeUSBInterface();

	//delete target6 interface object
	delete control;

	return 1;
}
