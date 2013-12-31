Software and Firmware for TARGET6 Daughter Card on Universal Eval
2013/12/30

The firmware project file is "ise-project/USB_and_fiber_readout.xise". It was successfully compiled with Xilinx ISE 13.2.

Please note the file "kcpsm3.vhdl" must be placed in the directory "src/picoblaze/command_interpreter". This file is not included in the repository for copyright reasons, but can be obtained through the Xilinx website (details to be added).

The software required to interface with the command interpreter through the USB connection is contained in the "usbInterface" directory. Please read the "README" file in that directory for instructions on how to compile and use it.