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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity daq_top is
	Port ( 
		BOARD_CLOCKP                : in  STD_LOGIC;
		BOARD_CLOCKN                : in  STD_LOGIC;
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
		USB_CLKOUT		             : in  STD_LOGIC
	);
end daq_top;

architecture Behavioral of daq_top is
	signal internal_BOARD_CLOCK               : std_logic;
	signal internal_CLOCK_50MHz_BUFG          : std_logic;

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
	
begin

	--Simple connection between the event output to event input and trg output to trig input
	internal_EVT_OUT_FIFO_DATA         <= internal_EVT_INP_FIFO_DATA;
	internal_EVT_OUT_FIFO_WRITE_ENABLE <= internal_EVT_INP_FIFO_VALID;
	internal_EVT_INP_FIFO_READ_ENABLE  <= (not(internal_EVT_INP_FIFO_EMPTY)) and (not(internal_EVT_OUT_FIFO_FULL));
	internal_TRG_OUT_FIFO_DATA         <= internal_TRG_INP_FIFO_DATA;
	internal_TRG_OUT_FIFO_WRITE_ENABLE <= internal_TRG_INP_FIFO_VALID;
	internal_TRG_INP_FIFO_READ_ENABLE  <= (not(internal_TRG_INP_FIFO_EMPTY)) and (not(internal_TRG_OUT_FIFO_FULL));
	--Use the same clock for everything:
	internal_EVT_OUT_FIFO_WRITE_CLOCK <= internal_CLOCK_50MHz_BUFG;
	internal_EVT_INP_FIFO_READ_CLOCK  <= internal_CLOCK_50MHz_BUFG;
	internal_TRG_OUT_FIFO_WRITE_CLOCK <= internal_CLOCK_50MHz_BUFG;
	internal_TRG_INP_FIFO_READ_CLOCK  <= internal_CLOCK_50MHz_BUFG;

	map_board_clock : ibufds
	port map(
		I  => BOARD_CLOCKP,
		IB => BOARD_CLOCKN,
		O  => internal_BOARD_CLOCK
	);
	map_clockgen : entity work.clockgen
	port map (
		-- Clock in ports
		CLK_IN1 => internal_BOARD_CLOCK,
		-- Clock out ports
		CLK_OUT1 => internal_CLOCK_50MHz_BUFG,
		-- Status and control signals
		LOCKED => PLL_LOCKED
	);

	map_daq_fifo_layer : entity work.daq_fifo_layer
	generic map(
		INCLUDE_AURORA => 1,
		INCLUDE_USB    => 1
	)
	port map (
		SYSTEM_CLOCK        => internal_CLOCK_50MHz_BUFG,
		
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
		FIBER_1_LINK_ERR            => FIBER_1_LINK_ERR
	);

end Behavioral;

