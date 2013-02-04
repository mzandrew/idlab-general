----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    09:57:12 05/23/2012 
-- Design Name: 
-- Module Name:    ASIC_TARGET4 - Behavioral 
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
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
--library UNISIM;
--use UNISIM.VComponents.all;

entity ASIC_TARGET4 is
	generic (
		constant BIT_WIDTH : integer := 363		--Total 363 bits for TARGET4 registers.
	);
	port (
		CLK 				:  in  	STD_LOGIC;
		RESET				:	IN		STD_LOGIC;
		UPDATE			:	IN		STD_LOGIC;
		IN_DATA			:	IN		STD_LOGIC_VECTOR(15 DOWNTO 0);
		Trig_thresh_1_ASIC	:	IN		STD_LOGIC_VECTOR(11 DOWNTO 0);
		Trig_thresh_2_ASIC	:	IN		STD_LOGIC_VECTOR(11 DOWNTO 0);
		Trig_thresh_3_ASIC	:	IN		STD_LOGIC_VECTOR(11 DOWNTO 0);
		Trig_thresh_4_ASIC	:	IN		STD_LOGIC_VECTOR(11 DOWNTO 0);
		Trig_thresh_5_ASIC	:	IN		STD_LOGIC_VECTOR(11 DOWNTO 0);
		Trig_thresh_6_ASIC	:	IN		STD_LOGIC_VECTOR(11 DOWNTO 0);
		Trig_thresh_7_ASIC	:	IN		STD_LOGIC_VECTOR(11 DOWNTO 0);
		Trig_thresh_8_ASIC	:	IN		STD_LOGIC_VECTOR(11 DOWNTO 0);
		Trig_thresh_9_ASIC	:	IN		STD_LOGIC_VECTOR(11 DOWNTO 0);
		Trig_thresh_10_ASIC	:	IN		STD_LOGIC_VECTOR(11 DOWNTO 0);
		Trig_thresh_11_ASIC	:	IN		STD_LOGIC_VECTOR(11 DOWNTO 0);
		Trig_thresh_12_ASIC	:	IN		STD_LOGIC_VECTOR(11 DOWNTO 0);
		Trig_thresh_13_ASIC	:	IN		STD_LOGIC_VECTOR(11 DOWNTO 0);
		Trig_thresh_14_ASIC	:	IN		STD_LOGIC_VECTOR(11 DOWNTO 0);
		Trig_thresh_15_ASIC	:	IN		STD_LOGIC_VECTOR(11 DOWNTO 0);
		Trig_thresh_16_ASIC	:	IN		STD_LOGIC_VECTOR(11 DOWNTO 0);
		SCLK 				:  out 	STD_LOGIC;
		SIN 				:  out 	STD_LOGIC;
		REGCLR			:	OUT	STD_LOGIC;
		PCLK 				:  out 	STD_LOGIC
	);
end ASIC_TARGET4;

architecture Behavioral of ASIC_TARGET4 is
	type STATE_TYPE is 
		(IDLE,
		LOAD_DAC,
		UPDATE_DACs
		);
	signal state 				: STATE_TYPE := IDLE;
	signal step_cnt			: std_logic_vector(1 downto 0);
	SIGNAL cnt					: integer := 0;	--count 363 bits when clocked in data serially
	signal REG_DATA			: STD_LOGIC_VECTOR(BIT_WIDTH-1 DOWNTO 0);
	signal check_IN_DATA		: STD_LOGIC;

	-----------------------TARGET4 internal DACs values-------------------------
	SIGNAL SGN_ASIC						: STD_LOGIC;
	SIGNAL Trig_type_ASIC				: STD_LOGIC;
	SIGNAL Wbias_ASIC						: STD_LOGIC_VECTOR(11 DOWNTO 0);
	SIGNAL TRGbias_ASIC					: STD_LOGIC_VECTOR(11 DOWNTO 0);
	SIGNAL Vbias_ASIC						: STD_LOGIC_VECTOR(11 DOWNTO 0);
	SIGNAL Vbuff_ASIC							: STD_LOGIC_VECTOR(11 DOWNTO 0);
	SIGNAL CMPbias_ASIC						: STD_LOGIC_VECTOR(11 DOWNTO 0);
	SIGNAL PUbias_ASIC						: STD_LOGIC_VECTOR(11 DOWNTO 0);
	SIGNAL VdlyN_ASIC							: STD_LOGIC_VECTOR(11 DOWNTO 0);
	SIGNAL VdlyP_ASIC							: STD_LOGIC_VECTOR(11 DOWNTO 0);
	SIGNAL MonTRGthresh_ASIC				: STD_LOGIC_VECTOR(11 DOWNTO 0);
	SIGNAL SST_SSP_out_ASIC					: STD_LOGIC;
	SIGNAL DBbias_ASIC						: STD_LOGIC_VECTOR(11 DOWNTO 0);
	SIGNAL SBbias_ASIC						: STD_LOGIC_VECTOR(11 DOWNTO 0);
	SIGNAL Isel_ASIC							: STD_LOGIC_VECTOR(11 DOWNTO 0);
	SIGNAL Vdischarge_ASIC					: STD_LOGIC_VECTOR(11 DOWNTO 0);
	SIGNAL Vdly_ASIC							: STD_LOGIC_VECTOR(11 DOWNTO 0);

begin

	--hardcoded settings for TARGET4 DACs
	Vbias_ASIC					<= x"FFC";
	Vbuff_ASIC					<= x"FFC";
	VdlyN_ASIC					<=	x"FFE"; --aka VadjN
	VdlyP_ASIC					<= x"FF7"; --aka VadjP
	SST_SSP_out_ASIC			<= '0'; --control signal on SSPout monitor pin
	
	REG_DATA	<= SGN_ASIC	& Trig_type_ASIC & Wbias_ASIC	& TRGbias_ASIC & Vbias_ASIC &			
		Trig_thresh_16_ASIC & Trig_thresh_15_ASIC & Trig_thresh_14_ASIC & Trig_thresh_13_ASIC &
		Trig_thresh_12_ASIC & Trig_thresh_11_ASIC & Trig_thresh_10_ASIC & Trig_thresh_9_ASIC &	
		Trig_thresh_8_ASIC & Trig_thresh_7_ASIC & Trig_thresh_6_ASIC & Trig_thresh_5_ASIC &	
		Trig_thresh_4_ASIC & Trig_thresh_3_ASIC & Trig_thresh_2_ASIC & Trig_thresh_1_ASIC &	
		Vbuff_ASIC & CMPbias_ASIC & PUbias_ASIC & VdlyN_ASIC & VdlyP_ASIC & MonTRGthresh_ASIC &
		SST_SSP_out_ASIC & DBbias_ASIC &	SBbias_ASIC	& Isel_ASIC & Vdischarge_ASIC & Vdly_ASIC;

	process (check_IN_DATA, RESET) is
	begin
	if (RESET = '1') then
		--set default values for configurable DACs
		CMPbias_ASIC				<= x"0FC"; --should be FFC?
		PUbias_ASIC					<=	x"007"; --previouly FFB, changed to 070
		DBbias_ASIC				   <= x"FFC";
		SBbias_ASIC					<=	x"0DE"; --was 076, changed to 00B
		Isel_ASIC					<=	x"FFE"; --003 = slow, changed to FFE = fast
		Vdischarge_ASIC			<= x"0C0"; --006 med, 00E is high, 0E0 low
		Vdly_ASIC					<= x"FFF"; --was FFF, tried FFE
		SGN_ASIC						<=	'0';
		Trig_type_ASIC				<=	'0';
		Wbias_ASIC					<= x"006";
		TRGbias_ASIC				<= x"006";
		MonTRGthresh_ASIC		   <= x"D06";
	elsif (check_IN_DATA'event and check_IN_DATA = '1') then	
		CASE IN_DATA(15 downto 12) IS
			WHEN "0000" =>
				CMPbias_ASIC				<= x"0FC"; --should be FFC?
				PUbias_ASIC					<=	x"007"; --previouly FFB, changed to 070
				DBbias_ASIC				   <= x"FFC";
				SBbias_ASIC					<=	x"0DE"; --was 076, changed to 00B
				Isel_ASIC					<=	x"FFE"; --003 = slow, changed to FFE = fast
				Vdischarge_ASIC			<= x"0C0"; --006 med, 00E is high, 0E0 low
				Vdly_ASIC					<= x"FFF"; --was FFF, tried FFE
				SGN_ASIC						<=	'0';
				Trig_type_ASIC				<=	'0';
				Wbias_ASIC					<= x"006";
				TRGbias_ASIC				<= x"006";
				MonTRGthresh_ASIC		   <= x"D06";
			WHEN "0001" =>
				Isel_ASIC <= IN_DATA(11 downto 0);
			WHEN "0010" =>
				Vdly_ASIC <= IN_DATA(11 downto 0);
			WHEN "0011" =>
				Vdischarge_ASIC <= IN_DATA(11 downto 0);
			WHEN "0100" =>
				CMPbias_ASIC <= IN_DATA(11 downto 0);
			WHEN "0101" =>
				PUbias_ASIC <= IN_DATA(11 downto 0);
			WHEN "0110" =>
				DBbias_ASIC <= IN_DATA(11 downto 0);
			WHEN "0111" =>
				SBbias_ASIC <= IN_DATA(11 downto 0);
			WHEN "1000" =>
				SGN_ASIC <= IN_DATA(0);
				Trig_type_ASIC <= IN_DATA(1);
			WHEN "1001" =>
				Wbias_ASIC <= IN_DATA(11 downto 0);
			WHEN "1010" =>
				TRGbias_ASIC <= IN_DATA(11 downto 0);
			WHEN "1011" =>
				MonTRGthresh_ASIC <= IN_DATA(11 downto 0);
			WHEN OTHERS =>
		END CASE;
	end if;
	end process;
	
	SERIAL_CONFIG_DAC_TARGET4 : PROCESS(CLK, RESET, UPDATE)
	BEGIN
		------------------------------------------------------------
		IF RESET = '1' THEN
			REGCLR	<= '1';	--RESET INTERNAL REGISTERS
			SCLK		<= '0';
			SIN		<= '0';
			PCLK 		<= '0';
			cnt 		<= 0;
			step_cnt <= "00";
			check_IN_DATA <= '0';
		ELSIF RISING_EDGE(CLK) THEN
			REGCLR	<= '0';
			------------------------------------------------------------
			CASE STATE IS
				--------------------------------
				WHEN IDLE =>
					SCLK		<= '0';
					SIN		<= '0';
					PCLK 		<= '0';
					cnt 		<= 0;
					step_cnt <= "00";
					if UPDATE = '1' then
						state <= LOAD_DAC;
						check_IN_DATA <= '1';
					else
						state <= IDLE;
						check_IN_DATA <= '0';
					end if;
				--------------------------------
				WHEN LOAD_DAC =>	--one clock cycle delay to allow DAC register settling
					state <= UPDATE_DACs;
				--------------------------------
				WHEN UPDATE_DACs =>
					check_IN_DATA <= '0';
					if cnt < BIT_WIDTH then
						if step_cnt = "00" then 
							SCLK <= '0';
							step_cnt <= "01";
						elsif step_cnt = "01" then
							SIN <= REG_DATA(cnt);	--SLB is sent first as "cnt" increasing.
							step_cnt <= "10";
						else
							SCLK <= '1';
							cnt <= cnt + 1;
							step_cnt <= "00";
						end if;
					else	--after 363 bits are clocked in
						SCLK <= '0';
						PCLK <= '1';	--update the actual control registers after all values have been serially loaded.
						state <= IDLE;
						cnt <= 0;
						step_cnt <= "00";
					end if;
				--------------------------------
				WHEN OTHERS =>
					state <= IDLE;
			END CASE;
			------------------------------------------------------------
		END IF;
		------------------------------------------------------------
	END PROCESS SERIAL_CONFIG_DAC_TARGET4;
	
end Behavioral;

