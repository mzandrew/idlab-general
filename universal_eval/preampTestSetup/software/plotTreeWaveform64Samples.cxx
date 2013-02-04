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

TH2F *samplePedestals[numChan];

void plotSampleGroup(TCanvas *c, sampleGroup_t sampleGroup);
void plotSampleGroups(TCanvas *c, sampleGroup_t sampleGroup[]);

bool havePedestals = 0;

//usage: root -l plotTreeWaveform.cxx++
void plotTreeWaveform64Samples(){
  	//gROOT->Reset();  
	//gROOT->ProcessLine(".x t2kPlot.cxx");

  	//int argc = 0;
  	//char* argv[argc];
  	//TApplication *gMyRootApp = new TApplication("My ROOT Application", &argc, argv);

	//define canvas
	//TCanvas *c0 = new TCanvas("C0","",0,0,400,300);
	TCanvas *c0 = new TCanvas("C0","",0,0,800,600);

	
	//get pedestal values
	TFile *g;
	g = new TFile("preampData64Samples_pedestalHists.root","READ"); //test mode
	if (g->IsZombie()) {
		std::cout << "Error opening pedestal file" << std::endl;
		//exit(-1);
		havePedestals = 0;
	}
	else
		havePedestals = 1;	

	//get pedestal histograms from file
	if(havePedestals)
	for( int i = 0 ; i < numChan ; i++ ){
		char name[100];
		memset(&name[0],0,sizeof(name) );
		sprintf(name,"samplePedestals_Ch%.2i",i);
		samplePedestals[i] = (TH2F*)g->Get(name);
		if( !samplePedestals[i] ){
			std::cout << "Error opening pedestal histogram" << std::endl;
			exit(-1);
		}
	}

	//load tree and assign variables
	TFile f("parsePreampData64Samples_output.root");
        TTree *tree = (TTree*)f.Get("tree");

	//define tree variables
   	sampleGroup_t sampleGroups[numCellGroup];
	for(int i = 0 ; i < numCellGroup ; i++){
		char name[100];
		memset(&name[0],0,sizeof(name) );
		sprintf(name,"sampleGroup0%.2i",i);
		//tree->SetBranchAddress(name, &sampleGroups[i]);

		TBranch *branch = tree->GetBranch(name);
  		branch->SetAddress(&sampleGroups[i]);

	}

	//loop through tree, plot each waveform in graph
	for (int i = 0; i < tree->GetEntries(); i++){
		std::cout << "event " << i << std::endl;
		if(i < 10 ) continue;

		tree->GetEvent(i);

		//if(sampleGroups[0].channel != 0)
		//	continue;

		std::cout << "Channel # " << sampleGroups[0].channel << std::endl;		
		plotSampleGroups(c0, sampleGroups);
   	}

	return;
}

void plotSampleGroup(TCanvas *c, sampleGroup_t sampleGroup){
	c->Clear();

	const int maxNum = numSamp; //32 samples in each conversion
  	double num[maxNum];
  	double numErr[maxNum];
  	double theVal[maxNum]; 
  	double theValErr[maxNum];
  	memset(&num[0],0,sizeof(num) );
  	memset(&numErr[0],0,sizeof(numErr) );
  	memset(&theVal[0],0,sizeof(theVal) );
  	memset(&theValErr[0],0,sizeof(theValErr) );

	for(int i = 0 ; i < numSamp ; i++){
		num[i] = i;
		theVal[i] = sampleGroup.samples[i];
		//get pedestal value
		///double ped = samplePedestals[chan]->GetBinContent(cell+1, j+1);
		//theVal[j] = double( samples[j] - ped );
	}

 	TGraphErrors *gr = new TGraphErrors(numSamp,num,theVal,numErr,theValErr); 
 	gr->SetName("Efficiency");
 	gr->SetMarkerColor(4);
 	gr->SetMarkerStyle(21);
 	gr->SetMarkerSize(1);
 
 	TMultiGraph *mg = new TMultiGraph();
 	mg->Add(gr);
 	mg->Draw("ALP");
	mg->SetTitle("Digitized Samples");
	mg->GetXaxis()->SetTitle("Sample Number");
	mg->GetXaxis()->CenterTitle();
	mg->GetYaxis()->SetTitle("Value (ADC)");
	mg->GetYaxis()->SetRangeUser(0,4100);
	mg->GetYaxis()->CenterTitle();

	gPad->Modified();
	c->Update();

	std::cout << "Enter character" << std::endl;
	char ct;
	std::cin >> ct;

	gr->Delete();
	mg->Delete();

	return;
}

void plotSampleGroups(TCanvas *c, sampleGroup_t sampleGroup[]){
	c->Clear();

	const int maxNum = numSamp*numCellGroup; //32 samples in each conversion
  	double num[maxNum];
  	double numErr[maxNum];
  	double theVal[maxNum]; 
  	double theValErr[maxNum];
  	memset(&num[0],0,sizeof(num) );
  	memset(&numErr[0],0,sizeof(numErr) );
  	memset(&theVal[0],0,sizeof(theVal) );
  	memset(&theValErr[0],0,sizeof(theValErr) );

	for(int i = 0 ; i < numCellGroup ; i++){
		for(int j = 0 ; j < numSamp ; j++){
			int ind = numSamp*i+j;
			int channel = sampleGroup[i].channel;
			int cell = sampleGroup[i].cellGroup;
			int sample = sampleGroup[i].samples[j];
			//get pedestal value from histogram global variable
			double ped = 0.;
			if( havePedestals )
				ped = samplePedestals[channel]->GetBinContent(cell+1, j+1);

			num[ind] = ind;
			theVal[ind] = double( sample);
			theVal[ind] = double( sample - ped );
			if(0){
				std::cout << "int " << ind;
				std::cout << "\t sample " << sampleGroup[i].samples[j];
				std::cout << "\t ped " << ped;
				std::cout << " corr " << theVal[j];
		 		std::cout << std::endl;
			}
		}
	}

 	TGraphErrors *gr = new TGraphErrors(maxNum,num,theVal,numErr,theValErr); 
 	gr->SetName("Efficiency");
 	gr->SetMarkerColor(4);
 	gr->SetMarkerStyle(21);
 	gr->SetMarkerSize(1);
 
 	TMultiGraph *mg = new TMultiGraph();
 	mg->Add(gr);
 	mg->Draw("ALP");
	mg->SetTitle("Digitized Samples");
	mg->GetXaxis()->SetTitle("Sample Number");
	mg->GetXaxis()->CenterTitle();
	mg->GetYaxis()->SetTitle("Value (ADC)");
	//mg->GetYaxis()->SetRangeUser(-100,100);
	mg->GetYaxis()->CenterTitle();

	gPad->Modified();
	c->Update();

	std::cout << "Enter character" << std::endl;
	char ct;
	std::cin >> ct;

	gr->Delete();
	mg->Delete();

	return;
}
