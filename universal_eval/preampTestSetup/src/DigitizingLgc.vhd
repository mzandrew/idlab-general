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
        clk		 			     : in   std_logic;
        rst 			       : in   std_logic;
        StartDig	 		   : in   std_logic;  -- capture trigger data
		  ramp_length		 : in std_logic_vector (11 downto 0);
        RAMP_DONE	       : out std_logic; -- indicate all ramp processing complition
        rd_ena           : out   std_logic; --enable read out??
        clr              : out   std_logic;
		  --start_out            : out   std_logic;
        --ramp_out             : out   std_logic;	--ramp enable signal
		  startramp_out   : out   std_logic;	--ramp enable signal
		  CUR_STATE			: out   std_logic_vector( 3 downto 0)
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

signal next_state					: state_type;
signal Buf_Sel		   : std_logic_vector(11 downto 0);
signal RAMP_CNT       : std_logic_vector(10 downto 0);
signal rd_ena_i   : std_logic;
--signal ramp : std_logic;
--signal start : std_logic;
signal startramp : std_logic;
--signal delay_count : std_logic_vector (7 downto 0);--temporary, offset ramp and start

--signal ramp_length    : std_logic_vector(10 downto 0);
signal ramp_start : std_logic_vector (11 downto 0);
signal RDEN_LENGTH : std_logic_vector(11 downto 0);
--signal trig_delay : std_logic_vector (7 downto 0);  -- count for trigger processing time
--------------------------------------------------------------------------------
begin

--assign output signals to Buf_sel, re_ena_i
rd_ena <= rd_ena_i;

--hardcoded versions of constants
--time delay between receipt of "Start" and setting rd_en high
ramp_start <= "000000010000";
--time rd_en is held high before setting ramp, start high
RDEN_LENGTH <= "000000100000";

--ramp_out <= ramp;
--start_out <= start;
startramp_out <= startramp;

process(Clk,rst)
begin
if (rst = '1') then
  clr              	<= '1';
  rd_ena_i           <= '0';
  --start             	<= '0';
  --ramp             	<= '0';
  startramp            	<= '0';
  RAMP_DONE	       	<= '0';
  RAMP_CNT         	<= (others=>'0');
  next_state <= Idle;
  CUR_STATE <= "0000";
elsif (Clk'event and Clk = '1') then
  
  Case next_state is
  When Idle =>
    clr              <= '1';
	 rd_ena_i         <= '0';
	 --start            <= '0';
    --ramp             <= '0';
	 startramp            	<= '0';
    RAMP_DONE	      <= '0';
    RAMP_CNT         <= (others=>'0');
	 CUR_STATE 			<= "0001";
    if (StartDig = '1') then   -- start (trigger was detected)
      next_state 	<= WaitAddress;
    else
      next_state 	<= Idle;
    end if;

  When WaitAddress =>  --wait for address to settle on ASIC
    clr              <= '0';
	 rd_ena_i         <= '0';  -- making guess on how transfer initiated
	 --start            <= '0';
    --ramp             <= '0';
	 startramp        <= '0';
    RAMP_DONE	      <= '0';
	 CUR_STATE <= "0010";
    if (RAMP_CNT(9 downto 0) < ramp_start) then  -- to delay ramp
      RAMP_CNT <= RAMP_CNT + '1';
      next_state 	<= WaitAddress;
    else
      RAMP_CNT <= (others => '0');
      next_state 	<= WaitRead;
    end if;

  When WaitRead =>  --set read enable high, wait for X clock cycles
    clr              <= '0';
	 rd_ena_i         <= '1';  -- latches column , row read address?
	 --start            <= '0';
    --ramp             <= '0';
	 startramp        <= '0';
    RAMP_DONE	      <= '0';
	 CUR_STATE <= "0011";
    if (RAMP_CNT(10 downto 0) < RDEN_LENGTH) then
      RAMP_CNT <= RAMP_CNT + '1';
      next_state 	<= WaitRead;
    else
      RAMP_CNT <= (others => '0');
      next_state 	<= WConvert;
    end if;

  When WConvert =>  --set ramp, start high
    clr              <= '0';
	 rd_ena_i         <= '1';
	 --start            <= '1';
    --ramp            <= '1'; -- actually leave ramp high until serial readout is done
	 startramp        <= '1';
    RAMP_DONE	      <= '0';
	 CUR_STATE 			<= "0100";
    if (RAMP_CNT(10 downto 0) < ramp_length(10 downto 0)) then  -- to generate ramp
      RAMP_CNT <= RAMP_CNT + '1';
      next_state 	<= WConvert;
    else
      RAMP_CNT <= (others => '0');
      next_state 	<= CheckDone;
    end if;

  When CheckDone =>  --wait for 32 sample readout to finish
	 clr              <= '0';
    rd_ena_i         <= '1';
    --start            <= '1';
    --ramp             <= '1'; -- keep ramp high until readout is done
	 startramp        <= '1';
    RAMP_CNT         <= (others=>'0');
	 RAMP_DONE	      <= '1'; --signal that digitization is done
	 CUR_STATE 			<= "0101";
    if(StartDig = '0') then  -- done
      next_state 	<= Idle	;
    else
      next_state 	<= CheckDone;
    end if;

  When Others =>
  clr              <= '1';
  --start            <= '0';
  --ramp             <= '0';
  startramp        <= '0';
  RAMP_DONE	       <= '0';
  rd_ena_i         <= '0';
  RAMP_CNT         <= (others=>'0');
  next_state <= Idle;
  end Case;
end if;
end process;

end Behavioral;