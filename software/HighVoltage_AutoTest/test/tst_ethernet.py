#!/usr/bin/env python
#Following command will print documentation of tst_ethernet.py:
#pydoc tst_ethernet

"""
OVERVIEW:
Test script to control an Instrument using GPIB with a Ethernet
Controller Connection. Configurations may be different for each 
instrument. Use this to DEBUG your commands to instrument. This 
is a great way in finding which commands work!

AUTHORS:
Bronson Edralin <bedralin@hawaii.edu>
University of Hawaii at Manoa
Instrumentation Development Lab (IDLab), WAT214
 
HOW TO USE:
python tst_ethernet.py
"""

import time
import socket  #for sockets
import sys     #for exit

# CONFIGURATIONS 
ip = "192.168.1.102"
port = 1234

#create an INET, STREAMing socket
try:
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
except socket.error:
    print 'Failed to create socket'
    sys.exit()

timeout = 0.5
s.settimeout(timeout)

print 'Socket Created'

#Connect to remote server
try:
    s.connect((ip , port))
except TypeError:
    print "Socket Failed to Connect to IP (" + ip + ") with port #" + str(port)
    sys.exit()
except socket.error:
    print "Socket Failed to Connect to IP (" + ip + ") with port #" + str(port)
    sys.exit()

print "Socket Connected to " + "IP (" + ip + ")"

#Send some data to remote server
message = "*IDN?\r\n\r\n"

try :
    #Set whole string
    s.sendall(message)
except socket.error:
    print 'Send failed'
    sys.exit()

#Now receive data
try:
    reply = s.recv(4096)
except socket.timeout:
    print "Socket Timeout has occured!"
    reply = ""

print reply

print 'Enter your commands below.\r\nInsert "exit" to leave the application.'


input=1
while 1 :
    # get keyboard input
    input = raw_input(">> ")
        # Python 3 users
        # input = input(">> ")
    if input == 'exit':
	s.close()
        sys.exit()
    else:
        # send the character to the device
        # (note that I happend a \r\n carriage return and line feed to the characters - this is requested by my device)
        try:
	    s.sendall(input + '\r\n')
	except socket.error:
	    print "Send failed!"
	    s.close()
	    sys.exit()
        # Receive data
	try:
	    reply = s.recv(4096)
	    print reply

	except:
	    print "try again"
	"""
	except socket.timeout:
	    print "Socket Timeout has occured!"
	    s.sendall("SYST:ERR?\r\n")
	    try:
		error_numb,error = s.recv(4096).split(',')
	    except socket.timeout:
		error=""
		error_numb=""
		reply=""
		print "Socket Timeout has occured in trying to get error!"
	    if (error != '"Query UNTERMINATED"\n' and error != ""):
		reply_e = "Error has occured: "+error_numb+", "+error
		print reply_e
	    else:
		reply=""	

    """

