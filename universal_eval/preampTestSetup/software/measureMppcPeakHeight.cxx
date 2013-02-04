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

void measurePeakPosition(TCanvas *c);

//define histograms
TH1F *hMppcPulseHeight;
TH1F *hSampleMppcPulse[numChan];

//usage: root -l plotTreeWaveform.cxx++
void measureMppcPeakHeight(){
  	//gROOT->Reset();  
	//gROOT->ProcessLine(".x t2kPlot.cxx");

  	//int argc = 0;
  	//char* argv[argc];
  	//TApplication *gMyRootApp = new TApplication("My ROOT Application", &argc, argv);

	//define canvas
	TCanvas *c0 = new TCanvas("C0","",0,0,800,600);
	//TCanvas *c1 = new TCanvas("C1","",0,0,800,600);

	//define input file and parsing
	TFile *g;
	g = new TFile("analyzeMppcBoardTreeWaveform64Samples_output.root","READ"); //test mode
	if (g->IsZombie()) {
		std::cout << "Error opening input file" << std::endl;
		exit(-1);
	}	

	//initialize histograms
	//input histograms
	//get pedestal histograms from file
	for( int i = 0 ; i < numChan ; i++ ){
		char name[100];
		memset(&name[0],0,sizeof(name) );
		sprintf(name,"hSampleMppcPulse_Ch%.2i",i);
		hSampleMppcPulse[i] = (TH1F*)g->Get(name);
		if( !hSampleMppcPulse[i] ){
			std::cout << "Error opening pedestal histogram" << std::endl;
			exit(-1);
		}
	}

	//output histograms
	hMppcPulseHeight = new TH1F("hMppcPulseHeight","",numChan,0,numChan);

	//at this point have pulse height histogram for each channel, can measure gain, relative gain
	measurePeakPosition(c0);

	//create output file
	string outputFileName = "measureMppcPeakHeight_output.root";
	TFile *gout;
	gout = new TFile(outputFileName.c_str(),"RECREATE");
	if (gout->IsZombie()) {
		std::cout << "Error creating output file" << std::endl;
		exit(-1);
	}

	//c0->Clear();
	//c0->Divide(4,4);
	//for(int i = 0 ; i < numChan ; i++){
	//	c0->cd(i+1);
	//	hSampleMppcPulse[i]->Draw();
	//}
	//gPad->Modified();
	//c0->Update();

	std::cout << " outputFileName " <<  outputFileName << std::endl;
	gout->cd();
	for(int i = 0 ; i < numChan ; i++)
		hSampleMppcPulse[i]->Write();
	hMppcPulseHeight->Write();
	gout->Close();

	gApplication->Terminate();
	return;
}

void measurePeakPosition(TCanvas *c){
	for(int i = 0 ; i < numChan ; i++){
		//set initial value of gain measurment to 0
		hMppcPulseHeight->SetBinContent(i+1, 0);

		//ignore pulse spectra with too few entries
		if( hSampleMppcPulse[i]->GetEntries() < 100 )
			continue;

		//for the purpose of finding pulse peaks, rebin pulse histogram
		TH1F *h = (TH1F*)hSampleMppcPulse[i]->Clone("h");
		h->Rebin();
		//TH1F *h = hSampleMppcPulse[i]->Rebin(2,"h");

		//simple local detection to find peaks in 
		TSpectrum *s = new TSpectrum(20);
		Int_t nfound = s->Search(h,1,"",0.1); //0.1 is default parameter
		if( nfound < 0 || nfound > 20 )
			std::cout << "Unexpected behaviour from TSpectrum search" << std::endl;
		
		//loop through recovered peaks, try to fit a Gaussian, find valid fitted peak closest to 0
		double maxPosition = -1.E+6;
		for(int j = 0 ; j < s->GetNPeaks() ; j++){
			//std::cout << "\t" << s->GetPositionX()[j] << std::endl;
			// Fit histogram w Gaussian, restrict range to only 10 ADC counts around TSpectrum peak
			TF1 *gfit = new TF1("Gaussian","gaus",s->GetPositionX()[j] - 10, s->GetPositionX()[j] + 10);
			gfit->SetLineColor(kBlue);
			h->Fit("Gaussian","QR"); 
			//require fitted peak to be larger than some threshold
			if(gfit->GetParameter(0) > 10 )
				if( gfit->GetParameter(1) > maxPosition )
					maxPosition = gfit->GetParameter(1);
			delete gfit;
		}
		
		std::cout << "maxPosition " << maxPosition << std::endl;
		hMppcPulseHeight->SetBinContent(i+1, -1.*maxPosition);

		if(0){
			c->Clear();
			hSampleMppcPulse[i]->GetXaxis()->SetRangeUser(-200,100);
			hSampleMppcPulse[i]->Draw();
			gPad->Modified();
			c->Update();

			std::cout << " Enter character " << std::endl;
			char ct;
			std::cin >> ct;
		}

		delete h;
		delete s;
	}
	return;
}
