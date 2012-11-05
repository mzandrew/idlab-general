----------------------------------------------------------------------------------
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.math_real.log2;
use ieee.math_real.ceil;

entity clock_enable_generator is
	Generic (
		DIVIDE_RATIO : integer := 40
	);
	Port (
		CLOCK_IN         : in  std_logic;
		CLOCK_ENABLE_OUT : out std_logic
	);
end clock_enable_generator;

architecture Behavioral of clock_enable_generator is
	constant counter_width          : integer := integer(ceil(log2(real(DIVIDE_RATIO))));
	signal   internal_COUNTER       : unsigned(counter_width-1 downto 0) := (others => '0');
	signal   internal_COUNTER_RESET : std_logic := '0';
begin
	--simple counter
	process(CLOCK_IN) begin
		if (rising_edge(CLOCK_IN)) then
			if (internal_COUNTER_RESET = '1') then
				internal_COUNTER <= (others => '0');
			else
				internal_COUNTER <= internal_COUNTER + 1;
			end if;
		end if;
	end process;
	--comparator
	process(CLOCK_IN) begin
		if (rising_edge(CLOCK_IN)) then
			if (internal_COUNTER = to_unsigned(DIVIDE_RATIO-2,counter_width)) then
				internal_COUNTER_RESET <= '1';
			else 
				internal_COUNTER_RESET <= '0';
			end if;
		end if;
	end process;
	--map output port
	CLOCK_ENABLE_OUT <= internal_COUNTER_RESET;
	
end Behavioral;

