#!/bin/bash
##script to record MPPC pulse data for a full set of preamplifiers and do basic analysis tasks

#need to test correct range of DACs, current best range is 20-50 (see voltage table)
BIAS_COUNTER=0
DACOFFSET=35
DACSTEP=5
NUMITER=7
INITCHAN=0
NUMCHAN=1

rm -r data_mppcBias_*

while [  $BIAS_COUNTER -lt $NUMITER ]; do

	DAC_VALUE=$(($BIAS_COUNTER*$DACSTEP))
	DAC_VALUE=$(($DAC_VALUE + $DACOFFSET))

	dirname=data_mppcBias_"$DAC_VALUE"
	mkdir $dirname

	#initialize DACs
	sudo ./bin/setPreampSetupDACs $DAC_VALUE

	###take new pedestal run for channels
	sudo ./bin/multiChannel64SampleReadout 0 1 $INITCHAN $NUMCHAN 1000

	#convert pedestal dat file to root tree
	root -l -b "parsePreampData64Samples.cxx++"
	cp parsePreampData64Samples_output.root $dirname/parsePreampData64Samples_pedestal_multich_output.root

	###take new data run for channels
	sudo ./bin/multiChannel64SampleReadout 1 1 $INITCHAN $NUMCHAN 2000

	#convert pedestal dat file to root tree
	root -l -b "parsePreampData64Samples.cxx++"
	cp parsePreampData64Samples_output.root $dirname/parsePreampData64Samples_mppcData_multich0_output.root

	###take new data run for channels
	sudo ./bin/multiChannel64SampleReadout 1 1 $INITCHAN $NUMCHAN 2000

	#convert pedestal dat file to root tree
	root -l -b "parsePreampData64Samples.cxx++"
	cp parsePreampData64Samples_output.root $dirname/parsePreampData64Samples_mppcData_multich1_output.root

	##set list of files to use to make pedestal file
	rm filelist_pedestalParsedData64Samples.txt
	ls $dirname/parsePreampData64Samples_pedestal_*_output.root > filelist_pedestalParsedData64Samples.txt
	
	#produce pedestal file
	root -l -b "makePedestalHists64Samples.cxx++"
	cp preampData64Samples_pedestalHists.root $dirname/.
	
	##set list of files to analyze
	rm filelist_mppcDataParsedData64Samples.txt
	ls $dirname/parsePreampData64Samples_mppcData_*_output.root > filelist_mppcDataParsedData64Samples.txt
	
	#analyze data files - produce pulse spectrum
	root -l -b "analyzeMppcBoardTreeWaveform64Samples.cxx++"
	cp analyzeMppcBoardTreeWaveform64Samples_output.root $dirname/.

	#analyze data files - measure 1pe pulse height in spectrum
	root -l -b "measureMppcPeakHeight.cxx++"
	cp measureMppcPeakHeight_output.root $dirname/.

	let BIAS_COUNTER=BIAS_COUNTER+1 
done

#list output files into filelist
ls data_mppcBias_*/measureMppcPeakHeight_output.root > filelist_measureBreakdownVoltage.txt
#ls data_mppcBias_*/analyzeMppcBoardTreeWaveform64Samples_output.root > filelist_measureBreakdownVoltage.txt
root -l -b "measureBreakdownVoltage.cxx++"
