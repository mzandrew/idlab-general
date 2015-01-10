#!/usr/bin/env python
#Following command will print documentation of iseg_SHQ226L.py:
#pydoc hvb_db_utility 

"""
AUTHORS:
Bronson Edralin <bedralin@hawaii.edu>
University of Hawaii at Manoa
Instrumentation Development Lab (IDLab), WAT214

OVERVIEW:
This is used to turn the relays off/on using the RPi's GPIO pins
"""


import RPi.GPIO as GPIO
import time

NO=False
YES=True
DELAY=1


# Getting rid of the RuntimeWarning: This channel is already in use, 
#continuing anyway.  Use GPIO.setwarnings(False) to disable warnings.
GPIO.setwarnings(False)

# GPIO.BOARD option specifies that you are referring to pins by the number
# of the pin the plug ex. See middle
GPIO.setmode(GPIO.BOARD)  

# GPIO.BCM option means that you are referring to pins by the
# "Broadcom SOC channel" number, these are the numbers after "GPIO"
# in the green rectangles around the outside of the diagrams
# Refer to http://raspberrypi.stackexchange.com/questions/12966/what-is-the-difference-between-board-and-bcm-for-gpio-pin-numbering
# GPIO.setmode(GPIO.BCM)


#GPIO.setmode(GPIO.BOARD) ## Use board pin numbering

# Declare outputs for GPIO Pins
GPIO.setup(12, GPIO.OUT)
GPIO.setup(15, GPIO.OUT)
GPIO.setup(16, GPIO.OUT)
GPIO.setup(18, GPIO.OUT)
GPIO.setup(22, GPIO.OUT)
GPIO.setup(13, GPIO.OUT)    
GPIO.setup(7, GPIO.OUT)
GPIO.setup(11, GPIO.OUT)

# 2nd Column of 5 LED lights left of board
def mux_relays(C,B,A):
    ''' Input:  C, B, A are strings '0'/'1'
	Output: returns nothing, but turns
		specified GPIO pins off/on '''
    # GPIO18 is Pin12
    # GPIO22 is Pin15
    # GPIO23 is Pin16
    #GPIO.setup(12, GPIO.OUT)
    #GPIO.setup(15, GPIO.OUT)
    #GPIO.setup(16, GPIO.OUT)

    GPIO.output(12, A)
    GPIO.output(15, B)
    GPIO.output(16, C)


def board_select(C,B,A):
    ''' Input:  C, B, A are strings '0'/'1'
        Output: returns nothing, but turns
                specified GPIO pins off/on '''
    # GPIO24 is Pin18
    # GPIO25 is Pin22
    # GPIO27 is Pin13
    #GPIO.setup(18, GPIO.OUT)
    #GPIO.setup(22, GPIO.OUT)
    #GPIO.setup(13, GPIO.OUT)

    GPIO.output(18, A)
    GPIO.output(22, B)
    GPIO.output(13, C)


# Far left 2 lights
def load_relays(B,A):
    ''' Input:  B, A are strings '0'/'1'
        Output: returns nothing, but turns
                specified GPIO pins off/on '''
    # GPIO4 is Pin7
    # GPIO17 is Pin11
    #GPIO.setup(7, GPIO.OUT)
    #GPIO.setup(11, GPIO.OUT)

    GPIO.output(7, A) 
    GPIO.output(11, B)


def invert_binary(state):
    ''' Input:  state is a tuple in binary
	Output: return inverted state as a tuple '''
    B = str(state[0])
    A = str(state[1])
    result = []
    if B == '0':
	result.append(int(B.replace("0","1")))
    else:
	result.append(int(B.replace("1","0")))
    if A == '0':
        result.append(int(A.replace("0","1")))
    else:
        result.append(int(A.replace("1","0")))
    return result

# This function is being used in hvb_assembly_test.py
def change_states(channel_addr,load_state,mux_state):
    ''' Input:  channel_addr = type is tuple, for board select
	        load_state = type is tuple, for load_relays
	        mux_state = type is tuple, for mux_relays	
	Output: return nothing, but changes states of GPIO '''

    # Beause logic for load relays are inverted on board
    load_state = invert_binary(load_state)

    # This is used to map the hardware logic to gpio logic 
    # for the GPIO pins.
    # Hardware Logic is: (K,MCPAT,MCPAB,MCPBT,MCPBB)
    # GPIO logic is: (PIN16,PIN15,PIN12) or (GPIO23,GPIO22,GPIO18)
    list_of_mux_state_addr =  {(0,0,0,0,1):(1,0,0),(0,0,0,1,0):(0,1,1),\
	(0,0,1,0,0):(0,1,0),(0,1,0,0,0):(0,0,1),(1,0,0,0,0):(0,0,0)}
    # Convert Hardware Logic to GPIO Logic
    mux_state_addr = list_of_mux_state_addr[mux_state]

    # This is used to select which board on the test board which
    # totals up to 8 boards associated with 8 channels for HVB assembly card
    # This is the logic to select Channel #1-8 or Test Board #1-8 (from top)
    # (0,0,0) = Channel #1 or Test Board #1
    # (0,0,1) = Channel #2 or Test Board #2
    # (0,1,0) = Channel #3 or Test Board #3
    # (0,1,1) = Channel #4 or Test Board #4
    # (1,0,0) = Channel #5 or Test Board #5
    # (1,0,1) = Channel #6 or Test Board #6
    # (1,1,0) = Channel #7 or Test Board #7
    # (1,1,1) = Channel #8 or Test Board #8
    board_select(channel_addr[0],channel_addr[1],channel_addr[2])
    
    # This is for the load relays with GPIO logic (0,0)
    load_relays(load_state[0],load_state[1])
    # Load up converted GPIO logic into mux relays for K, MCPAT, MCPAB, etc.
    mux_relays(mux_state_addr[0],mux_state_addr[1],mux_state_addr[2])

def reset_all_gpio():
    ''' Input:  nothing
	Output: return nothing, but resets all GPIO pins to 0 '''
    GPIO.output(12, 0)
    GPIO.output(15, 0)
    GPIO.output(16, 0)
    GPIO.output(18, 0)
    GPIO.output(22, 0)
    GPIO.output(13, 0)
    GPIO.output(7, 0)
    GPIO.output(11, 0)
