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
TH1F *hMppcPulseHeight;
TH1F *hPreampGain;

//usage: root -l plotTreeWaveform.cxx++
void measurePreampGain(){
  	//gROOT->Reset();  
	gROOT->ProcessLine(".x t2kPlot.cxx");

  	//int argc = 0;
  	//char* argv[argc];
  	//TApplication *gMyRootApp = new TApplication("My ROOT Application", &argc, argv);

	//define canvas
	TCanvas *c0 = new TCanvas("C0","",0,0,800,600);
	TCanvas *c1 = new TCanvas("C1","",500,0,1200,800);

	//define input file and parsing
	TFile *g;
	g = new TFile("measureMppcPeakHeight_output.root","READ"); //test mode
	if (g->IsZombie()) {
		std::cout << "Error opening input file" << std::endl;
		exit(-1);
	}	

	//define input file 2
	TFile *g1;
	g1 = new TFile("analyzeMppcBoardTreeWaveform64Samples_output.root","READ"); //test mode
	if (g1->IsZombie()) {
		std::cout << "Error opening input file" << std::endl;
		exit(-1);
	}	

	//get input channel pulse height histogram
	char hname[100];
	memset(&hname[0],0,sizeof(hname) );
	sprintf(hname,"hMppcPulseHeight");
	hMppcPulseHeight = (TH1F*)g->Get(hname);
	if( !hMppcPulseHeight ){
		std::cout << "Error opening input histogram" << std::endl;
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

	//define output histogram
	hPreampGain = new TH1F("hPreampGain","",numChan,0,numChan);

	//define MPPC relative gain correction constants
	double mppcGainConstant = 1.;
	double mppcRelativeGain = 1.; //should have one value per channel
	for( int i = 0 ; i < numChan ; i++ ){
		double gain = hMppcPulseHeight->GetBinContent(i+1);
		if( mppcRelativeGain > 0 && mppcGainConstant > 0 )
			gain = gain / mppcGainConstant / mppcRelativeGain;
		hPreampGain->SetBinContent(i+1, gain);
	}

	std::cout << std::endl << "PREAMP GAIN BY CHANNEL" << std::endl;
	for(int i = 0 ; i < numChan ; i++){
		std::cout << "\tChannel\t" << i << "\tGain\t" << hPreampGain->GetBinContent(i+1) << std::endl;
	}

	TH1F *hTempMax = new TH1F("hTempMax","",numChan,0,numChan);
	TH1F *hTempMin = new TH1F("hTempMin","",numChan,0,numChan);
	for(int i = 0 ; i < numChan ; i++){
		hTempMax->SetBinContent(i+1,100.); //max acceptable gain
		hTempMin->SetBinContent(i+1,40.); //min acceptable gain
	}
	hTempMax->SetLineColor(kRed);
	hTempMin->SetLineColor(kRed);

	c0->Clear();
	//hMppcPulseHeight->Draw();
	hPreampGain->GetYaxis()->SetRangeUser(0.,150.);
	hPreampGain->Draw();
	hTempMax->Draw("same");
	hTempMin->Draw("same");
	gPad->Modified();
	c0->Update();

	c1->Clear();
	c1->Divide(4,4);
	for(int i = 0 ; i < numChan ; i++){
		c1->cd(i+1);
		hSampleMppcPulse[i]->Draw();
	}
	gPad->Modified();
	c1->Update();

	//create output file
	string outputFileName = "measurePreampGain_output.root";
	TFile *gout;
	gout = new TFile(outputFileName.c_str(),"RECREATE");
	if (gout->IsZombie()) {
		std::cout << "Error creating output file" << std::endl;
		exit(-1);
	}

	std::cout << " outputFileName " <<  outputFileName << std::endl;
	gout->cd();
	hPreampGain->Write();
	gout->Close();

	//gApplication->Terminate();
	return;
}
