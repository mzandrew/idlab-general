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
--use ieee.std_logic_unsigned.all;
--library UNISIM;
--use UNISIM.VComponents.all;

entity ASIC_TARGET4_MOD is
	generic (
		constant BIT_WIDTH : integer := 363		--Total 363 bits for TARGET4 registers.
	);
	port (
		CLK 				:  in  	STD_LOGIC;
		LOAD_DACs_IN	:  IN		STD_LOGIC;
		UPDATE_DACS		:	IN		STD_LOGIC;
		UPDATE_REGS		:	IN		STD_LOGIC;
		UPDATE_REGS_NUMBER		:	IN		STD_LOGIC_VECTOR(15 DOWNTO 0);
		UPDATE_REGS_DATA			:	IN		STD_LOGIC_VECTOR(15 DOWNTO 0);
		UPDATE_REGS_CARRIER		:	IN		STD_LOGIC_VECTOR(15 DOWNTO 0);
		DAC_LOADING_PERIOD		:	IN		STD_LOGIC_VECTOR(15 DOWNTO 0);
		LOAD_DACs_DONE :  out 	STD_LOGIC;
		TRIG_TYPE_val  :  in 	STD_LOGIC;
		SCLK 				:  out 	STD_LOGIC;
		SIN 				:  out 	STD_LOGIC_VECTOR(9 downto 0);
		REGCLR			:	OUT	STD_LOGIC;
		PCLK 				:  out 	STD_LOGIC
	);
end ASIC_TARGET4_MOD;

architecture Behavioral of ASIC_TARGET4_MOD is
	type STATE_TYPE is 
		(IDLE,
		LOAD_DAC_LOW_WAIT0,
		LOAD_DAC_LOW,
		LOAD_DAC_LOW_WAIT1,
		LOAD_DAC_HIGH,
		LOAD_DAC_HIGH_WAIT0,
		LOAD_DAC_HIGH_WAIT1
		);
	signal state 				: STATE_TYPE := IDLE;
	SIGNAL cnt					: integer := 0;	--count 363 bits when clocked in data serially
	type RegDataWord is array( 0 to 9 ) of STD_LOGIC_VECTOR(BIT_WIDTH-1 DOWNTO 0);
	signal REG_DATA			: RegDataWord;
	SIGNAL anum					: integer := 0;
	signal LOAD_DACs		: STD_LOGIC;
	signal UPDATE_DACS_REG  : STD_LOGIC_VECTOR(1 downto 0);
	signal ENABLE_COUNTER : std_logic := '0';
	signal INTERNAL_COUNTER	: UNSIGNED(15 downto 0);
	signal PCLK_COUNTER	: UNSIGNED(15 downto 0);
	signal PCLK_START		: std_logic;
	-----------------------TARGET4 internal DACs values-------------------------
	type dacWord is array( 0 to 9 ) of std_logic_vector( 11 downto 0);
	SIGNAL SGN_ASIC						: STD_LOGIC_VECTOR(9 DOWNTO 0) := (others=>'0');
	SIGNAL Trig_type_ASIC				: STD_LOGIC_VECTOR(9 DOWNTO 0) := (others=>'0');
	SIGNAL Wbias_ASIC						: dacWord := (x"FDC",x"FDC",x"FDC",x"FDC",x"FDC",x"FDC",x"FDC",x"FDC",x"FDC",x"FDC");
	SIGNAL TRGbias_ASIC					: dacWord := (x"006",x"006",x"006",x"006",x"006",x"006",x"006",x"006",x"006",x"006");
	SIGNAL Vbias_ASIC						: dacWord := (x"FFC",x"FFC",x"FFC",x"FFC",x"FFC",x"FFC",x"FFC",x"FFC",x"FFC",x"FFC");
	SIGNAL Trig_thresh_16_ASIC			: dacWord := (x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000");
	SIGNAL Trig_thresh_15_ASIC			: dacWord := (x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000");
	SIGNAL Trig_thresh_14_ASIC			: dacWord := (x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000");
	SIGNAL Trig_thresh_13_ASIC			: dacWord := (x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000");
	SIGNAL Trig_thresh_12_ASIC			: dacWord := (x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000");
	SIGNAL Trig_thresh_11_ASIC			: dacWord := (x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000");
	SIGNAL Trig_thresh_10_ASIC			: dacWord := (x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000");
	SIGNAL Trig_thresh_9_ASIC			: dacWord := (x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000");
	SIGNAL Trig_thresh_8_ASIC			: dacWord := (x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000");
	SIGNAL Trig_thresh_7_ASIC			: dacWord := (x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000");
	SIGNAL Trig_thresh_6_ASIC			: dacWord := (x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000");
	SIGNAL Trig_thresh_5_ASIC			: dacWord := (x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000");
	SIGNAL Trig_thresh_4_ASIC			: dacWord := (x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000");
	SIGNAL Trig_thresh_3_ASIC			: dacWord := (x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000");
	SIGNAL Trig_thresh_2_ASIC			: dacWord := (x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000");
	SIGNAL Trig_thresh_1_ASIC			: dacWord := (x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000",x"000");
	SIGNAL Vbuff_ASIC						: dacWord := (x"FFC",x"FFC",x"FFC",x"FFC",x"FFC",x"FFC",x"FFC",x"FFC",x"FFC",x"FFC");
	SIGNAL CMPbias_ASIC					: dacWord := (x"0FC",x"0FC",x"0FC",x"0FC",x"0FC",x"0FC",x"0FC",x"0FC",x"0FC",x"0FC");
	SIGNAL PUbias_ASIC					: dacWord := (x"007",x"007",x"007",x"007",x"007",x"007",x"007",x"007",x"007",x"007");
	SIGNAL VdlyN_ASIC						: dacWord := (x"FFE",x"FFE",x"FFE",x"FFE",x"FFE",x"FFE",x"FFE",x"FFE",x"FFE",x"FFE");
	SIGNAL VdlyP_ASIC						: dacWord := (x"FF7",x"FF7",x"FF7",x"FF7",x"FF7",x"FF7",x"FF7",x"FF7",x"FF7",x"FF7");
	SIGNAL MonTRGthresh_ASIC			: dacWord := (x"D06",x"D06",x"D06",x"D06",x"D06",x"D06",x"D06",x"D06",x"D06",x"D06");
	SIGNAL SST_SSP_out_ASIC				: STD_LOGIC_VECTOR(9 DOWNTO 0) := (others=>'0');
	SIGNAL DBbias_ASIC					: dacWord := (x"FFC",x"FFC",x"FFC",x"FFC",x"FFC",x"FFC",x"FFC",x"FFC",x"FFC",x"FFC");
	SIGNAL SBbias_ASIC					: dacWord := (x"0DE",x"0DE",x"0DE",x"0DE",x"0DE",x"0DE",x"0DE",x"0DE",x"0DE",x"0DE");
	SIGNAL Isel_ASIC						: dacWord := (x"FFE",x"FFE",x"FFE",x"FFE",x"FFE",x"FFE",x"FFE",x"FFE",x"FFE",x"FFE");
	SIGNAL Vdischarge_ASIC				: dacWord := (x"0C0",x"0C0",x"0C0",x"0C0",x"0C0",x"0C0",x"0C0",x"0C0",x"0C0",x"0C0");
	SIGNAL Vdly_ASIC						: dacWord := (x"FFF",x"FFF",x"FFF",x"FFF",x"FFF",x"FFF",x"FFF",x"FFF",x"FFF",x"FFF");

begin
	
	gen_self_trig: for i in 0 to 9 generate
		REG_DATA(i)	<= SGN_ASIC(i)	& Trig_type_ASIC(i) & Wbias_ASIC(i)	& TRGbias_ASIC(i) & Vbias_ASIC(i) &			
		Trig_thresh_16_ASIC(i) & Trig_thresh_15_ASIC(i) & Trig_thresh_14_ASIC(i) & Trig_thresh_13_ASIC(i) &
		Trig_thresh_12_ASIC(i) & Trig_thresh_11_ASIC(i) & Trig_thresh_10_ASIC(i) & Trig_thresh_9_ASIC(i) &	
		Trig_thresh_8_ASIC(i) & Trig_thresh_7_ASIC(i) & Trig_thresh_6_ASIC(i) & Trig_thresh_5_ASIC(i) &	
		Trig_thresh_4_ASIC(i) & Trig_thresh_3_ASIC(i) & Trig_thresh_2_ASIC(i) & Trig_thresh_1_ASIC(i) &	
		Vbuff_ASIC(i) & CMPbias_ASIC(i) & PUbias_ASIC(i) & VdlyN_ASIC(i) & VdlyP_ASIC(i) & MonTRGthresh_ASIC(i) &
		SST_SSP_out_ASIC(i) & DBbias_ASIC(i) &	SBbias_ASIC(i)	& Isel_ASIC(i) & Vdischarge_ASIC(i) & Vdly_ASIC(i);
		--control trigger type
		Trig_type_ASIC(i) <= TRIG_TYPE_val;
	end generate;
	
	anum <= to_integer(unsigned( UPDATE_REGS_CARRIER(3 downto 0) ));

	--process updates DAC register values
	process (CLK) is
	begin
		if ( RISING_EDGE(CLK) ) then	
			if( UPDATE_REGS = '1' and anum < 10 ) then
				CASE UPDATE_REGS_NUMBER(15 downto 0) IS
					WHEN x"0000" => --load defaults
						SGN_ASIC(anum) <= '0';
						--Trig_type_ASIC <= '0';
						Wbias_ASIC(anum) <= x"FDC";
						TRGbias_ASIC(anum) <= x"006";
						Vbias_ASIC(anum) <= x"FFC";
						Trig_thresh_16_ASIC(anum) <= x"000";
						Trig_thresh_15_ASIC(anum) <= x"000";
						Trig_thresh_14_ASIC(anum) <= x"000";
						Trig_thresh_13_ASIC(anum) <= x"000";
						Trig_thresh_12_ASIC(anum) <= x"000";
						Trig_thresh_11_ASIC(anum) <= x"000";
						Trig_thresh_10_ASIC(anum) <= x"000";
						Trig_thresh_9_ASIC(anum) <= x"000";
						Trig_thresh_8_ASIC(anum) <= x"000";
						Trig_thresh_7_ASIC(anum) <= x"000";
						Trig_thresh_6_ASIC(anum) <= x"000";
						Trig_thresh_5_ASIC(anum) <= x"000";
						Trig_thresh_4_ASIC(anum) <= x"000";
						Trig_thresh_3_ASIC(anum) <= x"000";
						Trig_thresh_2_ASIC(anum) <= x"000";
						Trig_thresh_1_ASIC(anum) <= x"000";
						Vbuff_ASIC(anum) <= x"FFC";
						CMPbias_ASIC(anum) <= x"0FC";
						PUbias_ASIC(anum) <= x"007";
						VdlyN_ASIC(anum) <= x"FFE";
						VdlyP_ASIC(anum) <= x"FF7";
						MonTRGthresh_ASIC(anum) <= x"D06";
						SST_SSP_out_ASIC(anum) <= '0';
						DBbias_ASIC(anum) <=	x"FFC";
						SBbias_ASIC(anum) <=	x"0DE";
						Isel_ASIC(anum) <=	x"FFE";
						Vdischarge_ASIC(anum) <=	x"0C0";
						Vdly_ASIC(anum) <=	x"FFF";
					WHEN x"0001" =>
						SGN_ASIC(anum) <= UPDATE_REGS_DATA(0);
					WHEN x"0002" =>
						--Trig_type_ASIC <= UPDATE_REGS_DATA(0);
					WHEN x"0003" =>
						Wbias_ASIC(anum) <= UPDATE_REGS_DATA(11 downto 0);
					WHEN x"0004" =>
						TRGbias_ASIC(anum) <= UPDATE_REGS_DATA(11 downto 0);
					WHEN x"0005" =>
						Vbias_ASIC(anum) <= UPDATE_REGS_DATA(11 downto 0);
					WHEN x"0006" =>
						Trig_thresh_16_ASIC(anum) <= UPDATE_REGS_DATA(11 downto 0);
					WHEN x"0007" =>
						Trig_thresh_15_ASIC(anum) <= UPDATE_REGS_DATA(11 downto 0);
					WHEN x"0008" =>
						Trig_thresh_14_ASIC(anum) <= UPDATE_REGS_DATA(11 downto 0);
					WHEN x"0009" =>
						Trig_thresh_13_ASIC(anum) <= UPDATE_REGS_DATA(11 downto 0);
					WHEN x"000a" =>
						Trig_thresh_12_ASIC(anum) <= UPDATE_REGS_DATA(11 downto 0);
					WHEN x"000b" =>
						Trig_thresh_11_ASIC(anum) <= UPDATE_REGS_DATA(11 downto 0);
					WHEN x"000c" =>
						Trig_thresh_10_ASIC(anum) <= UPDATE_REGS_DATA(11 downto 0);
					WHEN x"000d" =>
						Trig_thresh_9_ASIC(anum) <= UPDATE_REGS_DATA(11 downto 0);
					WHEN x"000e" =>
						Trig_thresh_8_ASIC(anum) <= UPDATE_REGS_DATA(11 downto 0);
					WHEN x"000f" =>
						Trig_thresh_7_ASIC(anum) <= UPDATE_REGS_DATA(11 downto 0);
					WHEN x"0010" =>
						Trig_thresh_6_ASIC(anum) <= UPDATE_REGS_DATA(11 downto 0);
					WHEN x"0011" =>
						Trig_thresh_5_ASIC(anum) <= UPDATE_REGS_DATA(11 downto 0);
					WHEN x"0012" =>
						Trig_thresh_4_ASIC(anum) <= UPDATE_REGS_DATA(11 downto 0);
					WHEN x"0013" =>
						Trig_thresh_3_ASIC(anum) <= UPDATE_REGS_DATA(11 downto 0);
					WHEN x"0014" =>
						Trig_thresh_2_ASIC(anum) <= UPDATE_REGS_DATA(11 downto 0);
					WHEN x"0015" =>
						Trig_thresh_1_ASIC(anum) <= UPDATE_REGS_DATA(11 downto 0);
					WHEN x"0016" =>
						Vbuff_ASIC(anum) <= UPDATE_REGS_DATA(11 downto 0);
					WHEN x"0017" =>
						CMPbias_ASIC(anum) <= UPDATE_REGS_DATA(11 downto 0);
					WHEN x"0018" =>
						PUbias_ASIC(anum) <= UPDATE_REGS_DATA(11 downto 0);
					WHEN x"0019" =>
						VdlyN_ASIC(anum) <= UPDATE_REGS_DATA(11 downto 0);
					WHEN x"001a" =>
						VdlyP_ASIC(anum) <= UPDATE_REGS_DATA(11 downto 0);
					WHEN x"001b" =>
						MonTRGthresh_ASIC(anum) <= UPDATE_REGS_DATA(11 downto 0);
					WHEN x"001c" =>
						SST_SSP_out_ASIC(anum) <= UPDATE_REGS_DATA(0);
					WHEN x"001d" =>
						DBbias_ASIC(anum) <= UPDATE_REGS_DATA(11 downto 0);
					WHEN x"001e" =>
						SBbias_ASIC(anum) <=	UPDATE_REGS_DATA(11 downto 0);
					WHEN x"001f" =>
						Isel_ASIC(anum) <= UPDATE_REGS_DATA(11 downto 0);
					WHEN x"0020" =>
						Vdischarge_ASIC(anum) <= UPDATE_REGS_DATA(11 downto 0);
					WHEN x"0021" =>
						Vdly_ASIC(anum) <= UPDATE_REGS_DATA(11 downto 0);
					WHEN OTHERS =>
				END CASE;
			end if; --check update regs
		end if;
	end process;

	--Edge detector for key internal signals
	process (CLK) begin
		--The only other couple SST clock processes work on falling edges, so we should be consistent here
		if (falling_edge(CLK)) then	
			UPDATE_DACS_REG(1) <= UPDATE_DACS_REG(0);
			UPDATE_DACS_REG(0) <= UPDATE_DACS;
		end if;
	end process;
	PCLK_START <= '1' when (UPDATE_DACS_REG = "01") else
	                    '0';

	process (CLK) begin
		if( PCLK_START = '0' ) then
			PCLK_COUNTER <= x"0000";
			PCLK <= '0';
		else
			if(rising_edge(CLK)) then
				if( PCLK_COUNTER = x"0008" ) then
					PCLK_COUNTER <= PCLK_COUNTER;
					PCLK <= '0';
				else
					PCLK_COUNTER <= PCLK_COUNTER + x"0001";
					PCLK <= '1';
				end if;
			end if;
		end if;
	end process;

	--SYNC
	SYNC_PROC: process (CLK)
   begin
		--The only other couple SST clock processes work on falling edges, so we should be consistent here
		if (rising_edge(CLK)) then	
			LOAD_DACs <= LOAD_DACs_IN;
		end if;
	end process;
	
	--counter process
	process (CLK) begin
		if (rising_edge(CLK)) then
			if ENABLE_COUNTER = '1' then
				INTERNAL_COUNTER <= INTERNAL_COUNTER + 1;
			else
				INTERNAL_COUNTER <= (others=>'0');
			end if;
		end if;
	end process;
	
	--process to load DACs to ASIC
	SERIAL_CONFIG_DAC_TARGET4 : PROCESS(CLK)
	BEGIN
		------------------------------------------------------------
		IF RISING_EDGE(CLK) THEN
			REGCLR	<= '0';
			------------------------------------------------------------
			CASE STATE IS
				--------------------------------
				WHEN IDLE =>
					SCLK		<= '0';
					SIN	<= (others=>'0');
					cnt 		<= 0;
					ENABLE_COUNTER <= '0';
					if LOAD_DACs = '1' then
						state <= LOAD_DAC_LOW_WAIT0;
						LOAD_DACs_DONE <= '0';
					else
						state <= IDLE;
						LOAD_DACs_DONE <= '1';
					end if;
				--------------------------------
				
				WHEN LOAD_DAC_LOW_WAIT0 =>
					SCLK <= '0';
					ENABLE_COUNTER <= '1';
					state <= LOAD_DAC_LOW_WAIT0;
					if INTERNAL_COUNTER > UNSIGNED(DAC_LOADING_PERIOD) then
						ENABLE_COUNTER <= '0';
						state <= LOAD_DAC_LOW;
					end if;
				
				WHEN LOAD_DAC_LOW =>
					SCLK <= '0';
					ENABLE_COUNTER <= '0';
					if cnt < BIT_WIDTH then
						state <= LOAD_DAC_LOW_WAIT1;
						SIN(0) <= REG_DATA(0)(cnt);	--SLB is sent first as "cnt" increasing.
						SIN(1) <= REG_DATA(1)(cnt);	--SLB is sent first as "cnt" increasing.
						SIN(2) <= REG_DATA(2)(cnt);	--SLB is sent first as "cnt" increasing.
						SIN(3) <= REG_DATA(3)(cnt);	--SLB is sent first as "cnt" increasing.
						SIN(4) <= REG_DATA(4)(cnt);	--SLB is sent first as "cnt" increasing.
						SIN(5) <= REG_DATA(5)(cnt);	--SLB is sent first as "cnt" increasing.
						SIN(6) <= REG_DATA(6)(cnt);	--SLB is sent first as "cnt" increasing.
						SIN(7) <= REG_DATA(7)(cnt);	--SLB is sent first as "cnt" increasing.
						SIN(8) <= REG_DATA(8)(cnt);	--SLB is sent first as "cnt" increasing.
						SIN(9) <= REG_DATA(9)(cnt);	--SLB is sent first as "cnt" increasing.
					else	--after 363 bits are clocked in						
						state <= IDLE;
						cnt <= 0;
						LOAD_DACs_DONE <= '1';
					end if;
					
				WHEN LOAD_DAC_LOW_WAIT1 =>
					SCLK <= '0';
					ENABLE_COUNTER <= '1';
					state <= LOAD_DAC_LOW_WAIT1;
					if INTERNAL_COUNTER > UNSIGNED(DAC_LOADING_PERIOD) then
						ENABLE_COUNTER <= '0';
						state <= LOAD_DAC_HIGH;
					end if;
					
				WHEN LOAD_DAC_HIGH =>
					SCLK <= '1';
					ENABLE_COUNTER <= '0';
					state <= LOAD_DAC_HIGH_WAIT0;
					cnt <= cnt + 1;
					
				WHEN LOAD_DAC_HIGH_WAIT0 =>
					SCLK <= '1';
					ENABLE_COUNTER <= '1';
					state <= LOAD_DAC_HIGH_WAIT0;
					if INTERNAL_COUNTER > UNSIGNED(DAC_LOADING_PERIOD) + UNSIGNED(DAC_LOADING_PERIOD) then
						ENABLE_COUNTER <= '0';
						state <= LOAD_DAC_HIGH_WAIT1;
					end if;	
					
				WHEN LOAD_DAC_HIGH_WAIT1 =>
					SCLK <= '1';
					ENABLE_COUNTER <= '0';
					state <= LOAD_DAC_LOW_WAIT0;
					
				--------------------------------
				WHEN OTHERS =>
					state <= IDLE;
			END CASE;
			------------------------------------------------------------
		END IF;
		------------------------------------------------------------
	END PROCESS SERIAL_CONFIG_DAC_TARGET4;
	
end Behavioral;

