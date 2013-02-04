----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:10:06 09/18/2012 
-- Design Name: 
-- Module Name:    daq_top - Behavioral 
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

entity daq_top is
	Port ( 
		BOARD_40MHz_CLOCKP          : in  STD_LOGIC;
		BOARD_40MHz_CLOCKN          : in  STD_LOGIC;
		BOARD_150MHz_CLOCKP			 : in  STD_LOGIC;
		BOARD_150MHz_CLOCKN			 : in  STD_LOGIC;
		SMA_CONN							 : out STD_LOGIC;
		PLL_LOCKED                  : out STD_LOGIC;

		FIBER_0_RXP                 : in  STD_LOGIC;
		FIBER_0_RXN                 : in  STD_LOGIC;
		FIBER_1_RXP                 : in  STD_LOGIC;
		FIBER_1_RXN                 : in  STD_LOGIC;
		FIBER_0_TXP                 : out STD_LOGIC;
		FIBER_0_TXN                 : out STD_LOGIC;
		FIBER_1_TXP                 : out STD_LOGIC;
		FIBER_1_TXN                 : out STD_LOGIC;
		FIBER_REFCLKP               : in  STD_LOGIC;
		FIBER_REFCLKN               : in  STD_LOGIC;
		FIBER_0_DISABLE_TRANSCEIVER : out STD_LOGIC;
		FIBER_1_DISABLE_TRANSCEIVER : out STD_LOGIC;
		FIBER_0_LINK_UP             : out STD_LOGIC;
		FIBER_1_LINK_UP             : out STD_LOGIC;
		FIBER_0_LINK_ERR            : out STD_LOGIC;
		FIBER_1_LINK_ERR            : out STD_LOGIC;

		USB_IFCLK                   : in  STD_LOGIC;
		USB_CTL0                    : in  STD_LOGIC;
		USB_CTL1                    : in  STD_LOGIC;
		USB_CTL2                    : in  STD_LOGIC;
		USB_FDD                     : inout STD_LOGIC_VECTOR(15 downto 0);
		USB_PA0                     : out STD_LOGIC;
		USB_PA1                     : out STD_LOGIC;
		USB_PA2                     : out STD_LOGIC;
		USB_PA3                     : out STD_LOGIC;
		USB_PA4                     : out STD_LOGIC;
		USB_PA5                     : out STD_LOGIC;
		USB_PA6                     : out STD_LOGIC;
		USB_PA7                     : in  STD_LOGIC;
		USB_RDY0                    : out STD_LOGIC;
		USB_RDY1                    : out STD_LOGIC;
		USB_WAKEUP                  : in  STD_LOGIC;
		USB_CLKOUT		             : in  STD_LOGIC;
		
		--TARGET RELATED
		--DAC_MON
		SCK_DAC			: OUT	STD_LOGIC;
		DIN_DAC			: OUT STD_LOGIC;
		CS_DAC			: OUT STD_LOGIC;	--active low!!
		
		SCL_MUX			: OUT STD_LOGIC;
		SDA_MUX			: INOUT STD_LOGIC;
		
		SCL_MON			: OUT STD_LOGIC;
		SDA_MON			: INOUT STD_LOGIC;
		
		SSTIN				:	OUT STD_LOGIC;
		SSPIN				:	OUT STD_LOGIC;
		RAMP				:	OUT STD_LOGIC;
		RD_ROWSEL		:	OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
		RD_COLSEL		:	OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
		RD_ENA			:	OUT STD_LOGIC;
		TST_START		:	OUT STD_LOGIC;
		TST_BOIN_CLR	:	OUT STD_LOGIC;
		SIN				:	OUT STD_LOGIC;
		SCLK				:	OUT STD_LOGIC;
		REGCLR			:	OUT STD_LOGIC;
		WR_ADDRCLR		:	OUT STD_LOGIC;
		WR_STRB			:	OUT STD_LOGIC;
		START				:	OUT STD_LOGIC;		--start Wilkinson Conversion
		SAMPLESEL		:	OUT STD_LOGIC_VECTOR(5 DOWNTO 1);
		SAMPLESEL_ANY		:	OUT STD_LOGIC;
		PCLK				:	OUT STD_LOGIC;
		WR_ADVCLK		:	OUT STD_LOGIC;
		WR_ENA			:	OUT STD_LOGIC;
		CLR				:	OUT STD_LOGIC;		--Clear Wilkinson Counter
		SR_SEL			:	OUT STD_LOGIC;
		SR_CLOCK			:	OUT STD_LOGIC;
		SR_CLEAR			:	OUT STD_LOGIC;
		
		MON				:	INOUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		LMON				:	OUT STD_LOGIC_VECTOR(19 DOWNTO 16);
		
		DO						:	IN		STD_LOGIC_VECTOR(16 DOWNTO 1);
		SSPOUT				:	IN		STD_LOGIC;
		RCO					:	IN		STD_LOGIC;
		TRG_16				:	IN		STD_LOGIC;
		TRG					:	IN		STD_LOGIC_VECTOR(4 DOWNTO 1);
		
		TRGIN					:	out		STD_LOGIC;	--PULSE IN
		
		TRGMON				:	IN		STD_LOGIC;
		SHOUT					:	IN		STD_LOGIC;
		TSTOUT				:	IN		STD_LOGIC;
		SW						:	IN		STD_LOGIC_VECTOR(4 DOWNTO 1)	--SWITCH ON THE UNIVERSAL EVAL BOARD.
	);
end daq_top;

architecture Behavioral of daq_top is
	signal internal_CLOCK_40MHz_BUFG          : std_logic;
	signal internal_CLOCK_150MHz_BUFG          : std_logic;
	signal rst : std_logic := '1';
	signal rst_counter : UNSIGNED(7 downto 0) := "00000000";
	signal PLL_LOCKED_out : std_logic;
	signal MON_out : STD_LOGIC_VECTOR(15 DOWNTO 0);
	
	signal CLK0_40 : std_logic;
	signal LOCKED_40 : std_logic;
	signal CLKFB_40 : std_logic;
	
	signal CLK0_150 : std_logic;
	signal LOCKED_150 : std_logic;
	signal CLKDV_150 : std_logic;
	signal CLKFB_150 : std_logic;
	
	signal internal_EVT_OUT_FIFO_DATA         : std_logic_vector(31 downto 0);
	signal internal_EVT_OUT_FIFO_WRITE_ENABLE : std_logic;
	signal internal_EVT_OUT_FIFO_WRITE_CLOCK  : std_logic;
	signal internal_EVT_OUT_FIFO_FULL         : std_logic;
	signal internal_EVT_INP_FIFO_DATA         : std_logic_vector(31 downto 0);
	signal internal_EVT_INP_FIFO_READ_ENABLE  : std_logic;
	signal internal_EVT_INP_FIFO_READ_CLOCK   : std_logic;
	signal internal_EVT_INP_FIFO_EMPTY        : std_logic;
	signal internal_EVT_INP_FIFO_VALID        : std_logic;
	signal internal_TRG_OUT_FIFO_DATA         : std_logic_vector(31 downto 0);
	signal internal_TRG_OUT_FIFO_WRITE_ENABLE : std_logic;
	signal internal_TRG_OUT_FIFO_WRITE_CLOCK  : std_logic;
	signal internal_TRG_OUT_FIFO_FULL         : std_logic;
	signal internal_TRG_INP_FIFO_DATA         : std_logic_vector(31 downto 0);
	signal internal_TRG_INP_FIFO_READ_ENABLE  : std_logic;
	signal internal_TRG_INP_FIFO_READ_CLOCK   : std_logic;
	signal internal_TRG_INP_FIFO_EMPTY        : std_logic;
	signal internal_TRG_INP_FIFO_VALID        : std_logic;
	
	--signals to propagate RAMP, START signals out\
	--signal RAMP_out : std_logic;
	--signal START_out : std_logic;
	signal STARTRAMP_out : std_logic;
	
begin
	--Simple connection between the event output to event input and trg output to trig input
	internal_EVT_OUT_FIFO_DATA         <= internal_EVT_INP_FIFO_DATA;
	internal_EVT_OUT_FIFO_WRITE_ENABLE <= internal_EVT_INP_FIFO_VALID;
	internal_EVT_INP_FIFO_READ_ENABLE  <= (not(internal_EVT_INP_FIFO_EMPTY)) and (not(internal_EVT_OUT_FIFO_FULL));
	internal_TRG_OUT_FIFO_DATA         <= internal_TRG_INP_FIFO_DATA;
	internal_TRG_OUT_FIFO_WRITE_ENABLE <= internal_TRG_INP_FIFO_VALID;
	internal_TRG_INP_FIFO_READ_ENABLE  <= (not(internal_TRG_INP_FIFO_EMPTY)) and (not(internal_TRG_OUT_FIFO_FULL));
	--Use the same clock for everything:
	internal_EVT_OUT_FIFO_WRITE_CLOCK <= internal_CLOCK_40MHz_BUFG;
	internal_EVT_INP_FIFO_READ_CLOCK  <= internal_CLOCK_40MHz_BUFG;
	internal_TRG_OUT_FIFO_WRITE_CLOCK <= internal_CLOCK_40MHz_BUFG;
	internal_TRG_INP_FIFO_READ_CLOCK  <= internal_CLOCK_40MHz_BUFG;

	--connect STARTRAMP_out to both START and RAMP output pins
	RAMP <= STARTRAMP_out;
	START <= STARTRAMP_out;

	--PLL_LOCKED from DCM LOCKED signals
	PLL_LOCKED <= LOCKED_40 AND LOCKED_150;
	--MON <= LOCKED_40 & LOCKED_150 & MON_out(13 downto 0);
	MON <= MON_out(15 downto 0);

	--clock input buffers
	map_board_40MHz_clock : ibufds
	port map(
		I  => BOARD_40MHz_CLOCKP,
		IB => BOARD_40MHz_CLOCKN,
		O  => internal_CLOCK_40MHz_BUFG
	);
	map_board_150MHz_clock : ibufds
	port map(
		I  => BOARD_150MHz_CLOCKP,
		IB => BOARD_150MHz_CLOCKN,
		O  => internal_CLOCK_150MHz_BUFG
	);	
	
	--terrible hack to generate initial reset signal
	process (internal_CLOCK_40MHz_BUFG) begin
		if( rising_edge(internal_CLOCK_40MHz_BUFG) ) then
			IF (rst_counter = "11001010") THEN
				rst <= '0';
				rst_counter <= rst_counter;
			else
				rst <= '1';
				rst_counter <= rst_counter + 1;
			end if;
		end if;
	end process;
	
	-- DCM: Digital Clock Manager Circuit
   -- Spartan-3
   -- Xilinx HDL Language Template, version 13.2
   DCM_inst_40 : DCM
   generic map (
      CLKDV_DIVIDE => 2.0, --  Divide by: 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5
                           --     7.0,7.5,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0 or 16.0
      CLKFX_DIVIDE => 1,   --  Can be any interger from 1 to 32
      CLKFX_MULTIPLY => 4, --  Can be any integer from 1 to 32
      CLKIN_DIVIDE_BY_2 => FALSE, --  TRUE/FALSE to enable CLKIN divide by two feature
      CLKIN_PERIOD => 25.0,          --  Specify period of input clock
      CLKOUT_PHASE_SHIFT => "NONE", --  Specify phase shift of NONE, FIXED or VARIABLE
      CLK_FEEDBACK => "1X",         --  Specify clock feedback of NONE, 1X or 2X
      DESKEW_ADJUST => "SYSTEM_SYNCHRONOUS", --  SOURCE_SYNCHRONOUS, SYSTEM_SYNCHRONOUS or
                                             --     an integer from 0 to 15
      DFS_FREQUENCY_MODE => "LOW",     --  HIGH or LOW frequency mode for frequency synthesis
      DLL_FREQUENCY_MODE => "LOW",     --  HIGH or LOW frequency mode for DLL
      DUTY_CYCLE_CORRECTION => TRUE, --  Duty cycle correction, TRUE or FALSE
      FACTORY_JF => X"C080",          --  FACTORY JF Values
      PHASE_SHIFT => 0,        --  Amount of fixed phase shift from -255 to 255
      SIM_MODE => "SAFE", -- Simulation: "SAFE" vs "FAST", see "Synthesis and Simulation
                          -- Design Guide" for details
      STARTUP_WAIT => FALSE) --  Delay configuration DONE until DCM LOCK, TRUE/FALSE
   port map (
      CLK0 => CLK0_40,     -- 0 degree DCM CLK ouptput
      CLK180 => open, -- 180 degree DCM CLK output
      CLK270 => open, -- 270 degree DCM CLK output
      CLK2X => open,   -- 2X DCM CLK output
      CLK2X180 => open, -- 2X, 180 degree DCM CLK out
      CLK90 => open,   -- 90 degree DCM CLK output
      CLKDV => open,   -- Divided DCM CLK out (CLKDV_DIVIDE)
      CLKFX => open,   -- DCM CLK synthesis out (M/D)
      CLKFX180 => open, -- 180 degree CLK synthesis out
      LOCKED => LOCKED_40, -- DCM LOCK status output
      PSDONE => open, -- Dynamic phase adjust done output
      STATUS => open, -- 8-bit DCM status bits output
      CLKFB => CLKFB_40,   -- DCM clock feedback
      CLKIN => internal_CLOCK_40MHz_BUFG,   -- Clock input (from IBUFG, BUFG or DCM)
      PSCLK => open,   -- Dynamic phase adjust clock input
      PSEN => open,     -- Dynamic phase adjust enable input
      PSINCDEC => open, -- Dynamic phase adjust increment/decrement
      RST => rst        -- DCM asynchronous reset input
   );
   -- End of DCM_inst instantiation	
	
	--feedback clock input buffers
	map_board_feedback_clock_40 : bufg
	port map(
		I  => CLK0_40,
		O  => CLKFB_40
	);
	
	-- DCM: Digital Clock Manager Circuit
   -- Spartan-3
   -- Xilinx HDL Language Template, version 13.2
   DCM_inst_150 : DCM
   generic map (
      CLKDV_DIVIDE => 2.0, --  Divide by: 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5
                           --     7.0,7.5,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0 or 16.0
      CLKFX_DIVIDE => 1,   --  Can be any interger from 1 to 32
      CLKFX_MULTIPLY => 4, --  Can be any integer from 1 to 32
      CLKIN_DIVIDE_BY_2 => FALSE, --  TRUE/FALSE to enable CLKIN divide by two feature
      CLKIN_PERIOD => 6.666,          --  Specify period of input clock
      CLKOUT_PHASE_SHIFT => "NONE", --  Specify phase shift of NONE, FIXED or VARIABLE
      CLK_FEEDBACK => "1X",         --  Specify clock feedback of NONE, 1X or 2X
      DESKEW_ADJUST => "SYSTEM_SYNCHRONOUS", --  SOURCE_SYNCHRONOUS, SYSTEM_SYNCHRONOUS or
                                             --     an integer from 0 to 15
      DFS_FREQUENCY_MODE => "LOW",     --  HIGH or LOW frequency mode for frequency synthesis
      DLL_FREQUENCY_MODE => "LOW",     --  HIGH or LOW frequency mode for DLL
      DUTY_CYCLE_CORRECTION => TRUE, --  Duty cycle correction, TRUE or FALSE
      FACTORY_JF => X"C080",          --  FACTORY JF Values
      PHASE_SHIFT => 0,        --  Amount of fixed phase shift from -255 to 255
      SIM_MODE => "SAFE", -- Simulation: "SAFE" vs "FAST", see "Synthesis and Simulation
                          -- Design Guide" for details
      STARTUP_WAIT => FALSE) --  Delay configuration DONE until DCM LOCK, TRUE/FALSE
   port map (
      CLK0 => CLK0_150,     -- 0 degree DCM CLK ouptput
      CLK180 => open, -- 180 degree DCM CLK output
      CLK270 => open, -- 270 degree DCM CLK output
      CLK2X => open,   -- 2X DCM CLK output
      CLK2X180 => open, -- 2X, 180 degree DCM CLK out
      CLK90 => open,   -- 90 degree DCM CLK output
      CLKDV => CLKDV_150,   -- Divided DCM CLK out (CLKDV_DIVIDE)
      CLKFX => open,   -- DCM CLK synthesis out (M/D)
      CLKFX180 => open, -- 180 degree CLK synthesis out
      LOCKED => LOCKED_150, -- DCM LOCK status output
      PSDONE => open, -- Dynamic phase adjust done output
      STATUS => open, -- 8-bit DCM status bits output
      CLKFB => CLKFB_150,   -- DCM clock feedback
      CLKIN => internal_CLOCK_150MHz_BUFG,   -- Clock input (from IBUFG, BUFG or DCM)
      PSCLK => open,   -- Dynamic phase adjust clock input
      PSEN => open,     -- Dynamic phase adjust enable input
      PSINCDEC => open, -- Dynamic phase adjust increment/decrement
      RST => rst        -- DCM asynchronous reset input
   );
   -- End of DCM_inst instantiation	
	
	--feedback clock input buffers
	map_board_feedback_clock_150 : bufg
	port map(
		I  => CLK0_150,
		O  => CLKFB_150
	);

	map_daq_fifo_layer : entity work.daq_fifo_layer
	generic map(
		INCLUDE_AURORA => 0,
		INCLUDE_USB    => 1
	)
	port map (
		SYSTEM_40MHz_CLOCK  => CLKFB_40,
		SYSTEM_150MHz_CLOCK => CLKFB_150,
		SYSTEM_150MHz_CLOCK_DIV2 => CLKDV_150,
		SMA_CONN				  => SMA_CONN,
		rst 					  => rst,
		
		--FIFO signals for the 4 FIFOs
		FIFO_OUT_0_DATA     => internal_EVT_OUT_FIFO_DATA,
		FIFO_OUT_0_WR_EN    => internal_EVT_OUT_FIFO_WRITE_ENABLE,
		FIFO_OUT_0_WR_CLK   => internal_EVT_OUT_FIFO_WRITE_CLOCK,
		FIFO_OUT_0_FULL     => internal_EVT_OUT_FIFO_FULL,
		FIFO_INP_0_DATA     => internal_EVT_INP_FIFO_DATA,
		FIFO_INP_0_RD_EN    => internal_EVT_INP_FIFO_READ_ENABLE,
		FIFO_INP_0_RD_CLK   => internal_EVT_INP_FIFO_READ_CLOCK,
		FIFO_INP_0_EMPTY    => internal_EVT_INP_FIFO_EMPTY,
		FIFO_INP_0_VALID    => internal_EVT_INP_FIFO_VALID,
		FIFO_OUT_1_DATA     => internal_TRG_OUT_FIFO_DATA,
		FIFO_OUT_1_WR_EN    => internal_TRG_OUT_FIFO_WRITE_ENABLE,
		FIFO_OUT_1_WR_CLK   => internal_TRG_OUT_FIFO_WRITE_CLOCK,
		FIFO_OUT_1_FULL     => internal_TRG_OUT_FIFO_FULL,
		FIFO_INP_1_DATA     => internal_TRG_INP_FIFO_DATA,
		FIFO_INP_1_RD_EN    => internal_TRG_INP_FIFO_READ_ENABLE,
		FIFO_INP_1_RD_CLK   => internal_TRG_INP_FIFO_READ_CLOCK,
		FIFO_INP_1_EMPTY    => internal_TRG_INP_FIFO_EMPTY,
		FIFO_INP_1_VALID    => internal_TRG_INP_FIFO_VALID,

		--Signals that need to go to the top level for USB
		USB_IFCLK           => USB_IFCLK,
		USB_CTL0            => USB_CTL0,
		USB_CTL1            => USB_CTL1,
		USB_CTL2            => USB_CTL2,
		USB_FDD             => USB_FDD,
		USB_PA0             => USB_PA0,
		USB_PA1             => USB_PA1,
		USB_PA2             => USB_PA2,
		USB_PA3             => USB_PA3,
		USB_PA4             => USB_PA4,
		USB_PA5             => USB_PA5,
		USB_PA6             => USB_PA6,
		USB_PA7             => USB_PA7,
		USB_RDY0            => USB_RDY0,
		USB_RDY1            => USB_RDY1,
		USB_WAKEUP          => USB_WAKEUP,
		USB_CLKOUT          => USB_CLKOUT,

		--Signals that need to go to the top level for fiberoptic
		FIBER_0_RXP                 => FIBER_0_RXP,
		FIBER_0_RXN                 => FIBER_0_RXN,
		FIBER_1_RXP                 => FIBER_1_RXP,
		FIBER_1_RXN                 => FIBER_1_RXN,
		FIBER_0_TXP                 => FIBER_0_TXP,
		FIBER_0_TXN                 => FIBER_0_TXN,
		FIBER_1_TXP                 => FIBER_1_TXP,
		FIBER_1_TXN                 => FIBER_1_TXN,
		FIBER_REFCLKP               => FIBER_REFCLKP,
		FIBER_REFCLKN               => FIBER_REFCLKN,
		FIBER_0_DISABLE_TRANSCEIVER => FIBER_0_DISABLE_TRANSCEIVER,
		FIBER_1_DISABLE_TRANSCEIVER => FIBER_1_DISABLE_TRANSCEIVER,
		FIBER_0_LINK_UP             => FIBER_0_LINK_UP,
		FIBER_1_LINK_UP             => FIBER_1_LINK_UP,
		FIBER_0_LINK_ERR            => FIBER_0_LINK_ERR,
		FIBER_1_LINK_ERR            => FIBER_1_LINK_ERR,
		
		--TARGET RELATED
		--DAC_MON
		SCK_DAC            => SCK_DAC,
		DIN_DAC            => DIN_DAC,
		CS_DAC            => CS_DAC,
		
		SCL_MUX            => SCL_MUX,
		SDA_MUX            => SDA_MUX,
		
		SCL_MON            => SCL_MON,
		SDA_MON            => SDA_MON,
		
		SSTIN            => SSTIN,
		SSPIN            => SSPIN,
		RD_ROWSEL            => RD_ROWSEL,
		RD_COLSEL            => RD_COLSEL,
		RD_ENA            => RD_ENA,
		TST_START            => TST_START,
		TST_BOIN_CLR            => TST_BOIN_CLR,
		SIN            => SIN ,
		SCLK            => SCLK,
		REGCLR            => REGCLR,
		WR_ADDRCLR            => WR_ADDRCLR,
		WR_STRB            => WR_STRB,
		--START            => START_out,
		--RAMP            => RAMP_out ,
		STARTRAMP            => STARTRAMP_out,
		SAMPLESEL            => SAMPLESEL,
		SAMPLESEL_ANY            => SAMPLESEL_ANY,
		PCLK            => PCLK,
		WR_ADVCLK            => WR_ADVCLK,
		WR_ENA            => WR_ENA,
		CLR            => CLR,
		SR_SEL            => SR_SEL,
		SR_CLOCK            => SR_CLOCK,
		SR_CLEAR            => SR_CLEAR,
		
		MON            => MON_out,
		LMON            => LMON,
		
		DO            => DO,
		SSPOUT            => SSPOUT,
		RCO            => RCO,
		TRG_16            => TRG_16,
		TRG            => TRG,
		
		TRGIN            => TRGIN,
		
		TRGMON            => TRGMON,
		SHOUT            => SHOUT,
		TSTOUT            => TSTOUT,
		SW            => SW
	);

end Behavioral;

