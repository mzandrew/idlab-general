----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:20:38 10/25/2012 
-- Design Name: 
-- Module Name:    scrod_top - Behavioral 
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
library UNISIM;
use UNISIM.VComponents.all;
use work.readout_definitions.all;

entity scrod_top is
	Port(
		BOARD_CLOCKP                : in  STD_LOGIC;
		BOARD_CLOCKN                : in  STD_LOGIC;
		LEDS                        : out STD_LOGIC_VECTOR(15 downto 0);

--		--I2C addresses
--		--Bus A handles SCROD temperature sensor and SCROD EEPROM
--		I2C_BUSA_SCL                : inout STD_LOGIC;
--		I2C_BUSA_SDA                : inout STD_LOGIC;
--		--Bus B handles SCROD fiberoptic transceiver 0
--		I2C_BUSB_SCL                : inout STD_LOGIC;
--		I2C_BUSB_SDA                : inout STD_LOGIC;
--		--Bus C handles SCROD fiberoptic transceiver 1
--		I2C_BUSC_SCL                : inout STD_LOGIC;
--		I2C_BUSC_SDA                : inout STD_LOGIC;
--		--Other buses for daughter card / carrier level stuff can
--		--be inserted as necessary.

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
end scrod_top;

architecture Behavioral of scrod_top is
	signal internal_BOARD_CLOCK      : std_logic;
	signal internal_CLOCK_50MHz_BUFG : std_logic;
	signal internal_CLOCK_4MHz_BUFG  : std_logic;
	
	signal internal_OUTPUT_REGISTERS : GPR;
	signal internal_INPUT_REGISTERS  : RR;
	
begin

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
		CLK_OUT2 => internal_CLOCK_4MHz_BUFG,
		-- Status and control signals
		LOCKED => open
	);

	--Interface to the DAQ devices
	map_readout_interfaces : entity work.readout_interface
	port map ( 
		CLOCK                       => internal_CLOCK_50MHz_BUFG,

		OUTPUT_REGISTERS            => internal_OUTPUT_REGISTERS,
		INPUT_REGISTERS             => internal_INPUT_REGISTERS,

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

		USB_IFCLK                   => USB_IFCLK,
		USB_CTL0                    => USB_CTL0,
		USB_CTL1                    => USB_CTL1,
		USB_CTL2                    => USB_CTL2,
		USB_FDD                     => USB_FDD,
		USB_PA0                     => USB_PA0,
		USB_PA1                     => USB_PA1,
		USB_PA2                     => USB_PA2,
		USB_PA3                     => USB_PA3,
		USB_PA4                     => USB_PA4,
		USB_PA5                     => USB_PA5,
		USB_PA6                     => USB_PA6,
		USB_PA7                     => USB_PA7,
		USB_RDY0                    => USB_RDY0,
		USB_RDY1                    => USB_RDY1,
		USB_WAKEUP                  => USB_WAKEUP,
		USB_CLKOUT		             => USB_CLKOUT
	);

	--------------------------------------------------
	-------General registers interfaced to DAQ -------
	--------------------------------------------------
	
	--------Output register mapping-------------------
	LEDS <= internal_OUTPUT_REGISTERS(0);
	--------Input register mapping--------------------
	--Map the first N_GPR output registers to the first set of read registers
	gen_OUTREG_to_INREG: for i in 0 to N_GPR-1 generate
		gen_BIT: for j in 0 to 15 generate
			map_BUF_RR : BUF 
			port map( 
				I => internal_OUTPUT_REGISTERS(i)(j), 
				O => internal_INPUT_REGISTERS(i)(j) 
			);
		end generate;
	end generate;

end Behavioral;

