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
TH1F *hMppcPulseHeight;

//usage: root -l plotTreeWaveform.cxx++
void measureBreakdownVoltage(){
  	//gROOT->Reset();  
	gROOT->ProcessLine(".x t2kPlot.cxx");

	//define canvas
	TCanvas *c0 = new TCanvas("C0","",0,0,1000,725);
	//TCanvas *c1 = new TCanvas("C1","",0,0,800,600);

	//define input filelist
	ifstream infile;
	string infileName = "filelist_measureBreakdownVoltage.txt";

	//open infile for getting mppc data files
	infile.open(infileName.c_str(), ifstream::in);
	if (infile.fail()) {
		std::cout << "Error opening input filelist, exiting" << std::endl;
		exit(-1);
	}

	//define graph objects for storing measurements
	int grCount[numChan];
	memset(&grCount[0],0,sizeof(grCount) );
	TGraphErrors *gr[numChan];
	for(int i = 0 ; i < numChan ; i++){
		gr[i] = new TGraphErrors();
		gr[i]->SetMarkerStyle(21);
		gr[i]->SetMarkerSize(1);
	}

	//process input filelist line by line
	string temp = "";
	while (!infile.eof())
	{
		//get line from file
		if( !getline(infile, temp) )
			continue;

		std::cout << " input file " << temp << std::endl;

		//get histogram file
		TFile *f;
		f = new TFile(temp.c_str());
		if (f->IsZombie()) {
			std::cout << "Error opening tree file" << std::endl;
			exit(-1);
		}

		//get histogram from file
		char name[100];
		memset(&name[0],0,sizeof(name) );
		//sprintf(name,"hSampleMppcPulse_Ch%.2i",7);
		sprintf(name,"hMppcPulseHeight");
		TH1F *h = (TH1F*)f->Get(name);
		if (!h) {
			std::cout << "Error getting tree" << std::endl;
			exit(-1);
		}

		//try to determine DAC setting from input file paths
		size_t found;
  		found=temp.find("data_mppcBias_");
		if (found==string::npos){
			std::cout << "DAC value not found " << std::endl;
			continue;
		}
		string dacValueString = temp.substr(14,2);
		int dacValue = -1;
		dacValue = atoi(dacValueString.c_str());
		if( dacValue < 0 || dacValue > 255){
			std::cout << "Invalud DAC valid found " << std::endl;
			continue;
		}

		//enter points intro graph
		for(int i = 0 ; i < numChan ; i++){
			if( h->GetBinContent(i+1) > 20 ){
				gr[i]->SetPoint(grCount[i],dacValue, h->GetBinContent(i+1) );
				gr[i]->SetPointError(grCount[i],0, 0 );
				grCount[i]++;
			}
		}

		if(0){
			c0->Clear();
			h->Draw();
			gPad->Modified();
			c0->Update();

			std::cout << " Enter character " << std::endl;
			char ct;
			std::cin >> ct;
		}

		f->Close();
	}

	c0->Clear();
	c0->Divide(4,4);
	for(int i = 0 ; i < numChan ; i++){
		c0->cd(i+1);
		if(grCount[i]<2){
			std::cout << "Channel " << i << " breakdown voltage not found" << std::endl;
			continue;
		}
		TF1 *gfit = new TF1("Linear","[0]+[1]*x",32.5, 67.5);
		gr[i]->Fit("Linear","QR"); 
		gr[i]->Draw("AP");

		if(gfit->GetParameter(0) <= 0 || gfit->GetParameter(1) >= 0)
			std::cout << "Channel " << i << " breakdown voltage not found" << std::endl;
		else{
			double breakdownDac = -1.*gfit->GetParameter(0)/gfit->GetParameter(1);
			std::cout << "Channel " << i;
			std::cout << " breakdown voltage DAC " << breakdownDac;
			std::cout << " set DAC value " << (75.0 - gfit->GetParameter(0) )/gfit->GetParameter(1);
			std::cout << std::endl;

		}
		delete gfit;
	}
	gPad->Modified();
	c0->Update();
	std::cout << " Enter character " << std::endl;
	//char ct;
	//std::cin >> ct;

	//create output file
	string outputFileName = "measureBreakdownVoltage_output.root";
	TFile *gout;
	gout = new TFile(outputFileName.c_str(),"RECREATE");
	if (gout->IsZombie()) {
		std::cout << "Error creating output file" << std::endl;
		exit(-1);
	}

	std::cout << " outputFileName " <<  outputFileName << std::endl;
	gout->cd();
	gout->Close();

	//gApplication->Terminate();
	return;
}
