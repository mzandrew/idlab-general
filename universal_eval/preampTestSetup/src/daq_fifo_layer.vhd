----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:11:27 09/17/2012 
-- Design Name: 
-- Module Name:    daq_fifo_layer - Behavioral 
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
use work.utilities.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity daq_fifo_layer is
	Generic (
		INCLUDE_AURORA : integer :=   0;
		INCLUDE_USB    : integer :=   1
	);
	Port ( 
		--System clock input, used for detecting USB
		SYSTEM_40MHz_CLOCK        : in STD_LOGIC;
		SYSTEM_150MHz_CLOCK : in STD_LOGIC;
		SYSTEM_150MHz_CLOCK_DIV2 : in STD_LOGIC;
		SMA_CONN : out STD_LOGIC;
		rst : in STD_LOGIC;
		
		--FIFO signals for the 4 FIFOs
		FIFO_OUT_0_DATA     : in  STD_LOGIC_VECTOR(31 downto 0);
		FIFO_OUT_0_WR_EN    : in  STD_LOGIC;
		FIFO_OUT_0_WR_CLK   : in  STD_LOGIC;
		FIFO_OUT_0_FULL     : out STD_LOGIC;
		FIFO_INP_0_DATA     : out STD_LOGIC_VECTOR(31 downto 0);
		FIFO_INP_0_RD_EN    : in  STD_LOGIC;
		FIFO_INP_0_RD_CLK   : in  STD_LOGIC;
		FIFO_INP_0_EMPTY    : out STD_LOGIC;
		FIFO_INP_0_VALID    : out STD_LOGIC;
		FIFO_OUT_1_DATA     : in  STD_LOGIC_VECTOR(31 downto 0);
		FIFO_OUT_1_WR_EN    : in  STD_LOGIC;
		FIFO_OUT_1_WR_CLK   : in  STD_LOGIC;
		FIFO_OUT_1_FULL     : out STD_LOGIC;
		FIFO_INP_1_DATA     : out STD_LOGIC_VECTOR(31 downto 0);
		FIFO_INP_1_RD_EN    : in  STD_LOGIC;
		FIFO_INP_1_RD_CLK   : in  STD_LOGIC;
		FIFO_INP_1_EMPTY    : out STD_LOGIC;
		FIFO_INP_1_VALID    : out STD_LOGIC;
		
		--Signals that need to go to the top level for USB
		USB_IFCLK           : in  STD_LOGIC;
		USB_CTL0            : in  STD_LOGIC;
		USB_CTL1            : in  STD_LOGIC;
		USB_CTL2            : in  STD_LOGIC;
		USB_FDD             : inout STD_LOGIC_VECTOR(15 downto 0);
		USB_PA0             : out STD_LOGIC;
		USB_PA1             : out STD_LOGIC;
		USB_PA2             : out STD_LOGIC;
		USB_PA3             : out STD_LOGIC;
		USB_PA4             : out STD_LOGIC;
		USB_PA5             : out STD_LOGIC;
		USB_PA6             : out STD_LOGIC;
		USB_PA7             : in  STD_LOGIC;
		USB_RDY0            : out STD_LOGIC;
		USB_RDY1            : out STD_LOGIC;
		USB_WAKEUP          : in  STD_LOGIC;
		USB_CLKOUT          : in  STD_LOGIC;

		--Signals that need to go to the top level for fiberoptic
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
		--START				:	OUT STD_LOGIC;		--start Wilkinson Conversion
		--RAMP				:	OUT STD_LOGIC;
		STARTRAMP				:	OUT STD_LOGIC;
		SAMPLESEL		:	OUT STD_LOGIC_VECTOR(5 DOWNTO 1);
		SAMPLESEL_ANY		:	OUT STD_LOGIC;
		PCLK				:	OUT STD_LOGIC;
		WR_ADVCLK		:	OUT STD_LOGIC;
		WR_ENA			:	OUT STD_LOGIC;
		CLR				:	OUT STD_LOGIC;		--Clear Wilkinson Counter
		SR_SEL			:	OUT STD_LOGIC;
		SR_CLOCK			:	OUT STD_LOGIC;
		SR_CLEAR			:	OUT STD_LOGIC;
		
		--MON				:	OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
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
end daq_fifo_layer;

architecture Behavioral of daq_fifo_layer is
	signal internal_TOGGLE_DAQ_TO_FIBER  : std_logic;

	signal internal_USB_PRESENT          : std_logic;
	signal internal_USB_PRESENT_out          : std_logic;

	signal internal_FIBER_0_LANE_UP      : std_logic;
	signal internal_FIBER_1_LANE_UP      : std_logic;
	signal internal_FIBER_0_CHANNEL_UP   : std_logic;
	signal internal_FIBER_1_CHANNEL_UP   : std_logic;
	signal internal_FIBER_0_LINK_UP      : std_logic;
	signal internal_FIBER_1_LINK_UP      : std_logic;
	signal internal_FIBER_0_LINK_ERR     : std_logic;
	signal internal_FIBER_1_LINK_ERR     : std_logic;
	signal internal_FIBER_0_HARD_ERR     : std_logic;
	signal internal_FIBER_1_HARD_ERR     : std_logic;
	signal internal_FIBER_0_SOFT_ERR     : std_logic;
	signal internal_FIBER_1_SOFT_ERR     : std_logic;
	signal internal_FIBER_0_TX_DATA_LSB_TO_MSB : std_logic_vector(0 to 31);
	signal internal_FIBER_1_TX_DATA_LSB_TO_MSB : std_logic_vector(0 to 31);
	signal internal_FIBER_0_RX_DATA_LSB_TO_MSB : std_logic_vector(0 to 31);
	signal internal_FIBER_1_RX_DATA_LSB_TO_MSB : std_logic_vector(0 to 31);
	signal internal_FIBER_0_TX_DATA_MSB_TO_LSB : std_logic_vector(31 downto 0);
	signal internal_FIBER_1_TX_DATA_MSB_TO_LSB : std_logic_vector(31 downto 0);
	signal internal_FIBER_0_RX_DATA_MSB_TO_LSB : std_logic_vector(31 downto 0);
	signal internal_FIBER_1_RX_DATA_MSB_TO_LSB : std_logic_vector(31 downto 0);
	signal internal_FIBER_0_TX_DATA_TVALID     : std_logic;
	signal internal_FIBER_1_TX_DATA_TVALID     : std_logic;
	signal internal_FIBER_0_TX_DATA_TREADY     : std_logic;
	signal internal_FIBER_1_TX_DATA_TREADY     : std_logic;
	signal internal_FIBER_0_TX_READ_ENABLE     : std_logic;
	signal internal_FIBER_1_TX_READ_ENABLE     : std_logic;
	signal internal_FIBER_0_RX_DATA_TVALID     : std_logic;
	signal internal_FIBER_1_RX_DATA_TVALID     : std_logic;
--	signal internal_FIBER_0_USER_CLOCK         : std_logic;
--	signal internal_FIBER_1_USER_CLOCK         : std_logic;
	signal internal_FIBER_USER_CLOCK           : std_logic;
	signal internal_FIBER_0_TX_DATA_TVALID_STATE_reg : std_logic_vector(1 downto 0) := (others => '0');
	signal internal_FIBER_1_TX_DATA_TVALID_STATE_reg : std_logic_vector(1 downto 0) := (others => '0');
	signal internal_FIBER_0_TX_DATA_TVALID_NEXT_STATE : std_logic_vector(1 downto 0) := (others => '0');
	signal internal_FIBER_1_TX_DATA_TVALID_NEXT_STATE : std_logic_vector(1 downto 0) := (others => '0');
	
	signal internal_USB_CLOCK                  : std_logic;
	signal internal_USB_RESET                  : std_logic;
	signal internal_USB_EP2_DATA_16BIT         : std_logic_vector(15 downto 0);
	signal internal_USB_EP2_DATA_32BIT         : std_logic_vector(31 downto 0);
	signal internal_USB_EP2_WRITE_ENABLE       : std_logic;
	signal internal_USB_EP2_READ_ENABLE        : std_logic;
	signal internal_USB_EP2_READ_ENABLE_reg    : std_logic;
	signal internal_USB_EP2_FULL               : std_logic;
	signal internal_USB_EP2_EMPTY              : std_logic;
	signal internal_USB_EP4_DATA_16BIT         : std_logic_vector(15 downto 0);
	signal internal_USB_EP4_DATA_32BIT         : std_logic_vector(31 downto 0);
	signal internal_USB_EP4_WRITE_ENABLE       : std_logic;
	signal internal_USB_EP4_READ_ENABLE        : std_logic;
	signal internal_USB_EP4_READ_ENABLE_reg    : std_logic;
	signal internal_USB_EP4_FULL               : std_logic;
	signal internal_USB_EP4_EMPTY              : std_logic;
	signal internal_USB_EP6_DATA_16BIT         : std_logic_vector(15 downto 0);
	signal internal_USB_EP6_DATA_32BIT         : std_logic_vector(31 downto 0);
	signal internal_USB_EP6_READ_ENABLE        : std_logic;
	signal internal_USB_EP6_WRITE_ENABLE       : std_logic;
	signal internal_USB_EP6_WRITE_ENABLE_reg   : std_logic;
	signal internal_USB_EP6_EMPTY              : std_logic;
	signal internal_USB_EP6_FULL               : std_logic;
	signal internal_USB_EP8_DATA_16BIT         : std_logic_vector(15 downto 0);
	signal internal_USB_EP8_DATA_32BIT         : std_logic_vector(31 downto 0);
	signal internal_USB_EP8_READ_ENABLE        : std_logic;
	signal internal_USB_EP8_WRITE_ENABLE       : std_logic;
	signal internal_USB_EP8_WRITE_ENABLE_reg   : std_logic;
	signal internal_USB_EP8_EMPTY              : std_logic;
	signal internal_USB_EP8_FULL               : std_logic;

	signal internal_USB_TX_0_READ_ENABLE       : std_logic;
	signal internal_USB_TX_1_READ_ENABLE       : std_logic;
	signal internal_USB_RX_0_WRITE_ENABLE      : std_logic;
	signal internal_USB_RX_1_WRITE_ENABLE      : std_logic;
	signal internal_USB_RX_0_VALID             : std_logic;
	signal internal_USB_RX_1_VALID             : std_logic;
	
	signal internal_FIFO_OUT_0_READ_CLOCK      : std_logic;
	signal internal_FIFO_OUT_0_READ_ENABLE     : std_logic;
	signal internal_FIFO_OUT_0_EMPTY           : std_logic;
	signal internal_FIFO_OUT_0_FULL            : std_logic;
	signal internal_FIFO_OUT_0_READ_DATA       : std_logic_vector(31 downto 0);
	signal internal_FIFO_OUT_0_VALID           : std_logic;
	signal internal_FIFO_OUT_0_WRITE_ENABLE    : std_logic;
	signal internal_FIFO_OUT_0_WRITE_DATA      : std_logic_vector(31 downto 0);
	signal internal_FIFO_OUT_1_READ_CLOCK      : std_logic;
	signal internal_FIFO_OUT_1_READ_ENABLE     : std_logic;
	signal internal_FIFO_OUT_1_EMPTY           : std_logic;
	signal internal_FIFO_OUT_1_FULL            : std_logic;
	signal internal_FIFO_OUT_1_READ_DATA       : std_logic_vector(31 downto 0);
	signal internal_FIFO_OUT_1_VALID           : std_logic;
	signal internal_FIFO_OUT_1_WRITE_ENABLE    : std_logic;
	signal internal_FIFO_OUT_1_WRITE_DATA      : std_logic_vector(31 downto 0);
	
	signal internal_FIFO_INP_0_WRITE_CLOCK     : std_logic;
	signal internal_FIFO_INP_0_WRITE_ENABLE    : std_logic;
	signal internal_FIFO_INP_0_FULL            : std_logic;
	signal internal_FIFO_INP_0_EMPTY           : std_logic;
	signal internal_FIFO_INP_0_WRITE_DATA      : std_logic_vector(31 downto 0);
	signal internal_FIFO_INP_0_READ_DATA       : std_logic_vector(31 downto 0);
	signal internal_FIFO_INP_0_READ_ENABLE     : std_logic;
	signal internal_FIFO_INP_0_VALID           : std_logic;
	signal internal_FIFO_INP_1_WRITE_CLOCK     : std_logic;
	signal internal_FIFO_INP_1_WRITE_ENABLE    : std_logic;
	signal internal_FIFO_INP_1_FULL            : std_logic;
	signal internal_FIFO_INP_1_EMPTY           : std_logic;
	signal internal_FIFO_INP_1_WRITE_DATA      : std_logic_vector(31 downto 0);
	signal internal_FIFO_INP_1_READ_DATA       : std_logic_vector(31 downto 0);
	signal internal_FIFO_INP_1_READ_ENABLE     : std_logic;
	signal internal_FIFO_INP_1_VALID           : std_logic;

	signal internal_FIFO_CLOCK                 : std_logic;

	signal internal_CHIPSCOPE_CONTROL          : std_logic_vector(35 downto 0);
	signal internal_CHIPSCOPE_SYNC_IN          : std_logic_vector(63 downto 0);
	signal internal_CHIPSCOPE_SYNC_OUT         : std_logic_vector(15 downto 0);
	signal internal_CHIPSCOPE_ILA              : std_logic_vector(127 downto 0);
	
	signal tempReg										 : std_logic;
	signal MSG_set								: STD_LOGIC;
	signal MSG_rec								: STD_LOGIC;
	signal MSG									: STD_LOGIC;
	
	signal startRead : STD_LOGIC;
	signal StoreWrite : std_logic_vector(15 downto 0);
	signal sReadCount : std_logic_vector(7 downto 0);

	signal step_cnt : STD_LOGIC_VECTOR(2 downto 0);
	signal sampleTest : STD_LOGIC_VECTOR(11 downto 0);
	signal FIFO_WR_EN_test : STD_LOGIC;
	signal FIFO_WR_CLK_test : STD_LOGIC;
	signal FIFO_WR_DIN_test : STD_LOGIC_VECTOR(31 downto 0);
	signal FIFO_RD_EN_test : STD_LOGIC;
	signal FIFO_RD_CLK_test : STD_LOGIC;
	signal FIFO_RD_test_dout : STD_LOGIC_VECTOR(31 downto 0);
	signal MON_usb_test	: STD_LOGIC_VECTOR(31 downto 0);
	signal CUR_STATE_usb_test : STD_LOGIC_VECTOR(3 downto 0);
	signal internal_FIFO_INP_1_READ_ENABLE_test : STD_LOGIC;
	signal FIFO_INP_1_RD_CLK_test : STD_LOGIC;
	signal internal_FIFO_INP_1_READ_DATA_test : STD_LOGIC_VECTOR(31 downto 0);
	
	component usb_top
	Port (
		IFCLK						:	IN		STD_LOGIC;
		CTL0						:	IN		STD_LOGIC;
		CTL1						:	IN		STD_LOGIC;
		CTL2						:	IN		STD_LOGIC;
		FDD						:	INOUT		STD_LOGIC_VECTOR(15 downto 0);
		PA0						:	out		STD_LOGIC;
		PA1						:	out		STD_LOGIC;
		PA2						:	out		STD_LOGIC;
		PA3						:	out		STD_LOGIC;
		PA4						:	out		STD_LOGIC;
		PA5						:	out		STD_LOGIC;
		PA6						:	out		STD_LOGIC;
		PA7						:	IN		STD_LOGIC;
		RDY0						:	out		STD_LOGIC;
		RDY1						:	out		STD_LOGIC;
		WAKEUP					:	IN		STD_LOGIC;
		CLKOUT					:	IN		STD_LOGIC;
		USB_RESET				:	out		STD_LOGIC;
		FIFO_CLOCK				:	out		STD_LOGIC;
		EP2_DATA					:	out		STD_LOGIC_VECTOR(15 downto 0);
		EP2_WRITE_ENABLE		:	out		STD_LOGIC;
		EP2_FULL					:	IN		STD_LOGIC;
		EP4_DATA					:	out		STD_LOGIC_VECTOR(15 downto 0);
		EP4_WRITE_ENABLE		:	out		STD_LOGIC;
		EP4_FULL					:	IN		STD_LOGIC;
		EP6_DATA					:	IN		STD_LOGIC_VECTOR(15 downto 0);
		EP6_READ_ENABLE		:	out		STD_LOGIC;
		EP6_EMPTY				:	IN		STD_LOGIC;
		EP8_DATA					:	IN		STD_LOGIC_VECTOR(15 downto 0);
		EP8_READ_ENABLE		:	out		STD_LOGIC;
		EP8_EMPTY				:	IN		STD_LOGIC
	);
	end component usb_top;
	
begin
	SCL_MON <= '1';
	--SDA_MON <= 'Z';
	SDA_MON <= '1';

	--Port mapping
	FIBER_0_LINK_UP <= internal_FIBER_0_LINK_UP;
	FIBER_0_LINK_ERR <= internal_FIBER_0_LINK_ERR;
	FIBER_1_LINK_UP <= internal_FIBER_1_LINK_UP;
	FIBER_1_LINK_ERR <= internal_FIBER_1_LINK_ERR;

	FIFO_INP_0_EMPTY <= internal_FIFO_INP_0_EMPTY;
	FIFO_INP_0_DATA <= internal_FIFO_INP_0_READ_DATA;
	FIFO_INP_0_VALID <= internal_FIFO_INP_0_VALID;
	internal_FIFO_INP_0_READ_ENABLE <= FIFO_INP_0_RD_EN;

	FIFO_INP_1_EMPTY <= internal_FIFO_INP_1_EMPTY;
	FIFO_INP_1_DATA <= internal_FIFO_INP_1_READ_DATA;
	FIFO_INP_1_VALID <= internal_FIFO_INP_1_VALID;
	internal_FIFO_INP_1_READ_ENABLE <= FIFO_INP_1_RD_EN;

	FIFO_OUT_0_FULL  <= internal_FIFO_OUT_0_FULL;
	FIFO_OUT_1_FULL  <= internal_FIFO_OUT_1_FULL;
	internal_FIFO_OUT_0_WRITE_ENABLE <= FIFO_OUT_0_WR_EN;
	internal_FIFO_OUT_1_WRITE_ENABLE <= FIFO_OUT_1_WR_EN;
	internal_FIFO_OUT_0_WRITE_DATA <= FIFO_OUT_0_DATA;
	internal_FIFO_OUT_1_WRITE_DATA <= FIFO_OUT_1_DATA;
	
	--Switch over to fiberoptic if USB connection is not present
	internal_TOGGLE_DAQ_TO_FIBER <= not(internal_USB_PRESENT);
	--internal_USB_RESET <= not(internal_USB_PRESENT);
	internal_USB_RESET <= rst;
	--When this happens, disable the transceivers to save power
	FIBER_0_DISABLE_TRANSCEIVER <= not(internal_TOGGLE_DAQ_TO_FIBER);
	FIBER_1_DISABLE_TRANSCEIVER <= not(internal_TOGGLE_DAQ_TO_FIBER);

	--Multiplex the fiberoptic and USB signals for the output FIFOs
	--map_clock_select : bufgmux
	--port map(
	--	I0 => internal_USB_CLOCK,
	--	I1 => internal_FIBER_USER_CLOCK,
	--	O  => internal_FIFO_CLOCK,
	--	S  => internal_TOGGLE_DAQ_TO_FIBER
	--);
	internal_FIFO_CLOCK <= internal_USB_CLOCK;
	
	--The following two lines assumed the USER CLOCK can be reused.  This avoids consuming BUFG resources,
	--but I need to verify that this is really okay...
	internal_FIFO_OUT_0_READ_CLOCK <= internal_FIFO_CLOCK;
	internal_FIFO_OUT_1_READ_CLOCK <= internal_FIFO_CLOCK;
												 
	internal_FIFO_OUT_0_READ_ENABLE <= internal_FIBER_0_TX_READ_ENABLE when (internal_TOGGLE_DAQ_TO_FIBER = '1') else
	                                   internal_USB_TX_0_READ_ENABLE when (internal_TOGGLE_DAQ_TO_FIBER = '0') else
                                      'X';
	internal_FIFO_OUT_1_READ_ENABLE <= internal_FIBER_1_TX_READ_ENABLE when (internal_TOGGLE_DAQ_TO_FIBER = '1') else
	                                   internal_USB_TX_1_READ_ENABLE when (internal_TOGGLE_DAQ_TO_FIBER = '0') else
                                      'X';

	--Multiplex the fiberoptic and USB signals for the input FIFOs

	--As above, the following two lines assumed the USER CLOCK can be reused.  This avoids consuming BUFG resources,
	--but I need to verify that this is really okay...
	internal_FIFO_INP_0_WRITE_CLOCK <= internal_FIFO_CLOCK;
	internal_FIFO_INP_1_WRITE_CLOCK <= internal_FIFO_CLOCK;

	internal_FIFO_INP_0_WRITE_ENABLE <= internal_FIBER_0_RX_DATA_TVALID when (internal_TOGGLE_DAQ_TO_FIBER = '1') else
	                                    internal_USB_RX_0_WRITE_ENABLE when (internal_TOGGLE_DAQ_TO_FIBER = '0') else
												  'X';
	internal_FIFO_INP_1_WRITE_ENABLE <= internal_FIBER_1_RX_DATA_TVALID when (internal_TOGGLE_DAQ_TO_FIBER = '1') else
	                                    internal_USB_RX_1_WRITE_ENABLE when (internal_TOGGLE_DAQ_TO_FIBER = '0') else
												  'X';
	internal_FIFO_INP_0_WRITE_DATA  <=  internal_FIBER_0_RX_DATA_MSB_TO_LSB when (internal_TOGGLE_DAQ_TO_FIBER = '1') else
	                                    internal_USB_EP2_DATA_32BIT when (internal_TOGGLE_DAQ_TO_FIBER = '0') else
													(others => 'X');
	internal_FIFO_INP_1_WRITE_DATA  <=  internal_FIBER_1_RX_DATA_MSB_TO_LSB when (internal_TOGGLE_DAQ_TO_FIBER = '1') else
	                                    internal_USB_EP4_DATA_32BIT when (internal_TOGGLE_DAQ_TO_FIBER = '0') else
													(others => 'X');

	--Instantiate the OUTPUT FIFOs
	map_output_fifo_0 : entity work.FIFO_OUT_0 --(Depth is 32k 32-bit words)
	PORT MAP (
		rst    => rst,
		wr_clk => FIFO_OUT_0_WR_CLK,
		rd_clk => internal_FIFO_OUT_0_READ_CLOCK,
		din    => internal_FIFO_OUT_0_WRITE_DATA,
		wr_en  => internal_FIFO_OUT_0_WRITE_ENABLE,
		rd_en  => internal_FIFO_OUT_0_READ_ENABLE,
		dout   => internal_FIFO_OUT_0_READ_DATA,
		full   => internal_FIFO_OUT_0_FULL,
		empty  => internal_FIFO_OUT_0_EMPTY,
		valid  => internal_FIFO_OUT_0_VALID
	);
	map_output_fifo_1 : entity work.FIFO_OUT_0 --(Depth is 512 32-bit words)
	PORT MAP (
		rst    => rst,
		wr_clk => FIFO_OUT_1_WR_CLK, --orginal
		--wr_clk => FIFO_WR_CLK_srout, -- FIFO controlled by readout
		--wr_clk => FIFO_WR_CLK_test, -- FIFO controlled by test module
		rd_clk => internal_FIFO_OUT_1_READ_CLOCK,
		din    => internal_FIFO_OUT_1_WRITE_DATA, --original
		--din    => FIFO_WR_DIN_srout, -- FIFO controlled by readout
		--din    => FIFO_WR_DIN_test, -- FIFO controlled by test module
		wr_en  => internal_FIFO_OUT_1_WRITE_ENABLE, --original
		--wr_en  => FIFO_WR_EN_srout, -- FIFO controlled by readout
		--wr_en  => FIFO_WR_EN_test, -- FIFO controlled by test module
		rd_en  => internal_FIFO_OUT_1_READ_ENABLE,
		dout   => internal_FIFO_OUT_1_READ_DATA,
		full   => internal_FIFO_OUT_1_FULL,
		empty  => internal_FIFO_OUT_1_EMPTY,
		valid  => internal_FIFO_OUT_1_VALID
	);
	
	--Instantiate the INPUT FIFOs
	map_input_fifo_0 : entity work.FIFO_INP_0 -- (Depth is 512 32-bit words)
	PORT MAP (
		rst    => rst,
		wr_clk => internal_FIFO_INP_0_WRITE_CLOCK,
		rd_clk => FIFO_INP_0_RD_CLK,
		din    => internal_FIFO_INP_0_WRITE_DATA,
		wr_en  => internal_FIFO_INP_0_WRITE_ENABLE,
		rd_en  => internal_FIFO_INP_0_READ_ENABLE,
		dout   => internal_FIFO_INP_0_READ_DATA,
		full   => internal_FIFO_INP_0_FULL,
		empty  => internal_FIFO_INP_0_EMPTY,
		valid  => internal_FIFO_INP_0_VALID
	);
	map_input_fifo_1 : entity work.FIFO_INP_0 -- (Depth is 512 32-bit words) [same as the other input FIFO, for now]
	PORT MAP (
		rst    => rst,
		wr_clk => internal_FIFO_INP_1_WRITE_CLOCK,
		rd_clk => FIFO_INP_1_RD_CLK, --original
		--rd_clk => FIFO_RD_CLK_test, --read in controlled by test module
		din    => internal_FIFO_INP_1_WRITE_DATA,
		wr_en  => internal_FIFO_INP_1_WRITE_ENABLE,
		rd_en  => internal_FIFO_INP_1_READ_ENABLE, --original
		--rd_en  => FIFO_RD_EN_test, --read in controlled by test module
		dout   => internal_FIFO_INP_1_READ_DATA, --original
		--dout   => FIFO_RD_test_dout, --read in controlled by test module
		full   => internal_FIFO_INP_1_FULL,  
		empty  => internal_FIFO_INP_1_EMPTY,
		valid  => internal_FIFO_INP_1_VALID
	);

	--Synthesize with the USB interface
	synthesize_with_usb : if INCLUDE_USB = 1 generate
		--We need some logic here that interfaces between the 16-bit USB
		--bus and the 32-bit FIFOs.  This is for now implemented with
		--relatively small 16 <--> 32 FIFOs.
		-------Endpoint 2------
		map_fifo_wr16_rd32_EP2 : entity work.fifo_wr16_rd32
		port map(
			rst    => internal_USB_RESET,
			wr_clk => internal_USB_CLOCK,
			rd_clk => internal_USB_CLOCK,
			--rd_clk => SYSTEM_CLOCK,
			din    => internal_USB_EP2_DATA_16BIT,
			wr_en  => internal_USB_EP2_WRITE_ENABLE,
			rd_en  => internal_USB_EP2_READ_ENABLE_reg,
			dout   => internal_USB_EP2_DATA_32BIT,
			full   => internal_USB_EP2_FULL,
			empty  => internal_USB_EP2_EMPTY,
			valid  => internal_USB_RX_0_VALID
		);
		internal_USB_EP2_READ_ENABLE <= (not(internal_USB_EP2_EMPTY)) and (not(internal_FIFO_INP_0_FULL));
		internal_USB_RX_0_WRITE_ENABLE <= internal_USB_RX_0_VALID;
		process(internal_USB_CLOCK) begin
			if (rising_edge(internal_USB_CLOCK)) then
				internal_USB_EP2_READ_ENABLE_reg <= internal_USB_EP2_READ_ENABLE;
			end if;
		end process;
		-------Endpoint 4------
		map_fifo_wr16_rd32_EP4 : entity work.fifo_wr16_rd32
		port map(
			rst    => internal_USB_RESET,
			wr_clk => internal_USB_CLOCK,
			--rd_clk => internal_USB_CLOCK, --original
			--rd_clk => SYSTEM_CLOCK,
			rd_clk => FIFO_RD_CLK_test, --read in controlled by test module
			din    => internal_USB_EP4_DATA_16BIT,
			wr_en  => internal_USB_EP4_WRITE_ENABLE,
			--rd_en  => internal_USB_EP4_READ_ENABLE_reg, --original
			rd_en  => FIFO_RD_EN_test, --read in controlled by test module
			--dout   => internal_USB_EP4_DATA_32BIT, --original
			dout   => FIFO_RD_test_dout, --read in controlled by test module
			full   => internal_USB_EP4_FULL,
			empty  => internal_USB_EP4_EMPTY,
			valid  => internal_USB_RX_1_VALID
		);
		--internal_USB_EP4_DATA_32BIT <= FIFO_RD_test_dout; --read in controlled by test module
		internal_USB_EP4_READ_ENABLE <= (not(internal_USB_EP4_EMPTY)) and (not(internal_FIFO_INP_1_FULL));
		internal_USB_RX_1_WRITE_ENABLE <= internal_USB_RX_1_VALID;
		process(internal_USB_CLOCK) begin
			if (rising_edge(internal_USB_CLOCK)) then
				internal_USB_EP4_READ_ENABLE_reg <= internal_USB_EP4_READ_ENABLE;
			end if;
		end process;
		-------Endpoint 6------
		map_fifo_wr32_rd16_EP6 : entity work.fifo_wr32_rd16
		port map(
			rst    => internal_USB_RESET,
			wr_clk => internal_USB_CLOCK,
			rd_clk => internal_USB_CLOCK,
			din    => internal_USB_EP6_DATA_32BIT,
			wr_en  => internal_USB_EP6_WRITE_ENABLE_reg,
			rd_en  => internal_USB_EP6_READ_ENABLE,
			dout   => internal_USB_EP6_DATA_16BIT,
			full   => internal_USB_EP6_FULL,
			empty  => internal_USB_EP6_EMPTY,
			valid  => open
		);
		internal_USB_EP6_DATA_32BIT <= internal_FIFO_OUT_0_READ_DATA;
		internal_USB_EP6_WRITE_ENABLE <= internal_FIFO_OUT_0_VALID;
		process(internal_USB_CLOCK) begin
			if (rising_edge(internal_USB_CLOCK)) then
				internal_USB_EP6_WRITE_ENABLE_reg <= internal_USB_EP6_WRITE_ENABLE;
			end if;
		end process;
		internal_USB_TX_0_READ_ENABLE <= (not(internal_FIFO_OUT_0_EMPTY)) and (not(internal_USB_EP6_FULL));		
		-------Endpoint 8------
		map_fifo_wr32_rd16_EP8 : entity work.fifo_wr32_rd16
		port map(
			rst    => internal_USB_RESET,
			--wr_clk => internal_USB_CLOCK, --original
			--wr_clk => FIFO_WR_CLK_srout, -- FIFO controlled by readout
			wr_clk => FIFO_WR_CLK_test, -- FIFO controlled by test module
			rd_clk => internal_USB_CLOCK,
			--din    => internal_USB_EP8_DATA_32BIT, --original
			--din    => FIFO_WR_DIN_srout, -- FIFO controlled by readout
			din    => FIFO_WR_DIN_test, -- FIFO controlled by test module
			--wr_en  => internal_USB_EP8_WRITE_ENABLE_reg, --original
			--wr_en  => FIFO_WR_EN_srout, -- FIFO controlled by readout
			wr_en  => FIFO_WR_EN_test, -- FIFO controlled by test module		
			rd_en  => internal_USB_EP8_READ_ENABLE,
			dout   => internal_USB_EP8_DATA_16BIT,
			full   => internal_USB_EP8_FULL,
			empty  => internal_USB_EP8_EMPTY,
			valid  => open
		);
		internal_USB_EP8_DATA_32BIT <= internal_FIFO_OUT_1_READ_DATA;
		internal_USB_EP8_WRITE_ENABLE <= internal_FIFO_OUT_1_VALID;
		process(internal_USB_CLOCK) begin
			if (rising_edge(internal_USB_CLOCK)) then
				internal_USB_EP8_WRITE_ENABLE_reg <= internal_USB_EP8_WRITE_ENABLE;
			end if;
		end process;
		internal_USB_TX_1_READ_ENABLE <= (not(internal_FIFO_OUT_1_EMPTY)) and (not(internal_USB_EP8_FULL));
		--Instantiate the USB top module
		--map_usb_interface : entity work.usb_top
		map_usb_interface : usb_top
		port map(
			IFCLK            => USB_IFCLK,
			CTL0             => USB_CTL0,
			CTL1             => USB_CTL1,
			CTL2             => USB_CTL2,
			FDD              => USB_FDD,
			PA0              => USB_PA0,
			PA1              => USB_PA1,
			PA2              => USB_PA2,
			PA3              => USB_PA3,
			PA4              => USB_PA4,
			PA5              => USB_PA5,
			PA6              => USB_PA6,
			PA7              => USB_PA7,
			RDY0             => USB_RDY0,
			RDY1             => USB_RDY1,
			WAKEUP           => USB_WAKEUP,
			CLKOUT           => USB_CLKOUT,
			--Reset signal from the USB code
			USB_RESET        => open,
			--Signals for interfacing to FIFOs
			FIFO_CLOCK       => internal_USB_CLOCK,
			EP2_DATA         => internal_USB_EP2_DATA_16BIT,
			EP2_WRITE_ENABLE => internal_USB_EP2_WRITE_ENABLE, 
			EP2_FULL         => internal_USB_EP2_FULL,
			EP4_DATA         => internal_USB_EP4_DATA_16BIT,
			EP4_WRITE_ENABLE => internal_USB_EP4_WRITE_ENABLE,
			EP4_FULL         => internal_USB_EP4_FULL,
			EP6_DATA         => internal_USB_EP6_DATA_16BIT,
			EP6_READ_ENABLE  => internal_USB_EP6_READ_ENABLE,
			EP6_EMPTY        => internal_USB_EP6_EMPTY,
			EP8_DATA         => internal_USB_EP8_DATA_16BIT,
			EP8_READ_ENABLE  => internal_USB_EP8_READ_ENABLE,
			EP8_EMPTY        => internal_USB_EP8_EMPTY
		);

	--map_detect_usb : entity work.detect_usb
	--port map(
	--	USB_CLOCK    => internal_USB_CLOCK,
	--	SYSTEM_CLOCK => SYSTEM_CLOCK,
	--	USB_PRESENT  => internal_USB_PRESENT_out
	--);
	end generate synthesize_with_usb;
	internal_USB_PRESENT <= '1';
	
	--synthesize_without_usb : if INCLUDE_USB = 0 generate
	--	internal_USB_PRESENT <= '0';
	--end generate synthesize_without_USB;
	
	--implement TARGET control signals
	Inst_TargetSignals: entity work.TargetSignals PORT MAP(
		system_40MHz_clk => SYSTEM_40MHz_CLOCK,
		system_150MHz_clk => SYSTEM_150MHz_CLOCK,
		system_150MHz_clk_div2 => SYSTEM_150MHz_CLOCK_DIV2,
		usb_clk => internal_USB_CLOCK,
		SMA_CONN	=> SMA_CONN,
		rst => rst,
		fifo_wr_en => FIFO_WR_EN_test,
		fifo_wr_clk => FIFO_WR_CLK_test,
		fifo_wr_din => FIFO_WR_DIN_test,
		fifo_rd_empty => internal_USB_EP4_EMPTY,
		fifo_rd_en => FIFO_RD_EN_test,
		fifo_rd_clk => FIFO_RD_CLK_test,
		fifo_rd_dout => FIFO_RD_test_dout,
		SCK_DAC => SCK_DAC,
		DIN_DAC => DIN_DAC,
		CS_DAC  => CS_DAC,
		mon => MON,
		sclk => SCLK,
		sin => SIN,
		regclr => REGCLR,
		pclk => PCLK,
		TST_START => TST_START,
		TST_BOIN_CLR => TST_BOIN_CLR,
		SSTIN => SSTIN,
		SSPIN	=> SSPIN,
		WR_ADVCLK => WR_ADVCLK,
		WR_ADDRCLR => WR_ADDRCLR,
		WR_ENA => WR_ENA,
		WR_STRB => WR_STRB,
		--START => START,
		--RAMP => RAMP,
		STARTRAMP => STARTRAMP,
		RD_ENA => RD_ENA,
		RD_ROWSEL => RD_ROWSEL,
		RD_COLSEL => RD_COLSEL,
		CLR => CLR,
		SR_SEL => SR_SEL,
		SR_CLOCK => SR_CLOCK,
		SR_CLEAR => SR_CLEAR,
		DO => DO,
		SAMPLESEL => SAMPLESEL,
		SAMPLESEL_ANY => SAMPLESEL_ANY,
		TRG_16 => TRG_16,
		TRG	 => TRG,
		TRGIN	 => TRGIN,
		TRGMON => TRGMON
	);
end Behavioral;