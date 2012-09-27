----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:18:26 09/21/2012 
-- Design Name: 
-- Module Name:    detect_usb - Behavioral 
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

entity detect_usb is
    Port ( USB_CLOCK    : in  STD_LOGIC;
           SYSTEM_CLOCK : in  STD_LOGIC;
           USB_PRESENT  : out  STD_LOGIC);
end detect_usb;

architecture Behavioral of detect_usb is
	signal internal_WATCHDOG_COUNTER      : unsigned(15 downto 0) := (others => '0');
	signal internal_WATCHDOG_COUNTER_LAST : unsigned(15 downto 0) := (others => '0');
	signal internal_READ_ENABLE_COUNTER   : unsigned(7 downto 0)  := (others => '0');
	signal internal_READ_ENABLE      : std_logic;
	signal internal_USB_PRESENT_reg  : std_logic;
	signal internal_USB_PRESENT      : std_logic;
begin
	--Free running counter on the USB clock.
	process(USB_CLOCK) begin
		if (rising_edge(USB_CLOCK)) then
			internal_WATCHDOG_COUNTER <= internal_WATCHDOG_COUNTER + 1;
		end if;
	end process;
	
	--Generate read enables so that we sample the counter once every
	--so often...
	process(SYSTEM_CLOCK) begin
		if (rising_edge(SYSTEM_CLOCK)) then
			internal_READ_ENABLE_COUNTER <= internal_READ_ENABLE_COUNTER + 1;
			internal_READ_ENABLE <= '0';
			if (internal_READ_ENABLE_COUNTER = x"00") then
				internal_READ_ENABLE <= '1';
			end if;
		end if;
	
	end process;
	--Asynchronously check the counter against the last value
	process (internal_WATCHDOG_COUNTER, internal_WATCHDOG_COUNTER_LAST) begin
		if (internal_WATCHDOG_COUNTER = internal_WATCHDOG_COUNTER_LAST) then
			internal_USB_PRESENT <= '0';
		else
			internal_USB_PRESENT <= '1';
		end if;
	end process;
	--Move the asynchronous signal into the system clock domain
	--And move this value of the counter to the last seen value.
	process(SYSTEM_CLOCK) begin
		if (rising_edge(SYSTEM_CLOCK)) then
			if (internal_READ_ENABLE = '1') then
				internal_USB_PRESENT_REG       <= internal_USB_PRESENT;
				internal_WATCHDOG_COUNTER_LAST <= internal_WATCHDOG_COUNTER;
			end if;
		end if;
	end process;
	--Send the registered signal out on the port
	USB_PRESENT <= internal_USB_PRESENT_REG;
	
end Behavioral;

