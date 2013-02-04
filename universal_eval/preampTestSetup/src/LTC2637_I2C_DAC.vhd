----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:38:07 11/06/2012 
-- Design Name: 
-- Module Name:    LTC2637-I2C-DAC - Behavioral 
-- Project Name: 
-- Target Devices: 
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

entity LTC2637_I2C_DAC is
	generic (
		constant BIT_WIDTH : integer := 8		--DEFAULT: ONE BYTE
			);
	port (
		CLK				: IN		STD_LOGIC;
		RST				: IN		STD_LOGIC;
						
		SCL				: INOUT	STD_LOGIC;
		SDA				: INOUT	STD_LOGIC;
		
		UPDATE			: IN STD_LOGIC;
		
		DAC_ADDRESS		: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
		DAC_COMMAND			: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
		DAC_VALUE		: IN	STD_LOGIC_VECTOR(11 DOWNTO 0);
			
		UPDATE_DONE		: OUT STD_LOGIC
			);
	
end LTC2637_I2C_DAC;

architecture Behavioral of LTC2637_I2C_DAC is
--------------------------SIGNAL---------------------------------
	type I2C_STATE_TYPE is 
		(	
			
			st_start,			
			st_write_byte,	
			st_check_state,
			st_idle,
				
			st_wait_for_ack,
					
			st_stop				
		);
		
	type SUB_STATE_TYPE is 
		(	subst_slave_address,
			subst_1st_data_byte,
			subst_2nd_data_byte,
			subst_3rd_data_byte,
			subst_stop			
		);

	signal state      		: I2C_STATE_TYPE := st_check_state;
	signal sub_state			: SUB_STATE_TYPE := subst_stop;
	------------------------------------------------------------------
begin
	
	LTC2637_DAC : PROCESS (RST,CLK) 
	--=============================================================================
	
		
		constant W_BAR							: STD_LOGIC := '0';
		----------------------------------------------------------------
		VARIABLE CHIP_ADDRESS				: STD_LOGIC_VECTOR(6 DOWNTO 0) := "0010000";
--		VARIABLE i_DAC_ADDRESS					: STD_LOGIC_VECTOR(3 DOWNTO 0) := ALL_DACs;	--Default: all DACs.
--		VARIABLE i_DAC_COMMOND					: STD_LOGIC_VECTOR(3 DOWNTO 0) := No_Operation;
--		-------------------------------------------------------------------------
--		--Command codes
--		constant NoOperation				: std_logic_vector(3 downto 0) := "1111";
--		constant WriteReg					: std_logic_vector(3 downto 0) := "0000";
--		constant UpdateReg				: std_logic_vector(3 downto 0) := "0001";
--		constant WriteUpdateAll			: std_logic_vector(3 downto 0) := "0010";
--		constant WriteUpdateSingle		: std_logic_vector(3 downto 0) := "0011";
--		constant PowerDownSingle		: std_logic_vector(3 downto 0) := "0100";
--		constant PowerDownChip			: std_logic_vector(3 downto 0) := "0101";
--		-------------------------------------------------------------------------
--		--Address codes no shown are reserved and should not be used.
--		constant DAC_A						: std_logic_vector(3 downto 0) := "0000";
--		constant DAC_B						: std_logic_vector(3 downto 0) := "0001";
--		constant DAC_C						: std_logic_vector(3 downto 0) := "0010";
--		constant DAC_D						: std_logic_vector(3 downto 0) := "0011";
--		constant DAC_E						: std_logic_vector(3 downto 0) := "0100";
--		constant DAC_F						: std_logic_vector(3 downto 0) := "0101";
--		constant DAC_G						: std_logic_vector(3 downto 0) := "0110";
--		constant DAC_H						: std_logic_vector(3 downto 0) := "0111";
--		constant ALL_DACs					: std_logic_vector(3 downto 0) := "1111";
	--=============================================================================
		-------------------------------------------------------------------------------
		
		variable step_counter					: unsigned(1 downto 0) 	:= "00";
		variable bit_counter						: integer range 0 to BIT_WIDTH  := 0;
		--number of cycles will wait for the 'ACK' from slave
		variable wait_counter					: integer range 0 to 255 := 0;
		variable data_to_write_byte			: std_logic_vector(7 downto 0);
		-------------------------------------------------------------------------------
	BEGIN
		IF RST = '1' THEN
			step_counter	:= "00";
			bit_counter		:= 0;
			wait_counter	:= 0;
			SCL <= '1';
			SDA <= '1';
			state <= st_idle;
			sub_state <= subst_stop;
			UPDATE_DONE <= '0';
		ELSIF rising_edge(CLK) THEN
			CASE state IS
			WHEN st_idle =>
				SCL <= '1';
				SDA <= '1';
				UPDATE_DONE <= '0';
				if UPDATE = '1'  then
					state <= st_check_state;
					sub_state <= subst_slave_address;
				end if; 
			
			WHEN st_check_state =>
				case sub_state is
				when subst_slave_address =>
					data_to_write_byte := CHIP_ADDRESS & w_bar;
					state <= st_start;
					sub_state <= subst_1st_data_byte;
				when subst_1st_data_byte =>
					data_to_write_byte := DAC_COMMAND & DAC_ADDRESS;
					state <= st_write_byte;
					sub_state <= subst_2nd_data_byte;
				when subst_2nd_data_byte =>
					data_to_write_byte := DAC_VALUE(11 DOWNTO 4);
					state <= st_write_byte;
					sub_state <= subst_3rd_data_byte;
				when subst_3rd_data_byte =>
					data_to_write_byte := DAC_VALUE(3 DOWNTO 0) & "0000";
					state <= st_write_byte;
					sub_state <= subst_stop;
				when subst_stop =>
					state <= st_stop;
				when others =>
					state <= st_stop;
				
				end case;
			
			WHEN st_start =>
				if (step_counter = 0) then		
					SCL <= '1';
					step_counter := step_counter + 1;
				elsif (step_counter = 1) then
					SDA <= '1';
					step_counter := step_counter + 1;
				elsif (step_counter = 2) then
					SCL <= '1';
					step_counter := step_counter + 1;
				else
					SDA <= '0';
					step_counter := "00";
					bit_counter := 0;
					state <= st_write_byte;
					
				end if;	
			
			WHEN st_write_byte =>
				if bit_counter < BIT_WIDTH then   
					if step_counter = 0 then 
						SCL <= '0';
						step_counter := step_counter + 1;
					elsif step_counter = 1 then
								SDA <= data_to_write_byte(7 - bit_counter);
								step_counter := step_counter + 1;
					elsif step_counter = 2 then
								SCL <= '1';
								bit_counter := bit_counter + 1;
								step_counter := "00";
					end if;
				else   --after 1 byte is sent
					bit_counter := 0;
					state <= st_wait_for_ack;
						
				end if;
			
			WHEN st_wait_for_ack =>
				if step_counter = 0 then
					SCL <= '0';
					step_counter := step_counter + 1;
				elsif step_counter = 1 then
					SDA <= 'Z';
					step_counter := step_counter + 1;
				elsif step_counter = 2 then
					SCL <= '1';
					step_counter := step_counter + 1;
				elsif step_counter = 3 then
					if SDA = '0' then
							step_counter := "00";
							state <= st_check_state;
					else
						wait_counter := wait_counter + 1;
						if wait_counter > 200 then		--wait 200 cycles if not receiving 'ack' from slave
							
								step_counter := "00";
								wait_counter := 0;
								state <= st_stop;
							
						end if;
					end if;
				end if;
			
			WHEN st_stop =>
				if step_counter = 0 then
					SDA <= '0';
					SCL <= '0';
					step_counter := step_counter + 1;
				elsif step_counter = 1 then
					SDA <= '0';
					SCL <= '0';
					step_counter := step_counter + 1;
				elsif step_counter = 2 then
					SDA <= '0';
					SCL <= '1';
					step_counter := step_counter + 1;
				else
					if( UPDATE = '0') then
						SDA <= '1';
						step_counter := "00";
						UPDATE_DONE <= '0';
						state <= st_idle;
					else
						UPDATE_DONE <= '1';
					end if;
				end if;
			WHEN others =>
				state <= st_idle;
			
			END CASE;
				
		
		
		END IF;
	
	END PROCESS LTC2637_DAC;

end Behavioral;

