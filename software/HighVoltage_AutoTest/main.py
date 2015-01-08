#/usr/bin/env python
#Following command will print documentation of main.py:
#pydoc main 

"""
AUTHORS:
Bronson Edralin <bedralin@hawaii.edu>
University of Hawaii at Manoa
Instrumentation Development Lab (IDLab), WAT214

HVB ASSEMBLY TEST TEAM:
SOFTWARE = Bronson Edralin <bedralin@hawaii.edu>
HARDWARE = James Bynes <bynes@hawaii.edu>
MENTOR = Gerard Visser <gvisser@indiana.edu>

OVERVIEW:
This script is basically a user-interface for the automated 
HVB test.

DESCRIPTION:
This is an automated test written to test the HVB Assembly Boards. 
There should be around 90 of these up for testing. Just run this script 
on Raspberry Pi (RPi) and it will generate a csv file of the raw results 
in the Raspberry Pi location /home/pi/daqtest1 which points to 
daqtest1.iucf.indiana.edu:/home/gvisser/BelleII/hvbtest/export because 
of nfs mount. You can see the nfs mount settings in the Raspberry Pi 
location /etc/fstab file. Mount is automatically performed on reboot by 
editing /etc/rc.local file and putting: mount -o nolock /home/pi/daqtest1 

INSTRUMENTS USED:
ISEG SHQ226L High Voltage Power Supply
KEITHLEY 2010 Multimeter
 
HOW TO RUN:
sudo python main.py
"""

from hvb_assembly_test import *   # using hvb_assembly_test()
import sys
import datetime
import time
import logging          # Need this for logfile
import sync_datetime	# This is needed when datetime is out
			# of date. You can update it by 
			# syncronizing it with another server
#import hvb_db_utility	# Need this for uploading to postgresql database


# Global Values or Parameters that you can alter here
SERIAL_NUMBER = ""
MULTIMETER_ADDR = "192.168.1.102"
HV_SUPPLY_ADDR = "RS232"
ISEG_VOLTAGE = "1000"
ISEG_RAMP_SPEED = "255"
TIME_PERIOD = "0.2"
PURPOSE = "HVB_RawTest"
#LOC_DIR_FOR_STORING_CSV = "/home/pi/daqtest1/results/"  # Include '/' at end so it does not screw up directory
LOC_DIR_FOR_STORING_CSV = "results/"  # Include '/' at end so it does not screw up directory

# Global values for information of server that we are synchronizing clock with
# change it to your own login info if you want to be able to synchronize clock yourself
USERNAME = "bronson"
HOSTNAME = "192.168.1.2"

# Global values for information of database server
DB_HOST = "localhost"
DB_PORT = "3000"
DB_DBNAME = "belleII"
DB_USER = "postgres"
DB_PASSWORD = "pass123"

# Creating logfile for the hvb assembly test. It's a great way to keep track of the tests that we make
logging.basicConfig(filename='HVB_ASSEMBLY_TEST_log',level=logging.DEBUG,format='%(asctime)s %(message)s')

# Note: CSV File saved in /home/pi/daqtest1

print "\nWelcome to Automated Test for HVB Assemblies for the Belle II Detector System\n"
print "Collaboration between:"
print "\tIDLab from University of Hawaii"
print "\tUniversity of Indiana\n"
print "TEAM:"
print "\tSOFTWARE: Bronson Edralin <bedralin@hawaii.edu>"
print "\tHARDWARE: James Bynes <bynes@hawaii.edu>"
print "\tMENTOR: Gerard Visser <gvisser@indiana.edu>\n"

print "Recommended voltage for test using unpotted boards is 1kV, and 4kV after potted. If you want to change this parameter setting or anything else, please do so in main.py\n"
print "Current Parameters are:"
print "\t>> Keithley Mult Addr = "+MULTIMETER_ADDR
print "\t>> ISEG HV Supply Addr = "+HV_SUPPLY_ADDR
print "\t>> ISEG Voltage (V) = "+ISEG_VOLTAGE+" V"
print "\t>> ISEG RAMP Voltage Speed (V/s) = "+ISEG_RAMP_SPEED+" V/s"
print "\t>> TIME PERIOD(s) for Switching = "+TIME_PERIOD+" sec"
print "\t>> PURPOSE = "+PURPOSE
print "\t>> CSV file will be stored in: "+LOC_DIR_FOR_STORING_CSV
print "\n"

ts=time.time()
DateTime = datetime.datetime.fromtimestamp(ts).strftime('%Y-%m-%d %H:%M:%S')
is_datetime_correct = "Is current DateTime "+DateTime+" correct? (yes/no): "
while (1):
    yes_or_no = raw_input(is_datetime_correct)
    if str(yes_or_no).upper() == "YES":
	break
    elif str(yes_or_no).upper() == "NO":
	print "We will begin synchronizing time with another server. You can "+\
	    "global value USERNAME and HOSTNAME in main.py script"
	print "\tUSERNAME = "+USERNAME
	print "\tHOSTNAME = "+HOSTNAME
	sync_datetime.update_datetime(USERNAME,HOSTNAME)
	break
    else:
	print "\tError!!! Please input yes/no\n"

SERIAL_NUMBER = raw_input("Please enter serial number of board: ")

while (1):
    yes_or_no = raw_input("\tIs Serial_Number="+SERIAL_NUMBER+" correct? (yes/no): ")
    if str(yes_or_no).upper() == "YES":
        break
    elif str(yes_or_no).upper() == "NO":
	SERIAL_NUMBER = raw_input("Please enter serial number of board: ")
    else:
        print "\tError!!! Please input yes/no\n"

CSV_FILENAME = SERIAL_NUMBER+"_"+PURPOSE+".csv"

print "\nStarting Automated Test for HVB Assembly with Serial #"+SERIAL_NUMBER+" Now."+\
    "Results may be found in csv file on RPi at: "+LOC_DIR_FOR_STORING_CSV+\
    CSV_FILENAME+"."
print "If we enabled nfs mount, it may also be found on the other server at"+\
    " daqtest1.iucf.indiana.edu:/home/gvisser/BelleII/hvbtest/export/"+CSV_FILENAME+".\n"

DateTime = datetime.datetime.fromtimestamp(ts).strftime('%Y-%m-%d %H:%M:%S')

logging.info("Test for HVB Assembly with Serial Number "+SERIAL_NUMBER+"started!!!")
# START TEST
hvb_assembly_test(MULTIMETER_ADDR,HV_SUPPLY_ADDR,SERIAL_NUMBER,ISEG_VOLTAGE,ISEG_RAMP_SPEED,TIME_PERIOD,PURPOSE,LOC_DIR_FOR_STORING_CSV)

DateTime = datetime.datetime.fromtimestamp(ts).strftime('%Y-%m-%d %H:%M:%S')
logging.info("Test for HVB Assembly with Serial Number "+SERIAL_NUMBER+"ended!!!")

print "\nAutomated test for HVB Assembly has finished..."
print "Results may be found in csv file on RPi at: "+LOC_DIR_FOR_STORING_CSV+\
    CSV_FILENAME+"."
print "If we enabled nfs mount, it may also be found on the other server at"+\
    " daqtest1.iucf.indiana.edu:/home/gvisser/BelleII/hvbtest/export/"+CSV_FILENAME+".\n"

'''
should_we_upload_to_db = "Would you like to upload csv file "+LOC_DIR_FOR_STORING_CSV+\
    CSV_FILENAME+" to database? (yes/no): "
while (1):
    yes_or_no = raw_input(should_we_upload_to_db)
    if str(yes_or_no).upper() == "NO":
        break
    elif str(yes_or_no).upper() == "YES":
        print "We will begin uploading to database"
	print '\tDB_HOST = "'+DB_HOST+'"'
	print '\tDB_PORT = "'+DB_PORT+'"'
	print '\tDB_DBNAME = "'+DB_DBNAME+'"'
	print '\tDB_USER = "'+DB_USER+'"'
	print '\tDB_PASSWORD = "****"\n'
	print '\n\tCSV_FILENAME = '+CSV_FILENAME
	print '\tTableName = PURPOSE = '+PURPOSE

	db = hvb_db_utility.DatabaseUtility(DB_HOST,DB_PORT,DB_DBNAME,DB_USER,DB_PASSWORD)
	db.create_table(PURPOSE)
	LOC_N_CSV = LOC_DIR_FOR_STORING_CSV+CSV_FILENAME
	db.insert_data_into_database(LOC_N_CSV, PURPOSE)
        break
    else:
        print "\tError!!! Please input yes/no\n"
'''

print "\n We are finally done!!! MAHALO~"

