LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY my_module_test IS
END my_module_test;

ARCHITECTURE behavior OF my_module_test IS 
    --Inputs
   signal clock_40 : std_logic := '0';

	--BiDirs
   signal OLED_data_bus : std_logic_vector(7 downto 0);
	
 	--Outputs
   signal sync : std_logic;
   signal OLED_enable : std_logic;
   signal OLED_read_write_not : std_logic;
   signal OLED_chip_select_active_low : std_logic;
   signal OLED_data_command_not : std_logic;
   signal OLED_reset_active_low : std_logic;
   signal OLED_interface_type_select : std_logic_vector(1 downto 0);

   constant clock_40_period : time := 25 ns;

BEGIN

   uut : entity work.my_module_name PORT MAP (
          clock_40 => clock_40,
          sync => sync,
          OLED_data_bus => OLED_data_bus,
          OLED_enable => OLED_enable,
          OLED_read_write_not => OLED_read_write_not,
          OLED_chip_select_active_low => OLED_chip_select_active_low,
          OLED_data_command_not => OLED_data_command_not,
          OLED_reset_active_low => OLED_reset_active_low,
          OLED_interface_type_select => OLED_interface_type_select
        );

   clock_40_process : process
   begin
		clock_40 <= '0';
		wait for clock_40_period/2;
		clock_40 <= '1';
		wait for clock_40_period/2;
   end process;

	stim_proc: process
	begin		
		--wait for 100 ms;
		wait for clock_40_period*100;
		wait;
	end process;

END;

