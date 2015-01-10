#/usr/bin/env python
#Following command will print documentation of iseg_SHQ226L.py:
#pydoc hvb_assembly_autotest 

"""
AUTHORS:
Bronson Edralin <bedralin@hawaii.edu>
University of Hawaii at Manoa
Instrumentation Development Lab (IDLab), WAT214

OVERVIEW:
This is an automated test written to test the HVB Assembly Boards. There should be around 90 of these up for testing. Just run this script on Raspberry Pi (RPi) and it will generate a csv file of the results and upon request, it will upload it to IDLAB's database using PostgreSQL.

LOGGING:
HVB_ASSEMBLY_TEST_log

INSTRUMENTS USED:
ISEG SHQ226L High Voltage Power Supply
KEITHLEY 2010 Multimeter
 
HOW TO SET UP:
"from iseg_SHQ226L.py import Iseg_SHQ226L" will import the class
"iseg = Iseg_SHQ226L(addr)" will create the instrument object
"iseg.channel = 2" will set channel to chan 2 (IMPORTANT: Set chan 1st)
"iseg.set_voltage = 5" will set voltage to 5 Volts on channel 2
"print iseg.set_voltage" will read the set voltage on chan 2
"print iseg.actual_voltage" will read the actual voltage on chan 2

HOW TO RUN:
python main.py
"""


import datetime
import time
import os
import logging
import csv
import hvb_gpio
from iseg_SHQ226L import *
from keithley_2010 import *
import link
import math
import sys

VOLTAGE_DELAY_ERROR = 2.5 # Enter float value which is multiplied on actual voltage_delay 
ISEG_VOLTAGE_LIMIT = 4400 # ISEG Voltage should not be more  
CMD_DELAY = 0.0

# Creating logfile for the hvb assembly test. It's a great way to keep track of the tests that we make
logging.basicConfig(filename='HVB_ASSEMBLY_TEST_log',level=logging.DEBUG,format='%(asctime)s %(message)s')


def hvb_assembly_test(multimeter_addr="192.168.1.102",hv_supply_addr="RS232",SERIAL_NUMBER="123456",ISEG_VOLTAGE="1000",ISEG_RAMP_SPEED="10",TIME_PERIOD="0.2",PURPOSE="HVB_RawTest",CodeVersion='1',LOC="/home/pi/daqtest1/"):

    if (float(ISEG_VOLTAGE) < 0) or (float(ISEG_VOLTAGE) > float(ISEG_VOLTAGE_LIMIT)):
	print "Error!!! ISEG Voltage must be between 0 and "+str(ISEG_VOLTAGE_LIMIT)+\
	    "for test"
	logging.error('Error!!! ISEG Voltage must be between 0 and '+\
	    str(ISEG_VOLTAGE_LIMIT)+'for test!')
	sys.exit()

    # Set name of csv file for results
    #filename = LOC+SERIAL_NUMBER+"_"+PURPOSE+".csv" 
    filename = LOC+PURPOSE+".csv"    

    # Attach BoardName+CodeVersion
    # Ex. HVB_Board_Assembly1 where 1 is CodeVersion number
    BoardName = 'HVB_Board_Assembly'+str(CodeVersion)

    # If file does not exist, set name of headers for results in csv file
    # If file exists, it is not necessary to set name of headers because
    # it should already have headers for the file
    if os.path.exists(filename):
	passed = False # Initialize variable to check if header exist
	fIn = open(filename)
	for line in fIn:
	    line=line.replace(',',' ') # Replace each blank space
	    value = line.split()
	    # check to see if file has same header
	    try:
		if value[0].lower()=='serial' and (value[1].lower()=='datetime') and \
	       (value[2].lower()=='boardname') and (value[3].lower()=='loadcondition') \
	       and (value[4].lower()=='psvoltageset') and \
	       (value[5].lower()=='psvoltage1') and (value[6].lower()=='pscurrent1_ua') \
	       and (value[7].lower()=='psvoltage2') and (value[8].lower()=='pscurrent2_ua') \
	       and (value[9].lower()=='v0') and (value[10].lower()=='v1') and \
	       (value[11].lower()=='v2') and (value[12].lower()=='v3') and \
	       (value[13].lower()=='v4') and (value[14].lower()=='v5') and \
               (value[15].lower()=='v6') and (value[16].lower()=='v7') and \
               (value[17].lower()=='v8') and (value[18].lower()=='v9') and \
               (value[19].lower()=='v10') and (value[20].lower()=='v11') and \
               (value[21].lower()=='v12') and (value[22].lower()=='v13') and \
               (value[23].lower()=='v14') and (value[24].lower()=='v15') and \
               (value[25].lower()=='v16') and (value[26].lower()=='v17') and \
               (value[27].lower()=='v18') and (value[28].lower()=='v19') and \
               (value[29].lower()=='v20') and (value[30].lower()=='v21') and \
               (value[31].lower()=='v22') and (value[32].lower()=='v23') and \
               (value[33].lower()=='v24') and (value[34].lower()=='v25') and \
               (value[35].lower()=='v26') and (value[36].lower()=='v27') and \
               (value[37].lower()=='v28') and (value[38].lower()=='v29') and \
               (value[39].lower()=='v30') and (value[40].lower()=='v31') and \
               (value[41].lower()=='v32') and (value[42].lower()=='v33') and \
               (value[43].lower()=='v34') and (value[44].lower()=='v35') and \
               (value[45].lower()=='v36') and (value[46].lower()=='v37') and \
               (value[47].lower()=='v38') and (value[48].lower()=='v39'):
		    passed = True
		    break
	    except IndexError:
		pass
	    print "Checking file to see if it has right header..."
	if not passed:
	    print "Error!!! File exists already and it is not related to our test!"
	    logging.error('Error!!! File exists and not related to our test!')
	    sys.exit()
    else:
	with open(filename,'a') as csvfile: 
	    writer = csv.writer(csvfile) 
	    writer.writerow(['Purpose', PURPOSE])
	    writer.writerow(['CodeVersion', CodeVersion])
	    writer.writerow('')
	    writer.writerow(['Serial','DateTime','BoardName','LoadCondition',\
		'PSvoltageSet','PSvoltage1','PScurrent1_uA','PSvoltage2',
		'PScurrent2_uA','V0','V1','V2','V3','V4','V5','V6','V7','V8','V9',\
		'V10','V11','V12','V13','V14','V15','V16','V17','V18','V19',\
		'V20','V21','V22','V23','V24','V25','V26','V27','V28','V29',\
		'V30','V31','V32','V33','V34','V35','V36','V37','V38','V39'])

    
    # Make iseg object
    iseg = Iseg_SHQ226L("RS232")

    print "Initializing parameters for ISEG SHQ226L Supply..."

    # Initialize parameters for ISEG Channel #1
    iseg.channel=1  # NOTE: Remember to always set channel
                    # of ISEG before sending commands!!!
    iseg.ramp_speed = ISEG_RAMP_SPEED
    iseg.set_voltage = ISEG_VOLTAGE
    #status1 = iseg.start_voltage_change # This triggers it to change voltage    

    # Initialize parameters for ISEG Channel #2
    iseg.channel=2  # NOTE: Remember to always set channel
                    # of ISEG before sending commands!!!
    iseg.ramp_speed = ISEG_RAMP_SPEED
    iseg.set_voltage = ISEG_VOLTAGE
    #status2 = iseg.start_voltage_change # This triggers it to change voltage  

    # Grab values for ISEG Channel #1 	
    iseg.channel=1  # NOTE: Remember to always set channel
		    # of ISEG before sending commands!!!
    channel1 = iseg.channel
    #set_voltage1 = iseg.set_voltage
    #time.sleep(CMD_DELAY)
    actual_voltage1 = -1*float(iseg.actual_voltage) # flipping voltage
    time.sleep(CMD_DELAY)
    actual_current1 = float(iseg.actual_current)*10**6
    time.sleep(CMD_DELAY)
    ramp_speed1 = iseg.ramp_speed

    # Grab values for ISEG Channel #2   
    iseg.channel=2  # NOTE: Remember to always set channel
                    # of ISEG before sending commands!!!
    channel2 = iseg.channel
    #set_voltage2 = iseg.set_voltage
    #time.sleep(CMD_DELAY)
    actual_voltage2 = -1*float(iseg.actual_voltage) # flipping voltage
    time.sleep(CMD_DELAY)
    actual_current2 = float(iseg.actual_current)*10**6
    time.sleep(CMD_DELAY)
    ramp_speed2 = float(iseg.ramp_speed)
  
    # Calculate how long it will take voltage to ramp up to desired voltage 
    voltage_delay1 = (float(ISEG_VOLTAGE)/float(ramp_speed1))*VOLTAGE_DELAY_ERROR
    voltage_delay2 = (float(ISEG_VOLTAGE)/float(ramp_speed2))*VOLTAGE_DELAY_ERROR
    voltage_delay = voltage_delay1 + voltage_delay2 

    # Update how long it will take for voltage to reach set Voltage
    print "\tISEG Set voltage is: %s V"%ISEG_VOLTAGE
    print "\tISEG Ramp Speed is: "+str(ISEG_RAMP_SPEED)+" V/s"
    print "\tTherefore, it will take %f sec(s) "%voltage_delay+\
	  "for actual voltage to reach the set voltage...\n"

    # Print current status
    print "Current status is..."
    print "\tISEG HV Supply Channel #"+channel1+":"
    print "\t>> actual voltage = %0.2f V"%actual_voltage1
    print "\t>> actual current = %0.2f uA"%actual_current1
    print "\tISEG HV Supply Channel #"+channel2+":"
    print "\t>> actual voltage = %0.2f V"%actual_voltage2
    print "\t>> actual current = %0.2f uA"%actual_current2

    # Print Wait update
    print "\nWaiting "+str(voltage_delay)+" sec(s)...\n"


    # Trigger ISEG Voltage
    iseg.channel = 1
    status1 = iseg.start_voltage_change # This triggers it to change voltage 
    time.sleep(voltage_delay1) # Waiting for actual voltage of iseg 
                                    # to reach set voltage
    iseg.channel = 2
    status2 = iseg.start_voltage_change # This triggers it to change voltage 
    time.sleep(voltage_delay2) # Waiting for actual voltage of iseg 
                               # to reach set voltage
    
    print "About to start HVB Automated Test for HVB Assembly with"+\
	" Serial #"+SERIAL_NUMBER+" Now."+"\nResults may be found"+\
	" in "+"directory at: "+LOC
    # This while() loop is responsible for the interactive 
    # prompt to see if you are satisfied with the actal voltage.
    # It will wait until you want to proceed.
    while(1):
	# Grab values for ISEG Channel #1   
	iseg.channel=1  # NOTE: Remember to always set channel
			# of ISEG before sending commands!!!
	channel1 = iseg.channel
	#set_voltage1 = iseg.set_voltage
        #time.sleep(CMD_DELAY)
	actual_voltage1 = -1*float(iseg.actual_voltage) # flipping voltage
	time.sleep(CMD_DELAY)
	actual_current1 = float(iseg.actual_current)*10**6
        #time.sleep(CMD_DELAY)
	#ramp_speed1 = iseg.ramp_speed
	voltage_delay1 = (float(ISEG_VOLTAGE)/float(ISEG_RAMP_SPEED))*VOLTAGE_DELAY_ERROR

	# Grab values for ISEG Channel #2   
	iseg.channel=2  # NOTE: Remember to always set channel
			# of ISEG before sending commands!!!
	channel2 = iseg.channel
	#set_voltage2 = iseg.set_voltage
        #time.sleep(CMD_DELAY)
	actual_voltage2 = -1*float(iseg.actual_voltage) # flipping voltage
        time.sleep(CMD_DELAY)
	actual_current2 = float(iseg.actual_current)*10**6
        #time.sleep(CMD_DELAY)
	#ramp_speed2 = iseg.ramp_speed
	voltage_delay2 = float(ISEG_VOLTAGE)/float(ISEG_RAMP_SPEED)
	print "\nStatus of ISEG HV Supply with PSvoltageSet="+ISEG_VOLTAGE+\
	    "V is: "
	print "\tISEG HV Supply Channel #"+channel1+":"
	print "\t>> actual voltage = %0.2f V"%actual_voltage1
	print "\t>> actual current = %0.2f uA"%actual_current1
	print "\tISEG HV Supply Channel #"+channel2+":"
	print "\t>> actual voltage = %0.2f V"%actual_voltage2
	print "\t>> actual current = %0.2f uA"%actual_current2
	RESPONSE = raw_input("\tPlease enter (c)ontinue, (e)xit, "+\
	    "(u)pdate, or (s)et_voltage: ")
	try:
	    if (RESPONSE.lower() == "exit" or RESPONSE.lower() == "e"):
		print "\nExiting..."
		sys.exit()
	    elif (RESPONSE.lower() == "continue" or RESPONSE.lower() == "c"):
		break
	    elif (RESPONSE.lower() == "update" or RESPONSE.lower() == "u"):
		pass
            elif (RESPONSE.lower() == "set_voltage" or RESPONSE.lower() == "s"):
		while(1):
		    ISEG_VOLTAGE = raw_input('\tPlease enter new set voltage'+\
			' (V): ')
		    try:
			if (ISEG_VOLTAGE.lower() == "exit" or ISEG_VOLTAGE.lower() == "e"):
			    print "\nExiting..."
			    sys.exit()
			elif (int(ISEG_VOLTAGE) < 0) or (int(ISEG_VOLTAGE) > 5000):
			    print "\t>> Error!!! ISEG_VOLTAGE must be between 0 and 5000!"
			else:  # Setting new ISEG_VOLTAGE
			    # Initialize parameters for ISEG Channel #1
			    iseg.channel=1  # NOTE: Remember to always set channel
					    # of ISEG before sending commands!!!
			    iseg.set_voltage = ISEG_VOLTAGE
                            # Initialize parameters for ISEG Channel #2
                            iseg.channel=2  # NOTE: Remember to always set channel
                                            # of ISEG before sending commands!!!
                            iseg.set_voltage = ISEG_VOLTAGE
			    
			    # Calculate Waiting time
			    voltage_delay = ((float(ISEG_VOLTAGE)-float(actual_voltage1))/\
				float(ISEG_RAMP_SPEED) + (float(ISEG_VOLTAGE) - \
				float(actual_voltage2))/float(ISEG_RAMP_SPEED))*VOLTAGE_DELAY_ERROR

			    # Print Wait update
			    print "\nWaiting "+str(voltage_delay)+" sec(s)...\n"

			    # Trigger ISEG Voltage
			    iseg.channel = 1
			    status1 = iseg.start_voltage_change # This triggers it to change voltage 
			    iseg.channel = 2
			    status2 = iseg.start_voltage_change # This triggers it to change voltage 
			    time.sleep(voltage_delay) # Waiting for actual voltage of iseg 
					               # to reach set voltage
			    break
		    except ValueError:
			print "\t>> Error!!! ISEG_VOLTAGE must be between 0 and 508!"
	    else:
		print '\t>> Error!!! Must enter "(c)ontinue", "(e)xit", '+\
		    '"(u)pdate", or "(s)et_voltage"!'	
	except ValueError:
            print '\t>> Error!!! Must enter "(c)ontinue", "(e)xit", '+\
                '"(u)pdate", or "(s)et_voltage"!' 
    print "\n"

    logging.info("Status of ISEG HV Supply with PSvoltageSet="+\
	ISEG_VOLTAGE+"V is: ")
    logging.info("\tISEG HV Supply Channel #"+channel1+":")
    logging.info("\t>> actual voltage = %0.2f V"%actual_voltage1)
    logging.info("\t>> actual current = %0.2f uA"%actual_current1)
    logging.info("\tISEG HV Supply Channel #"+channel2+":")
    logging.info("\t>> actual voltage = %0.2f V"%actual_voltage2)
    logging.info("\t>> actual current = %0.2f uA"%actual_current2)

    
    # Make keithley object
    keith=Keithley_2010("192.168.1.102",1234)

    # Initialize parameters
    id=keith.identification() # Get identification of instrument
    print id
    keith.reset() # reset configurations
    keith.configure = "VOLTAGE"     # configure function to voltage
    keith.configure_voltage = "DC"  # configure voltage to DC
    func,acdc = keith.configure_voltage  # Get configuration settings
					 # to see if it is configured to
					 # voltage and dc
    keith.unit_voltage = 'VPP'  # Set units of voltage 
    unit = keith.unit_voltage	# Get units of voltage

    print "Keithley2010 Multimeter configured to: "+acdc+" "+func+" "+unit+"\n"
   

 
    # Necessary states to control 
    load_state=[(0,0),(0,1),(1,0),(1,1)]
    mux_state=[(0,0,0,0,1),(0,0,0,1,0),(0,0,1,0,0),(0,1,0,0,0),(1,0,0,0,0)]
    channel_addr={0:(0,0,0),1:(0,0,1),2:(0,1,0),3:(0,1,1),4:(1,0,0),5:(1,0,1),6:(1,1,0),7:(1,1,1)}
    ts = time.time()
    DateTime=datetime.datetime.fromtimestamp(ts).strftime('%Y-%m-%d %H:%M:%S')
    row = list()
    count = 0

    # Reset all GPIO pins of RPi to LOW (0)
    hvb_gpio.reset_all_gpio()   # Safety practice ensuring GPIO pins are low

    for LoadCondition in range(0,4): # changing load relays
	print "\nUnder LoadCondition = "+str(LoadCondition)
	# Update row to be written on csv
	row.append(SERIAL_NUMBER)
        row.append(DateTime) 
	row.append(BoardName)
	row.append(LoadCondition)  # LoadCondition:  0 = off off
		       #		 1 = off on
		       #		 2 = on off
		       #		 3 = on on
	row.append(ISEG_VOLTAGE)

	iseg.channel=1  # NOTE: Remember to always set channel
			# of ISEG before sending commands!!!
        PSvoltage1 = -1*float(iseg.actual_voltage) # Actual voltage from ISEG Ch1
						   # flipping voltage
	PScurrent1 = float(iseg.actual_current)    # Actual currrent from ISEG Ch1
	iseg.channel=2  # NOTE: Remember to always set channel
                        # of ISEG before sending commands!!!
        PSvoltage2 = -1*float(iseg.actual_voltage) # Actual voltage from ISEG Ch2
						   # flipping voltage
	PScurrent2 = float(iseg.actual_current)    # Actual current from ISEG Ch2

	# Update row to be written on csv
	row.append(format(PSvoltage1,'.2f'))
	row.append(format(PScurrent1*10**6,'.2f'))
        row.append(format(PSvoltage2,'.2f'))
        row.append(format(PScurrent2*10**6,'.2f'))

	for channel in range(0,8): # choosing channel
	    for k in range (0,5):  # Choosing different parameters in mux_state
		# print "channel address is: ",channel_addr[channel]
		a = channel_addr[channel]  # channel is associated with test board # on stack
		b = load_state[int(LoadCondition)]
		c = mux_state[k]
		hvb_gpio.change_states(a,b,c)
		time.sleep(float(TIME_PERIOD)/2)
		vdmm = keith.read_voltage # actual reading from keithley2010 mult.
		vdmm = -1*float(vdmm)	
	
		# Formula to convert Keithley DMM measures into real voltage on
		# HVB output terminals/test board input terminals, that this
		# corresponds to. It is actual voltage we want to store in test
		# test database. (NOTE: If it were remeasured at some later date with
		# a replacement test system, the intermediate voltage of the DMM
	        # might differ, it's the actual voltage which is really the 
		# universal thing of interest)
		b = 502.522692 # b constant for eqn
		c = 1.04007e-3 # c constant for eqn
		d = 1.96453e-5 # d constant for eqn
		# result is associated with V0, V1, V2, V3, .... V39
		result = format(b*vdmm*(1-c*vdmm-d*(vdmm**2)),'.2f')
		    
		row.append(result)
		
		print "\tV"+str(count)+" = "+str(result)+" "+"V"
		count+=1
		time.sleep(float(TIME_PERIOD)/2)
	count = 0

	with open(filename,'a') as csvfile:
	    writer = csv.writer(csvfile)
	    writer.writerow(row)	
	row = []
    
	
    # Reset parameters
    iseg.set_voltage = 0
        
    # Reset all GPIO pins of RPi to LOW (0)
    hvb_gpio.reset_all_gpio()



