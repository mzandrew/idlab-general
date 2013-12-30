#!/bin/bash

#Threshold Ch. 1(PCLK_1)
./bin/target6Control_writeDacReg 0 2030
#Threshold Ch. 2 (PCLK_2)
#./bin/target6Control_writeDacReg 1 0
#Threshold Ch. 3 (PCLK_3)
#./bin/target6Control_writeDacReg 2 0
#Threshold Ch. 4 (PCLK_4)
#./bin/target6Control_writeDacReg 3 0
#Threshold Ch. 5 (PCLK_5)
#./bin/target6Control_writeDacReg 4 0
#Threshold Ch. 6 (PCLK_6)
#./bin/target6Control_writeDacReg 5 0
#Threshold Ch. 7 (PCLK_7)
#./bin/target6Control_writeDacReg 6 0
#Threshold Ch. 8 (PCLK_8)
#./bin/target6Control_writeDacReg 7 0
#Threshold Ch. 9 (PCLK_9)
#./bin/target6Control_writeDacReg 8 0
#Threshold Ch. 10 (PCLK_10)
#./bin/target6Control_writeDacReg 9 0
#Threshold Ch. 11 (PCLK_11)
#./bin/target6Control_writeDacReg 10 0
#Threshold Ch. 12 (PCLK_12)
#./bin/target6Control_writeDacReg 11 0
#Threshold Ch. 13 (PCLK_13)
#./bin/target6Control_writeDacReg 12 0
#Threshold Ch. 14 (PCLK_14)
#./bin/target6Control_writeDacReg 13 0
#Threshold Ch. 15 (PCLK_15)
#./bin/target6Control_writeDacReg 14 0
#Threshold Ch. 16 (PCLK_16)
#./bin/target6Control_writeDacReg 15 0

#exit 0

#ITBias (PCLK_17)
./bin/target6Control_writeDacReg 16 1300
#SPAREbias (PCLK_18)
./bin/target6Control_writeDacReg 17 1300
#Vbias (PCLK_19)
./bin/target6Control_writeDacReg 18 1200
#GGbias (PCLK_20)
./bin/target6Control_writeDacReg 19 1600
#TRGbias (PCLK_21)
./bin/target6Control_writeDacReg 20 1800
#Wbias (PCLK_22)
./bin/target6Control_writeDacReg 21 600

#SBbuff = 2047  (PCLK_38)
./bin/target6Control_writeDacReg 37 1400
#SBbias  (PCLK_39)
./bin/target6Control_writeDacReg 38 1400
#MonTRGThresh (PCLK_40)
./bin/target6Control_writeDacReg 39 0

#WCBuff (PCLK_41)
./bin/target6Control_writeDacReg 40 1400
#CMPbias (PCLK_42)
./bin/target6Control_writeDacReg 41 1300
#PUbias  (PCLK_43)
./bin/target6Control_writeDacReg 42 2400

#Misc Digital Reg  (PCLK_44)
./bin/target6Control_writeDacReg 43 0 
#--NEEDS to be SET!

#VAbuff  (PCLK_45)
./bin/target6Control_writeDacReg 44 1500
#VAdjN (PCLK_46)
./bin/target6Control_writeDacReg 45 2000
#VAdjP (PCLK_47)
./bin/target6Control_writeDacReg 46 2050

#DBbias (DAC buffer bias) (PCLK_48)
./bin/target6Control_writeDacReg 47 1500
#ISEL (PCLK_49)
./bin/target6Control_writeDacReg 48 2400
#Vdischarge (PCLK_50)
./bin/target6Control_writeDacReg 49 500

#PROBIAS (Vdly DAC bias) (PCLK_51)
./bin/target6Control_writeDacReg 50 1400
#VDLY (PCLK_52)
./bin/target6Control_writeDacReg 51 3400
