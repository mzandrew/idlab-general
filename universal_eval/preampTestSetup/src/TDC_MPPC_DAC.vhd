----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:36:01 10/11/2012 
-- Design Name: 
-- Module Name:    TDC_MPPC_DAC - Behavioral 
-- Project Name: 
-- Target Devices:   MAX5258(8-bit DAC)
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity TDC_MPPC_DAC is
generic (
		CONSTANT MPPC_DACs_VALUE_WIDTH : integer := 32		--two MAX5258(8-bit DAC) in daisy-chain. 32 bit in total.
			);
	port (
		CLK			: IN STD_LOGIC;
		RESET			: IN STD_LOGIC;
		
		ADDR_MPPC_DAC				: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
		VALUE_MPPC_DAC				: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		ALL_OR_SINGLE_MPPC_DAC	: IN STD_LOGIC;	--ALL DACs: HIGH; SINGLE DAC: LOW.
		UPDATE_MPPC_DAC			: IN STD_LOGIC;
	
		
		SCK_DAC			: OUT	STD_LOGIC;
		DIN_DAC			: OUT STD_LOGIC;
		CS_DAC			: OUT STD_LOGIC;	--active low!!
				
		UPDATE_MPPCDAC_DONE			: OUT STD_LOGIC
	);

end TDC_MPPC_DAC;

architecture Behavioral of TDC_MPPC_DAC is

type STATE_TYPE is 
		(IDLE,
		WAIT_CS,
		UPDATE_DACs,
		WAIT_UPDATE
		);
		
type SUB_STATE_TYPE is 
		(SET_UPDATE_MODE,
		SET_SCK_DAC_LOW,
		SET_DIN_DAC_INPUT,
		SET_SCK_DAC_HIGH
		);	
		
signal state 				: STATE_TYPE := IDLE;
SIGNAL UPDATE_DACs_STATE : SUB_STATE_TYPE := SET_UPDATE_MODE;
SIGNAL bit_counter			: integer range 0 to MPPC_DACs_VALUE_WIDTH := 0;	
		
		
		
begin

SERIAL_CONFIG_MPPC_DAC : PROCESS(CLK, RESET, UPDATE_MPPC_DAC)
	variable bit_counter : integer range 0 to MPPC_DACs_VALUE_WIDTH := 0;

	variable mppc_dac_shift_in_data : std_logic_vector(MPPC_DACs_VALUE_WIDTH-1 downto 0);
	variable dac_output_address : integer range 0 to 15 := 0;
	
	----------------CONTROL BITS(MAX5258)------------------------------------
	CONSTANT UPDATE_ALL_OUTPUT 		: STD_LOGIC_VECTOR(2 DOWNTO 0) := "100";
	CONSTANT UPDATE_SINGLE_OUTPUT 	: STD_LOGIC_VECTOR(2 DOWNTO 0) := "110";
	CONSTANT NO_OPERATION			 	: STD_LOGIC_VECTOR(2 DOWNTO 0) := "000";
	CONSTANT CLEAR_ALL_OUTPUT			: STD_LOGIC_VECTOR(2 DOWNTO 0) := "001";
	-------------------------------------------------------------------------
	BEGIN
		------------------------------------------------------------
		IF RESET = '1' THEN
			
			--STATE		<= IDLE;
			--UPDATE_DACs_STATE  <= SET_UPDATE_MODE;
			
			SCK_DAC		<= '0';
			DIN_DAC		<= '0';
			CS_DAC 		<= '1';
			
			bit_counter := 0;
			
			mppc_dac_shift_in_data(10 downto 8) := CLEAR_ALL_OUTPUT;
			mppc_dac_shift_in_data(26 downto 24) := CLEAR_ALL_OUTPUT;
			state <= WAIT_CS;
			UPDATE_DACs_STATE <= SET_SCK_DAC_LOW;
			
			UPDATE_MPPCDAC_DONE <= '0';
			
		ELSIF RISING_EDGE(CLK) THEN
			CASE STATE IS
				--------------------------------
				WHEN IDLE =>
					SCK_DAC		<= '0';
					DIN_DAC		<= '0';
					CS_DAC 		<= '1';
					bit_counter := 0;
					UPDATE_MPPCDAC_DONE <= '0';

					
					if UPDATE_MPPC_DAC = '1' then
						CS_DAC <= '0';
						state <= WAIT_CS;
						UPDATE_DACs_STATE <= SET_UPDATE_MODE;
					else
						CS_DAC <= '1';
						state <= IDLE;
					end if;
				--------------------------------
				
				WHEN WAIT_CS =>
					CS_DAC <= '0';
					state <= UPDATE_DACs;
					
				WHEN UPDATE_DACs =>
					if bit_counter < MPPC_DACs_VALUE_WIDTH then
						CASE UPDATE_DACs_STATE IS
							WHEN SET_UPDATE_MODE =>
								IF ALL_OR_SINGLE_MPPC_DAC = '1' THEN
										--update all DAC outputs when it's '1', update single DAC output when it's '0'
										mppc_dac_shift_in_data(10 downto 8) := UPDATE_ALL_OUTPUT;	--control bits for the first chip(update all DACs output with the same value)
										mppc_dac_shift_in_data(26 downto 24) := UPDATE_ALL_OUTPUT;	--control bits for the second chip						
								ELSE	--single update
										dac_output_address := to_integer(unsigned(ADDR_MPPC_DAC));
										--> (DIN) ||firt chip 16 bits|| (DOUT)-->(DIN) ||second chip 16 bits||   
										--notes: MSB first. mppc_dac_shift_in_data(15 downto 0) will be the first chip. DAC1 to DAC8.
										if dac_output_address <= 7 then	----Output address for fist chip (DC8 -- DC1). Daisy-chain. 
											mppc_dac_shift_in_data(13 downto 11) := std_logic_vector(to_unsigned(dac_output_address, 3));	--address bits
											
											mppc_dac_shift_in_data(10 downto 8) := UPDATE_SINGLE_OUTPUT;	--for the first chip
											mppc_dac_shift_in_data(26 downto 24) := NO_OPERATION;	--for the second chip
										else	--Output address for second chip (DC16 -- DC9)
											
											mppc_dac_shift_in_data(29 downto 27) := std_logic_vector(to_unsigned(dac_output_address-8, 3));
											mppc_dac_shift_in_data(10 downto 8) := NO_OPERATION;	
											mppc_dac_shift_in_data(26 downto 24) := UPDATE_SINGLE_OUTPUT;
										end if;
									
								END IF;
								mppc_dac_shift_in_data(7 downto 0) := VALUE_MPPC_DAC;
								mppc_dac_shift_in_data(23 downto 16) := VALUE_MPPC_DAC;
							
								UPDATE_DACs_STATE <= SET_SCK_DAC_LOW;
								
							WHEN SET_SCK_DAC_LOW =>
								SCK_DAC <= '0';
								UPDATE_DACs_STATE <= SET_DIN_DAC_INPUT;
								
							WHEN SET_DIN_DAC_INPUT =>
								DIN_DAC <= mppc_dac_shift_in_data(MPPC_DACs_VALUE_WIDTH-1-bit_counter);		--start from the MSB
								UPDATE_DACs_STATE <= SET_SCK_DAC_HIGH;
								
							WHEN SET_SCK_DAC_HIGH =>
								SCK_DAC <= '1';
								bit_counter := bit_counter + 1;
								UPDATE_DACs_STATE <= SET_SCK_DAC_LOW;
								
							WHEN OTHERS =>
								UPDATE_DACs_STATE <= SET_SCK_DAC_LOW;								
						END CASE;
					else	--after 32 bits are shifted in
						SCK_DAC <= '0';
						bit_counter := 0;
						CS_DAC <= '1';
						
						STATE <= WAIT_UPDATE;
					end if;
				--------------------------------
				WHEN WAIT_UPDATE =>
				UPDATE_MPPCDAC_DONE <= '1';
				if UPDATE_MPPC_DAC = '0' then
					STATE <= IDLE;
				else
					STATE <= WAIT_UPDATE;
				end if;
				
				WHEN OTHERS =>
					STATE <= IDLE;
			END CASE;
			------------------------------------------------------------
		END IF;
		------------------------------------------------------------
	
	END PROCESS SERIAL_CONFIG_MPPC_DAC;

end Behavioral;

