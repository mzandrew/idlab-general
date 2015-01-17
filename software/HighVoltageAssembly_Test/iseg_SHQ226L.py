#!/usr/bin/env python
#Following command will print documentation of iseg_SHQ226L.py:
#pydoc iseg_SHQ226L 

"""
AUTHORS:
Bronson Edralin <bedralin@hawaii.edu>
University of Hawaii at Manoa
Instrumentation Development Lab (IDLab), WAT214

OVERVIEW:
Python wrapper for commands to control an Instrument called:
ISEG SHQ226L High Voltage Power Supply

HOW TO USE:
"from iseg_SHQ226L.py import Iseg_SHQ226L" will import the class
"iseg = Iseg_SHQ226L(addr)" will create the instrument object
"iseg.channel = 2" will set channel to chan 2 (IMPORTANT: Set chan 1st)
"iseg.set_voltage = 5" will set voltage to 5 Volts on channel 2
"print iseg.set_voltage" will read the set voltage on chan 2
"print iseg.actual_voltage" will read the actual voltage on chan 2

ISEG SHQ226L USER MANUAL:
http://www.fastcomtec.com/ftp/manuals/shqrs232.pdf
"""

from link import * 

class Iseg_SHQ226L(object):
    def __init__(self, addr=None):
	''' Input:  addr is a string for RS232 or IP which is 192.168.#.#
	    Output: returns nothing, but initializes connection  '''
	addr=addr.upper()
	#Set up link connection. Either RS232 via USB or GPIO via Ethernet
	if (addr == 'RS232') or (addr == 'RS-232'):
	    self.link = RS232()
	elif (addr != None):
	    self.link = Ethernet(addr)
	else:
	    print "Invalid address: "+str(addr)

    def __binary_cmd__(self, cmd):
	''' Input:  binary cmd
	    Output: return binary cmd as a string '''
        if isinstance(cmd, str):  #If cmd is a string
            cmd = cmd.upper()     
        try:  
	    # Binary cmd must be one of these and be converted into string
            cmd={1:'1','1':'1',0:'0','0':'0','ON':'1','OFF':'0'}[cmd]
        except KeyError:
            print "Invalid operation: "+str(cmd)  # If Binary cmd was not on list
        else:
	    #print cmd   # Uncomment for debug
            return str(cmd)

    #Channels 1-8
    @property
    def channel(self):
	''' Input:  None
	    Output: return channel number '''
        #print self.chan  # Uncomment for debug
        #self.chan=1
        return str(self.chan)

    @channel.setter
    def channel(self,chan):
	''' Input: channel number
	    Output: return nothing, but sets channel number '''
        valid_channels=[1,2,3,4,5,6,7,8]
        try:
            chan = int(chan)
            self.chan = str(valid_channels[valid_channels.index(chan)])
        except ValueError:
            print "Invalid Channel Number: "+str(chan)

    # Read module identifier
    # nnnn	;n.nn		;U	    ;I*
    # (unit #	;software rel.	;V_outmax   ;I_outmax)
    @property
    def module_identifier(self):
	''' Input:  None
	    Output: return module identifier '''
        #print ("#")  #Uncomment for debug
        #self.link.ask_print("#")  # Print Instrument's Resp
        return str(self.link.ask("#"))

    # Read break time
    # (break time 0 ... 255 ms)
    @property
    def break_time(self):
	''' Input:  None
	    Output: return break time of ISEG in ms '''
        #print ("W")  #Uncomment for debug
        #self.link.ask_print("W")  # Print Instrument's Resp
        raw = self.link.ask("W")
    	while(1):
	    try:
		break_time = float(raw.split()[-1].replace('-','e-').lstrip('e'))
		break
	    except ValueError:
		raw = self.link.ask("W")
	return str(break_time)

    # Write break time
    # (break time 0 ... 255 ms)
    @break_time.setter
    def break_time(self, cmd):
	''' Input:  break time value in ms
	    Output: return nothing, but sets break time in ms '''
        try:
            cmd = int(cmd)
        except ValueError:
            print "Invalid Break Time (ms) Value: "+str(cmd)
        else:
            #print ("W"+"="+str(cmd))  #Uncomment for debug
            self.link.cmd("W"+"="+str(cmd))

    # Read actual voltage (V) on channel
    # {polarity/mantisse/exp. with sign}      (in V)
    @property
    def actual_voltage(self):
	''' Input:  None
	    Output: return actual voltage (V) in scientific notation '''
        #print ("U"+self.chan)  #Uncomment for debug
        #self.link.ask_print("U"+self.chan)  # Print Instrument's Resp  
        raw = self.link.ask("U"+self.chan)
	#print "Raw Actual_voltage is: "+str(raw)
        while(1):
            try:
		actual_voltage = float(raw.split()[-1].replace('-','e-').lstrip('e'))
		break
	    except ValueError:
		raw = self.link.ask("U"+self.chan)
	return str(actual_voltage)

    # Read actual current (A) on channel
    # {mantisse/exp. with sign}	    (in A) 
    @property
    def actual_current(self):
        ''' Input:  None
            Output: return actual current (A) in scientific notation '''
        #print ("I"+self.chan)  #Uncomment for debug
        #self.link.ask_print("I"+self.chan)  # Print Instrument's Resp  
        raw = self.link.ask("I"+self.chan)
	while(1):
            try:
		actual_current = float(raw.split()[-1].replace('-','e-').lstrip('e'))
		break
	    except ValueError:
		raw = self.link.ask("I"+self.chan)
	return str(actual_current)

    # Read voltage limit on channel
    # (in % of V_outmax) 
    @property
    def voltage_limit(self):
	''' Input:  None
	    Output: return voltage limit '''
        #print ("M"+self.chan)  #Uncomment for debug
        #self.link.ask_print("M"+self.chan)  # Print Instrument's Resp  
	raw = self.link.ask("M"+self.chan)
        while(1):
            try:
		voltage_limit = float(raw.split()[-1].replace('-','e-').lstrip('e'))
                break
            except ValueError:
		raw = self.link.ask("M"+self.chan)
	return str(voltage_limit)

    # Read current limit on channel
    # (in % of I_outmax) 
    @property
    def current_limit(self):
	''' Input:  None
	    Output: return current limit '''
        #print ("N"+self.chan)  #Uncomment for debug
        #self.link.ask_print("N"+self.chan)  # Print Instrument's Resp  
	raw = self.link.ask("N"+self.chan)
        while(1):
            try:
		current_limit = float(raw.split()[-1].replace('-','e-').lstrip('e'))
                break
            except ValueError:
		raw = self.link.ask("N"+self.chan)
	return str(current_limit)

    # Read set voltage on channel
    # {mantisse/exp. with sign}     (in V) 
    @property
    def set_voltage(self):
	''' Input: None
	    Output: return set voltage (V) in scientific notation
		    (what voltage you want to set it as)          '''
	#print ("D"+self.chan)  #Uncomment for debug
	#self.link.ask_print("D"+self.chan)  # Print Instrument's Resp    
	raw = self.link.ask("D"+self.chan)
        while(1):
            try:
		output = float(raw.split()[-1].replace('-','e-').lstrip('e'))
                break
            except ValueError:
		raw = self.link.ask("D"+self.chan)
	return str(output)

    # Write set voltage on channeli
    # (voltage correspondig resolution in V; <M1)
    @set_voltage.setter
    def set_voltage(self, cmd):
        ''' Input:  voltage that you want to set the ISEG as
            Output: return nothing, but sets the set voltage '''
        try:
            cmd = float(cmd)
        except ValueError:
            print "Invalid Set Voltage Value: "+str(cmd)
        else:
            #print ("D"+self.chan+"="+str(cmd))  #Uncomment for debug
            self.link.cmd("D"+self.chan+"="+str(cmd))

    # Read ramp speed on channel 
    # (2 ... 255 V/s)
    @property
    def ramp_speed(self):
	''' Input:  None
	    Output: return ramp speed (V/s) in scientific notation '''
        #print ("V"+self.chan)  #Uncomment for debug
	#self.link.ask_print("V"+self.chan)  # Print Instrument's Resp
	raw = self.link.ask("V"+self.chan)
        while(1):
            try:
		ramp_speed = float(raw.split()[-1].replace('-','e-').lstrip('e'))
                break
            except ValueError:
		raw = self.link.ask("V"+self.chan)
	return str(ramp_speed)

    # Write ramp speed on channel
    # (ramp speed = 2 - 255 V/s)
    @ramp_speed.setter
    def ramp_speed(self, cmd):
	''' Input:  ramp speed (V/s)
	    Output: return nothing, but sets the ramp speed (V/s) '''
        try:
            cmd = int(cmd)
        except ValueError:
            print "Invalid Ramp Speed Value: "+str(cmd)
        else:
            #print ("V"+self.chan+"="+str(cmd))  #Uncomment for debug    
            self.link.cmd("V"+self.chan+"="+str(cmd))

    # Start voltage change on channel numb 
    # S1=xxx (S1, >> Status information)
    @property
    def start_voltage_change(self):
        ''' Input:  None
            Output: return status information and 
		    starts voltage change on channel number 
		    NOTE: MUST SET CHANNEL NUMB BEFORE USING THIS '''
        #print ("G"+self.chan)  #Uncomment for debug
        #self.link.ask_print("G"+self.chan)  # Print Instrument's Resp
	raw = self.link.ask("G"+self.chan)
	start_voltage_change = raw.split()[-1].replace('-','e-').lstrip('e')
	return start_voltage_change

    # Read current trip on channel 
    # (trip corresponding resolution Range: A>0) 
    @property
    def current_trip_A(self):
	''' Input:  None
	    Output: current trip on channel (A) '''
        #print ("L"+self.channel)  #Uncomment for debug
        #self.link.ask_print("L"+self.chan)  # Print Instrument's Resp
	raw = self.link.ask("L"+self.chan)
        while(1):
            try:
		current_trip_A = float(raw.split()[-1].replace('-','e-').lstrip('e'))
                break
            except ValueError:
		raw = self.link.ask("L"+self.chan)
	return str(current_trip_A)

    # Write current trip on channel  (Range: A)
    @current_trip_A.setter
    def current_trip_A(self, cmd):
	''' Input:  current trip (A) on channel
	    Output: return nothing, but sets the current trip (A) on channel '''
        try:
            cmd = int(cmd)
        except ValueError:
            print "Invalid Current (A) Trip Value: "+str(cmd)
        else:
            #print ("L"+self.chan+"="+str(cmd))  #Uncomment for debug  
            self.link.cmd("L"+self.chan+"="+str(cmd))

    # Read current trip on channel 
    # (trip corresponding resolution Range: mA>0) 
    @property
    def current_trip_mA(self):
        ''' Input:  None
            Output: current trip on channel (mA) '''
        #print ("LB"+self.chan)  #Uncomment for debug
        #self.link.ask_print("LB"+self.chan)  # Print Instrument's Resp
	raw = self.link.ask("LB"+self.chan)
        while(1):
            try:
		current_trip_mA = float(raw.split()[-1].replace('-','e-').lstrip('e'))
                break
            except ValueError:
		raw = self.link.ask("LB"+self.chan)
	return str(current_trip_mA)

    # Write current trip on channel (Range: mA)
    @current_trip_mA.setter
    def current_trip_mA(self, cmd):
        ''' Input:  current trip (mA) on channel
            Output: return nothing, but sets the current trip (mA) on channel '''
        try:
            cmd = int(cmd)
        except ValueError:
            print "Invalid Current (mA) Trip Value: "+str(cmd)
        else:
            #print ("LB"+self.chan+"="+str(cmd))  #Uncomment for debug  
            self.link.cmd("LB"+self.chan+"="+str(cmd))

    # Read current trip on channel 
    # (trip corresponding resolution Range: uA>0) 
    @property
    def current_trip_uA(self):
        ''' Input:  None
            Output: current trip on channel (uA) '''
        #print ("LS"+self.chan)  #Uncomment for debug
        #self.link.ask_print("LS"+self.chan)  # Print Instrument's Resp
	raw = self.link.ask("LS"+self.chan)
        while(1):
            try:
		current_trip_uA = float(raw.split()[-1].replace('-','e-').lstrip('e'))
                break
            except ValueError:
		raw = self.link.ask("LS"+self.chan)
	return str(current_trip_uA)

    # Write current trip on channel (Range: uA)
    @current_trip_uA.setter
    def current_trip_uA(self, cmd):
        ''' Input:  current trip (uA) on channel
            Output: return nothing, but sets the current trip (uA) on channel '''
        try:
            cmd = int(cmd)
        except ValueError:
            print "Invalid Current (uA) Trip Value: "+str(cmd)
        else:
            #print ("LS"+self.chan+"="+str(cmd))  #Uncomment for debug  
            self.link.cmd("LS"+self.chan+"="+str(cmd))

    # Read auto start on channel
    # (conditions => Auto start)
    @property
    def auto_start(self):
	''' Input:  None
	    Output: return auto start status '''
        #print ("A"+self.chan)  #Uncomment for debug
        #self.link.ask_print("A"+self.chan)  # Print Instrument's Resp
        auto_start = self.link.ask("A"+self.chan).split()[-1].replace('-','e-').lstrip('e')
	return auto_start

    # Write auto start on channel 
    @auto_start.setter
    def auto_start(self, cmd):
        ''' Input:  auto start cmd
            Output: return nothing, but set auto start '''
        try:
            cmd = int(cmd)
        except ValueError:
            print "Invalid Auto Start Value: "+str(cmd)
        else:
            #print ("A"+self.chan+"="+str(cmd))  #Uncomment for debug 
            self.link.cmd("A"+self.chan+"="+str(cmd))

    # Read status information
    @property
    def status_word(self):
        ''' Input:  None
            Output: return status information '''
        #print ("S"+self.chan)  #Uncomment for debug
        #self.link.ask_print("S"+self.chan)  # Print Instrument's Resp
        status_word = self.link.ask("S"+self.chan).split()[-1]
	return status_word

    # Read module status information 
    # (code 0...255, => Module Status)
    @property
    def module_status(self):
        ''' Input:  None
            Output: return module status information '''
        #print ("T"+self.chan)  #Uncomment for debug
        #self.link.ask_print("T"+self.chan)  # Print Instrument's Resp
        module_status = self.link.ask("T"+self.chan).split()[-1].replace('-','e-').lstrip('e')
	return module_status



