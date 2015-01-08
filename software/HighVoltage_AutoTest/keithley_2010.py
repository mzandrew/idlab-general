#!/usr/bin/env python
#Following command will print documentation of keithley_2010.py:
#pydoc keithley_2010 

"""
AUTHORS:
Bronson Edralin <bedralin@hawaii.edu>
University of Hawaii at Manoa
Instrumentation Development Lab (IDLab), WAT214

OVERVIEW:
Python wrapper for commands to control an Instrument called:
Keithley 2010 Multimeter
 
HOW TO USE:
"from keithley_2010.py import Keithley_2010" will import the class
"keithley = Keithley_2010(addr)" will create the instrument object
"keithley.channel = 2" will set channel to chan 2 (IMPORTANT: Set chan 1st)
"keithley.set_voltage = 5" will set voltage to 5 Volts on channel 2
"print keithley.set_voltage" will read the set voltage on chan 2

KEITHLEY 2010 MULTIMETER USER MANUAL:
http://exodus.poly.edu/~kurt/manuals/manuals/Keithley/KEI%202010%20User.pdf
"""

from link import *


class Keithley_2010(object):
    def __init__(self, addr=None,port=None):
        ''' Input:  addr is a string for RS232 or IP which is 192.168.#.#
            Output: returns nothing, but initializes connection  '''
        addr=addr.upper()
        #Set up link connection. Either RS232 via USB or GPIO via Ethernet
        if (addr == 'RS232') or (addr == 'RS-232'):
            self.link = RS232()
        elif (addr != None) and (port == None):
            self.link = Ethernet(addr)
	elif (addr != None) and (port != None):
	    self.link = Ethernet_Controller(addr,port)
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
            print "Invalid operation: "+cmd  # If Binary cmd was not on list
        else:
            #print cmd   # Uncomment for debug
            return cmd

    def reset(self):
        ''' Input:  None
            Output: return nothing, but resets settings '''
        self.link.cmd("*RST")
        #self.link.cmd("*CLS")

    # *IDN? - Identification Query: Read identification code
    def identification(self):
        ''' Input:  None
            Output: return identification of instrument '''
	return self.link.ask("*IDN?")

    def self_test_query(self):
        ''' Input:  None
            Output: return test query '''
	return self.link.ask("*TST?")

    def Check_Error(self):
        ''' Input:  None
            Output: return any existing error that is 
		    shown on lcd screen of instrument '''
	error_numb,error = self.link.ask("SYST:ERR?").split(',')
	print "checking for error"
	if (error_numb != "0") and (error_numb != "-420"):
	    print "Error has occured: "+error_numb+", "+error
	    return "Error has occured: "+error_numb+", "+error
	elif (error_numb == "-420" and error != '"Query UNTERMINATED"'):
            print "Error has occured: "+error_numb+", "+error
            return "Error has occured: "+error_numb+", "+error    
    # SCPI signal oriented measurement commands
    @property
    def configure(self):
        ''' Input:  None
            Output: return configuration '''
	return self.link.ask(":sens:func?")

    @configure.setter
    def configure(self,function):
	valid_set = {'CURRENT','VOLTAGE','RESISTANCE','FRESISTANCE',\
	'PERIOD','FREQUENCY','TEMPERATURE','DIODE','CONTINUITY'}
	function = function.upper()
	if function not in valid_set:
	    raise ValueError("Invalid Configuration")
	else:
	    self.link.cmd("CONFigure:"+function)	

    @property
    def configure_voltage(self):
        ''' Input:  None
            Output: return configuration setting, which is:
		    VOLT, CURR, etc.
		    AC, DC				    '''
        func,acdc=self.link.ask(":sens:func?").split(':')
	func = func.replace('"','')
	acdc = acdc.replace('"','')
	return func.replace("\n",""),acdc.replace("\n","")

    @configure_voltage.setter
    def configure_voltage(self,acdc='DC'):
        ''' Input:  acdc as DC or AC
            Output: return nothing, just set config to read
		    voltage in AC or DC		    '''
        valid_set = {'AC','DC'}
        acdc = acdc.upper()
        if (acdc not in valid_set):
            raise ValueError("Invalid Configuration of Voltage")
        else:
            self.link.cmd("CONFigure:VOLTage:"+acdc)   
 
    @property
    def configure_current(self):
        ''' Input:  None
            Output: return configuration setting, which is:
                    VOLT, CURR, etc.
                    AC, DC                                  '''
        func,acdc=self.link.ask(":sens:func?").split(':')
        return func.replace('"',''),acdc.replace('"','')

    @configure_current.setter
    def configure_current(self,acdc='DC'):
        ''' Input:  acdc as DC or AC
            Output: return nothing, just set config to read
                    current in AC or DC                   '''
        valid_set = {'AC','DC'}      
        acdc = acdc.upper()
        if (acdc not in valid_set):
            raise ValueError("Invalid Configuration of Current")
        else:
            self.link.cmd("CONFigure:CURRent:"+acdc)   

    @property
    def unit_voltage(self):
        ''' Input:  None
            Output: return units for voltage ''' 
        unit=self.link.ask(":UNIT:VOLTage?")
	unit=unit.replace("\n","")
	return unit
    @unit_voltage.setter
    def unit_voltage(self, unit='VPP'):
        ''' Input:  unit (VPP, VRMS or DBM)
            Output: return nothing, but sets units for voltage  ''' 
        valid_set = {'VPP','VRMS','DBM'}
        unit = unit.upper()
        if unit not in valid_set:
            raise ValueError("Invalid units for voltage")
        else:
            self.link.cmd("VOLTage:UNIT "+unit)

    @property
    def read_voltage(self):
        ''' Input:  None
            Output: return the read value, could be
		    in voltage or current. MAKE SURE 
		    CONFIGURATIONS ARE RIGHT BEFORE READING '''
	voltage = self.link.ask(":READ?").replace("\n","")
	return voltage

    @property
    def read_current(self):
        ''' Input:  None
            Output: return the read value, could be
                    in voltage or current. MAKE SURE 
                    CONFIGURATIONS ARE RIGHT BEFORE READING '''
        return self.link.ask(":READ?").replace("\n","")
