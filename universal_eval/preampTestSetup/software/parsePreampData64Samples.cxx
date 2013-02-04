#include <iostream>
#include <fstream>
#include <sstream>
#include <cstdlib>
#include <math.h>
#include <TH1F.h> 
#include <TH2F.h> 
#include <TF1.h>
#include <TFile.h>
#include <TMath.h> 
#include <TProfile.h>
#include <TGraph.h>
#include <TMultiGraph.h>
#include <TGraphErrors.h>
#include <TGraphAsymmErrors.h>
#include <THStack.h>
#include "TLorentzVector.h"
#include "TVector3.h"
#include "TTree.h"
#include "TChain.h"
#include "TClonesArray.h"
#include "TCanvas.h"
#include "THStack.h"
#include "TLegend.h"
#include "TStyle.h"
#include "TColor.h"
#include "TSystem.h"
#include "TROOT.h"
#include "TApplication.h"
using namespace std;

//global constants and data structures
const int numChan = 15; //there are 16 channels, but #16 is unused for now
const int numCellGroup = 2; //should be 512 cell groups, preamp test setup only uses the first 2
const int numSamp = 32; //number of samples in each cell group obtained in each digitization process
const int adcMax = 4095; //max value 12-bit ADC samaples can attain

struct sampleGroup_t{
	Int_t channel;
	Int_t cellGroup;
	Int_t samples[numSamp];
};

void storeEvent(TTree *tree, sampleGroup_t sampleGroups[]);
void startNewEvent(sampleGroup_t sampleGroups[]);
void addSampleToWaveform(string token, sampleGroup_t sampleGroups[]);

void parsePreampData64Samples(){
  	//gROOT->Reset();  
	//gROOT->SetStyle(“Plain”);

  	//const int argc = 1;
  	//char* argv[argc];

	//define input file and parsing
	ifstream infile;
	string inputFileName = "testOutput64Samples.dat";

	std::cout << " inputFileName " << inputFileName << std::endl;
	infile.open(inputFileName.c_str(), ifstream::in);
	if (infile.fail()) {
		std::cout << "Error opening input file, exiting" << std::endl;
		exit(-1);
	}

	//define tree variables
   	sampleGroup_t sampleGroups[numCellGroup];

	//initialize sample group objects
	for(int i = 0 ; i < numCellGroup ; i++){
		sampleGroups[i].channel = -1;
		sampleGroups[i].cellGroup = i;
		memset(&sampleGroups[i].samples[0],-1,sizeof(sampleGroups[i].samples) );
	}

	//define tree to store valid waveform data
	TTree *tree = new TTree("T","Waveform Tree");
	for(int i = 0 ; i < numCellGroup ; i++){
		char name[100];
		memset(&name[0],0,sizeof(name) );
		sprintf(name,"sampleGroup0%.2i",i);
		tree->Branch(name, &sampleGroups[i], "channel:cellGroup:samples[32]/I");
	}

	//process input file line by line
	string temp = "";
	while (!infile.eof())
	{
		//get line from file
		if( !getline(infile, temp) )
			continue;
	
		//parse each line using stingstream
		std::istringstream iss(temp);
		string token;
		iss >> token;

		//std::cout << token << std::endl;
		//first element in line determine data packet position
		//using if statements because C++ is dumb about case
		if( token.substr(0,1) == "N" ){
			//store previous event if any
			storeEvent(tree, sampleGroups);
			//reset waveform variables
			startNewEvent(sampleGroups);
		}
		else{
			addSampleToWaveform(token, sampleGroups);
		}
	}

	//define output file name
	std::string outputFileName = "parsePreampData64Samples_output.root";
	std::cout << " outputFileName " << outputFileName << std::endl;

	TFile g( outputFileName.c_str() , "RECREATE");
	tree->Write("tree");
	g.Close();
	
	gApplication->Terminate();
	return;
}

void startNewEvent(sampleGroup_t sampleGroups[]){
	//reset sample group objects
	for(int i = 0 ; i < numCellGroup ; i++){
		sampleGroups[i].channel = -1;
		sampleGroups[i].cellGroup = i;
		memset(&sampleGroups[i].samples[0],-1,sizeof(sampleGroups[i].samples) );
	}
	return;
}

void storeEvent(TTree *tree, sampleGroup_t sampleGroups[]){
	//determine if valid event exists
	for(int i = 0 ; i < numCellGroup ; i++){
		if( sampleGroups[i].channel < 0 || sampleGroups[i].channel > numChan ){
			//std::cout << "Invalid channel" <<  sampleGroups[i].channel << "\t event not saved"<< std::endl;
			return;
		}
		if( sampleGroups[i].cellGroup < 0 || sampleGroups[i].cellGroup > numCellGroup ){
			//std::cout << "Invalid cell group, event not saved" << std::endl;
			return;
		}
		for( int j = 0 ; j < numSamp ; j++ )
			if( sampleGroups[i].samples[j] < -1 || sampleGroups[i].samples[j] > adcMax){
				//std::cout << "Invalid sample value, event not saved" << std::endl;
				return;
			}
	}

	//valid event here, make tree entry
	tree->Fill();
	return;
}

void addSampleToWaveform(string token, sampleGroup_t sampleGroups[]){
	//make sure token is right size
	if( token.size() != 8 ){
		//std::cerr << "Invalid token size " << token << std::endl;
		return;
	}

	//get token ID
	int tokenId;
	std::stringstream sstoken;
	sstoken << std::hex << token.substr(0,1).c_str();
	sstoken >> tokenId;
	tokenId = tokenId & 0xC;
	tokenId = tokenId >> 2;
	tokenId = tokenId & 0x3;

	//check token identifier
	if( tokenId != 0x2 ){ //token ID for sample lines in data file
		//std::cerr << "Invalid token type " << token << std::endl;
		return;
	}

	//get channel #
	unsigned int chan;
	std::stringstream sschan;
	sschan << std::hex << token.substr(0,2).c_str();
	sschan >> chan;
	chan = chan & 0x3C;
	chan = chan >> 2;
	chan = chan & 0xF;

	//check that channel is valid
	if( int(chan) >= numChan ){
		//std::cerr << "Invalid channel\t" << chan << "\t" << token << std::endl;
		return;
	}

	//get cell #
	unsigned int cell;
	std::stringstream sscell;
	sscell << std::hex << token.substr(1,3).c_str();
	sscell >> cell;
	cell = cell & 0x3FE;
	cell = cell >> 1;
	cell = cell & 0x1FF;

	//check that cell is if
	if( int(cell) >= numCellGroup ){
		//std::cerr << "Invalid cell group #\t" << cell << "\t" << token << std::endl;
		return;
	}

	//get sample #
	unsigned int samp;
	std::stringstream sssamp;
	sssamp << std::hex << token.substr(2,4).c_str();
	sssamp >> samp;
	samp = samp & 0x01F0;
	samp = samp >> 4;
	samp = samp & 0x1F;

	//check that sample # is valid
	if( int(samp) >= numSamp ){
		//std::cerr << "Invalid sample # "  << token << std::endl;
		return;
	}

	//get sample value
	unsigned int value;
	std::stringstream ssvalue;
	ssvalue << std::hex << token.substr(5,3).c_str();
	ssvalue >> value;
	value = value & 0xFFF;

	//check that sample value is valid
	if( int(value) >= adcMax ){
		//std::cerr << "Invalid sample value " << token << std::endl;
		return;
	}

	//enter valid sample value into tree variables
	sampleGroups[cell].channel = int(chan);
	//sampleGroups[cell].cellGroup = cell;
	sampleGroups[cell].samples[samp] = int(value);

	return;
}
