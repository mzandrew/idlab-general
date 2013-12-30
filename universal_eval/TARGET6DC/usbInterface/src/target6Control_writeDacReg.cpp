#include <stdio.h>
#include <time.h>
#include <unistd.h>
#include <iostream>
#include <stdlib.h> 
#include "target6ControlClass.h"

using namespace std;

int main(int argc, char* argv[]){
	if (argc != 3){
    		std::cout << "wrong number of arguments: usage ./target6Control_test" << std::endl;
    		return 0;
  	}

	int regNum = atoi(argv[1]);
	int regVal = atoi(argv[2]);
	int regValReadback;

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

	//write a register
	//if( !control->registerWriteReadback(board_id, 0, 1023, regValReadback) )
	//	std::cout << "Register write failed" << std::endl;
	//std::cout << "ASIC register: " << regNum;
	//std::cout << "ASIC register value: " << regVal;
	//std::cout << std::endl;

	//begin ASIC DAC programming through software, uses regNum and regVal
	//function assumes SIN register = 5, sclkReg = 6, pclk reg = 7, use bit 0 in each case (must agree with firmware)

	//int progReg = 46;
	//int progRegVal = 4000;
	int progReg = regNum;
	int progRegVal = regVal;
	int progVal = ( progReg << 12 ) + progRegVal;
	int size_progVal = 6+12;

	int sinReg = 5;
	int sclkReg = 6;
	int pclkReg = 7;
	int sinRegVal = 0;
	int sclkRegVal = 0;
	int pclkRegVal = 0;

	int sleepTime = 10;

	std::cout << "Start DAC Program Process - Writing Register " << progReg << "\tValue " << progVal << std::endl;

	sinRegVal = 0; sclkRegVal = 0; pclkRegVal = 0;
	control->registerWriteReadback(board_id, sinReg, sinRegVal, regValReadback);
	control->registerWriteReadback(board_id, sclkReg, sclkRegVal, regValReadback);
	control->registerWriteReadback(board_id, pclkReg, pclkRegVal, regValReadback);

	for(int i = 0 ; i < size_progVal ; i++ ){
		//std::cout << ( (progVal >> size_progVal - i - 1) & 0x1) << std::endl;

		sinRegVal = ( (progVal >> size_progVal - i - 1) & 0x1);
		pclkRegVal = 0;

		sclkRegVal = 0; 
		control->registerWriteReadback(board_id, sinReg, sinRegVal, regValReadback);
		control->registerWriteReadback(board_id, sclkReg, sclkRegVal, regValReadback);
		control->registerWriteReadback(board_id, pclkReg, pclkRegVal, regValReadback);
		usleep(sleepTime);

		sclkRegVal = 1;
		//control->registerWriteReadback(board_id, sinReg, sinRegVal, regValReadback);
		control->registerWriteReadback(board_id, sclkReg, sclkRegVal, regValReadback);
		//control->registerWriteReadback(board_id, pclkReg, pclkRegVal, regValReadback);
		usleep(sleepTime);

		sclkRegVal = 0;
		//control->registerWriteReadback(board_id, sinReg, sinRegVal, regValReadback);
		control->registerWriteReadback(board_id, sclkReg, sclkRegVal, regValReadback);
		//control->registerWriteReadback(board_id, pclkReg, pclkRegVal, regValReadback);
		usleep(sleepTime);

		//control->registerRead(board_id, 64, regValReadback);
		//std::cout << "\tSHOUT " << regValReadback << std::endl;
	}

	//set DAC signals to 0
	sinRegVal = 0; sclkRegVal = 0; pclkRegVal = 0;
	control->registerWriteReadback(board_id, sinReg, sinRegVal, regValReadback);
	control->registerWriteReadback(board_id, sclkReg, sclkRegVal, regValReadback);
	control->registerWriteReadback(board_id, pclkReg, pclkRegVal, regValReadback);
	usleep(sleepTime);

	//set PCLK to 1 then 0 , latch Data bus
	sinRegVal = 0; sclkRegVal = 0; pclkRegVal = 1;
	//control->registerWriteReadback(board_id, sinReg, sinRegVal, regValReadback);
	//control->registerWriteReadback(board_id, sclkReg, sclkRegVal, regValReadback);
	control->registerWriteReadback(board_id, pclkReg, pclkRegVal, regValReadback);
	usleep(sleepTime);

	sinRegVal = 0; sclkRegVal = 0; pclkRegVal = 0;
	//control->registerWriteReadback(board_id, sinReg, sinRegVal, regValReadback);
	//control->registerWriteReadback(board_id, sclkReg, sclkRegVal, regValReadback);
	control->registerWriteReadback(board_id, pclkReg, pclkRegVal, regValReadback);
	usleep(sleepTime);

	//set SIN to 1
	sinRegVal = 1; sclkRegVal = 0; pclkRegVal = 0;
	control->registerWriteReadback(board_id, sinReg, sinRegVal, regValReadback);
	//control->registerWriteReadback(board_id, sclkReg, sclkRegVal, regValReadback);
	//control->registerWriteReadback(board_id, pclkReg, pclkRegVal, regValReadback);
	usleep(sleepTime);
	
	//set PCLK to 1 then 0 , latch Data bus
	sinRegVal = 1; sclkRegVal = 0; pclkRegVal = 1;
	//control->registerWriteReadback(board_id, sinReg, sinRegVal, regValReadback);
	//control->registerWriteReadback(board_id, sclkReg, sclkRegVal, regValReadback);
	control->registerWriteReadback(board_id, pclkReg, pclkRegVal, regValReadback);
	usleep(sleepTime);

	sinRegVal = 1; sclkRegVal = 0; pclkRegVal = 0;
	//control->registerWriteReadback(board_id, sinReg, sinRegVal, regValReadback);
	//control->registerWriteReadback(board_id, sclkReg, sclkRegVal, regValReadback);
	control->registerWriteReadback(board_id, pclkReg, pclkRegVal, regValReadback);
	usleep(sleepTime);

	sinRegVal = 0; sclkRegVal = 0; pclkRegVal = 0;
	control->registerWriteReadback(board_id, sinReg, sinRegVal, regValReadback);
	//control->registerWriteReadback(board_id, sclkReg, sclkRegVal, regValReadback);
	//control->registerWriteReadback(board_id, pclkReg, pclkRegVal, regValReadback);
	usleep(sleepTime);

	//close USB interface
        control->closeUSBInterface();

	//delete target6 interface object
	delete control;

	return 1;
}
