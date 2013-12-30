--
--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 
--
--   To use any of the example code shown below, uncomment the lines and modify as necessary
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;

package readout_definitions is
	--General purpose registers (GPR) are outputs from this block, and are also
	--routed back to the inputs 
	------------------------------------------------
	--ERROR:Pack:2310 - Too many comps of type "SLICEL" found to fit this device(SPARTAN3).
	--constant N_GPR : integer := 256;	--Not enough slices for Univ Eval revB
	------------------------------------------------		
	constant N_GPR : integer := 64;
	--Read registers (RR) are inputs to the command interpreter
	--The first N_GPR of these are directly connected to the general
	--purpose registers to allow readback of any values.
	--This means N_RR should be >= N_GPR.
	--constant N_RR  : integer := 260;
	constant N_RR  : integer := 70;
	--Widths of both of these types of registers are set to 16 bits.
	type GPR is array(N_GPR-1 downto 0) of std_logic_vector(15 downto 0);
	type RR is array(N_RR-1 downto 0) of std_logic_vector(15 downto 0);
end readout_definitions;

package body readout_definitions is
--Nothing in the body 
end readout_definitions;
