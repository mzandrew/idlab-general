----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:14:34 01/27/2013 
-- Design Name: 
-- Module Name:    SciFiTop - Behavioral 
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

entity SciFiTop is
    Port ( CLK : in  STD_LOGIC;
			  --Input/Control
			  CONTROL_SCIFI : in STD_LOGIC_VECTOR(15 DOWNTO 0);
			  CONTROL_SCIFI_REG0 : in STD_LOGIC_VECTOR(15 DOWNTO 0);
			  CONTROL_SCIFI_REG1 : in STD_LOGIC_VECTOR(15 DOWNTO 0);
			  CONTROL_SCIFI_REG2 : in STD_LOGIC_VECTOR(15 DOWNTO 0);
			  CONTROL_SCIFI_REG3 : in STD_LOGIC_VECTOR(15 DOWNTO 0);
			  CONTROL_SCIFI_REG4 : in STD_LOGIC_VECTOR(15 DOWNTO 0);
			  --TRIGGER Signals
			  TRIGGER_IN : in  STD_LOGIC;
			  TRIGSCALAR : out STD_LOGIC_VECTOR(15 DOWNTO 0);
			  --Global bus signals
			  BUS_SCLK                    : out STD_LOGIC;
			  BUS_PCLK                    : out STD_LOGIC;
			  BUS_REGCLR                  : out STD_LOGIC;
			  BUS_TST_START					 : out STD_LOGIC;
			  BUS_TST_BOIN_CLR			 	 : out STD_LOGIC;
			  --ASIC specific pins
			  TDC_CS_DAC						  : out STD_LOGIC_VECTOR(9 downto 0);	
			  TDC_SDA_MUX						  : inout STD_LOGIC_VECTOR(9 downto 0);	
			  TDC_SDA_MON						  : inout STD_LOGIC_VECTOR(9 downto 0);	
			  TDC_SAMPLESEL_ANY				  : out STD_LOGIC_VECTOR(9 downto 0);	
		     TDC_SIN						  	  : out STD_LOGIC_VECTOR(9 downto 0);	
			  TDC_SHOUT						  : in STD_LOGIC_VECTOR(9 downto 0);	
			  TDC_TSTOUT						  : in STD_LOGIC_VECTOR(9 downto 0);	
			  TDC_SSPOUT						  : in STD_LOGIC_VECTOR(9 downto 0);	
			  TDC_SSPIN						  : out STD_LOGIC_VECTOR(9 downto 0);	
			  TDC_SSTIN						  : out STD_LOGIC_VECTOR(9 downto 0);	
			  TDC_WR_ADVCLK					  : out STD_LOGIC_VECTOR(9 downto 0);	
			  TDC_WR_STRB						  : out STD_LOGIC_VECTOR(9 downto 0);	
			  TDC_TRG_1						  : in STD_LOGIC_VECTOR(9 downto 0);
			  TDC_TRG_2						  : in STD_LOGIC_VECTOR(9 downto 0);			
			  TDC_TRG_3						  : in STD_LOGIC_VECTOR(9 downto 0);
			  TDC_TRG_4						  : in STD_LOGIC_VECTOR(9 downto 0);
			  TDC_TRG_16						  : in STD_LOGIC_VECTOR(9 downto 0);
			  TDC_TRGMON						  : in STD_LOGIC_VECTOR(9 downto 0);
			  TDC_RCO							  : in STD_LOGIC_VECTOR(9 downto 0);	
			  TDC_SR_CLOCK					  : out STD_LOGIC_VECTOR(9 downto 0);
			  --Event builder related
			  READOUT_FIFO_DATA_OUT : out  STD_LOGIC_VECTOR(31 downto 0);
			  READOUT_FIFO_EMPTY : out  STD_LOGIC;
			  READOUT_FIFO_DATA_VALID : out  STD_LOGIC;
			  READOUT_FIFO_READ_CLOCK : in STD_LOGIC;
			  READOUT_FIFO_READ_ENABLE : in STD_LOGIC;
			  READOUT_PACKET_BUILDER_BUSY : out STD_LOGIC;
			  READOUT_PACKET_BUILDER_VETO : in STD_LOGIC
			  );
end SciFiTop;

architecture Behavioral of SciFiTop is
	--SciFi - ASIC DAC writing
	signal SIN_out							: std_logic_vector(9 downto 0);
	--SciFi - event builder
	signal internal_TRIGGER_REG		: std_logic_vector(1 downto 0);
	signal internal_DONE_SENDING_EVENT		   : std_logic;
	signal internal_MAKE_READY		 		      : std_logic := '0';
	signal START_BUILDING_EVENT					: std_logic := '0';
	--SciFi - trigger related
	signal internal_TRIGSCALAR_START		: std_logic;
	signal internal_TRIGSCALAR_COUNTER	: UNSIGNED(15 downto 0);
	signal internal_TRIGSCALAR_ENABLE	: std_logic;
	signal internal_TRIGSCALAR_REG		: std_logic_vector(1 downto 0);
	signal internal_TRIGGER					: std_logic;
	signal TDC_TRG_IN							: std_logic;
	--self trigger
	signal internal_TRIGGER_SELECT	: std_logic_vector(1 downto 0);
	signal internal_TRIGSELF_REG		: std_logic_vector(1 downto 0);
	signal internal_TRGSELF				: std_logic := '0';
	signal TRG_SELF						: std_logic_vector(9 downto 0);
	signal TRG_SELF_TOTAL				: std_logic := '0';
	signal LOAD_DACs						: std_logic := '0';
	signal UPDATE_DACS					: std_logic := '0';
	signal LOAD_DACs_trig				: std_logic := '0';
	signal UPDATE_DACs_trig				: std_logic := '0';
	signal LOAD_DACs_DONE				: std_logic := '0';
	signal TRIG_TYPE_val					: std_logic := '0';
	signal TDC_TRG_1_out0				: STD_LOGIC_VECTOR(9 downto 0);
	signal TDC_TRG_2_out0				: STD_LOGIC_VECTOR(9 downto 0);
	signal TDC_TRG_3_out0				: STD_LOGIC_VECTOR(9 downto 0);
	signal TDC_TRG_4_out0				: STD_LOGIC_VECTOR(9 downto 0);
	signal TDC_TRG_16_out0				: STD_LOGIC_VECTOR(9 downto 0);
	signal TDC_TRG_1_out1				: STD_LOGIC_VECTOR(9 downto 0);
	signal TDC_TRG_2_out1				: STD_LOGIC_VECTOR(9 downto 0);
	signal TDC_TRG_3_out1				: STD_LOGIC_VECTOR(9 downto 0);
	signal TDC_TRG_4_out1				: STD_LOGIC_VECTOR(9 downto 0);
	signal TDC_TRG_16_out1				: STD_LOGIC_VECTOR(9 downto 0);
	signal internal_LOAD_DACS 			: STD_LOGIC;
	signal internal_UPDATE_DACS 		: STD_LOGIC;
	signal internal_UPDATE_REGS 		: STD_LOGIC;
	signal internal_TOGGLE_INPUT_SELF_TRIGGER : STD_LOGIC;
	signal internal_TRIGSCALAR_CONTROL		: std_logic;
	signal UPDATE_REGS_NUMBER 			: STD_LOGIC_VECTOR(15 DOWNTO 0);
	signal UPDATE_REGS_DATA 			: STD_LOGIC_VECTOR(15 DOWNTO 0);
	signal TRIGSCALAR_COUNTER_PERIOD : STD_LOGIC_VECTOR(15 DOWNTO 0);
	signal UPDATE_REGS_CARRIER 		: STD_LOGIC_VECTOR(15 DOWNTO 0);
	signal DAC_LOADING_PERIOD 			: STD_LOGIC_VECTOR(15 DOWNTO 0);

begin

	--set constant signals
	BUS_TST_START <= '0';
	BUS_TST_BOIN_CLR <= '0';
	TDC_CS_DAC <= (others=>'0');
	TDC_SDA_MUX <= (others=>'0');
	TDC_SDA_MON <= (others=>'0');
	TDC_SAMPLESEL_ANY <= (others=>'0');
	TDC_SSPIN <= (others=>'0');
	TDC_SSTIN <= (others=>'0');
	TDC_WR_ADVCLK <= (others=>'0');
	TDC_WR_STRB <= (others=>'0');
	TDC_SR_CLOCK <= (others=>'0');
	
	--set control signals
	internal_LOAD_DACS <= CONTROL_SCIFI(0);
	internal_UPDATE_DACS <= CONTROL_SCIFI(1);
	internal_UPDATE_REGS <= CONTROL_SCIFI(2);
	internal_TOGGLE_INPUT_SELF_TRIGGER <= CONTROL_SCIFI(3);
	internal_TRIGSCALAR_CONTROL <= CONTROL_SCIFI(4);
	
	UPDATE_REGS_NUMBER <= CONTROL_SCIFI_REG0; --reg 5
	UPDATE_REGS_DATA <= CONTROL_SCIFI_REG1; --reg 6
	UPDATE_REGS_CARRIER <= CONTROL_SCIFI_REG2; --reg 7
	TRIGSCALAR_COUNTER_PERIOD <= CONTROL_SCIFI_REG3; --reg 8
	DAC_LOADING_PERIOD	<= CONTROL_SCIFI_REG4; --reg 9

	--ASIC DAC writing module
	map_ASIC_TARGET4_MOD : entity work.ASIC_TARGET4_MOD
	port map(
		CLK => CLK,
		LOAD_DACs_IN => LOAD_DACs,
		UPDATE_DACS => UPDATE_DACS,
		UPDATE_REGS => internal_UPDATE_REGS,
		UPDATE_REGS_NUMBER  => UPDATE_REGS_NUMBER,
		UPDATE_REGS_DATA => UPDATE_REGS_DATA,
		UPDATE_REGS_CARRIER  => UPDATE_REGS_CARRIER,
		DAC_LOADING_PERIOD	=> DAC_LOADING_PERIOD,
		LOAD_DACs_DONE => LOAD_DACs_DONE,
		TRIG_TYPE_val => TRIG_TYPE_val,
		SCLK => BUS_SCLK,
		SIN => SIN_out,
		REGCLR => BUS_REGCLR,
		PCLK => BUS_PCLK
	);	
	LOAD_DACs  <= LOAD_DACs_trig OR internal_LOAD_DACS;
	UPDATE_DACS <= UPDATE_DACs_trig OR internal_UPDATE_DACS;
	TDC_SIN(0) <= SIN_out(0);
	TDC_SIN(1) <= SIN_out(1);
	TDC_SIN(2) <= SIN_out(2);
	TDC_SIN(3) <= SIN_out(3);
	TDC_SIN(4) <= SIN_out(4);
	TDC_SIN(5) <= SIN_out(5);
	TDC_SIN(6) <= SIN_out(6);
	TDC_SIN(7) <= SIN_out(7);
	TDC_SIN(8) <= SIN_out(8);
	TDC_SIN(9) <= SIN_out(9);

	Inst_triggerBitLogic: entity work.triggerBitLogic PORT MAP(
		CLK => CLK,
		TRIGGER_IN => internal_trigger,
		LOAD_DACs_DONE_in => LOAD_DACs_DONE,
		REQ_PACKET_IN => TRIGGER_IN,
		SEND_PACKET => START_BUILDING_EVENT,
		PACKETSENT_IN => internal_DONE_SENDING_EVENT,
		MAKE_READY => internal_MAKE_READY,
		LOAD_DACs => LOAD_DACs_trig,
		WRITE_DACs => UPDATE_DACs_trig,
		TRIG_TYPE_val => TRIG_TYPE_val,
		TDC_TRG_1_IN => TDC_TRG_1,
		TDC_TRG_2_IN => TDC_TRG_2,
		TDC_TRG_3_IN => TDC_TRG_3, 
		TDC_TRG_4_IN => TDC_TRG_4,
		TDC_TRG_16_IN => TDC_TRG_16,
		TDC_TRG_1_out0 => TDC_TRG_1_out0,
		TDC_TRG_2_out0 => TDC_TRG_2_out0,
		TDC_TRG_3_out0 => TDC_TRG_3_out0,
		TDC_TRG_4_out0 => TDC_TRG_4_out0,
		TDC_TRG_16_out0 => TDC_TRG_16_out0,
		TDC_TRG_1_out1 => TDC_TRG_1_out1,
		TDC_TRG_2_out1 => TDC_TRG_2_out1,
		TDC_TRG_3_out1 => TDC_TRG_3_out1,
		TDC_TRG_4_out1 => TDC_TRG_4_out1,
		TDC_TRG_16_out1 => TDC_TRG_16_out1
	);

	--Event builder -- related	
	--note: not connected to ROI readout at present
	Inst_event_builder: entity work.event_builder PORT MAP(
		READ_CLOCK => READOUT_FIFO_READ_CLOCK,
		SCROD_REV_AND_ID_WORD => x"0000ABCD",
		EVENT_NUMBER_WORD => x"00000001",
		EVENT_TYPE_WORD => x"00000000",
		EVENT_FLAG_WORD => x"00000000",
		NUMBER_OF_WAVEFORM_PACKETS_WORD => x"00000000",
		START_BUILDING_EVENT => START_BUILDING_EVENT,
		DONE_SENDING_EVENT => internal_DONE_SENDING_EVENT,
		MAKE_READY => internal_MAKE_READY,
		WAVEFORM_FIFO_DATA => x"00000000",
		WAVEFORM_FIFO_DATA_VALID => '0',
		WAVEFORM_FIFO_EMPTY => '1',
		WAVEFORM_FIFO_READ_ENABLE => open,
		WAVEFORM_FIFO_READ_CLOCK => open,
		FIFO_DATA_OUT => READOUT_FIFO_DATA_OUT,
		FIFO_DATA_VALID => READOUT_FIFO_DATA_VALID,
		FIFO_EMPTY => READOUT_FIFO_EMPTY,
		FIFO_READ_ENABLE => READOUT_FIFO_READ_ENABLE,
		TDC_TRG_16_0 => TDC_TRG_16_out0,
		TDC_TRG_4_0 => TDC_TRG_4_out0,
		TDC_TRG_3_0 => TDC_TRG_3_out0,
		TDC_TRG_2_0 => TDC_TRG_2_out0,
		TDC_TRG_1_0 => TDC_TRG_1_out0,
		TDC_TRG_16_1 => TDC_TRG_16_out1,
		TDC_TRG_4_1 => TDC_TRG_4_out1,
		TDC_TRG_3_1 => TDC_TRG_3_out1,
		TDC_TRG_2_1 => TDC_TRG_2_out1,
		TDC_TRG_1_1 => TDC_TRG_1_out1
	);
	
	--TRIGGER SCALAR RELATED
	--Edge detector for the trigger counter start	
	process (CLK) begin
		--The only other couple SST clock processes work on falling edges, so we should be consistent here
		if (falling_edge(CLK)) then	
			internal_TRIGSCALAR_REG(1) <= internal_TRIGSCALAR_REG(0);
			internal_TRIGSCALAR_REG(0) <= internal_TRIGSCALAR_CONTROL;
		end if;
	end process;
	internal_TRIGSCALAR_START <= '1' when (internal_TRIGSCALAR_REG = "01") else
	                    '0';
	
	--counter enable for scaler trigger
	process (CLK) begin
		if( internal_TRIGSCALAR_START = '1' ) then
			internal_TRIGSCALAR_COUNTER <= x"0000";
			internal_TRIGSCALAR_ENABLE <= '0';
		else
			if(rising_edge(CLK)) then
				if( internal_TRIGSCALAR_COUNTER = UNSIGNED(TRIGSCALAR_COUNTER_PERIOD) ) then
					internal_TRIGSCALAR_COUNTER <= internal_TRIGSCALAR_COUNTER;
					internal_TRIGSCALAR_ENABLE <= '0';
				else
					internal_TRIGSCALAR_COUNTER <= internal_TRIGSCALAR_COUNTER + x"0001";
					internal_TRIGSCALAR_ENABLE <= '1';
				end if;
			end if;
		end if;
	end process;
	
	--TRIGGER SCALARs
	Inst_trigger_scaler_single_channel: entity work.trigger_scaler_single_channel 
	PORT MAP(
		SIGNAL_TO_COUNT => TRG_SELF_TOTAL,
		CLOCK => CLK,
		READ_ENABLE => internal_TRIGSCALAR_ENABLE,
		RESET_COUNTER => internal_TRIGSCALAR_START,
		SCALER => TRIGSCALAR
	);
	
	--create overall self-trigger OR
	gen_self_trig: for i in 0 to 9 generate
		TRG_SELF(i) <= TDC_TRG_1(i) OR TDC_TRG_2(i) OR TDC_TRG_3(i) OR TDC_TRG_4(i) OR TDC_TRG_16(i);
	end generate;
	TRG_SELF_TOTAL <= TRG_SELF(0) OR TRG_SELF(1) OR TRG_SELF(2) OR TRG_SELF(3) OR TRG_SELF(4) OR TRG_SELF(5) OR TRG_SELF(6) OR TRG_SELF(7) OR TRG_SELF(8) OR TRG_SELF(9);

	--Edge detector for self trigger
	process (CLK) begin
		--The only other couple SST clock processes work on falling edges, so we should be consistent here
		if (rising_edge(CLK)) then			
				internal_TRIGSELF_REG(1) <= internal_TRIGSELF_REG(0);
				internal_TRIGSELF_REG(0) <= TRG_SELF_TOTAL;
		end if;
	end process;
	internal_TRGSELF <= '1' when (internal_TRIGSELF_REG = "01") else
	                    '0';
	
	--control trigger source for trigger bit readout
	internal_TRIGGER <= TRIGGER_IN OR internal_TRGSELF;	
	--internal_TRIGGER <= TRIGGER_IN OR (internal_TRGSELF AND internal_TOGGLE_INPUT_SELF_TRIGGER);
	
end Behavioral;