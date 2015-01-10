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

iseg=Iseg_SHQ226L("RS232")

# Set Channel
iseg.channel = 1
channel = iseg.channel
print "Channel is: "+channel


# Set Voltage
iseg.ramp_speed = 255
ramp_speed = iseg.ramp_speed
print "ramp speed is: %r" %ramp_speed

iseg.set_voltage = 50 
#time.sleep(0.5)
set2_voltage = iseg.set_voltage
status = iseg.start_voltage_change # This triggers it to change voltage
print "Status is: %r" %status


print "\nSet voltage is: %r" %set2_voltage
time.sleep(5)

actual_voltage = float(iseg.actual_voltage)
print "read voltage is: %r" %actual_voltage
time.sleep(0.5)
actual_current = iseg.actual_current
print "read current is: %r" %actual_current
break_time = iseg.break_time
print "break time is: %r" %break_time


# Set Voltage
iseg.ramp_speed = 255
time.sleep(0.5)
iseg.set_voltage = 10
time.sleep(0.5)
set2_voltage = iseg.set_voltage
print "Set voltage is: %r" %set2_voltage
time.sleep(0.5)


actual_voltage = iseg.actual_voltage
print "read voltage is: %r" %actual_voltage
time.sleep(0.5)
actual_current = iseg.actual_current
print "read current is: %r" %actual_current
break_time = iseg.break_time
print "break time is: %r" %break_time

voltage_limit = iseg.voltage_limit
print "voltage limit is: %r" %voltage_limit
current_limit = iseg.current_limit
print "current limit is: %r" %current_limit
set_voltage = iseg.set_voltage
print "set voltage is: %r" %set_voltage
ramp_speed = iseg.ramp_speed
print "ramp speed is: %r" %ramp_speed
current_trip_A = iseg.current_trip_A
print "current_trip_A is: %r" %current_trip_A
current_trip_mA = iseg.current_trip_mA
print "current_trip_mA is: %r" %current_trip_mA
current_trip_uA = iseg.current_trip_uA
print "current_trip_uA is: %r" %current_trip_uA
auto_start = iseg.auto_start
print "auto start is: %r" %auto_start
status_word = iseg.status_word
print "status word is: %r" %status_word
module_status = iseg.module_status
print "module status is: %r" %module_status




