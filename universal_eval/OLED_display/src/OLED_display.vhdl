--------------------------------------------------------------------------------
-- University of Hawaii at Manoa
-- Department of Physics
-- Instrumentation Development Lab
--
-- for driving a newhaven NHD-3.12-25664UCB2 OLED display
-- connected to a universal_eval revB with a xilinx xc3s400-4pq208 FPGA
-- started 2013-12-26 by mza
-- originally based on code from http://code.google.com/p/idlab-daq/source/browse/iTOP-DSP_FIN-COPPER-FINESSE/branches/finesse_copper_local_bus_test/FPGA/src/top.vhdl; concept for ucf-less vhdl from Nakao-san
-- core of the code came together on 2014-01-02 (Isaac Asimov's birthday)
-- last edited 2014-05-07 by mza
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity my_module_name is
	Port (
--		clock_150               : in    std_logic;
		clock_40                : in    std_logic;
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
	--attribute tnm_net               : string;
	--attribute timespec              : string;
--	attribute loc of clock_150                   : signal is "p181";
	attribute loc of clock_40                    : signal is "p79";
	attribute loc of OLED_data_bus               : signal is "p178,p176,p175,p172,p171,p169,p168,p166";
	attribute loc of OLED_enable                 : signal is "p165";
	attribute loc of OLED_read_write_not         : signal is "p162";
	attribute loc of OLED_chip_select_active_low : signal is "p161";
	attribute loc of OLED_data_command_not       : signal is "p156";
	attribute loc of OLED_reset_active_low       : signal is "p155";
	attribute loc of OLED_interface_type_select  : signal is "p154,p152";
	attribute loc of sync                        : signal is "p150";
	--attribute tnm_net of clock_40                : signal is "clock_40"; -- this is not available in a vhdl file
	--attribute timespec of clock_40               : signal is "period clock_40 25 ns high 50%"; -- this is not available in a vhdl file
--	attribute iostandard of data_bus                 : signal is "lvcmos";
--	attribute clock_dedicated_route of copper2_localbus_chip_select_active_low : signal is "false";
--	attribute iostandard of ibufgds : component is "LVDS_25";
--	attribute box_type of ibufgds : component is "BLACK_BOX";
end my_module_name;

architecture my_module_name_architecture of my_module_name is
	signal internal_sync      : std_logic := '0';
	signal internal_clock_40  : std_logic := '0';
	signal internal_data_bus               : std_logic_vector(7 downto 0) := x"00";
	signal internal_enable                 : std_logic := '0';
	signal internal_read_write_not         : std_logic := '0';
	signal internal_chip_select            : std_logic := '0';
	signal internal_data_command_not       : std_logic := '1';
	signal internal_reset                  : std_logic := '1';
	signal internal_interface_type_select  : std_logic_vector(1 downto 0) := "11";
	signal clock_enable_1kHz  : std_logic := '0';
	constant size_of_reset_counter : integer := 4;
	constant a_prime_number : integer := 16381;
	signal reset_counter : unsigned(size_of_reset_counter-1 downto 0) := (others => '0');
	signal initialization_counter : unsigned(11 downto 0) := (others => '0');
	signal initialization_phase : std_logic := '0';
	signal normal_counter : unsigned(31 downto 0) := (others => '0');
	signal individual_transaction_counter : unsigned(3 downto 0) := (others => '0');
	signal x : unsigned(8 downto 0) := (others => '0');
	signal y : unsigned(6 downto 0) := (others => '0');
	signal row    : unsigned(7 downto 0) := (others => '0');
	signal column : unsigned(6 downto 0) := (others => '0');
	signal row_start : unsigned(7 downto 0) := (others => '0');
	signal row_end   : unsigned(7 downto 0) := to_unsigned(127, 8);
	signal column_start : unsigned(6 downto 0) := to_unsigned( 28, 7);
	signal column_end   : unsigned(6 downto 0) := to_unsigned( 91, 7);
	signal transaction_required    : std_logic := '0';
	signal transaction_in_progress : std_logic := '0';

begin
	internal_clock_40 <= clock_40;
	sync <= internal_sync;
	x <=    row - row_start     & '0';
	y <= column - column_start;
	OLED_enable                 <=     internal_enable;
	OLED_read_write_not         <=     internal_read_write_not;
	OLED_chip_select_active_low <= not internal_chip_select; -- enforce using positive logic internally
	OLED_data_command_not       <=     internal_data_command_not;
	OLED_reset_active_low       <= not internal_reset;       -- enforce using positive logic internally
	OLED_interface_type_select  <=     internal_interface_type_select;
	OLED_data_bus               <=     internal_data_bus;

	clock_1kHz : entity work.clock_enable_generator
		generic map (
			DIVIDE_RATIO => 40000 -- 1 kHz
		)
		port map (
			CLOCK_IN         => internal_clock_40,
			CLOCK_ENABLE_OUT => clock_enable_1kHz
		);

	process (internal_clock_40)
	begin
		if rising_edge(internal_clock_40) then
			if (clock_enable_1kHz = '1') then
				if (reset_counter < 3) then
					reset_counter <= reset_counter + 1;
					internal_reset <= '1';
					internal_data_bus               <= x"00";
					internal_enable                 <= '0';
					internal_read_write_not         <= '0';
					internal_chip_select            <= '0';
					internal_data_command_not       <= '0';
					internal_interface_type_select  <= "11"; -- 6800 mode
					initialization_phase <= '1';
					initialization_counter <= x"000";
					normal_counter <= x"00000000";
					row_start <= to_unsigned(  0, 8);
					row_end   <= to_unsigned(127, 8);
					column_start <= to_unsigned( 28, 7);
					column_end   <= to_unsigned( 91, 7);
					transaction_required <= '0';
					transaction_in_progress <= '0';
					individual_transaction_counter <= (others => '0');
				else
					internal_reset <= '0';
				end if;
			end if;

			if (transaction_required = '1') then
				if (individual_transaction_counter < 10) then      -- total 300 ns cycle time
																					-- (takes a cycle to get here from elsewhere)
					transaction_in_progress <= '1';
					if (individual_transaction_counter < 1) then    -- itc = 0 (for 25 ns)
						internal_sync <= not internal_sync;
						internal_enable <= '1';
					elsif (individual_transaction_counter < 4) then -- itc = 1, 2, 3 (for 75 ns)
						internal_chip_select <= '1';
					else                                            -- itc = 4, 5, 6, 7, 8, 9 (for 150 ns)
						internal_chip_select <= '0';
						internal_enable <= '0';
					end if;
					individual_transaction_counter <= individual_transaction_counter + 1;
				else                                               -- itc = 10 (for 25 ns)
					transaction_required <= '0';
					transaction_in_progress <= '0';
					individual_transaction_counter <= (others => '0');
				end if;
			end if;

			if (internal_reset = '0' and initialization_phase = '1') then
				if (transaction_in_progress = '0' and transaction_required = '0') then
					initialization_counter <= initialization_counter + 1;
					transaction_required <= '1';
					if (initialization_counter < 1) then
						internal_read_write_not         <= '0';
						internal_data_command_not       <= '0';
						internal_data_bus <= x"ae"; -- display off
					elsif (initialization_counter < 2) then
						--internal_data_bus <= x"a5"; -- all pixels on
						internal_data_bus <= x"a6"; -- normal mode
					elsif (initialization_counter < 3) then
						internal_data_bus <= x"c7"; -- master brightness control (by next data transaction)
					elsif (initialization_counter < 4) then
						internal_data_command_not       <= '1';
						internal_data_bus <= x"09"; -- master brightness (range 0-f)
					elsif (initialization_counter < 5) then
						internal_data_command_not       <= '0';
						internal_data_bus <= x"75"; -- set row start and end address (by the following two transactions)
					elsif (initialization_counter < 6) then
						internal_data_command_not       <= '1';
						internal_data_bus <= std_logic_vector(row_start); -- row start address
					elsif (initialization_counter < 7) then
						internal_data_bus <= std_logic_vector(row_end); -- row end address
					elsif (initialization_counter < 8) then
						internal_data_command_not       <= '0';
						internal_data_bus <= x"15"; -- set column start and end address (by the following two transactions)
					elsif (initialization_counter < 9) then
						internal_data_command_not       <= '1';
						internal_data_bus <= '0' & std_logic_vector(column_start); -- column start address
					elsif (initialization_counter < 10) then
						internal_data_bus <= '0' & std_logic_vector(column_end); -- column end address
					elsif (initialization_counter < 11) then
						internal_data_command_not       <= '0';
						internal_data_bus <= x"b8"; -- setup grayscale gamma levels (next 15 data transactions)
					elsif (initialization_counter < 12) then
						internal_data_command_not       <= '1';
						internal_data_bus <= x"00"; -- gamma level for GS1 (range 00-b4)
					elsif (initialization_counter < 13) then
						internal_data_bus <= x"20"; -- gamma level for GS2 (range 00-b4)
					elsif (initialization_counter < 14) then
						internal_data_bus <= x"40"; -- gamma level for GS3 (range 00-b4)
					elsif (initialization_counter < 15) then
						internal_data_bus <= x"60"; -- gamma level for GS4 (range 00-b4)
					elsif (initialization_counter < 16) then
						internal_data_bus <= x"80"; -- gamma level for GS5 (range 00-b4)
					elsif (initialization_counter < 17) then
						internal_data_bus <= x"90"; -- gamma level for GS6 (range 00-b4)
					elsif (initialization_counter < 18) then
						internal_data_bus <= x"94"; -- gamma level for GS7 (range 00-b4)
					elsif (initialization_counter < 19) then
						internal_data_bus <= x"98"; -- gamma level for GS8 (range 00-b4)
					elsif (initialization_counter < 20) then
						internal_data_bus <= x"9c"; -- gamma level for GS9 (range 00-b4)
					elsif (initialization_counter < 21) then
						internal_data_bus <= x"a0"; -- gamma level for GS10 (range 00-b4)
					elsif (initialization_counter < 22) then
						internal_data_bus <= x"a4"; -- gamma level for GS11 (range 00-b4)
					elsif (initialization_counter < 23) then
						internal_data_bus <= x"a8"; -- gamma level for GS12 (range 00-b4)
					elsif (initialization_counter < 24) then
						internal_data_bus <= x"ac"; -- gamma level for GS13 (range 00-b4)
					elsif (initialization_counter < 25) then
						internal_data_bus <= x"b0"; -- gamma level for GS14 (range 00-b4)
					elsif (initialization_counter < 26) then
						internal_data_bus <= x"b4"; -- gamma level for GS15 (range 00-b4)
					elsif (initialization_counter < 27) then
						internal_data_command_not       <= '0';
						internal_data_bus <= x"00"; -- enable grayscale mode with custom lut
						--internal_data_bus <= x"b9"; -- use linear grayscale lut
					elsif (initialization_counter < 28) then
						internal_data_bus <= x"af"; -- display on
					elsif (initialization_counter < 29) then
						internal_data_bus <= x"5c"; -- write to display ram
					else
						internal_data_command_not       <= '1';
						normal_counter <= x"00000000";
						transaction_in_progress <= '0';
						individual_transaction_counter <= (others => '0');
						initialization_phase <= '0';
						transaction_required <= '0';
					end if;
				end if;
			end if;

			if (initialization_phase = '0') then
				if (transaction_in_progress = '0' and transaction_required = '0') then
					--internal_data_bus <= std_logic_vector(y(5 downto 2)) & std_logic_vector(normal_counter(14 downto 11));
					--internal_data_bus <= std_logic_vector(y(5 downto 2)) & std_logic_vector(x(3 downto 0));
					internal_data_bus <= (x(8) and x(7)) & std_logic_vector(y(6 downto 0) xor x(6 downto 0));
					if (row < row_end) then
						row <= row + 1;
					else
						row <= row_start;
						if (column < column_end) then
							column <= column + 1;
						else
							column <= column_start;
						end if;
					end if;
					if (normal_counter < a_prime_number) then
						normal_counter <= normal_counter + 1;
					else
						normal_counter <= (others => '0');
					end if;
					transaction_required <= '1';
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
