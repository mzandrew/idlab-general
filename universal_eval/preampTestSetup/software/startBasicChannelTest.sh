#!/bin/bash
##script to record MPPC pulse data for a full set of preamplifiers and do basic analysis tasks

dirname=data_$(date +%Y%m%d)_$(date +%H%M%S)
mkdir $dirname

INITCHAN=0
NUMCHAN=1

#initialize DACs to specific value
#sudo ./bin/setPreampSetupDACs 35
#initialize DACs to very high value to eliminate dark noise
sudo ./bin/setPreampSetupDACs -1

###take new pedestal run for channel
sudo ./bin/multiChannel64SampleReadout 0 1 $INITCHAN $NUMCHAN 1000

#convert pedestal dat file to root tree
root -l -b "parsePreampData64Samples.cxx++"

cp parsePreampData64Samples_output.root $dirname/parsePreampData64Samples_pedestal_multich_output.root

##take new data run for channel - 1st round
sudo ./bin/multiChannel64SampleReadout 1 1 $INITCHAN $NUMCHAN 1000

#convert data dat file to root tree
root -l -b "parsePreampData64Samples.cxx++"
cp parsePreampData64Samples_output.root $dirname/parsePreampData64Samples_mppcData_multich0_output.root

##take new data run for channel - 2nd round
sudo ./bin/multiChannel64SampleReadout 1 1 $INITCHAN $NUMCHAN 1000

#convert data dat file to root tree
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

#analyze data files
root -l -b "analyzeMppcBoardTreeWaveform64Samples.cxx++"
cp analyzeMppcBoardTreeWaveform64Samples_output.root $dirname/.
