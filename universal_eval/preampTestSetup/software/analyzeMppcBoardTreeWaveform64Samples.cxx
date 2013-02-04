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

struct sampleGroup_t{
	Int_t channel;
	Int_t cellGroup;
	Int_t samples[numSamp];
};

TH2F *samplePedestals[numChan];

void plotSampleGroup(TCanvas *c, sampleGroup_t sampleGroup);
void plotSampleGroups(TCanvas *c, sampleGroup_t sampleGroup[]);
void initializeHistograms();
void analyzeSampleGroups(TCanvas *c,sampleGroup_t sampleGroup[]);
Double_t myfunction(Double_t *x, Double_t *par);

//define histograms
TH1F *hSampleDiff[numChan];
TH1F *hSampleMinNum[numChan];
TH1F *hSampleMinVal[numChan];
TH1F *hSampleMppcPulse[numChan];
TH1F *hMppcPulseHeight;
//TH1F *hMppcPulseHeight3PAvg[numChan];

//usage: root -l plotTreeWaveform.cxx++
void analyzeMppcBoardTreeWaveform64Samples(){
  	//gROOT->Reset();  
	//gROOT->ProcessLine(".x t2kPlot.cxx");

  	//int argc = 0;
  	//char* argv[argc];
  	//TApplication *gMyRootApp = new TApplication("My ROOT Application", &argc, argv);

	//define canvas
	TCanvas *c0 = new TCanvas("C0","",0,0,800,600);
	//TCanvas *c1 = new TCanvas("C1","",0,0,800,600);

	//get pedestal values
	TFile *g;
	g = new TFile("preampData64Samples_pedestalHists.root","READ"); //test mode
	if (g->IsZombie()) {
		std::cout << "Error opening pedestal file" << std::endl;
		exit(-1);
	}

	//get pedestal histograms from file
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

	//initialize histograms
	initializeHistograms();

	//define input filelist
	ifstream infile;
	string infileName = "filelist_mppcDataParsedData64Samples.txt";

	//open infile for getting mppc data files
	infile.open(infileName.c_str(), ifstream::in);
	if (infile.fail()) {
		std::cout << "Error opening input filelist, exiting" << std::endl;
		exit(-1);
	}

	//process input filelist line by line
	string temp = "";
	while (!infile.eof())
	{
		//get line from file
		if( !getline(infile, temp) )
			continue;

		std::cout << " input file " << temp << std::endl;

		//load input tree file
		TFile *f;
		f = new TFile(temp.c_str());
		if (f->IsZombie()) {
			std::cout << "Error opening tree file" << std::endl;
			exit(-1);
		}

		//get tree from file
        	TTree *tree = (TTree*)f->Get("tree");
		if (!tree) {
			std::cout << "Error getting tree" << std::endl;
			exit(-1);
		}
		if( tree->GetEntries() <= 0 ) {
			std::cout << "Empty tree" << std::endl;
			exit(-1);
		}

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
			//if( i % 1000 == 0 ) std::cout << "event " << i << std::endl;
			if(i < 10 ) continue;
	
			tree->GetEvent(i);
			//if(sampleGroups[0].channel != 1)
			//	continue;

			//plotSampleGroups(c0, sampleGroups);
			analyzeSampleGroups(c0, sampleGroups);
   		}

		//close tree
		tree->Delete("");
		//close tree file
		f->Close();
	}

	//create output file
	string outputFileName = "analyzeMppcBoardTreeWaveform64Samples_output.root";
	TFile *gout;
	gout = new TFile(outputFileName.c_str(),"RECREATE");
	if (gout->IsZombie()) {
		std::cout << "Error creating output file" << std::endl;
		exit(-1);
	}

	std::cout << " outputFileName " <<  outputFileName << std::endl;
	gout->cd();
	hMppcPulseHeight->Write();
	for(int i = 0 ; i < numChan ; i++){
		hSampleDiff[i]->Write();
		hSampleMinNum[i]->Write();
		hSampleMinVal[i]->Write();
		hSampleMppcPulse[i]->Write();
	}
	gout->Close();

	gApplication->Terminate();
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
			double ped = samplePedestals[channel]->GetBinContent(cell+1, j+1);

			num[ind] = ind;
			//theVal[ind] = double( sample);
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
	//mg->GetYaxis()->SetRangeUser(-1000,200);
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

void initializeHistograms(){

	//overall histograms
	hMppcPulseHeight = new TH1F("hMppcPulseHeight","",numChan,0,numChan);

	//channel specific histograms
	for(int i = 0 ; i < numChan ; i++){
		char name[100];
		char title[200];
		char xaxis[200];
		char yaxis[200];
		
		//make sample difference histograms
		memset(&name[0],0,sizeof(name) );
		memset(&title[0],0,sizeof(title) );
		memset(&xaxis[0],0,sizeof(xaxis) );
		memset(&yaxis[0],0,sizeof(yaxis) );

		sprintf(name,"hSampleDiff_Ch%.2i",i);
	       	sprintf(title,"Adjacent Sample Difference Distribution Channel %i",i);
		sprintf(xaxis,"Difference between Sample Values (ADC)");
		sprintf(yaxis,"Number of Entries");

		hSampleDiff[i] = new TH1F(name, title, 100,-100,100);
		hSampleDiff[i]->GetXaxis()->SetTitle(xaxis);
		hSampleDiff[i]->GetXaxis()->CenterTitle();
		hSampleDiff[i]->GetYaxis()->SetTitle(yaxis);
		hSampleDiff[i]->GetYaxis()->CenterTitle();
		hSampleDiff[i]->StatOverflows(1);

		//make sample maximum histograms
		memset(&name[0],0,sizeof(name) );
		memset(&title[0],0,sizeof(title) );
		memset(&xaxis[0],0,sizeof(xaxis) );
		memset(&yaxis[0],0,sizeof(yaxis) );

		sprintf(name,"hSampleMinNum_Ch%.2i",i);
	       	sprintf(title,"Minimum Sample Distribution Channel %i",i);
		sprintf(xaxis,"Sample Number");
		sprintf(yaxis,"Number of Entries");

		hSampleMinNum[i] = new TH1F(name, title, numCellGroup*numSamp,0,numCellGroup*numSamp);
		hSampleMinNum[i]->GetXaxis()->SetTitle(xaxis);
		hSampleMinNum[i]->GetXaxis()->CenterTitle();
		hSampleMinNum[i]->GetYaxis()->SetTitle(yaxis);
		hSampleMinNum[i]->GetYaxis()->CenterTitle();
		hSampleMinNum[i]->StatOverflows(1);

		//make sample maximum histograms
		memset(&name[0],0,sizeof(name) );
		memset(&title[0],0,sizeof(title) );
		memset(&xaxis[0],0,sizeof(xaxis) );
		memset(&yaxis[0],0,sizeof(yaxis) );

		sprintf(name,"hSampleMinVal_Ch%.2i",i);
	       	sprintf(title,"Minimum Sample Value Distribution Channel %i",i);
		sprintf(xaxis,"Sample (ADC)");
		sprintf(yaxis,"Number of Entries");

		hSampleMinVal[i] = new TH1F(name, title, 300,-500,100);
		hSampleMinVal[i]->GetXaxis()->SetTitle(xaxis);
		hSampleMinVal[i]->GetXaxis()->CenterTitle();
		hSampleMinVal[i]->GetYaxis()->SetTitle(yaxis);
		hSampleMinVal[i]->GetYaxis()->CenterTitle();
		hSampleMinVal[i]->StatOverflows(1);

		//make sample maximum histograms
		memset(&name[0],0,sizeof(name) );
		memset(&title[0],0,sizeof(title) );
		memset(&xaxis[0],0,sizeof(xaxis) );
		memset(&yaxis[0],0,sizeof(yaxis) );

		sprintf(name,"hSampleMppcPulse_Ch%.2i",i);
	       	sprintf(title,"Mppc Pulse Distribution Channel %i",i);
		sprintf(xaxis,"Sample (ADC)");
		sprintf(yaxis,"Number of Entries");

		hSampleMppcPulse[i] = new TH1F(name, title, 400,-900,100);
		hSampleMppcPulse[i]->GetXaxis()->SetTitle(xaxis);
		hSampleMppcPulse[i]->GetXaxis()->CenterTitle();
		hSampleMppcPulse[i]->GetYaxis()->SetTitle(yaxis);
		hSampleMppcPulse[i]->GetYaxis()->CenterTitle();
		hSampleMppcPulse[i]->StatOverflows(1);
	}
}

void analyzeSampleGroups(TCanvas *c,sampleGroup_t sampleGroup[]){

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
			double ped = samplePedestals[channel]->GetBinContent(cell+1, j+1);
			//double corr = double( sample );
			double corr = double( sample - ped );

			num[ind] = ind;
			theVal[ind] = corr;
			if(0){
				std::cout << "int " << ind;
				std::cout << "\t sample " << sample;
				std::cout << "\t ped " << ped;
				std::cout << " corr " << corr;
		 		std::cout << std::endl;
			}
		}
	}

	//calculate 3-point average
	double theVal3pAvg[maxNum]; 
	theVal3pAvg[0] = (theVal[0] + theVal[1])/2.;
	theVal3pAvg[maxNum-1] = (theVal[maxNum-2] + theVal[maxNum-1])/2.;
	for( int j = 0+1 ; j < maxNum-1 ; j++ )
		theVal3pAvg[j] = (theVal[j-1] + theVal[j] + theVal[j+1])/3.;
	for( int j = 0 ; j < maxNum ; j++ )
		theVal[j] = theVal3pAvg[j];

	//loop through corrected sample array, analyze
	int chan = sampleGroup[0].channel;
	//variables used in analysis loop
	//determine min 3-point average value in waveform
	double minVal = 1.E+6;
	int minSamp = -1;
	for( int j = 0 ; j < maxNum ; j++ ){
		if( j > 0 )
			hSampleDiff[chan]->Fill( theVal[j] - theVal[j-1]);
		if( theVal[j] < minVal ){
			minVal = theVal[j];
			minSamp = j;
		}
	}//end analysis loop

	int minRange = 4;
	int maxRange = 58;
	int endMinDiff = 20;
	hSampleMinNum[chan]->Fill(minSamp);
	if( minSamp > minRange && minSamp < maxRange ){
		hSampleMinVal[chan]->Fill(minVal);
		double avg = theVal[minSamp];
		//double avg = (theVal[minSamp-1]+theVal[minSamp+1])/2.0;
		//if( minVal < theVal[0] - 20 && minVal < theVal[62] - 20 )
		//	hSampleMppcPulse[chan]->Fill(theVal);
		//require minimum sample to be lower than waveform start and endpoints, ie local minimum
		if( avg < theVal[1] - endMinDiff && avg < theVal[60] -endMinDiff ){
			hSampleMppcPulse[chan]->Fill(avg);
			//std::cout << " Pulse " << minSamp << "\ttime" << avg << std::endl;
		}
	}

	if(0){	
		plotSampleGroups(c, sampleGroup);
	}

	if(0){
		c->Clear();
		//define histogram and function for fitting
		TH1F *hWave = new TH1F("hWave","Fitted Sample Waveform", maxNum, 0 , maxNum);
		for( int j = 0 ; j < maxNum ; j++ )
			hWave->SetBinContent(j+1, theVal[j]);
		//try fitting pulse shape
		//TF1 *gfit = new TF1("gfit",myfunction,0,minSamp+8,4);
		//gfit->SetParameters(0.,-100.,10.,15.); //starter parameter values
		//gfit->SetParLimits(0, -15.,15.);
		//gfit->SetParLimits(1, -1.E+6,0.);
		//gfit->SetParLimits(2, -50.,64.);
		//gfit->SetParLimits(3, 5.,10.);
		//hWave->Fit("gfit","R"); 

		hWave->Draw();
		//gfit->Draw();

		gPad->Modified();
		c->Update();

		std::cout << " Enter character " << std::endl;
		char ct;
		std::cin >> ct;
		//gfit->Delete();
		hWave->Delete();
	}

	return;
}

Double_t myfunction(Double_t *x, Double_t *par)
{
	Float_t xx =x[0];
	Double_t f = 0;
	if( xx < par[2] )
		f = par[0];
	else
		f = par[0]+par[1]*TMath::Power( (xx-par[2])/par[3] , 4)*TMath::Exp(-1.*(xx-par[2])/par[3]);
		//f = par[0]+par[1]*TMath::Power( (xx-par[2])/par[3] , 4)*TMath::Exp(-1.*(xx-par[2])/par[3]);
	return f;
}
