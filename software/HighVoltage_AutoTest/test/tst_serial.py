#!/usr/bin/env python
#Following command will print documentation of tst_serial.py:
#pydoc tst_serial

"""
OVERVIEW:
Test script to control an Instrument using RS-232 (Serial)
Connection. Configurations may be different for each instrument.
Use this to DEBUG your commands to instrument. This is a great
way in finding which commands work!

AUTHORS:
Bronson Edralin <bedralin@hawaii.edu>
University of Hawaii at Manoa
Instrumentation Development Lab (IDLab), WAT214
 
HOW TO USE:
python tst_serial.py
"""

import time
import serial

# configure serial connections (config may diff per device)
ser = serial.Serial(
    port="/dev/ttyUSB0",
    baudrate=9600,
    parity=serial.PARITY_NONE,
    stopbits=serial.STOPBITS_ONE,
    bytesize=serial.EIGHTBITS
)

print "/dev/ttyUSB ",9600,serial.PARITY_NONE,serial.STOPBITS_ONE,serial.EIGHTBITS

#ser.close()
#ser.open()
ser.isOpen()

print "Enter your commands below.\r\nInsert 'exit' to leave the application."

input=1
while 1 :
    # get keyboard input 
    input = raw_input(">> ")    # Python 2 users
    #input = input(">> ")  # Python 3 users
    if input == "exit":
        ser.close()
        exit()
    else:
        # send cmd to instrument
        # \r\n requested by iseg device
        ser.write(input + "\r\n")
        out = ""
        # wait one sec for response from instrument
        time.sleep(1)
        while ser.inWaiting() > 0:
            out += ser.read(1)

        if out != " ":
            print ">>" + out
