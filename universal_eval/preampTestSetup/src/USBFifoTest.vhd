-------------------------------------------------------------------------------
-- Title         : Evolution Target 2 board
-- Project       : Hiro
-------------------------------------------------------------------------------
-- File          : SerialDataRout.vhd
-- Author        : Leonid Sapozhnikov, leosap@slac.stanford.edu
-- Created       : 6/22/2011
-------------------------------------------------------------------------------
-- Description:--
--	Function:		Assume identical processing for all enabled channels
--              on completion store size and enabled channels to build ethernet communication.
--              Logic need some details. If software readout it always start on buffer boundry
--              but read only enabled samples. If readout in response to trigger then no use_offset
--              sellected it is similar to above. However if use_offset selected in order to have better
--              capture image with less data readout, buffer can start from any modulo 8 boundry.
--              In this case if sample observed let say in the middle 32 bit sample. Logic will read half of one buffer
--              and half from next for 32 sample buffer. Sample enable is shifted accordinly to match offseted start
--              Total size can be precomputed because we know number of samples in buffer and number of buffers
--              And extra. This number is verified at the end of transfer. Should match, otherwise error.
--				To simplify logic the following approach is implemented:
--				If BufferNumb = 0, then   upto 64 samples can be read defined by Sample enable (operational mode), if BufferNumb > 0
--				Then readout is always in buffers boundry and all samples are read (test mode).
--	Modifications:
--
--

--


-------------------------------------------------------------------------------
-- Copyright (c) 2011 by Leonid Sapozhnikov. All rights reserved.
-------------------------------------------------------------------------------
-- Modification history:
-- 6/22/2011: created.
-------------------------------------------------------------------------------
Library work;
use work.all;
--use work.Target2Package.all;

Library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
--Library synplify;
--use synplify.attributes.all;

entity USBFifoTest is
   port (
        clk		 			     : in   std_logic;
        rst 			       : in   std_logic;
        StartTest	 		 : in   std_logic;  -- capture trigger data
		  
		  FIFO_WR_EN		 :out std_logic;
		  FIFO_WR_CLK		 :out std_logic;
		  FIFO_WR_DIN		 :out std_logic_vector(31 downto 0);
		  
		  FIFO_RD_EMPTY 	: in   std_logic;
		  FIFO_RD_EN 		: out   std_logic;
		  FIFO_RD_CLK 		: out   std_logic;
		  FIFO_RD_DOUT   	: in   std_logic_vector(31 downto 0);
		  
		  MON					 : out 	std_logic_vector(31 downto 0);
		  CUR_STATE			: out   std_logic_vector( 3 downto 0)
       );
end USBFifoTest;

architecture Behavioral of USBFifoTest is

	type fifo_write_state_type is
	(
	Idle,		
	StartFifo,
	preHigh,
	High,
	preLow,
	Low,
	WaitDone
	);
	signal fifo_write_state					: fifo_write_state_type;	
	
	type fifo_read_state_type is
	(
	IdleRd,		
	preHighRd,
	HighRd,
	preLowRd,
	LowRd
	);
	signal fifo_read_state					: fifo_read_state_type;	
	
	signal	start_fifo	:	STD_LOGIC;
	signal	FifoDone		:	STD_LOGIC;
	signal	FifoCount	:	STD_LOGIC_VECTOR(7 downto 0);
	signal	SAMP_DONE_out : STD_LOGIC;
	signal 	store_signal  : STD_LOGIC;
	signal   FIFO_RD_DOUT_store : STD_LOGIC_VECTOR(31 downto 0);
	
begin

MON <= FIFO_RD_DOUT_store(31 downto 0);

--FIFO process
process(clk,rst)
begin
if (rst = '1') then
	FifoDone	<= '0';
	FIFO_WR_EN <= '0';
	FIFO_WR_CLK <= '0';
	FIFO_WR_DIN <= (others=>'0');
	FifoCount <= (others=>'0');
	fifo_write_state <= Idle;
elsif (clk'event and clk = '1') then
  Case fifo_write_state is
  
  When Idle =>
	 FifoDone <= '0';
	 FIFO_WR_EN <= '0';
	 FIFO_WR_CLK <= '0';
	 FIFO_WR_DIN <= (others=>'0');
	 FifoCount <= (others=>'0');
    if( StartTest = '1') then
      fifo_write_state <= StartFifo;
    else
      fifo_write_state <= Idle;
    end if;
   
  When StartFifo =>
	 FifoDone <= '0';
	 FIFO_WR_EN <= '1';
	 FIFO_WR_CLK <= '0';
	 --FIFO_WR_DIN <= (others=>'0');
	 FifoCount <= FifoCount;
	 if( FifoCount < "00100000" ) then
	  fifo_write_state <= preHigh;
	 else
	  fifo_write_state <= WaitDone;	
	 end if;

  When preHigh => --load DIN here if latched on leading edge
	 FifoDone <= '0';
	 FIFO_WR_EN <= '1';
	 FIFO_WR_CLK <= '0';
	 FIFO_WR_DIN <= x"AAAA" & FifoCount & FifoCount;
	 FifoCount <= FifoCount;
	  fifo_write_state 		<= High;

  When High =>
	 FifoDone <= '0';
	 FIFO_WR_EN <= '1';
	 FIFO_WR_CLK <= '1';
	 FifoCount <= FifoCount;
	  fifo_write_state 		<= preLow;

  When preLow => --load DIN here if latched on falling edge
	 FifoDone <= '0';
	 FIFO_WR_EN <= '1';
	 FIFO_WR_CLK <= '1';
	 FifoCount <= FifoCount;
	  fifo_write_state 		<= Low;

	When Low =>
	 FifoDone <= '0';
	 FIFO_WR_EN <= '1';
	 FIFO_WR_CLK <= '0';
	 FifoCount <= FifoCount + "00001"; --increment count here
	  fifo_write_state 		<= StartFifo;
	  
	When WaitDone =>
	 FifoDone <= '1';
	 FIFO_WR_EN <= '0';
	 FIFO_WR_CLK <= '0';
	 FIFO_WR_DIN <= (others=>'0');
	 FifoCount <= (others=>'0');
	 if( StartTest = '0' ) then
      fifo_write_state 		<= Idle;
	 else
		fifo_write_state 	<= WaitDone;
	 end if;
	 
  When Others =>
    FifoDone <= '0';
	 FIFO_WR_EN <= '0';
	 FIFO_WR_CLK <= '0';
	 FIFO_WR_DIN <= (others=>'0');
	 FifoCount <= (others=>'0');
	 fifo_write_state 		<= Idle;
	end case;
end if;
end process;

--FIFO Read process
process(clk,rst)
begin
if (rst = '1') then
	FIFO_RD_EN <= '0';
	FIFO_RD_CLK <= '0';
	fifo_read_state <= IdleRd;
	FIFO_RD_DOUT_store <= (Others => '0');
	CUR_STATE <= "0000";
	store_signal <= '0';
elsif (clk'event and clk = '1') then
  Case fifo_read_state is
  
  When IdleRd =>
	 FIFO_RD_CLK <= '0';
	 CUR_STATE <= "0001";
    if( FIFO_RD_EMPTY = '0') then
		FIFO_RD_EN <= '1';
		store_signal <= '1';
	 else
		FIFO_RD_EN <= '0';
	   store_signal <= '0';
	 end if;
      fifo_read_state <= preHighRd;

  When preHighRd =>
	 FIFO_RD_CLK <= '0';
	 CUR_STATE <= "0010";
	  fifo_read_state 		<= HighRd;

  When HighRd =>
	 FIFO_RD_CLK <= '1';
	 if( store_signal = '1' ) then
		FIFO_RD_DOUT_store <= FIFO_RD_DOUT;
	 end if;
	 CUR_STATE <= "0011";
	  fifo_read_state 		<= preLowRd;

  When preLowRd =>
	 FIFO_RD_CLK <= '1';
	 CUR_STATE <= "0100";
	  fifo_read_state 		<= LowRd;

	When LowRd =>
	 FIFO_RD_CLK <= '0';
	 CUR_STATE <= "0101";
	  fifo_read_state 		<= IdleRd;
	 
  When Others =>
	 FIFO_RD_EN <= '0';
	 FIFO_RD_CLK <= '0';
	 CUR_STATE <= "0110";
	 fifo_read_state 		<= IdleRd;
	end case;
end if;
end process;

end Behavioral;
