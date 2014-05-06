--------------------------------------------------------------------------------
-- University of Hawaii at Manoa
-- Department of Physics
-- Instrumentation Development Lab
--
-- for driving a newhaven NHD-3.12-25664UCB2 OLED display
-- connected to a universal_eval revB with a xilin xc3s400-4pq208 FPGA
-- started 2013-12-26 by mza
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.STD_LOGIC_ARITH.ALL;
--use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
--use work.clock_enable_generator.all;

entity my_module_name is
	Port (
		clock_150               : in    STD_LOGIC;
		clock_40                : in    STD_LOGIC;
		sync                    :   out STD_LOGIC;
		data_bus                : inout STD_LOGIC_VECTOR (7 downto 0);
		enable_active_low       :   out STD_LOGIC;
		read_write_not          :   out STD_LOGIC;
		chip_select_active_low  :   out STD_LOGIC;
		data_command_not        :   out STD_LOGIC;
		reset_active_low        :   out STD_LOGIC;
		interface_type_select   :   out STD_LOGIC_VECTOR (1 downto 0)
	);
	attribute loc                   : string;
--	attribute pullup                : string;
	attribute iostandard            : string;
	attribute clock_dedicated_route : string;
	attribute box_type              : string;
	attribute loc of clock_150              : signal is "p181";
	attribute loc of clock_40               : signal is "p79";
	attribute loc of data_bus               : signal is "p178,p176,p175,p172,p171,p169,p168,p166";
	attribute loc of enable_active_low      : signal is "p165";
	attribute loc of read_write_not         : signal is "p162";
	attribute loc of chip_select_active_low : signal is "p161";
	attribute loc of data_command_not       : signal is "p156";
	attribute loc of reset_active_low       : signal is "p155";
	attribute loc of interface_type_select  : signal is "p154,p152";
	attribute loc of sync                   : signal is "p150";
--	attribute iostandard of data_bus                 : signal is "lvcmos";
--	attribute clock_dedicated_route of copper2_localbus_chip_select_active_low : signal is "false";
--	attribute iostandard of ibufgds : component is "LVDS_25";
--	attribute box_type of ibufgds : component is "BLACK_BOX";
end my_module_name;

architecture my_module_name_architecture of my_module_name is
	signal internal_sync      : std_logic := '0';
	signal internal_clock_150 : std_logic := '0';
	signal internal_clock_40  : std_logic := '0';
	signal internal_clock_20  : std_logic := '0';
	signal internal_clock_3   : std_logic := '0';
	signal internal_data_bus               : std_logic_vector(7 downto 0) := x"00";
	signal internal_enable_active_low      : std_logic := '1';
	signal internal_read_write_not         : std_logic := '1';
	signal internal_chip_select_active_low : std_logic := '1';
	signal internal_data_command_not       : std_logic := '1';
	signal internal_reset_active_low       : std_logic := '0';
	signal internal_interface_type_select  : std_logic_vector(1 downto 0) := "11";
	signal clock_enable_1kHz : std_logic := '0';
	signal clock_enable_3MHz : std_logic := '0';
	constant size_of_reset_counter : integer := 16;
	signal reset_counter : unsigned(size_of_reset_counter-1 downto 0) := (others => '0');
	signal initialization_counter : unsigned(11 downto 0) := (others => '0');
begin
	--
	internal_clock_150 <= clock_150;
	internal_clock_40 <= clock_40;
	sync <= internal_sync;
	enable_active_low <= internal_enable_active_low;
	read_write_not <= internal_read_write_not;
	chip_select_active_low <= internal_chip_select_active_low;
	data_command_not <= internal_data_command_not;
	reset_active_low <= internal_reset_active_low;
	interface_type_select <= internal_interface_type_select;
	data_bus <= internal_data_bus;
	--
	mapper_1kHz : entity work.clock_enable_generator
		generic map (
			DIVIDE_RATIO => 150000
		)
		port map (
			CLOCK_IN         => internal_clock_150,
			CLOCK_ENABLE_OUT => clock_enable_1kHz
		);
	mapper_3MHz : entity work.clock_enable_generator
		generic map (
			DIVIDE_RATIO => 50
		)
		port map (
			CLOCK_IN         => internal_clock_150,
			CLOCK_ENABLE_OUT => clock_enable_3MHz
		);
	--
	process (internal_clock_150)
	begin
		if rising_edge(internal_clock_150) then
			if (clock_enable_1kHz = '1') then
				if (reset_counter < 1000) then
					internal_reset_active_low <= '0';
					reset_counter <= reset_counter + 1;
					internal_data_bus               <= x"00";
					internal_enable_active_low      <= '1';
					internal_read_write_not         <= '1';
					internal_chip_select_active_low <= '1';
					internal_data_command_not       <= '1';
					internal_reset_active_low       <= '0';
					internal_interface_type_select  <= "11";
				else
					internal_reset_active_low <= '1';
				end if;
			end if;
			if (clock_enable_3MHz = '1') then
				internal_sync <= not internal_sync;
				if (internal_reset_active_low = '1') then
				--	if (initialization_counter < 1000) then
						initialization_counter <= initialization_counter + 1;
				--	end if;
					if (initialization_counter < 4) then
						internal_read_write_not <= '0';
						internal_data_command_not <= '0';
						internal_data_bus <= x"00";
					--
					elsif (initialization_counter < 5) then
						internal_data_bus <= x"a5";
					elsif (initialization_counter < 6) then
						internal_enable_active_low <= '1';
					elsif (initialization_counter < 7) then
						internal_chip_select_active_low <= '0';
					elsif (initialization_counter < 8) then
					elsif (initialization_counter < 9) then
						internal_chip_select_active_low <= '1';
						internal_enable_active_low <= '0';
					--
					elsif (initialization_counter < 10) then
						internal_data_bus <= x"af";
					elsif (initialization_counter < 11) then
						internal_enable_active_low <= '1';
					elsif (initialization_counter < 12) then
						internal_chip_select_active_low <= '0';
					elsif (initialization_counter < 13) then
					elsif (initialization_counter < 14) then
						internal_chip_select_active_low <= '1';
						internal_enable_active_low <= '0';
					--
					elsif (initialization_counter < 15) then
						internal_data_bus <= x"00";
						internal_enable_active_low      <= '0';
						internal_read_write_not         <= '1';
						internal_chip_select_active_low <= '1';
						internal_data_command_not       <= '1';
					end if;
				end if;
			end if;
		end if;
	end process;
end my_module_name_architecture;

