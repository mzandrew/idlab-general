----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:43:03 02/08/2013 
-- Design Name: 
-- Module Name:    triggerBitLogic - Behavioral 
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

entity triggerBitLogic is
    Port ( CLK : in  STD_LOGIC;
           TRIGGER_IN : in  STD_LOGIC;
			  LOAD_DACs_DONE_in : in  STD_LOGIC;
			  REQ_PACKET_IN : in STD_LOGIC;
			  SEND_PACKET : out  STD_LOGIC;
			  PACKETSENT_IN : in  STD_LOGIC;
			  MAKE_READY : out std_logic;
           LOAD_DACs : out  STD_LOGIC;
           WRITE_DACs : out  STD_LOGIC;
           TRIG_TYPE_val : out  STD_LOGIC;
			  TDC_TRG_1_IN : in STD_LOGIC_VECTOR(9 downto 0);
			  TDC_TRG_2_IN : in STD_LOGIC_VECTOR(9 downto 0);			
			  TDC_TRG_3_IN : in STD_LOGIC_VECTOR(9 downto 0);
			  TDC_TRG_4_IN : in STD_LOGIC_VECTOR(9 downto 0);
			  TDC_TRG_16_IN : in STD_LOGIC_VECTOR(9 downto 0);
			  TDC_TRG_1_out0 : out STD_LOGIC_VECTOR(9 downto 0);
			  TDC_TRG_2_out0 : out STD_LOGIC_VECTOR(9 downto 0);			
			  TDC_TRG_3_out0 : out STD_LOGIC_VECTOR(9 downto 0);
			  TDC_TRG_4_out0 : out STD_LOGIC_VECTOR(9 downto 0);
			  TDC_TRG_16_out0 : out STD_LOGIC_VECTOR(9 downto 0);
			  TDC_TRG_1_out1 : out STD_LOGIC_VECTOR(9 downto 0);
			  TDC_TRG_2_out1 : out STD_LOGIC_VECTOR(9 downto 0);			
			  TDC_TRG_3_out1 : out STD_LOGIC_VECTOR(9 downto 0);
			  TDC_TRG_4_out1 : out STD_LOGIC_VECTOR(9 downto 0);
			  TDC_TRG_16_out1 : out STD_LOGIC_VECTOR(9 downto 0)
			  );
end triggerBitLogic;

architecture Behavioral of triggerBitLogic is

	--state machine for trigger bit recording
	--Insert the following in the architecture before the begin keyword
   --Use descriptive names for the states, like st1_reset, st2_search
   type state_type is (st1_LoadAsicWord0, st2_WaitLoadAsicWord0, st3_WriteAsicWord0, st4_WaitSettle0, st5_LoadAsicWord1,
			st6_WaitLoadAsicWord1, st7_WaitTrigger, st8_WriteAsicWord1, st9_WaitSettle1, st10_WaitPacketReq, st11_WaitPacketSend, st12_SendMakeReady, st13_WaitReset); 
   signal state : state_type := st1_LoadAsicWord0;
	signal next_state : state_type := st1_LoadAsicWord0;
	
	signal LOAD_DACs_DONE : std_logic := '0';
   signal PACKETSENT : std_logic := '0';
	signal REQ_PACKET : std_logic := '0';
	signal internal_TRIGGER : std_logic := '0';
	signal LATCH_TRGBITS_0 : std_logic := '0';
	signal LATCH_TRGBITS_1 : std_logic := '0';
	signal ENABLE_COUNTER : std_logic := '0';
	signal INTERNAL_COUNTER	: UNSIGNED(15 downto 0);
	signal TRIGGER_REG : std_logic_vector(1 downto 0) := "00";
	signal LATCH_TRGBITS_0_REG : std_logic_vector(1 downto 0) := "00";
	signal LATCH_TRGBITS_1_REG : std_logic_vector(1 downto 0) := "00";
	signal TDC_TRG_16_d				: std_logic_vector(9 downto 0);
	signal TDC_TRG_4_d					: std_logic_vector(9 downto 0);
	signal TDC_TRG_3_d					: std_logic_vector(9 downto 0);
	signal TDC_TRG_2_d					: std_logic_vector(9 downto 0);
	signal TDC_TRG_1_d					: std_logic_vector(9 downto 0);
	signal TDC_TRG_16_ext				: std_logic_vector(9 downto 0);
	signal TDC_TRG_4_ext					: std_logic_vector(9 downto 0);
	signal TDC_TRG_3_ext					: std_logic_vector(9 downto 0);
	signal TDC_TRG_2_ext					: std_logic_vector(9 downto 0);
	signal TDC_TRG_1_ext					: std_logic_vector(9 downto 0);
	signal TDC_TRG_16_latch0				: std_logic_vector(9 downto 0);
	signal TDC_TRG_4_latch0					: std_logic_vector(9 downto 0);
	signal TDC_TRG_3_latch0					: std_logic_vector(9 downto 0);
	signal TDC_TRG_2_latch0					: std_logic_vector(9 downto 0);
	signal TDC_TRG_1_latch0					: std_logic_vector(9 downto 0);
	signal TDC_TRG_16_latch1				: std_logic_vector(9 downto 0);
	signal TDC_TRG_4_latch1					: std_logic_vector(9 downto 0);
	signal TDC_TRG_3_latch1					: std_logic_vector(9 downto 0);
	signal TDC_TRG_2_latch1					: std_logic_vector(9 downto 0);
	signal TDC_TRG_1_latch1					: std_logic_vector(9 downto 0);
	
begin

	--Edge detector for the trigger, key internal signals
	process (CLK) begin
		--The only other couple SST clock processes work on falling edges, so we should be consistent here
		if (falling_edge(CLK)) then	
			TRIGGER_REG(1) <= TRIGGER_REG(0);
			TRIGGER_REG(0) <= TRIGGER_IN;
			
			LATCH_TRGBITS_0_REG(1) <= LATCH_TRGBITS_0_REG(0);
			LATCH_TRGBITS_0_REG(0) <= LATCH_TRGBITS_0;
			
			LATCH_TRGBITS_1_REG(1) <= LATCH_TRGBITS_1_REG(0);
			LATCH_TRGBITS_1_REG(0) <= LATCH_TRGBITS_1;
		end if;
	end process;
	internal_TRIGGER <= '1' when (TRIGGER_REG = "01") else
	                    '0';

	--Trigger bit related
	--extend trigger bit signals
	gen_trig_delay: for i in 0 to 9 generate
		process (CLK) begin
			if(rising_edge(CLK)) then
				TDC_TRG_1_d(i) <= TDC_TRG_1_IN(i);
				TDC_TRG_2_d(i) <= TDC_TRG_2_IN(i);
				TDC_TRG_3_d(i) <= TDC_TRG_3_IN(i);
				TDC_TRG_4_d(i) <= TDC_TRG_4_IN(i);
				TDC_TRG_16_d(i) <= TDC_TRG_16_IN(i);
			end if;
		end process;		
		TDC_TRG_1_ext(i) <= TDC_TRG_1_d(i) or TDC_TRG_1_IN(i);
		TDC_TRG_2_ext(i) <= TDC_TRG_2_d(i) or TDC_TRG_2_IN(i);
		TDC_TRG_3_ext(i) <= TDC_TRG_3_d(i) or TDC_TRG_3_IN(i);
		TDC_TRG_4_ext(i) <= TDC_TRG_4_d(i) or TDC_TRG_4_IN(i);
		TDC_TRG_16_ext(i) <= TDC_TRG_16_d(i) or TDC_TRG_16_IN(i);
	end generate;

	--store trigger bits on receipt of  trigger
	gen_trig_capture0 : for i in 0 to 9 generate
		TDC_TRG_16_latch0(i) <= TDC_TRG_16_ext(i) when (LATCH_TRGBITS_0_REG = "01") else
	                    TDC_TRG_16_latch0(i);
		TDC_TRG_4_latch0(i) <= TDC_TRG_4_ext(i) when (LATCH_TRGBITS_0_REG = "01") else
	                    TDC_TRG_4_latch0(i);
		TDC_TRG_3_latch0(i) <= TDC_TRG_3_ext(i) when (LATCH_TRGBITS_0_REG = "01") else
	                    TDC_TRG_3_latch0(i);
		TDC_TRG_2_latch0(i) <= TDC_TRG_2_ext(i) when (LATCH_TRGBITS_0_REG = "01") else
	                    TDC_TRG_2_latch0(i);
		TDC_TRG_1_latch0(i) <= TDC_TRG_1_ext(i) when (LATCH_TRGBITS_0_REG = "01") else
	                    TDC_TRG_1_latch0(i);
		TDC_TRG_16_out0(i) <= TDC_TRG_16_latch0(i);
		TDC_TRG_4_out0(i) <= TDC_TRG_4_latch0(i);
		TDC_TRG_3_out0(i) <= TDC_TRG_3_latch0(i);
		TDC_TRG_2_out0(i) <= TDC_TRG_2_latch0(i);
		TDC_TRG_1_out0(i) <= TDC_TRG_1_latch0(i);
	end generate;
 
 	gen_trig_capture1 : for i in 0 to 9 generate
		TDC_TRG_16_latch1(i) <= TDC_TRG_16_ext(i) when (LATCH_TRGBITS_1_REG = "01") else
	                    TDC_TRG_16_latch1(i);
		TDC_TRG_4_latch1(i) <= TDC_TRG_4_ext(i) when (LATCH_TRGBITS_1_REG = "01") else
	                    TDC_TRG_4_latch1(i);
		TDC_TRG_3_latch1(i) <= TDC_TRG_3_ext(i) when (LATCH_TRGBITS_1_REG = "01") else
	                    TDC_TRG_3_latch1(i);
		TDC_TRG_2_latch1(i) <= TDC_TRG_2_ext(i) when (LATCH_TRGBITS_1_REG = "01") else
	                    TDC_TRG_2_latch1(i);
		TDC_TRG_1_latch1(i) <= TDC_TRG_1_ext(i) when (LATCH_TRGBITS_1_REG = "01") else
	                    TDC_TRG_1_latch1(i);
		TDC_TRG_16_out1(i) <= TDC_TRG_16_latch1(i);
		TDC_TRG_4_out1(i) <= TDC_TRG_4_latch1(i);
		TDC_TRG_3_out1(i) <= TDC_TRG_3_latch1(i);
		TDC_TRG_2_out1(i) <= TDC_TRG_2_latch1(i);
		TDC_TRG_1_out1(i) <= TDC_TRG_1_latch1(i);
	end generate;
	
	--counter process
	process (CLK) begin
		if (rising_edge(CLK)) then
			if ENABLE_COUNTER = '1' then
				INTERNAL_COUNTER <= INTERNAL_COUNTER + 1;
			else
				INTERNAL_COUNTER <= (others=>'0');
			end if;
		end if;
	end process;
 
	--STATE MACHINE SYNC
   SYNC_PROC: process (CLK)
   begin
      if (CLK'event and CLK = '1') then
         state <= next_state;
			LOAD_DACs_DONE <= LOAD_DACs_DONE_in;
         PACKETSENT <= PACKETSENT_IN;
			REQ_PACKET <= REQ_PACKET_IN;
      end if;
   end process;
 
   --MOORE State-Machine - Outputs based on state only
   OUTPUT_DECODE: process (state)
   begin
      if state = st1_LoadAsicWord0 OR state = st5_LoadAsicWord1 then
         LOAD_DACs <= '1';
      else
         LOAD_DACs <= '0';
      end if;
		if state = st3_WriteAsicWord0 OR state = st8_WriteAsicWord1 then
         WRITE_DACs <= '1';
      else
         WRITE_DACs <= '0';
      end if;
		if state = st1_LoadAsicWord0 or state = st2_WaitLoadAsicWord0 or state = st3_WriteAsicWord0 then
			TRIG_TYPE_val <= '0';
		else
			TRIG_TYPE_val <= '1';
		end if;
		if state = st11_WaitPacketSend then
			SEND_PACKET <= '1';
		else
			SEND_PACKET <= '0';
		end if;
		if state = st8_WriteAsicWord1 then
			LATCH_TRGBITS_0 <= '1';
		else
			LATCH_TRGBITS_0 <= '0';
		end if;
		if state = st10_WaitPacketReq then
			LATCH_TRGBITS_1 <= '1';
		else
			LATCH_TRGBITS_1 <= '0';
		end if;
		if state = st4_WaitSettle0 OR state = st9_WaitSettle1 then
			ENABLE_COUNTER <= '1';
		else
			ENABLE_COUNTER <= '0';
		end if;
		if state = st12_SendMakeReady then
			MAKE_READY <= '1';
		else
			MAKE_READY <= '0';
		end if;
   end process;
 
   NEXT_STATE_DECODE: process (state, LOAD_DACs_DONE, internal_TRIGGER, INTERNAL_COUNTER, REQ_PACKET, PACKETSENT)
   begin
      --declare default state for next_state to avoid latches
      next_state <= state;  --default is to stay in current state
      --insert statements to decode next_state
      --below is a simple example
      case (state) is
         when st1_LoadAsicWord0 =>
            if LOAD_DACs_DONE = '0' then
               next_state <= st2_WaitLoadAsicWord0;
            end if;
			when st2_WaitLoadAsicWord0 =>
				if LOAD_DACs_DONE = '1' then
               next_state <= st3_WriteAsicWord0;
            end if;
         when st3_WriteAsicWord0 =>
				next_state <= st4_WaitSettle0;
				--next_state <= st4_WaitSettle0;
			when st4_WaitSettle0 =>
				if INTERNAL_COUNTER > 0 then
					next_state <= st5_LoadAsicWord1;
				end if;
         when st5_LoadAsicWord1 =>
				if LOAD_DACs_DONE = '0' then
					next_state <= st6_WaitLoadAsicWord1;
				end if;
			when st6_WaitLoadAsicWord1 =>
				if LOAD_DACs_DONE = '1' then
               next_state <= st7_WaitTrigger;
            end if;
			when st7_WaitTrigger =>	
				if internal_TRIGGER = '1' or REQ_PACKET = '1' then
					next_state <= st8_WriteAsicWord1;
				end if;
			when st8_WriteAsicWord1 =>	
				next_state <= st9_WaitSettle1;
				--next_state <= st10_WaitPacketReq;
			when st9_WaitSettle1 =>
				if INTERNAL_COUNTER > 0 then
					next_state <= st10_WaitPacketReq;
				end if;
			when st10_WaitPacketReq =>
				if REQ_PACKET = '1' then
					next_state <= st11_WaitPacketSend;
				end if;
			when st11_WaitPacketSend =>
				if PACKETSENT = '1' then
					next_state <= st12_SendMakeReady;
				end if;
			when st12_SendMakeReady =>
				next_state <= st13_WaitReset;
			when st13_WaitReset =>
				if REQ_PACKET = '0' and PACKETSENT = '0' then
					next_state <= st1_LoadAsicWord0;
				end if;
         when others =>
            next_state <= st1_LoadAsicWord0;
      end case;      
   end process;
	
end Behavioral;