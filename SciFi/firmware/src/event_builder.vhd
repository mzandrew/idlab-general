----------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.readout_definitions.all;
use work.asic_definitions_irs2_carrier_revA.all;

entity event_builder is
	Port ( 
		READ_CLOCK                      : in  STD_LOGIC;
		--Data that needs to come in to generate words
		SCROD_REV_AND_ID_WORD           : in  STD_LOGIC_VECTOR(31 downto 0);
		EVENT_NUMBER_WORD               : in  STD_LOGIC_VECTOR(31 downto 0);
		EVENT_TYPE_WORD                 : in  STD_LOGIC_VECTOR(31 downto 0);
		EVENT_FLAG_WORD                 : in  STD_LOGIC_VECTOR(31 downto 0);
		NUMBER_OF_WAVEFORM_PACKETS_WORD : in  STD_LOGIC_VECTOR(31 downto 0);
		--Flow control from the other blocks
		START_BUILDING_EVENT            : in  STD_LOGIC;
		DONE_SENDING_EVENT              : out STD_LOGIC;
		MAKE_READY                      : in  STD_LOGIC;
		--FIFO interface to the waveform packets
		WAVEFORM_FIFO_DATA              : in  STD_LOGIC_VECTOR(31 downto 0);
		WAVEFORM_FIFO_DATA_VALID        : in  STD_LOGIC;
		WAVEFORM_FIFO_EMPTY             : in  STD_LOGIC;
		WAVEFORM_FIFO_READ_ENABLE       : out STD_LOGIC;
		WAVEFORM_FIFO_READ_CLOCK        : out STD_LOGIC;
		--FIFO-like outputs to the command interpreter
		FIFO_DATA_OUT                   : out STD_LOGIC_VECTOR(31 downto 0);
		FIFO_DATA_VALID                 : out STD_LOGIC;
		FIFO_EMPTY                      : out STD_LOGIC;
		FIFO_READ_ENABLE                : in  STD_LOGIC;
		--trigger bits
		TDC_TRG_16_0							: in std_logic_vector(9 downto 0);
		TDC_TRG_4_0							: in std_logic_vector(9 downto 0);
		TDC_TRG_3_0							: in std_logic_vector(9 downto 0);
		TDC_TRG_2_0							: in std_logic_vector(9 downto 0);
		TDC_TRG_1_0							: in std_logic_vector(9 downto 0);
		TDC_TRG_16_1							: in std_logic_vector(9 downto 0);
		TDC_TRG_4_1							: in std_logic_vector(9 downto 0);
		TDC_TRG_3_1							: in std_logic_vector(9 downto 0);
		TDC_TRG_2_1							: in std_logic_vector(9 downto 0);
		TDC_TRG_1_1							: in std_logic_vector(9 downto 0)
	);
end event_builder;

architecture Behavioral of event_builder is
	type event_builder_state is (IDLE, START, SEND_HEADER_PACKET, SEND_WAVEFORM_PACKETS, DONE);
	signal internal_EVENT_BUILDER_STATE      : event_builder_state := IDLE;
	signal internal_EVENT_BUILDER_NEXT_STATE : event_builder_state := IDLE;
	--Signals to choose between data sources
	signal internal_DATA_MUX_SELECT          : std_logic := '0'; --'0' for event header, '1' for waveform data
	signal internal_EVENT_HEADER_DATA        : std_logic_vector(31 downto 0);
	signal internal_EVENT_HEADER_DATA_VALID  : std_logic;
	signal internal_EVENT_HEADER_EMPTY       : std_logic;
	--Counter to track which word we're on in event packet
	--We reset the counter to max count so that on the first word "clocked" out of it, we wrap to 0
	--This is a bit of a kluge but it works for now.
	signal internal_PACKET_COUNTER           : unsigned(7 downto 0) := (others => '1');
	signal internal_PACKET_COUNTER_RESET     : std_logic := '0';
	signal internal_PACKET_COUNTER_ENABLE    : std_logic := '0';
	--Registers to make an edge detector for start signal
	signal internal_START_BUILDING_EVENT_REG : std_logic_vector(1 downto 0);
	signal internal_START                    : std_logic := '0';
	--Signals for dealing with the checksum
	signal internal_CHECKSUM                 : unsigned(31 downto 0);
	signal internal_CHECKSUM_RESET           : std_logic := '0';
	--SciFi related
	signal TRIGGER_BIT_WORD_0						: std_logic_vector(31 downto 0);
	signal TRIGGER_BIT_WORD_1						: std_logic_vector(31 downto 0);
	signal TRIGGER_BIT_WORD_2						: std_logic_vector(31 downto 0);
	signal TRIGGER_BIT_WORD_3						: std_logic_vector(31 downto 0);
	signal TRIGGER_BIT_WORD_4						: std_logic_vector(31 downto 0);
	signal TRIGGER_BIT_WORD_5						: std_logic_vector(31 downto 0);
	signal TRIGGER_BIT_WORD_6						: std_logic_vector(31 downto 0);
	signal TRIGGER_BIT_WORD_7						: std_logic_vector(31 downto 0);
	signal TRIGGER_BIT_WORD_8						: std_logic_vector(31 downto 0);
	signal TRIGGER_BIT_WORD_9						: std_logic_vector(31 downto 0);
begin
	--Connect to top level output ports
	WAVEFORM_FIFO_READ_CLOCK <= READ_CLOCK;

	--State machine for the event builder
	--Logic outputs
	process(internal_EVENT_BUILDER_STATE) begin
		internal_DATA_MUX_SELECT         <= '0'; --Usually choose event header
		internal_CHECKSUM_RESET          <= '0';
		internal_EVENT_HEADER_EMPTY      <= '1';
		internal_PACKET_COUNTER_RESET    <= '0';
		DONE_SENDING_EVENT               <= '0';
		case internal_EVENT_BUILDER_STATE is
			when IDLE =>
				internal_EVENT_HEADER_EMPTY   <= '1';
				internal_CHECKSUM_RESET       <= '1';
				internal_PACKET_COUNTER_RESET <= '1';
			when START =>
				internal_EVENT_HEADER_EMPTY   <= '0';
			when SEND_HEADER_PACKET =>
				internal_EVENT_HEADER_EMPTY   <= '0';
			when SEND_WAVEFORM_PACKETS =>
				internal_EVENT_HEADER_EMPTY   <= '1';
				internal_DATA_MUX_SELECT      <= '1';
			when DONE =>
				internal_EVENT_HEADER_EMPTY   <= '1';
				DONE_SENDING_EVENT            <= '1';
		end case;
	end process;
	--Next state logic
	process(internal_EVENT_BUILDER_STATE, internal_START, FIFO_READ_ENABLE, internal_PACKET_COUNTER, WAVEFORM_FIFO_EMPTY, internal_EVENT_HEADER_DATA_VALID) begin
		case internal_EVENT_BUILDER_STATE is
			when IDLE =>
				if (internal_START = '1') then
					internal_EVENT_BUILDER_NEXT_STATE <= START;
				else 
					internal_EVENT_BUILDER_NEXT_STATE <= IDLE;
				end if;
			when START =>
				if (FIFO_READ_ENABLE = '1') then
					internal_EVENT_BUILDER_NEXT_STATE <= SEND_HEADER_PACKET;
				else
					internal_EVENT_BUILDER_NEXT_STATE <= START;
				end if;
			when SEND_HEADER_PACKET =>
				if (internal_EVENT_HEADER_DATA_VALID = '0') then
--				if (internal_PACKET_COUNTER = unsigned(word_NUMBER_WORDS_IN_EVENT_HEADER(internal_PACKET_COUNTER'length-1 downto 0)) + 1) then
					--internal_EVENT_BUILDER_NEXT_STATE <= SEND_WAVEFORM_PACKETS;
					internal_EVENT_BUILDER_NEXT_STATE <= DONE;
				else
					internal_EVENT_BUILDER_NEXT_STATE <= SEND_HEADER_PACKET;
				end if;
			when SEND_WAVEFORM_PACKETS =>
				if (WAVEFORM_FIFO_EMPTY = '1') then
					internal_EVENT_BUILDER_NEXT_STATE <= DONE;
				else
					internal_EVENT_BUILDER_NEXT_STATE <= SEND_WAVEFORM_PACKETS;
				end if;
			when DONE =>
				if (MAKE_READY = '1') then
					internal_EVENT_BUILDER_NEXT_STATE <= IDLE;
				else
					internal_EVENT_BUILDER_NEXT_STATE <= DONE;
				end if;
			when others =>
				internal_EVENT_BUILDER_NEXT_STATE <= IDLE;
		end case;
	end process;	
	--Register the next state
	process(READ_CLOCK) begin
		if (rising_edge(READ_CLOCK)) then
			internal_EVENT_BUILDER_STATE <= internal_EVENT_BUILDER_NEXT_STATE;
		end if;
	end process;

	--Choose data and FIFO interface based on where we are in the event building
	FIFO_DATA_OUT <= internal_EVENT_HEADER_DATA when internal_DATA_MUX_SELECT = '0' else
	                 WAVEFORM_FIFO_DATA;
	FIFO_DATA_VALID <= internal_EVENT_HEADER_DATA_VALID when internal_DATA_MUX_SELECT = '0' else
	                   WAVEFORM_FIFO_DATA_VALID;
	FIFO_EMPTY    <= internal_EVENT_HEADER_EMPTY when internal_DATA_MUX_SELECT = '0' else
	                 WAVEFORM_FIFO_EMPTY;
	WAVEFORM_FIFO_READ_ENABLE <= '0' when internal_DATA_MUX_SELECT = '0' else
	                             FIFO_READ_ENABLE;
	
	--Counter to track which packet we're on during the event header packet
	internal_PACKET_COUNTER_ENABLE <= FIFO_READ_ENABLE;
	process(READ_CLOCK) begin
		if (rising_edge(READ_CLOCK)) then
			if (internal_PACKET_COUNTER_RESET = '1') then
				--We reset the counter to max count so that on the first word "clocked" out of it, we wrap to 0
				--This is a bit of a kluge but it works for now.
				internal_PACKET_COUNTER <= (others => '1');
			elsif (internal_PACKET_COUNTER_ENABLE = '1') then
				internal_PACKET_COUNTER <= internal_PACKET_COUNTER + 1;
			end if;
		end if;
	end process;
	--Data is valid from the packet header if the word is in a valid range
	process(internal_PACKET_COUNTER) begin
		--if (internal_PACKET_COUNTER < unsigned(word_NUMBER_WORDS_IN_EVENT_HEADER(internal_PACKET_COUNTER'length-1 downto 0))+2) then
		if (internal_PACKET_COUNTER < unsigned(word_NUMBER_WORDS_IN_EVENT_HEADER(internal_PACKET_COUNTER'length-1 downto 0))+12) then
			internal_EVENT_HEADER_DATA_VALID <= '1';
		else
			internal_EVENT_HEADER_DATA_VALID <= '0';
		end if;
	end process;

	--Muliplexer to choose what the data is during the event header packet
	internal_EVENT_HEADER_DATA <= word_PACKET_HEADER                  when (to_integer(internal_PACKET_COUNTER) = 0) else
	                              word_NUMBER_WORDS_IN_EVENT_HEADER   when (to_integer(internal_PACKET_COUNTER) = 1) else
	                              word_EVENT_HEADER                   when (to_integer(internal_PACKET_COUNTER) = 2) else
											SCROD_REV_AND_ID_WORD               when (to_integer(internal_PACKET_COUNTER) = 3) else
											word_PROTOCOL_FREEZE_DATE           when (to_integer(internal_PACKET_COUNTER) = 4) else
	                              EVENT_NUMBER_WORD                   when (to_integer(internal_PACKET_COUNTER) = 5) else
	                              EVENT_FLAG_WORD                     when (to_integer(internal_PACKET_COUNTER) = 6) else
	                              EVENT_TYPE_WORD                     when (to_integer(internal_PACKET_COUNTER) = 7) else
											NUMBER_OF_WAVEFORM_PACKETS_WORD     when (to_integer(internal_PACKET_COUNTER) = 8) else
	                              word_NUMBER_AUX_PACKETS             when (to_integer(internal_PACKET_COUNTER) = 9) else
											TRIGGER_BIT_WORD_0 						when (to_integer(internal_PACKET_COUNTER) = 10) else
											TRIGGER_BIT_WORD_1 						when (to_integer(internal_PACKET_COUNTER) = 11) else
											TRIGGER_BIT_WORD_2 						when (to_integer(internal_PACKET_COUNTER) = 12) else
											TRIGGER_BIT_WORD_3 						when (to_integer(internal_PACKET_COUNTER) = 13) else
											TRIGGER_BIT_WORD_4 						when (to_integer(internal_PACKET_COUNTER) = 14) else
											TRIGGER_BIT_WORD_5 						when (to_integer(internal_PACKET_COUNTER) = 15) else
											TRIGGER_BIT_WORD_6 						when (to_integer(internal_PACKET_COUNTER) = 16) else
											TRIGGER_BIT_WORD_7 						when (to_integer(internal_PACKET_COUNTER) = 17) else
											TRIGGER_BIT_WORD_8 						when (to_integer(internal_PACKET_COUNTER) = 18) else
											TRIGGER_BIT_WORD_9 						when (to_integer(internal_PACKET_COUNTER) = 19) else
											std_logic_vector(internal_CHECKSUM) when (to_integer(internal_PACKET_COUNTER) = 20) else
											(others => 'X');

	--Process to handle incrementing the checksum
	process(READ_CLOCK) begin
		if (rising_edge(READ_CLOCK)) then
			if (internal_CHECKSUM_RESET = '1') then
				internal_CHECKSUM <= (others => '0');
			elsif (FIFO_READ_ENABLE = '1') then
				internal_CHECKSUM <= internal_CHECKSUM + unsigned(internal_EVENT_HEADER_DATA);
			end if;
		end if;
	end process;

	--Synchronous edge-to-pulse for the event builder
	process(READ_CLOCK) begin
		if (rising_edge(READ_CLOCK)) then
			internal_START_BUILDING_EVENT_REG(1) <= internal_START_BUILDING_EVENT_REG(0);
			internal_START_BUILDING_EVENT_REG(0) <= START_BUILDING_EVENT;
		end if;
	end process;
	process(internal_START_BUILDING_EVENT_REG) begin
		if (internal_START_BUILDING_EVENT_REG = "01") then
			internal_START <= '1';
		else
			internal_START <= '0';
		end if;
	end process;
	
	--generate trigger bit words
	TRIGGER_BIT_WORD_0 <=  
		x"ABCD" & "000" & TDC_TRG_16_1(0) & TDC_TRG_4_1(0) & TDC_TRG_3_1(0) & TDC_TRG_2_1(0) & TDC_TRG_1_1(0)
		& "000" & TDC_TRG_16_0(0) & TDC_TRG_4_0(0) & TDC_TRG_3_0(0) & TDC_TRG_2_0(0) & TDC_TRG_1_0(0);
	TRIGGER_BIT_WORD_1 <=  
		x"ABCD" & "000" & TDC_TRG_16_1(1) & TDC_TRG_4_1(1) & TDC_TRG_3_1(1) & TDC_TRG_2_1(1) & TDC_TRG_1_1(1)
		& "000" & TDC_TRG_16_0(1) & TDC_TRG_4_0(1) & TDC_TRG_3_0(1) & TDC_TRG_2_0(1) & TDC_TRG_1_0(1);
	TRIGGER_BIT_WORD_2 <=  
		x"ABCD" & "000" & TDC_TRG_16_1(2) & TDC_TRG_4_1(2) & TDC_TRG_3_1(2) & TDC_TRG_2_1(2) & TDC_TRG_1_1(2)
		& "000" & TDC_TRG_16_0(2) & TDC_TRG_4_0(2) & TDC_TRG_3_0(2) & TDC_TRG_2_0(2) & TDC_TRG_1_0(2);
	TRIGGER_BIT_WORD_3 <=  
		x"ABCD" & "000" & TDC_TRG_16_1(3) & TDC_TRG_4_1(3) & TDC_TRG_3_1(3) & TDC_TRG_2_1(3) & TDC_TRG_1_1(3)
		& "000" & TDC_TRG_16_0(3) & TDC_TRG_4_0(3) & TDC_TRG_3_0(3) & TDC_TRG_2_0(3) & TDC_TRG_1_0(3);
	TRIGGER_BIT_WORD_4 <=  
		x"ABCD" & "000" & TDC_TRG_16_1(4) & TDC_TRG_4_1(4) & TDC_TRG_3_1(4) & TDC_TRG_2_1(4) & TDC_TRG_1_1(4)
		& "000" & TDC_TRG_16_0(4) & TDC_TRG_4_0(4) & TDC_TRG_3_0(4) & TDC_TRG_2_0(4) & TDC_TRG_1_0(4);
	TRIGGER_BIT_WORD_5 <=  
		x"ABCD" & "000" & TDC_TRG_16_1(5) & TDC_TRG_4_1(5) & TDC_TRG_3_1(5) & TDC_TRG_2_1(5) & TDC_TRG_1_1(5)
		& "000" & TDC_TRG_16_0(5) & TDC_TRG_4_0(5) & TDC_TRG_3_0(5) & TDC_TRG_2_0(5) & TDC_TRG_1_0(5);	
	TRIGGER_BIT_WORD_6 <=  
		x"ABCD" & "000" & TDC_TRG_16_1(6) & TDC_TRG_4_1(6) & TDC_TRG_3_1(6) & TDC_TRG_2_1(6) & TDC_TRG_1_1(6)
		& "000" & TDC_TRG_16_0(6) & TDC_TRG_4_0(6) & TDC_TRG_3_0(6) & TDC_TRG_2_0(6) & TDC_TRG_1_0(6);
	TRIGGER_BIT_WORD_7 <=  
		x"ABCD" & "000" & TDC_TRG_16_1(7) & TDC_TRG_4_1(7) & TDC_TRG_3_1(7) & TDC_TRG_2_1(7) & TDC_TRG_1_1(7)
		& "000" & TDC_TRG_16_0(7) & TDC_TRG_4_0(7) & TDC_TRG_3_0(7) & TDC_TRG_2_0(7) & TDC_TRG_1_0(7);	
	TRIGGER_BIT_WORD_8 <=  
		x"ABCD" & "000" & TDC_TRG_16_1(8) & TDC_TRG_4_1(8) & TDC_TRG_3_1(8) & TDC_TRG_2_1(8) & TDC_TRG_1_1(8)
		& "000" & TDC_TRG_16_0(8) & TDC_TRG_4_0(8) & TDC_TRG_3_0(8) & TDC_TRG_2_0(8) & TDC_TRG_1_0(8);
	TRIGGER_BIT_WORD_9 <=  
		x"ABCD" & "000" & TDC_TRG_16_1(9) & TDC_TRG_4_1(9) & TDC_TRG_3_1(9) & TDC_TRG_2_1(9) & TDC_TRG_1_1(9)
		& "000" & TDC_TRG_16_0(9) & TDC_TRG_4_0(9) & TDC_TRG_3_0(9) & TDC_TRG_2_0(9) & TDC_TRG_1_0(9);
end Behavioral;

