#!/usr/bin/env python
#Following command will print documentation of sync_datetime.py:
#pydoc sync_datetime 

"""
AUTHORS:
Bronson Edralin <bedralin@hawaii.edu>
University of Hawaii at Manoa
Instrumentation Development Lab (IDLab), WAT214

OVERVIEW:
This will automatically sync this current server's time with another server.
This is very useful when your server does not have internet access because
it is on a private server. You can synchronize your time with a server, 
on the same network, that has internet access.

On command line it would look like this:
sudo date --set="$(ssh username@hostIP date)"
"""

 
import subprocess
import sys
 

# Ports are handled in ~/.ssh/config since we use OpenSSH
def update_datetime(USERNAME="bronson",HOST="192.168.1.2"):
    ''' Input:  USERNAME for a server is a string
	        HOST is IP of the server is a string
	Output: returns nothing, but synchronizes RPi's
		clock with another server	       '''
    COMMAND='date --set="$(ssh '+USERNAME+"@"+HOST+' date)"'
 
    ssh = subprocess.Popen(COMMAND,
			shell=True,
			stdout=subprocess.PIPE,
			stderr=subprocess.PIPE,
			)
    result = ssh.stdout.readlines()
    if result == []:
	error = ssh.stderr.readlines()
	print >>sys.stderr, "ERROR: %s" % error
    else:
	print result[0].replace("\n","")
