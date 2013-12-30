----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    06:01:47 11/08/2012 
-- Design Name: 
-- Module Name:    TargetSignals - Behavioral 
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
library UNISIM;
use UNISIM.VComponents.all;

entity TargetSignals is
    Port ( system_40MHz_clk : in  STD_LOGIC;
           system_150MHz_clk : in  STD_LOGIC;
			  system_150MHz_clk_div2 : in  STD_LOGIC;
           usb_clk : in  STD_LOGIC;
			  SMA_CONN : out STD_LOGIC;
           rst : in  STD_LOGIC;
           fifo_wr_en : out  STD_LOGIC;
           fifo_wr_clk : out  STD_LOGIC;
           fifo_wr_din : out  STD_LOGIC_VECTOR (31 downto 0);
           fifo_rd_empty : in  STD_LOGIC;
           fifo_rd_en : out  STD_LOGIC;
           fifo_rd_clk : out  STD_LOGIC;
           fifo_rd_dout : in  STD_LOGIC_VECTOR (31 downto 0);
			  --DAC_MON
			  SCK_DAC			: OUT	STD_LOGIC;
			  DIN_DAC			: OUT STD_LOGIC;
		     CS_DAC			: OUT STD_LOGIC;	--active low!!
           --mon : out  STD_LOGIC_VECTOR (15 downto 0);
			  mon : inout  STD_LOGIC_VECTOR (15 downto 0);
           sclk : out  STD_LOGIC;
           sin : out  STD_LOGIC;
           regclr : out  STD_LOGIC;
           pclk : out  STD_LOGIC;
			  TST_START		:	OUT STD_LOGIC;
			  TST_BOIN_CLR	:	OUT STD_LOGIC;
			  SSTIN				:	OUT STD_LOGIC;
			  SSPIN				:	OUT STD_LOGIC;
			  WR_ADVCLK		:	OUT STD_LOGIC;
			  WR_ADDRCLR		:	OUT STD_LOGIC;
			  WR_ENA			:	OUT STD_LOGIC;
			  WR_STRB			:	OUT STD_LOGIC;
			  --START				:	OUT STD_LOGIC;		--start Wilkinson Conversion
			  --RAMP				:	OUT STD_LOGIC;
			  STARTRAMP				:	OUT STD_LOGIC;		--start Wilkinson Conversion
			  RD_ENA			:	OUT STD_LOGIC;
			  RD_ROWSEL		:	OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
			  RD_COLSEL		:	OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
			  CLR				:	OUT STD_LOGIC;		--Clear Wilkinson Counter
			  SR_SEL			:	OUT STD_LOGIC;
			  SR_CLOCK			:	OUT STD_LOGIC;
			  SR_CLEAR			:	OUT STD_LOGIC;
			  DO					:	IN		STD_LOGIC_VECTOR(15 DOWNTO 0);
			  SAMPLESEL		:	OUT STD_LOGIC_VECTOR(5 DOWNTO 1);
			  SAMPLESEL_ANY	:	OUT STD_LOGIC;
			  TRG_16				:	IN		STD_LOGIC;
			  TRG					:	IN		STD_LOGIC_VECTOR(4 DOWNTO 1);
			  TRGIN				:	out		STD_LOGIC;	--PULSE IN
			  TRGMON				:	IN		STD_LOGIC
			  );
end TargetSignals;

architecture Behavioral of TargetSignals is
	
	--FIFO captured word
	signal MON_usb_test : STD_LOGIC_VECTOR(31 downto 0);

	--Control word related signals
	signal tempState0 : STD_LOGIC;
	signal tempPulse0 : STD_LOGIC;
	signal tempState1 : STD_LOGIC;
	signal tempPulse1 : STD_LOGIC;
	signal tempState2 : STD_LOGIC;
	signal tempPulse2 : STD_LOGIC;
	signal tempState3 : STD_LOGIC;
	signal tempPulse3 : STD_LOGIC;
	signal tempState4 : STD_LOGIC;
	signal tempPulse4 : STD_LOGIC;	
	signal tempState5 : STD_LOGIC;
	signal tempPulse5 : STD_LOGIC;
	signal tempState6 : STD_LOGIC;
	signal tempPulse6 : STD_LOGIC;
	signal TRIG_DATA : STD_LOGIC_VECTOR(15 DOWNTO 0);
	signal CHAN_DATA : STD_LOGIC_VECTOR(15 DOWNTO 0);
	signal DAC_DATA : STD_LOGIC_VECTOR(15 DOWNTO 0);
	signal PIN_DATA : STD_LOGIC_VECTOR(15 DOWNTO 0);
	signal I2C_DATA : STD_LOGIC_VECTOR(15 DOWNTO 0);
	signal MPPCDAC_DATA : STD_LOGIC_VECTOR(15 DOWNTO 0);

	--i2c signals
	signal SCL_out : STD_LOGIC;
	signal SDA_out : STD_LOGIC;
	signal DAC_VALUE_in : STD_LOGIC_VECTOR(11 DOWNTO 0);
	signal clk_counter : UNSIGNED(7 DOWNTO 0);
	signal UPDATE : STD_LOGIC;
	signal UPDATE_DONE: STD_LOGIC;
	signal UPDATE_MPPCDAC : STD_LOGIC;
	signal UPDATE_MPPCDAC_DONE: STD_LOGIC;

	--readout signals related signals
	signal dig_offset : std_logic_vector(11 DOWNTO 0);
	signal ramp_length : STD_LOGIC_VECTOR(11 DOWNTO 0);
	signal trig_delay : STD_LOGIC_VECTOR(11 DOWNTO 0);
	signal samp_delay : STD_LOGIC_VECTOR(11 DOWNTO 0);
	signal trigControl : STD_LOGIC_VECTOR(11 downto 0);
	signal STOP_SMP_out : STD_LOGIC;
	signal START_DIG_out : STD_LOGIC;
	signal START_SROUT_out : STD_LOGIC;
	signal SAMP_DONE_out : STD_LOGIC;
	signal RD_ROWSEL_out		:	STD_LOGIC_VECTOR(2 DOWNTO 0);
	signal RD_COLSEL_out		:	STD_LOGIC_VECTOR(5 DOWNTO 0);
	
	--trigger signals
	signal SMA_CONN_out : std_logic;
	
	--150MHz clock signals
	--signal clk_counter_150 : UNSIGNED(7 DOWNTO 0);
	
   --sampling signals
	signal IDLE : STD_LOGIC;
	signal TestTrig : STD_LOGIC;
	signal SSPIN_out : STD_LOGIC;
	signal SSTIN_out : STD_LOGIC;
	signal WR_ADVCLK_out : STD_LOGIC;
	signal WR_ADDRCLR_out : STD_LOGIC;
	signal WR_STRB_out : STD_LOGIC;
	signal WR_ENA_out : STD_LOGIC;
	signal MAIN_CNT		: std_logic_vector(10 downto 0);
	signal MAIN_CNT_cap		: std_logic_vector(10 downto 0);
	
	--digtizing signals
	signal RAMP_DONE_out : STD_LOGIC;
	signal rd_ena_out : STD_LOGIC;
	signal CLR_out : STD_LOGIC;
	--signal START_out : STD_LOGIC;
   --signal ramp_out : STD_LOGIC;
	signal STARTRAMP_out : STD_LOGIC;
	signal CUR_STATE_DIG_out : std_logic_vector(3 downto 0);
	signal CUR_STATE_SRD_out : std_logic_vector(3 downto 0);
	signal MON_SR_out			 : std_logic_vector(15 downto 0);

	--serial readout signals
	signal SR_CLEAR_out : STD_LOGIC;
	signal SAMPLESEL_out : STD_LOGIC_VECTOR(5 downto 0);
	signal SAMPLESEL_ANY_out : STD_LOGIC;
	signal SR_CLOCK_out : STD_LOGIC;
	signal SR_SEL_out : STD_LOGIC;
	signal DO_in : STD_LOGIC_VECTOR(16 DOWNTO 1);
	signal FIFO_WR_EN_srout : STD_LOGIC;
	signal FIFO_WR_CLK_srout : STD_LOGIC;
	signal FIFO_WR_DIN_srout : STD_LOGIC_VECTOR(31 downto 0);
	
	--trigger threshold signals
	SIGNAL Trig_thresh_16_ASIC						: STD_LOGIC_VECTOR(11 DOWNTO 0);
	SIGNAL Trig_thresh_15_ASIC						: STD_LOGIC_VECTOR(11 DOWNTO 0);
	SIGNAL Trig_thresh_14_ASIC						: STD_LOGIC_VECTOR(11 DOWNTO 0);
	SIGNAL Trig_thresh_13_ASIC						: STD_LOGIC_VECTOR(11 DOWNTO 0);
	SIGNAL Trig_thresh_12_ASIC						: STD_LOGIC_VECTOR(11 DOWNTO 0);
	SIGNAL Trig_thresh_11_ASIC						: STD_LOGIC_VECTOR(11 DOWNTO 0);
	SIGNAL Trig_thresh_10_ASIC						: STD_LOGIC_VECTOR(11 DOWNTO 0);
	SIGNAL Trig_thresh_9_ASIC						: STD_LOGIC_VECTOR(11 DOWNTO 0);
	SIGNAL Trig_thresh_8_ASIC						: STD_LOGIC_VECTOR(11 DOWNTO 0);
	SIGNAL Trig_thresh_7_ASIC						: STD_LOGIC_VECTOR(11 DOWNTO 0);
	SIGNAL Trig_thresh_6_ASIC						: STD_LOGIC_VECTOR(11 DOWNTO 0);
	SIGNAL Trig_thresh_5_ASIC						: STD_LOGIC_VECTOR(11 DOWNTO 0);
	SIGNAL Trig_thresh_4_ASIC						: STD_LOGIC_VECTOR(11 DOWNTO 0);
	SIGNAL Trig_thresh_3_ASIC						: STD_LOGIC_VECTOR(11 DOWNTO 0);
	SIGNAL Trig_thresh_2_ASIC						: STD_LOGIC_VECTOR(11 DOWNTO 0);
	SIGNAL Trig_thresh_1_ASIC						: STD_LOGIC_VECTOR(11 DOWNTO 0);

begin

	--assign monitor pins
	MON(0) <= 'Z';
	MON( 1 ) <= SDA_out;
	MON( 2 ) <= SCL_out;
	MON( 3 ) <= 'Z';
	--MON( 4 ) <= TRG(1);
	--MON( 5 ) <= TRG(2);
	--MON( 6 ) <= TRG(3);
	--MON( 7 ) <= TRG(4);
	--MON( 8 ) <= TRG_16;
	--MON( 9 ) <= TRGMON;
	--MON( 15 downto 10 ) <= Trig_thresh_1_ASIC(5 downto 0);
	MON( 15 downto 4 ) <= (others =>'0');

	--monitor FIFO endpoint 4 words on MON_USBFifoTest_out
	Inst_USBFifoTest: entity work.USBFifoTest PORT MAP(
		clk => usb_clk,
		rst => rst,
		StartTest => '0',
		FIFO_WR_EN => open,
		FIFO_WR_CLK	=> open,
		FIFO_WR_DIN	=> open,
		FIFO_RD_EMPTY => fifo_rd_empty,
		FIFO_RD_EN => fifo_rd_en,
		FIFO_RD_CLK => fifo_rd_clk,
		FIFO_RD_DOUT => fifo_rd_dout,
		MON => MON_usb_test
	);

	--detect control words on MON_usb_test (FIFO output)
	process (rst, system_40MHz_clk) begin
		IF rst = '1' THEN
			tempState0 <= '0';
			tempPulse0 <= '0';
			
			tempState1 <= '0';
			tempPulse1 <= '0';
			
			tempState2 <= '0';
			tempPulse2 <= '0';
			
			tempState3 <= '0';
			tempPulse3 <= '0';
			
			tempState4 <= '0';
			tempPulse4 <= '0';
			
			tempState5 <= '0';
			tempPulse5 <= '0';
			
			tempState6 <= '0';
			tempPulse6 <= '0';
			
			TRIG_DATA <= x"0000";
			CHAN_DATA <= x"0000"; --set default readout channel
			DAC_DATA <= x"0011";
			PIN_DATA <= x"0000";
			--I2C_DATA <= x"0000";
		elsif( rising_edge(system_40MHz_clk) ) then
			--pulse trigger 0 --software trigger
			if( MON_usb_test(15 downto 0) = x"ABC0" and tempState0 = '0' ) then
				tempState0 <= '1';
				tempPulse0 <= '1';
				--TRIG_DATA <= MON_usb_test(31 downto 16);				
			elsif( MON_usb_test(15 downto 0) = x"ABC0" and tempState0 = '1' ) then
				tempState0 <= '1';
				tempPulse0 <= '0';
				--TRIG_DATA <= MON_usb_test(31 downto 16);				
			else
				tempState0 <= '0';
				tempPulse0 <= '0';
			end if;
			
			--pulse trigger 1 -- readout specific samples
			if( MON_usb_test(15 downto 0) = x"ABC1" and tempState1 = '0' ) then
				tempState1 <= '1';
				tempPulse1 <= '1';
				CHAN_DATA <= MON_usb_test(31 downto 16);
			elsif( MON_usb_test(15 downto 0) = x"ABC1" and tempState1 = '1' ) then
				tempState1 <= '1';
				tempPulse1 <= '0';
				CHAN_DATA <= MON_usb_test(31 downto 16);
			else
				tempState1 <= '0';
				tempPulse1 <= '0';
			end if;
			
			--pulse trigger 2
			if( MON_usb_test(15 downto 0) = x"ABC2" and tempState2 = '0' ) then
				tempState2 <= '1';
				tempPulse2 <= '1';
				DAC_DATA <= MON_usb_test(31 downto 16);
			elsif( MON_usb_test(15 downto 0) = x"ABC2" and tempState2 = '1' ) then
				tempState2 <= '1';
				tempPulse2 <= '0';
				DAC_DATA <= MON_usb_test(31 downto 16);
			else
				tempState2 <= '0';
				tempPulse2 <= '0';
			end if;
			
			--pulse trigger 3
			if( MON_usb_test(15 downto 0) = x"ABC3" and tempState3 = '0' ) then
				tempState3 <= '1';
				tempPulse3 <= '1';
				PIN_DATA <= MON_usb_test(31 downto 16);
			elsif( MON_usb_test(15 downto 0) = x"ABC3" and tempState3 = '1' ) then
				tempState3 <= '1';
				tempPulse3 <= '0';
				PIN_DATA <= MON_usb_test(31 downto 16);
			else
				tempState3 <= '0';
				tempPulse3 <= '0';
			end if;

			--pulse trigger 4
			if( MON_usb_test(15 downto 0) = x"ABC4" and tempState4 = '0' ) then
				tempState4 <= '1';
				tempPulse4 <= '1';
				--I2C_DATA <= MON_usb_test(31 downto 16);
			elsif( MON_usb_test(15 downto 0) = x"ABC4" and tempState4 = '1' ) then
				tempState4 <= '1';
				tempPulse4 <= '0';
				--I2C_DATA <= MON_usb_test(31 downto 16);
			else
				tempState4 <= '0';
				tempPulse4 <= '0';
			end if;	
			
			--pulse trigger 5
			if( MON_usb_test(15 downto 0) = x"ABC5" and tempState5 = '0' ) then
				tempState5 <= '1';
				tempPulse5 <= '1';
				--I2C_DATA <= MON_usb_test(31 downto 16);
			elsif( MON_usb_test(15 downto 0) = x"ABC5" and tempState5 = '1' ) then
				tempState5 <= '1';
				tempPulse5 <= '0';
				--I2C_DATA <= MON_usb_test(31 downto 16);
			else
				tempState5 <= '0';
				tempPulse5 <= '0';
			end if;	
			
			--pulse trigger 6
			if( MON_usb_test(15 downto 0) = x"ABC6" and tempState6 = '0' ) then
				tempState6 <= '1';
				tempPulse6 <= '1';
				TRIG_DATA <= MON_usb_test(31 downto 16);				
			elsif( MON_usb_test(15 downto 0) = x"ABC6" and tempState6 = '1' ) then
				tempState6 <= '1';
				tempPulse6 <= '0';
				TRIG_DATA <= MON_usb_test(31 downto 16);
			else
				tempState6 <= '0';
				tempPulse6 <= '0';
			end if;
			
		end if;
	end process;

	--module controls ASIC DAC serial write
	Inst_ASIC_TARGET4: entity work.ASIC_TARGET4 PORT MAP(
		CLK => system_40MHz_clk,
		RESET => rst,
		UPDATE => tempPulse2,
		IN_DATA => DAC_DATA,
		Trig_thresh_1_ASIC => Trig_thresh_1_ASIC,
		Trig_thresh_2_ASIC => Trig_thresh_2_ASIC,
		Trig_thresh_3_ASIC => Trig_thresh_3_ASIC,
		Trig_thresh_4_ASIC => Trig_thresh_4_ASIC,
		Trig_thresh_5_ASIC => Trig_thresh_5_ASIC,
		Trig_thresh_6_ASIC => Trig_thresh_6_ASIC,
		Trig_thresh_7_ASIC => Trig_thresh_7_ASIC,
		Trig_thresh_8_ASIC => Trig_thresh_8_ASIC,
		Trig_thresh_9_ASIC => Trig_thresh_9_ASIC,
		Trig_thresh_10_ASIC => Trig_thresh_10_ASIC,
		Trig_thresh_11_ASIC => Trig_thresh_11_ASIC,
		Trig_thresh_12_ASIC => Trig_thresh_12_ASIC,
		Trig_thresh_13_ASIC => Trig_thresh_13_ASIC,
		Trig_thresh_14_ASIC => Trig_thresh_14_ASIC,
		Trig_thresh_15_ASIC => Trig_thresh_15_ASIC,
		Trig_thresh_16_ASIC => Trig_thresh_16_ASIC,
		SCLK => sclk,
		SIN => sin,
		REGCLR => regclr,
		PCLK => pclk
	);
	
	--MPPC voltage DAC I2C control
	Inst_TDC_MPPC_DAC: entity work.TDC_MPPC_DAC PORT MAP(
		CLK => clk_counter(7),
		RESET => rst,
		ADDR_MPPC_DAC => MPPCDAC_DATA(11 downto 8),
		VALUE_MPPC_DAC => MPPCDAC_DATA(7 downto 0),
		ALL_OR_SINGLE_MPPC_DAC => MPPCDAC_DATA(12),
		UPDATE_MPPC_DAC => UPDATE_MPPCDAC,
		SCK_DAC => SCK_DAC,
		DIN_DAC => DIN_DAC,
		CS_DAC => CS_DAC,
		UPDATE_MPPCDAC_DONE => UPDATE_MPPCDAC_DONE
	);

	--TEST BOARD I2C control
	Inst_LTC2637_I2C_DAC: entity work.LTC2637_I2C_DAC PORT MAP(
		--CLK => system_40MHz_clk,
		CLK => clk_counter(7),
		RST => rst,
		SCL => SCL_out,
		SDA => SDA_out,
		UPDATE => UPDATE,
		DAC_ADDRESS => I2C_DATA(11 downto 8),
		DAC_COMMAND => I2C_DATA(15 downto 12),
		DAC_VALUE => DAC_VALUE_in,
		UPDATE_DONE => UPDATE_DONE
	);
	DAC_VALUE_in <= (I2C_DATA(7 downto 0) & "0000");
	
	--hold I2C update rrequest as module is on slower clock
	process (rst,system_40MHz_clk ) begin
		if(rst = '1' ) then
			UPDATE <= '0';
			UPDATE_MPPCDAC <= '0';
			I2C_DATA <= x"0000";
			MPPCDAC_DATA <= x"0000";
		elsif( rising_edge(system_40MHz_clk) ) then
			--hold test board dac I2C update signals
			if( tempPulse4 = '1' ) then
				UPDATE <= '1';
				I2C_DATA <= MON_usb_test(31 downto 16);
			elsif( UPDATE_DONE = '1' ) then
				UPDATE <= '0';
			end if;
			--hold MPPC DAC I2C update signals
			if( tempPulse5 = '1' ) then
				UPDATE_MPPCDAC <= '1';
				MPPCDAC_DATA <= MON_usb_test(31 downto 16);
			elsif( UPDATE_MPPCDAC_DONE = '1' ) then
				UPDATE_MPPCDAC <= '0';
			end if;
		end if;
	end process;
	
	--basic clock divisor
	process (rst,system_40MHz_clk) begin
		if(rst = '1' ) then
			clk_counter <= (others=>'0');
		elsif( rising_edge(system_40MHz_clk) ) then
			clk_counter <= clk_counter + 1;
		end if;
	end process;
	
	--process sets key readout variables
	process (system_40MHz_clk, rst) is
	begin
	if (rst = '1') then
		--set default values
		dig_offset <= X"000";
		ramp_length <= X"400";
		trig_delay <= X"004";
		trigControl <= X"206";
		samp_delay <= X"000";
	elsif( rising_edge(system_40MHz_clk) ) then
		if( tempState3 = '1' ) then
			CASE PIN_DATA(15 downto 12) IS
				WHEN "0000" => --set default case
					dig_offset <= X"000";
					ramp_length <= X"400";
					trig_delay <= X"004";
					trigControl <= X"206";
					samp_delay <= X"000";
				WHEN "0001" =>
					dig_offset(11 downto 0) <= PIN_DATA(11 downto 0);
				WHEN "0010" =>
					trigControl(11 downto 0)<= PIN_DATA(11 downto 0);
				WHEN "0011" =>
					samp_delay(11 downto 0) <= PIN_DATA(11 downto 0);
				WHEN OTHERS => --do nothing
			END CASE;
		end if;
	end if;
	end process;
	
	--process controls trigger DACs
	process (system_40MHz_clk, rst) is
	begin
	if (rst = '1') then
		--set default values
		Trig_thresh_16_ASIC		<= x"FF3";
		Trig_thresh_15_ASIC		<=	x"FF3";
		Trig_thresh_14_ASIC		<=	x"FF3";
		Trig_thresh_13_ASIC		<= x"FF3";
		Trig_thresh_12_ASIC		<= x"FF3";
		Trig_thresh_11_ASIC		<= x"FF3";
		Trig_thresh_10_ASIC		<= x"FF3";
		Trig_thresh_9_ASIC		<=	x"FF3";
		Trig_thresh_8_ASIC		<=	x"FF3";
		Trig_thresh_7_ASIC		<= x"FF3";
		Trig_thresh_6_ASIC		<= x"FF3";
		Trig_thresh_5_ASIC		<= x"FF3";
		Trig_thresh_4_ASIC		<= x"FF3";
		Trig_thresh_3_ASIC		<=	x"FF3";
		Trig_thresh_2_ASIC		<=	x"FF3";
		Trig_thresh_1_ASIC		<=	x"FF3";
	elsif( rising_edge(system_40MHz_clk) ) then
		if( tempState6 = '1' ) then
			CASE TRIG_DATA(15 downto 12) IS
				WHEN "0000" => --set default case
					Trig_thresh_16_ASIC		<= x"000";
					Trig_thresh_15_ASIC		<=	x"000";
					Trig_thresh_14_ASIC		<=	x"000";
					Trig_thresh_13_ASIC		<= x"000";
					Trig_thresh_12_ASIC		<= x"000";
					Trig_thresh_11_ASIC		<= x"000";
					Trig_thresh_10_ASIC		<= x"000";
					Trig_thresh_9_ASIC		<=	x"000";
					Trig_thresh_8_ASIC		<=	x"000";
					Trig_thresh_7_ASIC		<= x"000";
					Trig_thresh_6_ASIC		<= x"000";
					Trig_thresh_5_ASIC		<= x"000";
					Trig_thresh_4_ASIC		<= x"000";
					Trig_thresh_3_ASIC		<=	x"000";
					Trig_thresh_2_ASIC		<=	x"000";
					Trig_thresh_1_ASIC		<=	x"000";
				WHEN "0001" =>
					Trig_thresh_1_ASIC(11 downto 0) <= TRIG_DATA(11 downto 0);
				WHEN "0010" =>
					Trig_thresh_2_ASIC(11 downto 0) <= TRIG_DATA(11 downto 0);
				WHEN "0011" =>
					Trig_thresh_3_ASIC(11 downto 0) <= TRIG_DATA(11 downto 0);	
				WHEN "0100" =>
					Trig_thresh_4_ASIC(11 downto 0) <= TRIG_DATA(11 downto 0);	
				WHEN "0101" =>
					Trig_thresh_5_ASIC(11 downto 0) <= TRIG_DATA(11 downto 0);		
				WHEN "0110" =>
					Trig_thresh_6_ASIC(11 downto 0) <= TRIG_DATA(11 downto 0);	
				WHEN "0111" =>
					Trig_thresh_7_ASIC(11 downto 0) <= TRIG_DATA(11 downto 0);	
				WHEN "1000" =>
					Trig_thresh_8_ASIC(11 downto 0) <= TRIG_DATA(11 downto 0);	
				WHEN "1001" =>
					Trig_thresh_9_ASIC(11 downto 0) <= TRIG_DATA(11 downto 0);	
				WHEN "1010" =>
					Trig_thresh_10_ASIC(11 downto 0) <= TRIG_DATA(11 downto 0);	
				WHEN "1011" =>
					Trig_thresh_11_ASIC(11 downto 0) <= TRIG_DATA(11 downto 0);	
				WHEN "1100" =>
					Trig_thresh_12_ASIC(11 downto 0) <= TRIG_DATA(11 downto 0);	
				WHEN "1101" =>
					Trig_thresh_13_ASIC(11 downto 0) <= TRIG_DATA(11 downto 0);	
				WHEN "1110" =>
					Trig_thresh_14_ASIC(11 downto 0) <= TRIG_DATA(11 downto 0);	
				WHEN "1111" =>
					Trig_thresh_15_ASIC(11 downto 0) <= TRIG_DATA(11 downto 0);	
				--trigger threshold 16 never updated, temperature monitor channel
				WHEN OTHERS => --do nothing
			END CASE;
		end if;
	end if;
	end process;
	
	--assign constant output signalss
	TST_START <= '0';
	TST_BOIN_CLR <= '0';
	
	--module co-ordinates readout proces following trigger
	u_ReadoutControl : entity work.ReadoutControl
   Port map (
			  clk => system_40MHz_clk,
           rst => rst,
           trigger => tempState0,
			  read_req => tempState1,
           ramp_done => RAMP_DONE_out,
           samp_done => SAMP_DONE_out,
           fifo_full => '0',
			  trig_delay => trig_delay,
			  --TRIG_DATA => TRIG_DATA,
			  CHAN_DATA	=> CHAN_DATA,
           stop_smp => STOP_SMP_out,
           start_dig => START_DIG_out,
           start_srout => START_SROUT_out,
			  samplesel	=> SAMPLESEL_out
	);
	
	--basic clock divisor for sampling logic
	--process (rst,system_150MHz_clk) begin
	--	if(rst = '1' ) then
	--		clk_counter_150 <= (others=>'0');
	--	elsif( rising_edge(system_150MHz_clk) ) then
	--		clk_counter_150 <= clk_counter_150 + 1;
	--	end if;
	--end process;
	
	--control TARGET4 sampling
	u_SamplingLgc : entity work.SamplingLgc
   Port map (
				--clk				=> system_40MHz_clk,
				clk				=> system_150MHz_clk,
				--clk				=> clk_counter_150(0),
				--clk				=> system_150MHz_clk_div2,
				rst				=> rst,
				stop				=> STOP_SMP_out,
				IDLE_status			=> IDLE,
				TestTrig				=> TestTrig,
				MAIN_CNT_out		=> MAIN_CNT,
				sspin_out			=> SSPIN_out,
				sstin_out			=> SSTIN_out,
				wr_advclk_out		=> WR_ADVCLK_out,
				wr_addrclr_out		=> WR_ADDRCLR_out,
				wr_strb_out			=> WR_STRB_out,
				wr_ena_out			=> WR_ENA_out,
				samp_delay			=> samp_delay,
				trigControl 		=> trigControl,
				trigger				=> SMA_CONN_out
	);
	--control swapping off SSPIN/SSTIN
	SSPIN <= SSPIN_out WHEN CHAN_DATA(14) = '0' ELSE SSTIN_out;
	SSTIN <= SSTIN_out WHEN CHAN_DATA(14) = '0' ELSE SSPIN_out;
	--SSPIN <= SSPIN_out;
	--SSTIN <= SSTIN_out;
	WR_ADVCLK <= WR_ADVCLK_out;
	WR_ADDRCLR <= WR_ADDRCLR_out;
	WR_STRB <= WR_STRB_out;
	WR_ENA <= WR_ENA_out;
	SMA_CONN <= not(SMA_CONN_out); 

	--capture COL, ROW on IDLE signal going high (Sampling stopped)
	process (rst,IDLE) begin
		if(rst = '1' ) then
			MAIN_CNT_cap <= (others=>'0');
		elsif( IDLE'event and IDLE = '1' ) then
			MAIN_CNT_cap 
			<= std_logic_vector( UNSIGNED(MAIN_CNT(10 downto 0))
										- UNSIGNED(dig_offset(10 downto 0)) );
		end if;
	end process;
	--original definition
	--RD_COLSEL <= MAIN_CNT_cap(10 downto 5);
	--RD_ROWSEL <= MAIN_CNT_cap(4 downto 2);
	--control which storage cell group is read out using CHAN_DATA(15) bit
	RD_COLSEL_out <= MAIN_CNT_cap(8 downto 3) WHEN CHAN_DATA(15) = '0' ELSE CHAN_DATA(12 downto 7);
	RD_ROWSEL_out <= MAIN_CNT_cap(2 downto 0) WHEN CHAN_DATA(15) = '0' ELSE CHAN_DATA(6 downto 4);
	RD_COLSEL <= RD_COLSEL_out;
	RD_ROWSEL <= RD_ROWSEL_out;

	u_DigitizingLgc : entity work.DigitizingLgc
   port map (
        clk		 			   => system_40MHz_clk,
        rst 			      => rst,
		  StartDig	 		   => START_DIG_out,
		  ramp_length		 	=> ramp_length,
        RAMP_DONE	       	=> RAMP_DONE_out,
        rd_ena           	=> rd_ena_out,
        clr              	=> CLR_out,
		  --start_out          => START_out,
        --ramp_out           => ramp_out,
		  startramp_out      => STARTRAMP_out,
		  CUR_STATE				=> CUR_STATE_DIG_out
   );
	--START <= START_out;
	--RAMP <= ramp_out;
	STARTRAMP <= STARTRAMP_out;
	RD_ENA <= rd_ena_out;
	CLR <= CLR_out;	

	u_SerialDataRout : entity work.SerialDataRout
   port map (
        clk		 			    => system_40MHz_clk,
        rst 			       => rst,
        StartSROut	 		 => START_SROUT_out,
        SAMP_DONE	       		=> SAMP_DONE_out,
        dout     	       		=> DO_in,
        sr_clr          		=> SR_CLEAR_out,
        sr_clk           		=> SR_CLOCK_out,
        sr_sel           		=> SR_SEL_out,
		  samplesel					=> SAMPLESEL_out,
        smplsi_any       		=> SAMPLESEL_ANY_out,
		  FIFO_WR_EN		 		=> FIFO_WR_EN_srout,
		  FIFO_WR_CLK		 		=> FIFO_WR_CLK_srout,
		  FIFO_WR_DIN		 		=> FIFO_WR_DIN_srout,
		  CHAN_DATA					=> CHAN_DATA,
		  rd_cs_s          		=> RD_COLSEL_out,
        rd_rs_s          		=> RD_ROWSEL_out,
		  MON							=> MON_SR_out,
		  CUR_STATE					=> CUR_STATE_SRD_out
   );
	fifo_wr_en <= FIFO_WR_EN_srout;
   fifo_wr_clk <= FIFO_WR_CLK_srout;
   fifo_wr_din <= FIFO_WR_DIN_srout;
	DO_in <= DO;
	SR_CLEAR <= SR_CLEAR_out;
	SR_CLOCK <= SR_CLOCK_out;
	SR_SEL <= SR_SEL_out;
	SAMPLESEL_ANY <= SAMPLESEL_ANY_out;
	SAMPLESEL <= SAMPLESEL_out(4 downto 0);
	
end Behavioral;