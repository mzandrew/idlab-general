#/usr/bin/env python
#Following command will print documentation of iseg_SHQ226L.py:
#pydoc hvb_assembly_autotest 

"""
AUTHORS:
Bronson Edralin <bedralin@hawaii.edu>
University of Hawaii at Manoa
Instrumentation Development Lab (IDLab), WAT214

OVERVIEW:
This is an automated test written to test the HVB Assembly Boards. There should be around 90 of these up for testing. Just run this script on Raspberry Pi (RPi) and it will generate a csv file of the results and upload it to IDLAB's database using PostgreSQL.

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


def hvb_assembly_test(multimeter_addr="192.168.1.102",hv_supply_addr="RS232",SERIAL_NUMBER="123456",ISEG_VOLTAGE="1000",ISEG_RAMP_SPEED="10",TIME_PERIOD="0.2",PURPOSE="HVB_RawTest",LOC="/home/pi/daqtest1/"):

    # Set name of csv file for results
    filename = LOC+SERIAL_NUMBER+"_"+PURPOSE+".csv" 
    # Set name of headers for results in csv file
    with open(filename,'a') as csvfile: 
	writer = csv.writer(csvfile) 
	writer.writerow(['Purpose','DateTime','Serial_Number','BoardName',\
	    'Channel','ISEG_V','LoadRelay1','LoadRelay2','K','MCPAT','MCPAB',\
	    'MCPBT','MCPBB','Result_V'])

    
    # Make iseg object
    iseg = Iseg_SHQ226L("RS232")

    # Initialize parameters
    print "Initializing parameters for ISEG SHQ226L Supply..."
    iseg.channel=1
    iseg.ramp_speed = ISEG_RAMP_SPEED
    iseg.set_voltage = ISEG_VOLTAGE

    # Grab values 
    status = iseg.start_voltage_change # This triggers it to change voltage    
    channel = iseg.channel
    set_voltage = iseg.set_voltage
    actual_voltage = iseg.actual_voltage
    ramp_speed = iseg.ramp_speed
    voltage_delay = float(ISEG_VOLTAGE)/float(ISEG_RAMP_SPEED)

    # Print status
    print "\tISEG Channel is: "+channel
    print "\tStatus is: %r" %status
    print "\tSet voltage is: %r V" %set_voltage
    print "\t>> But, currently, actual voltage is: %r V" %actual_voltage    
    print "\tVoltage Ramp Speed is: %r" %ramp_speed
    print "\t>> Therefore, it will take "+str(voltage_delay)+" sec(s) to"+\
	  " reach set voltage="+str(set_voltage)+"V"

    time.sleep(voltage_delay) # Waiting for actual voltage of iseg 
			      # to reach set voltage

    # Print update status to see if actual_voltage=set_voltage now
    actual_voltage = iseg.actual_voltage
    print "\tActual voltage on ISEG Channel "+channel+" is now: "+actual_voltage+" V"

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
    channel_addr={1:(0,0,0),2:(0,0,1),3:(0,1,0),4:(0,1,1),5:(1,0,0),6:(1,0,1),7:(1,1,0),8:(1,1,1)}


    count = 0
    for j in range(0,4): # changing load relays
	for channel in range(1,9): # choosing channel
	    for k in range (0,5):  # Choosing different parameters in mux_state
		row = list()
		# print "channel address is: ",channel_addr[channel]
		a = channel_addr[channel]
		b = load_state[j]
		c = mux_state[k]
		hvb_gpio.change_states(a,b,c)
		time.sleep(float(TIME_PERIOD)/2)
		result = keith.read_voltage

		row.append('HVB_RawTest')
		ts=time.time()
		DateTime=datetime.datetime.fromtimestamp(ts).strftime('%Y-%m-%d %H:%M:%S')
		row.append(DateTime)
		row.append(SERIAL_NUMBER)
		row.append('HVB_Board_Assembly')
		row.append(channel)
		row.append(ISEG_VOLTAGE)
		row.append(load_state[j][0])
		row.append(load_state[j][1])
		row.append(mux_state[k][0])
                row.append(mux_state[k][1])
                row.append(mux_state[k][2])
                row.append(mux_state[k][3])
                row.append(mux_state[k][4])
		row.append(float(result))
		
		count+=1
		print "Measurement #"+str(count)+"= "+result+" "+unit
		with open(filename,'a') as csvfile:
		    writer = csv.writer(csvfile)
		    writer.writerow(row)	
	    
	        time.sleep(float(TIME_PERIOD)/2)
		
    # Reset parameters
    iseg.set_voltage = 0
        
    # Reset all GPIO pins of RPi to LOW (0)
    hvb_gpio.reset_all_gpio()



