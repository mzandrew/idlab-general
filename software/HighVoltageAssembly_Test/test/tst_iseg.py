#!/usr/bin/env python
#Following command will print documentation of tst_iseg.py:
#pydoc tst_iseg 

"""
OVERVIEW:
Test script to control an Instrument called:
ISEG SHQ226L High Voltage Power Supply

AUTHORS:
Bronson Edralin <bedralin@hawaii.edu>
University of Hawaii at Manoa
Instrumentation Development Lab (IDLab), WAT214
 
HOW TO USE:
sudo python tst_iseg.py
"""

import csv
import math
import datetime
import subprocess
from collections import *
from link import * 
from threading import Lock
from iseg_SHQ226L import *
import vxi11
import time
import math
import os
import serial

#b=RS232()
#b.ask_print("*IDN?")

iseg=Iseg_SHQ226L("RS232")

# Set Channel
iseg.channel = 1 
channel = iseg.channel
print "Channel is: "+channel

# Set Voltage
iseg.set_voltage = 10 
time.sleep(0.5)
set2_voltage = iseg.set_voltage

print "Set voltage is: %r" %set2_voltage 




