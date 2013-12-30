-------------------------------------------------------------------------------
-- Title         : Evolution Target 2 board
-- Project       : Hiro
-------------------------------------------------------------------------------
-- File          : DigitizingLgc.vhd
-- Author        : Leonid Sapozhnikov, leosap@slac.stanford.edu
-- Created       : 6/22/2011
-------------------------------------------------------------------------------
-- Description:--
--	Function:		Implement sampling control signals
--               At this point very simple. Start recording when enable
--              Stop signal due to readout stop recording and recording restart
--              from location 0 when readout is complete, need to verify if stop desireble
--              wrt_addrclr clear Target2 address as well on stop
--              SM desined for easy change if require different timing
--	Modifications:
--
--

--
-- ROVDD  need to be set in way that it is a little slower then 125*8 =1Ghz in order to
-- avoid missing samples but rather to have double sampling at the end and beginning of
-- two neiboring rows
--

-------------------------------------------------------------------------------
-- Copyright (c) 2011 by Leonid Sapozhnikov. All rights reserved.
-------------------------------------------------------------------------------
-- Modification history:
-- 6/22/2011: created.
-- 09/2012: modified by BK
-------------------------------------------------------------------------------
Library work;
use work.all;
--use work.Target2Package.all;

Library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
--Library synplify;
--use synplify.attributes.all;


entity DigitizingLgc is
   port (
        clk		 			     	: in   std_logic;
        StartDig	 		   	: in   std_logic;  -- capture trigger data
		  ramp_length		 		: in std_logic_vector (11 downto 0);
        rd_ena           		: out   std_logic; --enable read out??
        clr              		: out   std_logic;
		  startramp	   			: out   std_logic	--ramp enable signal
       );
end DigitizingLgc;

architecture Behavioral of DigitizingLgc is

type state_type is
	(
	Idle,				  -- Idling until command start bit
   WaitAddress,		  -- Wait for address to settle
   WaitRead,		  -- Wait for transfer time from Array to WADC, read enable
	WConvert,	    -- wait for conversion to complete
	CheckDone, 	  -- check if done of more loops
	ClrState
	);

signal StartDig_in	: std_logic := '0';
signal next_state		: state_type := Idle;
signal rd_ena_out    : std_logic := '0';
signal clr_out 		: std_logic := '0';
signal startramp_out : std_logic := '0';

signal ramp_start : std_logic_vector (11 downto 0);
signal RDEN_LENGTH : std_logic_vector(11 downto 0);
signal RAMP_CNT    : std_logic_vector(10 downto 0) := "00000000000";

--------------------------------------------------------------------------------
begin

--assign output signals
rd_ena <= rd_ena_out;
clr <= clr_out;
startramp <= startramp_out;

--hardcoded versions of constants
--time delay between receipt of "Start" and setting rd_en high
ramp_start <= "000000010000";
--time rd_en is held high before setting ramp, start high
RDEN_LENGTH <= "000000100000";

--latch stop to local clock domain
process(Clk)
begin
if (clk'event and clk = '1') then
	StartDig_in <= StartDig;
end if;
end process;

process(Clk)
begin
if (Clk'event and Clk = '1') then
  
  Case next_state is
  When Idle =>
    clr_out              <= '1';
	 rd_ena_out         <= '0';
	 startramp_out            	<= '0';
    RAMP_CNT         <= (others=>'0');
    if (StartDig_in = '1') then   -- start (trigger was detected)
      next_state 	<= WaitAddress;
    else
      next_state 	<= Idle;
    end if;

  When WaitAddress =>  --wait for address to settle on ASIC
    clr_out              <= '0';
	 rd_ena_out         <= '0';  -- making guess on how transfer initiated
	 startramp_out        <= '0';
    if (RAMP_CNT(9 downto 0) < ramp_start) then  -- to delay ramp
      RAMP_CNT <= RAMP_CNT + '1';
      next_state 	<= WaitAddress;
    else
      RAMP_CNT <= (others => '0');
      next_state 	<= WaitRead;
    end if;

  When WaitRead =>  --set read enable high, wait for X clock cycles
    clr_out              <= '0';
	 rd_ena_out         <= '1';  -- latches column , row read address?
	 startramp_out        <= '0';
    if (RAMP_CNT(10 downto 0) < RDEN_LENGTH) then
      RAMP_CNT <= RAMP_CNT + '1';
      next_state 	<= WaitRead;
    else
      RAMP_CNT <= (others => '0');
      next_state 	<= WConvert;
    end if;

  When WConvert =>  --set ramp, start high
    clr_out              <= '0';
	 rd_ena_out         <= '1';
	 startramp_out        <= '1';
    if (RAMP_CNT(10 downto 0) < ramp_length(10 downto 0)) then  -- to generate ramp
      RAMP_CNT <= RAMP_CNT + '1';
      next_state 	<= WConvert;
    else
      RAMP_CNT <= (others => '0');
      next_state 	<= CheckDone;
    end if;

  When CheckDone =>  --wait for 32 sample readout to finish
	 clr_out              <= '0';
    rd_ena_out         <= '1';
	 startramp_out        <= '1';
    RAMP_CNT         <= (others=>'0');
    if(StartDig_in = '0') then  -- done
      next_state 	<= Idle	;
    else
      next_state 	<= CheckDone;
    end if;

  When Others =>
  clr_out              <= '1';
  startramp_out        <= '0';
  rd_ena_out         <= '0';
  RAMP_CNT         <= (others=>'0');
  next_state <= Idle;
  end Case;
end if;
end process;

end Behavioral;