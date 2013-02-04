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
#include "TSpectrum.h"
using namespace std;

//global constants and data structures
const int numChan = 15; //there are 16 channels, but #16 is unused for now
const int numCellGroup = 2; //should be 512 cell groups, preamp test setup only uses the first 2
const int numSamp = 32; //number of samples in each cell group obtained in each digitization process
const int adcMax = 4095; //max value 12-bit ADC samaples can attain

//define histograms
TH1F *hSampleMppcPulse[numChan];

//usage: root -l plotTreeWaveform.cxx++
void plotChargeSpectra(){
	//define canvas
	TCanvas *c1 = new TCanvas("C1","",500,0,1000,750);

	//define input file and parsing
	TFile *g1;
	g1 = new TFile("analyzeMppcBoardTreeWaveform64Samples_output.root","READ"); //test mode
	if (g1->IsZombie()) {
		std::cout << "Error opening input file" << std::endl;
		exit(-1);
	}	

	//get charge spectrum for each channel
	for( int i = 0 ; i < numChan ; i++ ){
		char name[100];
		memset(&name[0],0,sizeof(name) );
		sprintf(name,"hSampleMppcPulse_Ch%.2i",i);
		hSampleMppcPulse[i] = (TH1F*)g1->Get(name);
		if( !hSampleMppcPulse[i] ){
			std::cout << "Error opening pedestal histogram" << std::endl;
			exit(-1);
		}
	}

	c1->Clear();
	c1->Divide(4,4);
	for(int i = 0 ; i < numChan ; i++){
		c1->cd(i+1);
		hSampleMppcPulse[i]->Draw();
	}
	gPad->Modified();
	c1->Update();

	return;
}
