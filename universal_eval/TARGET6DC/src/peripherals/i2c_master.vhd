----------------------------------------------------------------------------------
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity i2c_master is
	Port ( 
		I2C_BYTE_TO_SEND      : in    STD_LOGIC_VECTOR(7 downto 0);
		I2C_BYTE_RECEIVED     : out   STD_LOGIC_VECTOR(7 downto 0);
		ACKNOWLEDGED          : out   STD_LOGIC;
		SEND_START            : in    STD_LOGIC;
		SEND_BYTE             : in    STD_LOGIC;
		READ_BYTE             : in    STD_LOGIC;
		SEND_ACKNOWLEDGE      : in    STD_LOGIC;
		SEND_STOP             : in    STD_LOGIC;
		BUSY                  : out   STD_LOGIC;
		CLOCK                 : in    STD_LOGIC;
		CLOCK_ENABLE          : in    STD_LOGIC;
		SCL                   : inout STD_LOGIC;
		SDA                   : inout STD_LOGIC
--		CHIPSCOPE_ILA_CONTROL : inout STD_LOGIC_VECTOR(35 downto 0)
	);
end i2c_master;

architecture Behavioral of i2c_master is
	signal internal_BYTE_RECEIVED             : std_logic_vector(7 downto 0);
	signal internal_BYTE_RECEIVED_reg         : std_logic_vector(7 downto 0);
	signal internal_BYTE_RECEIVED_READ_ENABLE : std_logic;
	signal internal_BIT_RECEIVE_READ_ENABLE   : std_logic;
	signal internal_I2C_BYTE_TO_SEND_reg      : std_logic_vector(7 downto 0);
	signal internal_BYTE_TO_SEND_READ_ENABLE  : std_logic;
	signal internal_BIT_COUNTER               : integer range 0 to 7 := 0;
	signal internal_BIT_COUNTER_ENABLE        : std_logic := '0';
	signal internal_BIT_COUNTER_RESET         : std_logic := '1';
	type i2c_state is (IDLE, START, SETUP_REPEAT_START, REPEAT_START, WAIT_FOR_COMMAND, PREPARE_BYTE, PREPARE_BIT, SEND_BIT, PREPARE_TO_CHECK_ACK, CHECK_ACK, ARM_RECEIVE, PREPARE_TO_RECEIVE, RECEIVE_BIT, PREPARE_TO_GENERATE_ACK, GENERATE_ACK, STOP);
	signal internal_I2C_STATE_reg             : i2c_state := IDLE;
	signal internal_I2C_NEXT_STATE            : i2c_state := IDLE;
	signal internal_ACKNOWLEDGED_reg          : std_logic;
	signal internal_ACKNOWLEDGED_READ_ENABLE  : std_logic;
	signal internal_ACKNOWLEDGED_RESET        : std_logic;
	signal internal_SEND_ACK_reg              : std_logic;
	signal internal_SEND_ACK_READ_ENABLE      : std_logic;
	
	signal internal_SEND_START : std_logic;
	signal internal_SEND_BYTE  : std_logic;
	signal internal_READ_BYTE  : std_logic;
	signal internal_SEND_STOP  : std_logic;
	
--	signal internal_CHIPSCOPE_ILA             : std_logic_vector(37 downto 0);
begin
	--Wiring
	ACKNOWLEDGED <= internal_ACKNOWLEDGED_reg;
	I2C_BYTE_RECEIVED <= internal_BYTE_RECEIVED_reg;
	--Outputs for the various states
	process(internal_I2C_STATE_reg, internal_BIT_COUNTER, internal_I2C_BYTE_TO_SEND_reg, SDA, internal_SEND_ACK_reg) begin
		--Default values
		SDA <= 'Z';
		SCL <= 'Z';
		BUSY <= '1';
		internal_BYTE_TO_SEND_READ_ENABLE  <= '0';
		internal_ACKNOWLEDGED_READ_ENABLE  <= '0';
		internal_ACKNOWLEDGED_RESET        <= '0';
		internal_BYTE_RECEIVED_READ_ENABLE <= '0';
		internal_BIT_COUNTER_ENABLE        <= '0';
		internal_BIT_COUNTER_RESET         <= '0';
		internal_BIT_RECEIVE_READ_ENABLE   <= '0';
		internal_SEND_ACK_READ_ENABLE      <= '0';
		--Outputs for each state of the machine
		case internal_I2C_STATE_reg is
			when IDLE =>
				BUSY <= '0';
				--Just use the defaults
			when START => 
				--Bring SDA low with SCL still in default high
				SDA <= '0';
			when SETUP_REPEAT_START =>
				--Let SDA go high while SCL stays low
				SDA <= 'Z';
				SCL <= '0';
			when REPEAT_START =>
				--Let SCL go high
				SDA <= 'Z';
				SCL <= 'Z';
			when WAIT_FOR_COMMAND =>
				BUSY <= '0';
				--Keep both SDA and SCL low in preparation for doing something
				SDA <= '0';
				SCL <= '0';
				--Reset the bit counter
				internal_BIT_COUNTER_RESET <= '1';
				--Read the status of whether to acknowledge or not
				internal_SEND_ACK_READ_ENABLE <= '1';
			when PREPARE_BYTE =>
				--Continue to keep both SDA and SCL low in preparation for doing something
				SDA <= '0';
				SCL <= '0';
				--Read the byte to send into the register that we'll use for this process
				internal_BYTE_TO_SEND_READ_ENABLE <= '1';
				--Reset the acknowledged signal 
				internal_ACKNOWLEDGED_RESET <= '1';
			when PREPARE_BIT =>
				--Hold SCL low while the bit is prepared
				SCL <= '0';
				--Prepare the bit
				for i in 0 to 7 loop
					if (internal_BIT_COUNTER = i) then
						SDA <= internal_I2C_BYTE_TO_SEND_reg(7-i);
					end if;
				end loop;
				--Make sure the bit counter isn't in reset
				internal_BIT_COUNTER_RESET <= '0';
			when SEND_BIT =>
				--Keep SDA in its previous state
				for i in 0 to 7 loop
					if (internal_BIT_COUNTER = i) then
						SDA <= internal_I2C_BYTE_TO_SEND_reg(7-i);
					end if;
				end loop;
				--Toggle SCL to high
				SCL <= 'Z';
				--Increment the bit counter by 1
				internal_BIT_COUNTER_ENABLE <= '1';
				--And make sure it isn't in reset
				internal_BIT_COUNTER_RESET <= '0';
			when PREPARE_TO_CHECK_ACK =>
				--Let SDA go to high impedance
				SDA <= 'Z';
				SCL <= '0';
			when CHECK_ACK =>
				--Read the value of SDA
				SDA <= 'Z';
				SCL <= 'Z';
				internal_ACKNOWLEDGED_READ_ENABLE <= '1';
			when ARM_RECEIVE =>
				--Coming in from WAIT_FOR_COMMAND state, hold SCL low
				SCL <= '0';
				--Prepare SDA in high impedance so that the device presents data on bus
				SDA <= 'Z';
				--Read the bit in on the next cycle
				internal_BIT_RECEIVE_READ_ENABLE <= '1';
				--internal_BIT_COUNTER_ENABLE <= '1'; --This is an intentional comment out... since we're using a 3 bit counter we shouldn't count the first bit in.
			when PREPARE_TO_RECEIVE =>
				--Bring SCL low, slave will change output bus data
				SCL <= '0';
				--SDA should be high impedance for reading
				SDA <= 'Z';
				--Receive at the next cycle and count up
				if (internal_BIT_COUNTER < 7) then
					internal_BIT_RECEIVE_READ_ENABLE <= '1';
					internal_BIT_COUNTER_ENABLE <= '1';
				end if;
			when RECEIVE_BIT =>
				--Bring SCL high.
				SCL <= 'Z';
				--Keep SDA high impedance during the read
				SDA <= 'Z';
			when PREPARE_TO_GENERATE_ACK =>
				--Hold SDA low to indicate data has been acknowledged (if desired)
				if (internal_SEND_ACK_reg = '1') then
					SDA <= '0';
				else 
					SDA <= 'Z';
				end if;
				--Let SCL go high so that the slave sees our ack (or no-ack)
				SCL <= 'Z';
				--Register the data that was just read
				internal_BYTE_RECEIVED_READ_ENABLE <= '1';
			when GENERATE_ACK =>
				--Give SCL low to finish the ACK pulse
				SCL <= '0';
				--Keep SDA 0 to let the ack go through (if desired)
				if (internal_SEND_ACK_reg = '1') then
					SDA <= '0';
				else 
					SDA <= 'Z';
				end if;
			when STOP =>
				--SDA should transition from low to high while SCL is high
				--This sets it up but the actual transition happens when we go from here to IDLE.
				SCL <= 'Z';
				SDA <= '0';
		end case;
	end process;
	--Next state logic
	process (internal_I2C_STATE_reg, internal_BIT_COUNTER, internal_SEND_START, internal_SEND_BYTE, internal_READ_BYTE, internal_SEND_STOP) begin
		internal_I2C_NEXT_STATE <= IDLE;
		case internal_I2C_STATE_reg is
			when IDLE =>
				if (internal_SEND_START = '1') then
					internal_I2C_NEXT_STATE <= START;
				end if;
			when START =>
				internal_I2C_NEXT_STATE <= WAIT_FOR_COMMAND;
			when SETUP_REPEAT_START =>
				internal_I2C_NEXT_STATE <= REPEAT_START;
			when REPEAT_START =>
				internal_I2C_NEXT_STATE <= START;
			when WAIT_FOR_COMMAND =>
				if (internal_SEND_BYTE = '1') then
					internal_I2C_NEXT_STATE <= PREPARE_BYTE;
				elsif (internal_READ_BYTE = '1') then
					internal_I2C_NEXT_STATE <= ARM_RECEIVE;
				elsif (internal_SEND_STOP = '1') then
					internal_I2C_NEXT_STATE <= STOP;
				elsif (internal_SEND_START = '1') then
					internal_I2C_NEXT_STATE <= SETUP_REPEAT_START;
				else
					internal_I2C_NEXT_STATE <= WAIT_FOR_COMMAND;
				end if;
			when PREPARE_BYTE =>
				internal_I2C_NEXT_STATE <= PREPARE_BIT;
			when PREPARE_BIT =>
				internal_I2C_NEXT_STATE <= SEND_BIT;
			when SEND_BIT =>
				if (internal_BIT_COUNTER < 7) then
					internal_I2C_NEXT_STATE <= PREPARE_BIT;
				else
					internal_I2C_NEXT_STATE <= PREPARE_TO_CHECK_ACK;
				end if;
			when PREPARE_TO_CHECK_ACK =>
				internal_I2C_NEXT_STATE <= CHECK_ACK;
			when CHECK_ACK =>
				internal_I2C_NEXT_STATE <= WAIT_FOR_COMMAND;
			when ARM_RECEIVE =>
				internal_I2C_NEXT_STATE <= RECEIVE_BIT;
			when PREPARE_TO_RECEIVE =>
				if (internal_BIT_COUNTER < 7) then
					internal_I2C_NEXT_STATE <= RECEIVE_BIT;
				else
					internal_I2C_NEXT_STATE <= PREPARE_TO_GENERATE_ACK;
				end if;
			when RECEIVE_BIT =>
				internal_I2C_NEXT_STATE <= PREPARE_TO_RECEIVE;
			when PREPARE_TO_GENERATE_ACK =>
				internal_I2C_NEXT_STATE <= GENERATE_ACK;
			when GENERATE_ACK =>
				internal_I2C_NEXT_STATE <= WAIT_FOR_COMMAND;
			when STOP =>
				internal_I2C_NEXT_STATE <= IDLE;
		end case;		
	end process;
	--Clock the new state into the state register
	process(CLOCK, CLOCK_ENABLE, internal_I2C_NEXT_STATE) begin
		if (CLOCK_ENABLE = '1') then
			if (rising_edge(CLOCK)) then
				internal_I2C_STATE_reg <= internal_I2C_NEXT_STATE;
			end if;
		end if;
	end process;
	--Auxiliary read enables and clocks for state machine
	--Register the byte to send
	process(CLOCK, CLOCK_ENABLE, internal_BYTE_TO_SEND_READ_ENABLE) begin
		if (internal_BYTE_TO_SEND_READ_ENABLE = '1' and CLOCK_ENABLE = '1') then
			if (rising_edge(CLOCK)) then
				internal_I2C_BYTE_TO_SEND_reg <= I2C_BYTE_TO_SEND;
			end if;
		end if;
	end process;
	--Register the byte to send
	process(CLOCK, CLOCK_ENABLE, internal_BYTE_RECEIVED_READ_ENABLE) begin
		if (internal_BYTE_RECEIVED_READ_ENABLE = '1' and CLOCK_ENABLE = '1') then
			if (rising_edge(CLOCK)) then
				internal_BYTE_RECEIVED_reg <= internal_BYTE_RECEIVED;
			end if;
		end if;
	end process;
	--Read in individual bits here
	process(CLOCK, CLOCK_ENABLE, internal_BIT_RECEIVE_READ_ENABLE, internal_BIT_COUNTER) begin
		if (internal_BIT_RECEIVE_READ_ENABLE = '1' and CLOCK_ENABLE = '1') then
			if (rising_edge(CLOCK)) then
				internal_BYTE_RECEIVED <= internal_BYTE_RECEIVED(6 downto 0) & SDA;
--				for i in 0 to 7 loop
--					if (i = to_integer(internal_BIT_COUNTER)) then
--						internal_BYTE_RECEIVED(7-i) <= SDA;
--					end if;
--				end loop;
			end if;
		end if;
	end process;
	--Register the acknowledged signal
	process(CLOCK, CLOCK_ENABLE, internal_ACKNOWLEDGED_READ_ENABLE, internal_ACKNOWLEDGED_RESET) begin
		if (internal_ACKNOWLEDGED_RESET = '1') then
			internal_ACKNOWLEDGED_reg <= '0';
		elsif (internal_ACKNOWLEDGED_READ_ENABLE = '1' and CLOCK_ENABLE = '1') then
			if (rising_edge(CLOCK)) then
				internal_ACKNOWLEDGED_reg <= not(SDA);
			end if;
		end if;
	end process;
	--Register the signal telling us whether we should send the acknowledge signal
	process(CLOCK, internal_SEND_ACK_READ_ENABLE, CLOCK_ENABLE) begin
		if (CLOCK_ENABLE = '1' and internal_SEND_ACK_READ_ENABLE = '1') then
			if (rising_edge(CLOCK)) then
				internal_SEND_ACK_reg <= SEND_ACKNOWLEDGE;
			end if;
		end if;
	end process;
	--Counter for the bit to send or receive
	process(CLOCK, CLOCK_ENABLE, internal_BIT_COUNTER_RESET) begin
		if (internal_BIT_COUNTER_RESET = '1') then
			internal_BIT_COUNTER <= 0;
		elsif (CLOCK_ENABLE = '1') then
			if (rising_edge(CLOCK)) then
				if (internal_BIT_COUNTER_ENABLE = '1' and internal_BIT_COUNTER < 7) then
					internal_BIT_COUNTER <= internal_BIT_COUNTER + 1;
				end if;
			end if;
		end if;
	end process;
	
	map_send_start_pulsegen : entity work.edge_to_pulse_converter
	port map(INPUT_EDGE => SEND_START, CLOCK => CLOCK, CLOCK_ENABLE => CLOCK_ENABLE, OUTPUT_PULSE => internal_SEND_START);
	map_send_byte_pulsegen : entity work.edge_to_pulse_converter
	port map(INPUT_EDGE => SEND_BYTE, CLOCK => CLOCK, CLOCK_ENABLE => CLOCK_ENABLE, OUTPUT_PULSE => internal_SEND_BYTE);
	map_read_byte_pulsegen : entity work.edge_to_pulse_converter
	port map(INPUT_EDGE => READ_BYTE, CLOCK => CLOCK, CLOCK_ENABLE => CLOCK_ENABLE, OUTPUT_PULSE => internal_READ_BYTE);
	map_send_stop_pulsegen : entity work.edge_to_pulse_converter
	port map(INPUT_EDGE => SEND_STOP, CLOCK => CLOCK, CLOCK_ENABLE => CLOCK_ENABLE, OUTPUT_PULSE => internal_SEND_STOP);
	
--	--Chipscope diagnostics
--	map_s6_ila : entity work.s6_ila
--	port map (
--		CONTROL => CHIPSCOPE_ILA_CONTROL,
--		CLK     => CLOCK,
--		TRIG0   => internal_CHIPSCOPE_ILA
--	);	
--	
--	internal_CHIPSCOPE_ILA(0) <= SCL;
--	internal_CHIPSCOPE_ILA(1) <= SDA;
--	internal_CHIPSCOPE_ILA(2) <= internal_SEND_START;
--	internal_CHIPSCOPE_ILA(3) <= internal_SEND_BYTE;
--	internal_CHIPSCOPE_ILA(4) <= internal_READ_BYTE;
--	internal_CHIPSCOPE_ILA(5) <= internal_SEND_STOP;
--	internal_CHIPSCOPE_ILA(6) <= internal_ACKNOWLEDGED_reg;
----	internal_CHIPSCOPE_ILA(7) <= BUSY;
----	internal_CHIPSCOPE_ILA(8) <= WAITING;
--	internal_CHIPSCOPE_ILA(16 downto 9) <= internal_BYTE_RECEIVED;
----	internal_CHIPSCOPE_ILA(16 downto 9) <= internal_I2C_BYTE_TO_SEND_reg;
--	internal_CHIPSCOPE_ILA(20 downto 17) <= "0000" when internal_I2C_STATE_reg = IDLE else
--	                                        "0001" when internal_I2C_STATE_reg = START else
--	                                        "0010" when internal_I2C_STATE_reg = WAIT_FOR_COMMAND else
--	                                        "0011" when internal_I2C_STATE_reg = PREPARE_BYTE else
--	                                        "0100" when internal_I2C_STATE_reg = PREPARE_BIT else
--	                                        "0101" when internal_I2C_STATE_reg = SEND_BIT else
--	                                        "0110" when internal_I2C_STATE_reg = PREPARE_TO_CHECK_ACK else
--	                                        "0111" when internal_I2C_STATE_reg = CHECK_ACK else
--														 "1000" when internal_I2C_STATE_reg = PREPARE_TO_RECEIVE else
--														 "1001" when internal_I2C_STATE_reg = RECEIVE_BIT else
--														 "1010" when internal_I2C_STATE_reg = PREPARE_TO_GENERATE_ACK else
--														 "1011" when internal_I2C_STATE_reg = GENERATE_ACK else
--	                                        "1100" when internal_I2C_STATE_reg = STOP else
--														 "1101" when internal_I2C_STATE_reg = SETUP_REPEAT_START else
--														 "1110" when internal_I2C_STATE_reg = REPEAT_START else
--	                                        "1111";
--	internal_CHIPSCOPE_ILA(23 downto 21) <= std_logic_vector(to_unsigned(internal_BIT_COUNTER,3));
--	internal_CHIPSCOPE_ILA(24) <= internal_BIT_COUNTER_ENABLE;
--	internal_CHIPSCOPE_ILA(25) <= internal_BIT_COUNTER_RESET;
--	internal_CHIPSCOPE_ILA(26) <= internal_ACKNOWLEDGED_READ_ENABLE;
--	internal_CHIPSCOPE_ILA(27) <= internal_BIT_RECEIVE_READ_ENABLE;
--	internal_CHIPSCOPE_ILA(28) <= internal_BYTE_TO_SEND_READ_ENABLE;
----	internal_CHIPSCOPE_ILA(29) <= internal_BYTE_RECEIVED_READ_ENABLE;
--	internal_CHIPSCOPE_ILA(37 downto 30) <= internal_I2C_BYTE_TO_SEND_reg;
	
end Behavioral;

