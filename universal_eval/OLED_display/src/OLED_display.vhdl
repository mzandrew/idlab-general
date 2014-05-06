--------------------------------------------------------------------------------
-- University of Hawaii at Manoa
-- Department of Physics
-- Instrumentation Development Lab
--
-- for driving a newhaven NHD-3.12-25664UCB2 OLED display
-- connected to a universal_eval revB with a xilinx xc3s400-4pq208 FPGA
-- started 2013-12-26 by mza
-- last edited 2013-12-31 by mza
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
--use work.clock_enable_generator.all;

entity my_module_name is
	Port (
		clock_150               : in    std_logic;
--		clock_40                : in    std_logic;
		sync                    :   out std_logic;
		OLED_data_bus                : inout std_logic_vector (7 downto 0);
		OLED_enable                  :   out std_logic;
		OLED_read_write_not          :   out std_logic;
		OLED_chip_select_active_low  :   out std_logic;
		OLED_data_command_not        :   out std_logic;
		OLED_reset_active_low        :   out std_logic;
		OLED_interface_type_select   :   out std_logic_vector (1 downto 0)
	);
	attribute loc                   : string;
--	attribute pullup                : string;
	attribute iostandard            : string;
	attribute clock_dedicated_route : string;
	attribute box_type              : string;
	attribute loc of clock_150                   : signal is "p181";
--	attribute loc of clock_40                    : signal is "p79";
	attribute loc of OLED_data_bus               : signal is "p178,p176,p175,p172,p171,p169,p168,p166";
	attribute loc of OLED_enable                 : signal is "p165";
	attribute loc of OLED_read_write_not         : signal is "p162";
	attribute loc of OLED_chip_select_active_low : signal is "p161";
	attribute loc of OLED_data_command_not       : signal is "p156";
	attribute loc of OLED_reset_active_low       : signal is "p155";
	attribute loc of OLED_interface_type_select  : signal is "p154,p152";
	attribute loc of sync                        : signal is "p150";
--	attribute iostandard of data_bus                 : signal is "lvcmos";
--	attribute clock_dedicated_route of copper2_localbus_chip_select_active_low : signal is "false";
--	attribute iostandard of ibufgds : component is "LVDS_25";
--	attribute box_type of ibufgds : component is "BLACK_BOX";
end my_module_name;

architecture my_module_name_architecture of my_module_name is
	signal internal_sync      : std_logic := '0';
	signal internal_clock_150 : std_logic := '0';
--	signal internal_clock_40  : std_logic := '0';
	signal internal_data_bus               : std_logic_vector(7 downto 0) := x"00";
	signal internal_enable                 : std_logic := '0';
	signal internal_read_write_not         : std_logic := '1';
	signal internal_chip_select            : std_logic := '0';
	signal internal_data_command_not       : std_logic := '1';
	signal internal_reset                  : std_logic := '1';
	signal internal_interface_type_select  : std_logic_vector(1 downto 0) := "11";
	signal clock_enable_1kHz  : std_logic := '0';
	signal clock_enable_7MHz  : std_logic := '0';
	signal clock_enable_50MHz : std_logic := '0';
	constant size_of_reset_counter : integer := 16;
	signal reset_counter : unsigned(size_of_reset_counter-1 downto 0) := (others => '0');
	signal initialization_counter : unsigned(11 downto 0) := (others => '0');
	signal initialization_phase : std_logic := '0';
	signal normal_counter : unsigned(11 downto 0) := (others => '0');
	signal individual_transaction_counter : unsigned(2 downto 0) := (others => '0');
	signal x2 : unsigned(7 downto 0) := (others => '0');
	signal y : unsigned(6 downto 0) := (others => '0');
	signal x2_start : unsigned(7 downto 0) := (others => '0');
	signal x2_end   : unsigned(7 downto 0) := (others => '0');
	signal y_start  : unsigned(6 downto 0) := (others => '0');
	signal y_end    : unsigned(6 downto 0) := (others => '0');
	signal blargh : std_logic := '0';
	--procedure chip_select_active is
	--begin
	--	internal_chip_select_active_low <= '0';
	--end chip_select_active;
begin
	--
	internal_clock_150 <= clock_150;
--	internal_clock_40 <= clock_40;
	sync <= internal_sync;
	OLED_enable                 <=     internal_enable;
	OLED_read_write_not         <=     internal_read_write_not;
	OLED_chip_select_active_low <= not internal_chip_select; -- enforce using positive logic internally
	OLED_data_command_not       <=     internal_data_command_not;
	OLED_reset_active_low       <= not internal_reset;       -- enforce using positive logic internally
	OLED_interface_type_select  <=     internal_interface_type_select;
	OLED_data_bus               <=     internal_data_bus;
	--
	clock_1kHz : entity work.clock_enable_generator
		generic map (
			DIVIDE_RATIO => 150000 -- 1 kHz
		)
		port map (
			CLOCK_IN         => internal_clock_150,
			CLOCK_ENABLE_OUT => clock_enable_1kHz
		);
	clock_7MHz : entity work.clock_enable_generator
		generic map (
			--DIVIDE_RATIO => 45 -- 3.333 MHz
			DIVIDE_RATIO => 21 -- 7.143 MHz, corresponding to 140 ns max read cycle timing
		)
		port map (
			CLOCK_IN         => internal_clock_150,
			CLOCK_ENABLE_OUT => clock_enable_7MHz
		);
	clock_50MHz : entity work.clock_enable_generator
		generic map (
			--DIVIDE_RATIO => 45 -- 3.333 MHz
			--DIVIDE_RATIO => 21 -- 7.143 MHz, corresponding to 140 ns max read cycle timing
			DIVIDE_RATIO => 3 -- 50 MHz, corresponding to 20 ns
		)
		port map (
			CLOCK_IN         => internal_clock_150,
			CLOCK_ENABLE_OUT => clock_enable_50MHz
		);
--	OLED_control : entity work.OLED_controller
		--generic map (
		--	mode => 6800
		--)
--		port map (
--			CLOCK            => internal_clock_150,
--			CLOCK_ENABLE     => clock_enable_3MHz,
--			OLED_ENABLE      => ,
--			OLED_CHIP_SELECT => ,
--		);
	--
	process (internal_clock_150)
	begin
		if rising_edge(internal_clock_150) then
			if (clock_enable_1kHz = '1') then

				if (reset_counter < 100) then
					reset_counter <= reset_counter + 1;
					internal_reset                  <= '1';
					internal_data_bus               <= x"00";
					internal_enable                 <= '0';
					internal_read_write_not         <= '1';
					internal_chip_select            <= '0';
					internal_data_command_not       <= '1';
					internal_interface_type_select  <= "11"; -- 6800 mode
					initialization_phase <= '1';
					initialization_counter <= x"000";
					normal_counter <= x"000";
					blargh <= '0';
					--x_start <= to_unsigned( 28, 8);
					--x_end   <= to_unsigned( 91, 8);
					--y_start <= to_unsigned(  0, 7);
					--y_end   <= to_unsigned( 63, 7);
					y_start  <= to_unsigned( 28, 7);
					y_end    <= to_unsigned( 91, 7);
					x2_start <= to_unsigned(  0, 8);
					x2_end   <= to_unsigned(127, 8);
				else
					internal_reset <= '0';
				end if;

			end if;
			if (clock_enable_7MHz = '1') then

				if (internal_reset = '0' and initialization_phase = '1') then
						initialization_counter <= initialization_counter + 1;
					if (initialization_counter < 4) then
						internal_read_write_not   <= '0';
						internal_data_command_not <= '0';
					--
					elsif (initialization_counter < 5) then
						--internal_data_bus <= x"a5"; -- all pixels on
						internal_data_bus <= x"a6"; -- normal mode
					elsif (initialization_counter < 6) then
						internal_enable <= '1';
					elsif (initialization_counter < 7) then
						internal_chip_select <= '1';
					elsif (initialization_counter < 9) then
						internal_chip_select <= '0';
						internal_enable <= '0';
					--
					elsif (initialization_counter < 10) then
						internal_data_bus <= x"af"; -- display on
					elsif (initialization_counter < 11) then
						internal_enable <= '1';
					elsif (initialization_counter < 12) then
						internal_chip_select <= '1';
					elsif (initialization_counter < 14) then
						internal_chip_select <= '0';
						internal_enable <= '0';
					--
					elsif (initialization_counter < 15) then
						--internal_data_bus <= x"00"; -- enable grayscale mode with custom lut
						internal_data_bus <= x"b9"; -- use linear grayscale lut
					elsif (initialization_counter < 16) then
						internal_enable <= '1';
					elsif (initialization_counter < 17) then
						internal_chip_select <= '1';
					elsif (initialization_counter < 18) then
						internal_chip_select <= '0';
						internal_enable <= '0';
					--
					elsif (initialization_counter < 19) then
						internal_data_bus <= x"75"; -- set row start and end address (by the following two transactions)
					elsif (initialization_counter < 20) then
						internal_enable <= '1';
					elsif (initialization_counter < 21) then
						internal_chip_select <= '1';
					elsif (initialization_counter < 22) then
						internal_chip_select <= '0';
						internal_enable <= '0';
					--
					elsif (initialization_counter < 23) then
						internal_data_command_not       <= '1';
						internal_data_bus <= '0' & std_logic_vector(y_start); -- row start address
					elsif (initialization_counter < 24) then
						internal_enable <= '1';
					elsif (initialization_counter < 25) then
						internal_chip_select <= '1';
					elsif (initialization_counter < 26) then
						internal_chip_select <= '0';
						internal_enable <= '0';
					--
					elsif (initialization_counter < 27) then
						internal_data_bus <= '0' & std_logic_vector(y_end); -- row end address
					elsif (initialization_counter < 28) then
						internal_enable <= '1';
					elsif (initialization_counter < 29) then
						internal_chip_select <= '1';
					elsif (initialization_counter < 30) then
						internal_chip_select <= '0';
						internal_enable <= '0';
					--
					elsif (initialization_counter < 31) then
						internal_data_bus <= x"15"; -- set column start and end address (by the following two transactions)
						internal_data_command_not       <= '0';
					elsif (initialization_counter < 32) then
						internal_enable <= '1';
					elsif (initialization_counter < 33) then
						internal_chip_select <= '1';
					elsif (initialization_counter < 34) then
						internal_chip_select <= '0';
						internal_enable <= '0';
					--
					elsif (initialization_counter < 35) then
						internal_data_command_not       <= '1';
						internal_data_bus <= std_logic_vector(x2_start); -- column start address
					elsif (initialization_counter < 36) then
						internal_enable <= '1';
					elsif (initialization_counter < 37) then
						internal_chip_select <= '1';
					elsif (initialization_counter < 38) then
						internal_chip_select <= '0';
						internal_enable <= '0';
					--
					elsif (initialization_counter < 39) then
						internal_data_bus <= std_logic_vector(x2_end); -- column end address
					elsif (initialization_counter < 40) then
						internal_enable <= '1';
					elsif (initialization_counter < 41) then
						internal_chip_select <= '1';
					elsif (initialization_counter < 42) then
						internal_chip_select <= '0';
						internal_enable <= '0';
					--
					elsif (initialization_counter < 43) then
						internal_data_command_not       <= '0';
						internal_data_bus <= x"5c"; -- write to display ram
					elsif (initialization_counter < 44) then
						internal_enable <= '1';
					elsif (initialization_counter < 45) then
						internal_chip_select <= '1';
					elsif (initialization_counter < 46) then
						internal_chip_select <= '0';
						internal_enable <= '0';
					--
					elsif (initialization_counter < 47) then
						internal_data_command_not       <= '1';
						normal_counter <= x"000";
						individual_transaction_counter <= "000";
						x2 <= x2_start;
						y <= y_start;
					else
						initialization_phase <= '0';
					end if;
				end if;

				if (blargh = '1' and internal_reset = '0' and initialization_phase = '1') then
--					if (individual_transaction_counter < 6) then
--						individual_transaction_counter <= individual_transaction_counter + 1;
--					else
--						normal_counter <= normal_counter + 1;
--						individual_transaction_counter <= "000";
--					end if;
--					if (individual_transaction_counter < 1) then
						internal_sync <= not internal_sync;
--					elsif (individual_transaction_counter < 2) then
--						internal_sync <= not internal_sync;
--						--internal_data_bus <= std_logic_vector(normal_counter(3 downto 0))
--					elsif (individual_transaction_counter < 3) then
--						internal_enable <= '1';
--					elsif (individual_transaction_counter < 4) then
--						internal_chip_select <= '1';
--					elsif (individual_transaction_counter < 5) then
--						internal_chip_select <= '0';
--						internal_enable <= '0';
--					end if;
--					--
				end if;
--						individual_transaction_counter <= "000";

				if (initialization_phase = '0') then
					if (individual_transaction_counter < 7) then
						individual_transaction_counter <= individual_transaction_counter + 1;
					else
						if (x2 < x2_end) then
							x2 <= x2 + 1;
						else
							x2 <= x2_start;
							if (y < y_end) then
								y <= y + 1;
							else
								y <= y_start;
							end if;
						end if;
						normal_counter <= normal_counter + 1;
						individual_transaction_counter <= "000";
					end if;
					if (individual_transaction_counter < 1) then
						internal_sync <= not internal_sync;
					elsif (individual_transaction_counter < 2) then
						internal_sync <= not internal_sync;
						--internal_data_bus <= std_logic_vector(normal_counter(3 downto 0))
						if (x2 = x2_start + 20) then
							if (y = y_start + 20) then
								internal_data_bus <= x"ff";
							else
								--internal_data_bus <= (others => '0');
								internal_data_bus <= x"cc";
							end if;
						else
							internal_data_bus <= (others => '0');
						end if;
					elsif (individual_transaction_counter < 3) then
						internal_enable <= '1';
					elsif (individual_transaction_counter < 4) then
						internal_chip_select <= '1';
					elsif (individual_transaction_counter < 5) then
						internal_chip_select <= '0';
					elsif (individual_transaction_counter < 6) then
						internal_enable <= '0';
					end if;
					--
				end if;

			end if;
		end if;
	end process;
end my_module_name_architecture;

--use work.OLED_control.all;
--package OLED_control is
--	procedure chip_select_active();
--end OLED_control;

--package body OLED_control is
--end OLED_control;

