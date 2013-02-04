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
#include <TMinuit.h>
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

int sampleCount[numChan][numCellGroup][numSamp];
double sampleAvg[numChan][numCellGroup][numSamp];
double maxPeak[numChan][numCellGroup][numSamp];
TH1S *hSample[numChan][numCellGroup][numSamp];

void initializeHistograms();
void processTree(TTree *tree, int control);

void makePedestalHists64Samples(){
	//gROOT->Reset();  

	//open pedestal histogram file, create if it doesn't exist
	string pedestalFileName = "preampData64Samples_pedestalHists.root";
	TFile *g;
	g = new TFile(pedestalFileName.c_str(),"RECREATE"); //test mode
	if (g->IsZombie()) {
		std::cout << "Error opening pedestal file" << std::endl;
		exit(-1);
	}

	//define input filelist
	ifstream infile;
	string infileName = "filelist_pedestalParsedData64Samples.txt";

	//open infile for measuring mean and RMS
	infile.open(infileName.c_str(), ifstream::in);
	if (infile.fail()) {
		std::cout << "Error opening input file, exiting" << std::endl;
		exit(-1);
	}

	//intialize mean, RMS, count array
	memset(sampleCount,0,sizeof(sampleCount));
	memset(sampleAvg,0,sizeof(sampleAvg));
	memset(maxPeak,0,sizeof(maxPeak));

	//process input filelist line by line
	string temp = "";
	std::cout << " Finding channel means, RMS " << std::endl;
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
		//load tree
       	 	TTree *tree = (TTree*)f->Get("tree");
		//process tree
		processTree(tree, 0);
		//close tree
		tree->Delete("");
		//close tree file
		f->Close();
	}
	infile.close();

	//open infile again
	infile.open(infileName.c_str(), ifstream::in);
	if (infile.fail()) {
		std::cout << "Error opening input file, exiting" << std::endl;
		exit(-1);
	}

	//define histograms
	initializeHistograms();

	//process input filelist line by line
	std::cout << " Histogram channel distributions " << std::endl;
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
		//load tree
       	 	TTree *tree = (TTree*)f->Get("tree");
		//process tree
		processTree(tree, 1);
		//close tree
		tree->Delete("");
		//close tree file
		f->Close();
	}
	infile.close();

	//fit histograms and save pedstals here as saving histograms may take too much space
	TH2F *samplePedestals[numChan];
	for( int i = 0 ; i < numChan ; i++ ){
		char name[100];
		char title[200];
		memset(&name[0],0,sizeof(name) );
		memset(&title[0],0,sizeof(title) );
		sprintf(name,"samplePedestals_Ch%.2i",i);
	       	sprintf(title,"Sample Pedestals Channel %i",i);

		samplePedestals[i] = new TH2F(name, title, numCellGroup,0,numCellGroup,numSamp,0,numSamp);
	}

	//TCanvas *c0 = new TCanvas("C0","",0,0,400,300);
	for( int i = 0 ; i < numChan ; i++ ){
	for( int j = 0 ; j < numCellGroup ; j++ ){
	for( int k = 0 ; k < numSamp ; k++ ){
		//c0->Clear();
		samplePedestals[i]->SetBinContent(j+1,k+1,-1); //default value
		if( !hSample[i][j][k] )
			continue;
		if( hSample[i][j][k]->GetEntries() <= 0 )
			continue;

		//find max peak position in pedestal sample histogram
		int maxVal = -1;
		int maxInd = -1;
		for(int ind = 0 ; ind < hSample[i][j][k]->GetNbinsX() ; ind++){
			if( hSample[i][j][k]->GetBinContent(ind+1) > maxVal ){
				maxVal = hSample[i][j][k]->GetBinContent(ind+1);
				maxInd = ind;
			}
		}

		// Fit histogram w Gaussian
		//TF1 *gfit = new TF1("Gaussian","gaus",sampleAvg[i][j][k] - 30, sampleAvg[i][j][k] + 30);
		TF1 *gfit = new TF1("Gaussian","gaus", hSample[i][j][k]->GetBinCenter(maxInd) - 30, hSample[i][j][k]->GetBinCenter(maxInd) + 30);
		if( maxInd > 0 ){
			hSample[i][j][k]->Fit("Gaussian","QR"); 
			samplePedestals[i]->SetBinContent(j+1,k+1,gfit->GetParameter(1)); //save pedestal value
		}
		else
			samplePedestals[i]->SetBinContent(j+1,k+1,0); //save pedestal value
		if(0){
			std::cout << " Fitting " << i << " " << j << " " << k;
			std::cout << " avg " << sampleAvg[i][j][k];
			std::cout << " mean " << gfit->GetParameter(1);
			std::cout << " RMS " << gfit->GetParameter(2);
			std::cout << std::endl;
		}
		gfit->Delete();

		//hSample[i][j][k]->Draw();
		//gPad->Modified();
		//c0->Update();
		//char ct;
		//std::cin >> ct;
	}//end k loop
	}//end j loop
	}//end i loop
		
	//close pedestal file, make individual diretories for each channel
	g->cd();
	for( int i = 0 ; i < numChan ; i++ )
		samplePedestals[i]->Write();	
	for( int i = 0 ; i < numChan ; i++ ){
		g->cd();
		char name[100];
		memset(&name[0],0,sizeof(name) );
		sprintf(name,"pedestals_Ch%.2i",i);
		g->mkdir(name);
		g->cd(name);
		for( int j = 0 ; j < numCellGroup ; j++ )
		for( int k = 0 ; k < numSamp ; k++ )
			hSample[i][j][k]->Write();
	}
	g->Close();

	std::cout << " pedestalFileName " << pedestalFileName << std::endl;

	gApplication->Terminate();
	return;
}

void initializeHistograms(){
	char name[100];
	char title[200];
	char xaxis[200];
	char yaxis[200];
	for( int i = 0 ; i < numChan ; i++ ){
	for( int j = 0 ; j < numCellGroup ; j++ ){
	for( int k = 0 ; k < numSamp ; k++ ){
		memset(&name[0],0,sizeof(name) );
		memset(&title[0],0,sizeof(title) );
		memset(&xaxis[0],0,sizeof(xaxis) );
		memset(&yaxis[0],0,sizeof(yaxis) );

		sprintf(name,"hSample_Ch%.2i_Cg%.3i_Sm%.2i",i,j,k);
	       	sprintf(title,"Sample Distribution %i",k);
		sprintf(xaxis,"Sample %i Values (ADC)",k);
		sprintf(yaxis,"Number of Entries");

		hSample[i][j][k] = new TH1S(name, title, 1000,sampleAvg[i][j][k] - 1000, sampleAvg[i][j][k] + 1000);
		hSample[i][j][k]->GetXaxis()->SetTitle(xaxis);
		hSample[i][j][k]->GetXaxis()->CenterTitle();
		hSample[i][j][k]->GetYaxis()->SetTitle(yaxis);
		hSample[i][j][k]->GetYaxis()->CenterTitle();
		hSample[i][j][k]->StatOverflows(1);
	}//end k loop
	}//end j loop
	}//end i loop
}

void processTree(TTree *tree, int control){
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
	for (int ient = 0; ient < tree->GetEntries(); ient++){
		//if( ient % 1000 == 0) std::cout << "\tTree entry " << ient << std::endl;
		tree->GetEvent(ient);

		//loop over all cell groups in tree
		for(int icell = 0 ; icell < numCellGroup ; icell++){
			int chan = sampleGroups[icell].channel;
			int cell = sampleGroups[icell].cellGroup;

			//determin if valid entry
			if( chan < 0 || chan > numChan )
				continue;
			if( cell != icell )
				continue;
			for(int j = 0 ; j < numSamp ; j++){
				int samp = sampleGroups[icell].samples[j];
				if( samp > adcMax )
					continue;

				if( control == 0){
					//variable for calculating running average, used to reduce roundoff error
					// AVGX = AVGX + (Xi - AVGX)/I , I starts at 1
					sampleCount[chan][cell][j] = sampleCount[chan][cell][j] + 1;
					sampleAvg[chan][cell][j] = sampleAvg[chan][cell][j] + (samp - sampleAvg[chan][cell][j])/double(sampleCount[chan][cell][j]);
				}
				else {
					//add entry to histogram
					hSample[chan][cell][j]->Fill(samp);
				}
			}
		}
	}

	return;
}
