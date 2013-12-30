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
-- 09/2012: Modified by BK
-------------------------------------------------------------------------------
Library work;
use work.all;
--use work.Target2Package.all;

Library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
--Library synplify;
--use synplify.attributes.all;


entity SerialDataRout is
   port (
        clk		 			     : in   std_logic;
        rst 			       : in   std_logic;
        StartSROut	 		 : in   std_logic;  -- capture trigger data

        SAMP_DONE	       : out std_logic;  -- indicate that all sampled processed

        dout              : in   std_logic_vector(15 downto 0);
        sr_clr           : out   std_logic;     -- Unused set to 0
        sr_clk           : out   std_logic;     -- start slow at 125/2=62.5MHz
        sr_sel           : out   std_logic;     -- 1 -latch data, 0 - shift
		  samplesel 	 : in    STD_LOGIC_VECTOR(5 downto 0);
        smplsi_any       : out   std_logic;     -- off during conversion
		  
		  FIFO_WR_EN		 :out std_logic;
		  FIFO_WR_CLK		 :out std_logic;
		  FIFO_WR_DIN		 :out std_logic_vector(31 downto 0);
		  
		  CHAN_DATA			 : in 	std_logic_vector(15 downto 0);
		  rd_cs_s          : in   std_logic_vector(5 downto 0);
        rd_rs_s          : in   std_logic_vector(2 downto 0);
		  
		  MON					 : out 	std_logic_vector(15 downto 0);
		  CUR_STATE			: out   std_logic_vector( 3 downto 0)
       );
end SerialDataRout;

architecture Behavioral of SerialDataRout is
	
	--time samplesel_any is held high
	constant ADDR_TIME : std_logic_vector(4 downto 0) := "00001";
	constant LOAD_TIME : std_logic_vector(4 downto 0) := "00001";
	constant LOAD_TIME1 : std_logic_vector(4 downto 0) := "00001";
	--constant CLK_CNT_MAX : std_logic_vector(3 downto 0) := "1100"; -- 12 clk -> 12 bits
	--constant CLK_CNT_MAX : std_logic_vector(4 downto 0) := "01100"; -- (11+1)->12 clk -> 12 bits
	constant CLK_CNT_MAX : std_logic_vector(4 downto 0) := "01100"; -- (11+1)->12 clk -> 12 bits


	type sr_state_type is
	(
	Idle,				  -- Idling until command start bit and store size	
	CheckType,
	WaitAddr,	    -- Wait for address to settle, need docs to finilize
	WaitLoad,	    -- Wait for load cmd to settle, need docs to finilize
	WaitLoad1,	    -- Wait for load cmd to settle relatively to clk, need docs to finilize
	clkHigh,	    -- Clock high, now at 62.5 MHz ,can investigate later at higher speed
	clkLow,	      -- Clock low, now at 62.5 MHz ,can investigate later at higher speed
	StoreDataSt,	  -- Store shifted in data
	WaitTrig
	);
	signal next_state					: sr_state_type;

	type fifo_state_type is
	(
	Idle,		
	StartFifo,
	preHigh,
	High,
	preLow,
	Low,
	WaitDone
	);
	signal fifo_state					: fifo_state_type;	
	
	Type SftReg_array is array(15 downto 0) of std_logic_vector(11 downto 0);
	signal     SftReg  	          : SftReg_array;

	signal     sr_clk_i  	     : std_logic;
	signal     Ev_CNT     	   : std_logic_vector(4 downto 0);
	signal     sr_clk_d        : std_logic;
	signal     EventCnt        : std_logic_vector(7 downto 0);
	signal	start_fifo	:	STD_LOGIC;
	signal	FifoDone		:	STD_LOGIC;
	signal	FifoCount	:	STD_LOGIC_VECTOR(7 downto 0);
	signal	SAMP_DONE_out : STD_LOGIC;

--------------------------------------------------------------------------------

begin

MON <= "0000" & SftReg(3)(11 downto 0);
sr_clk <= sr_clk_i;
SAMP_DONE <= SAMP_DONE_out;

--read and store samples from Dout (16 channels)
k2: FOR i IN 0 TO 15 GENERATE
process (clk, rst) is
begin
if (rst = '1') then
  SftReg(i)  <= (Others => '0');
elsif (clk'event and clk = '1') then
  if (sr_clk_d = '1') then
    SftReg(i) <= SftReg(i)(10 downto 0) &  Dout(i);
	 --SftReg(i) <= SftReg(i)(10 downto 0) &  '1'; --TEST
  end if;
end if;
end process;
end GENERATE k2;

--delay by one clock for proper latch
process (clk, rst) is
begin
if (rst = '1') then
  sr_clk_d <= '0';
elsif (clk'event and clk = '1') then
  sr_clk_d <= sr_clk_i;       
end if;
end process;

process(Clk,rst)
begin
if (rst = '1') then
    sr_clr            <= '0';
    sr_clk_i  	       <= '0';
    sr_sel  	       <= '0';
    smplsi_any       <= '0';
    Ev_CNT           <= (others=>'0');
	 start_fifo			<= '0';
    SAMP_DONE_out        <= '0';
	 CUR_STATE			<= "0000";
	 next_state <= Idle;
elsif (Clk'event and Clk = '1') then
  sr_clr            <= '0'; --doesn't do anything
  Case next_state is
  
  When Idle =>
    sr_clk_i  	       <= '0';
    sr_sel  	       <= '0';
	 start_fifo			<= '0';
    SAMP_DONE_out    <= '0';
    Ev_CNT           <= (others=>'0');
	 CUR_STATE			<= "0001";
	 smplsi_any       <= '0';
    if( StartSROut = '1') then   -- start (readout initiated)
      next_state 		  <= CheckType;
    else
      next_state 		<= Idle;
    end if;
	 
  When CheckType => 
	 sr_clk_i  	       <= '0';
    sr_sel  	       <= '0';
	 start_fifo			<= '0';
    SAMP_DONE_out    <= '0';
    Ev_CNT           <= (others=>'0');
	 CUR_STATE			<= "0001";
	 smplsi_any       <= '0';
	 if( samplesel = "100000" ) then
		smplsi_any       <= '0';
		next_state 		  <= StoreDataSt;
	 else
		smplsi_any       <= '1';
		next_state 		  <= WaitAddr;
	 end if;

	--turn smplsi_any on, wait to settle
   When WaitAddr =>
    sr_clk_i  	       <= '0';
    sr_sel  	       <= '0';
    smplsi_any       <= '1';
	 start_fifo			<= '0';
    SAMP_DONE_out        <= '0';
	 CUR_STATE			<= "0011";
    if (Ev_CNT < ADDR_TIME) then   -- start (trigger was detected)
      Ev_CNT <= Ev_CNT + '1';
      next_state 	<= WaitAddr;
    else
      Ev_CNT           <= (others=>'0');
      next_state 	<= WaitLoad;
    end if;

	--turn sr_sel on, wait to settle
   When WaitLoad =>
	 sr_sel  	       <= '1';
    smplsi_any       <= '1';
	 start_fifo			<= '0';
    SAMP_DONE_out        <= '0';
	 CUR_STATE			<= "0100";
    if (Ev_CNT < LOAD_TIME) then
      Ev_CNT <= Ev_CNT + '1';
		sr_clk_i  	       <= '0';
      next_state 	<= WaitLoad;
    else
      Ev_CNT           <= (others=>'0');
		sr_clk_i  	       <= '1';
      next_state 	<= WaitLoad1;
    end if;

	--turn sr_clk_i on, wait to settle
	--turn off sr_sel and sr_clk_i on transition
   When WaitLoad1 =>
    smplsi_any       <= '1';
	 start_fifo			<= '0';
    SAMP_DONE_out        <= '0';
	 CUR_STATE			<= "0101";
    if (Ev_CNT < LOAD_TIME1) then
      Ev_CNT <= Ev_CNT + '1';
      sr_sel  	       <= '1';
		sr_clk_i  	       <= '1';
      next_state 	<= WaitLoad1;
    else
      Ev_CNT           <= (others=>'0');
      sr_sel  	       <= '0';
		sr_clk_i  	       <= '0';
      next_state 	<= ClkHigh;
    end if;
	
	--hold sr_clk_i high
   When ClkHigh =>
    sr_sel  	       <= '0';
    smplsi_any       <= '1';
    Ev_CNT <= Ev_CNT + '1';
	 start_fifo			<= '0';
    SAMP_DONE_out        <= '0';
	 CUR_STATE			<= "0110";
    if (Ev_CNT < CLK_CNT_MAX) then
      sr_clk_i  	       <= '1';
      next_state 	<= ClkLow;
    else
      sr_clk_i  	       <= '0';
      next_state 	<= StoreDataSt;
    end if;

	--hold sr_clk_i low
   When ClkLow =>
    sr_sel  	       <= '0';
    smplsi_any       <= '1';
    Ev_CNT <= Ev_CNT;
    sr_clk_i  	       <= '0';
	 start_fifo			<= '0';
    SAMP_DONE_out        <= '0';
      next_state 	<= ClkHigh;

	--Start FIFO write process, wait for DONE signal
   When StoreDataSt =>
    sr_clk_i  	       <= '0';
    sr_sel  	       <= '0';
    smplsi_any       <= '0';
	 start_fifo			<= '1';
    SAMP_DONE_out        <= '0';
	 CUR_STATE			<= "0111";
	 if( FifoDone = '1' ) then
      next_state 		<= WaitTrig;
	 else
		next_state 	<= StoreDataSt;
	 end if;

	--wait for start signal to go low
   When WaitTrig =>
    sr_clk_i  	       <= '0';
    sr_sel  	       <= '0';
    smplsi_any       <= '0';
	 start_fifo			<= '0';
    SAMP_DONE_out        <= '1';
	 CUR_STATE			<= "1000";
	 if( StartSROut = '0' ) then
      next_state 		<= Idle;
	 else
		next_state 	<= WaitTrig;
	 end if;
	 
  When Others =>
    sr_clk_i  	       <= '0';
    sr_sel  	       <= '0';
    smplsi_any       <= '0';
    Ev_CNT           <= (others=>'0');
	 start_fifo			<= '0';
    SAMP_DONE_out        <= '0';
	 next_state 		<= Idle;
	end case;
end if;
end process;

--FIFO process
process(Clk,rst)
begin
if (rst = '1') then
	FifoDone	<= '0';
	FIFO_WR_EN <= '0';
	FIFO_WR_CLK <= '0';
	FIFO_WR_DIN <= (others=>'0');
	FifoCount <= (others=>'0');
	fifo_state <= Idle;
elsif (Clk'event and Clk = '1') then
  Case fifo_state is
  
  When Idle =>
	 FifoDone <= '0';
	 FIFO_WR_EN <= '0';
	 FIFO_WR_CLK <= '0';
	 FIFO_WR_DIN <= (others=>'0');
	 FifoCount <= (others=>'0');
    if( start_fifo = '1') then   -- start (ramping is detected)
      fifo_state <= StartFifo;
    else
      fifo_state <= Idle;
    end if;
   
  When StartFifo =>
	 FifoDone <= '0';
	 FIFO_WR_EN <= '1';
	 FIFO_WR_CLK <= '0';
	 FIFO_WR_DIN <= (others=>'0');
	 FifoCount <= "00000011";
	 fifo_state <= preHigh;
	 --FifoCount <= FifoCount;
	 --if( FifoCount < "00001000" ) then
	 -- fifo_state <= preHigh;
	 --else
	 -- fifo_state <= WaitDone;	
	 --end if;

  When preHigh => --load DIN here if latched on leading edge
	 FifoDone <= '0';
	 FIFO_WR_EN <= '1';
	 FIFO_WR_CLK <= '0';

	 if( CHAN_DATA(3 downto 0) = "0000" ) then
		FIFO_WR_DIN <= samplesel(3 downto 0) & SftReg(0) & "10" & CHAN_DATA(3 downto 0 ) & rd_cs_s( 5 downto 0) & rd_rs_s(2 downto 0) & samplesel(4);
	 elsif( CHAN_DATA(3 downto 0) = "0001" ) then
		FIFO_WR_DIN <= samplesel(3 downto 0) & SftReg(1) & "10" & CHAN_DATA(3 downto 0 ) & rd_cs_s( 5 downto 0) & rd_rs_s(2 downto 0) & samplesel(4);
	 elsif( CHAN_DATA(3 downto 0) = "0010" ) then 
	 	FIFO_WR_DIN <= samplesel(3 downto 0) & SftReg(2) & "10" & CHAN_DATA(3 downto 0 ) & rd_cs_s( 5 downto 0) & rd_rs_s(2 downto 0) & samplesel(4);
	 elsif( CHAN_DATA(3 downto 0) = "0011" ) then 
	 	FIFO_WR_DIN <= samplesel(3 downto 0) & SftReg(3) & "10" & CHAN_DATA(3 downto 0 ) & rd_cs_s( 5 downto 0) & rd_rs_s(2 downto 0) & samplesel(4);
	 elsif( CHAN_DATA(3 downto 0) = "0100" ) then 
	 	FIFO_WR_DIN <= samplesel(3 downto 0) & SftReg(4) & "10" & CHAN_DATA(3 downto 0 ) & rd_cs_s( 5 downto 0) & rd_rs_s(2 downto 0) & samplesel(4);
	 elsif( CHAN_DATA(3 downto 0) = "0101" ) then 
	 	FIFO_WR_DIN <= samplesel(3 downto 0) & SftReg(5) & "10" & CHAN_DATA(3 downto 0 ) & rd_cs_s( 5 downto 0) & rd_rs_s(2 downto 0) & samplesel(4);
	 elsif( CHAN_DATA(3 downto 0) = "0110" ) then 
	 	FIFO_WR_DIN <= samplesel(3 downto 0) & SftReg(6) & "10" & CHAN_DATA(3 downto 0 ) & rd_cs_s( 5 downto 0) & rd_rs_s(2 downto 0) & samplesel(4);
	 elsif( CHAN_DATA(3 downto 0) = "0111" ) then 
	 	FIFO_WR_DIN <= samplesel(3 downto 0) & SftReg(7) & "10" & CHAN_DATA(3 downto 0 ) & rd_cs_s( 5 downto 0) & rd_rs_s(2 downto 0) & samplesel(4);
	 elsif( CHAN_DATA(3 downto 0) = "1000" ) then 
	 	FIFO_WR_DIN <= samplesel(3 downto 0) & SftReg(8) & "10" & CHAN_DATA(3 downto 0 ) & rd_cs_s( 5 downto 0) & rd_rs_s(2 downto 0) & samplesel(4);
	 elsif( CHAN_DATA(3 downto 0) = "1001" ) then 
	 	FIFO_WR_DIN <= samplesel(3 downto 0) & SftReg(9) & "10" & CHAN_DATA(3 downto 0 ) & rd_cs_s( 5 downto 0) & rd_rs_s(2 downto 0) & samplesel(4);
	 elsif( CHAN_DATA(3 downto 0) = "1010" ) then 
	 	FIFO_WR_DIN <= samplesel(3 downto 0) & SftReg(10) & "10" & CHAN_DATA(3 downto 0 ) & rd_cs_s( 5 downto 0) & rd_rs_s(2 downto 0) & samplesel(4);
	 elsif( CHAN_DATA(3 downto 0) = "1011" ) then 
	 	FIFO_WR_DIN <= samplesel(3 downto 0) & SftReg(11) & "10" & CHAN_DATA(3 downto 0 ) & rd_cs_s( 5 downto 0) & rd_rs_s(2 downto 0) & samplesel(4);
	 elsif( CHAN_DATA(3 downto 0) = "1100" ) then 
	 	FIFO_WR_DIN <= samplesel(3 downto 0) & SftReg(12) & "10" & CHAN_DATA(3 downto 0 ) & rd_cs_s( 5 downto 0) & rd_rs_s(2 downto 0) & samplesel(4);
	 elsif( CHAN_DATA(3 downto 0) = "1101" ) then 
	 	FIFO_WR_DIN <= samplesel(3 downto 0) & SftReg(13) & "10" & CHAN_DATA(3 downto 0 ) & rd_cs_s( 5 downto 0) & rd_rs_s(2 downto 0) & samplesel(4);
	 elsif( CHAN_DATA(3 downto 0) = "1110" ) then 
	 	FIFO_WR_DIN <= samplesel(3 downto 0) & SftReg(14) & "10" & CHAN_DATA(3 downto 0 ) & rd_cs_s( 5 downto 0) & rd_rs_s(2 downto 0) & samplesel(4);
	 elsif( CHAN_DATA(3 downto 0) = "1111" ) then 
	 	FIFO_WR_DIN <= samplesel(3 downto 0) & SftReg(15) & "10" & CHAN_DATA(3 downto 0 ) & rd_cs_s( 5 downto 0) & rd_rs_s(2 downto 0) & samplesel(4);
	 else
	 	FIFO_WR_DIN <= samplesel(3 downto 0) & SftReg(0) & "10" & CHAN_DATA(3 downto 0 ) & rd_cs_s( 5 downto 0) & rd_rs_s(2 downto 0) & samplesel(4);
	 end if;
	 FifoCount <= FifoCount;
	  fifo_state 		<= High;

  When High =>
	 FifoDone <= '0';
	 FIFO_WR_EN <= '1';
	 FIFO_WR_CLK <= '1';
	 FifoCount <= FifoCount;
	  fifo_state 		<= preLow;

  When preLow => --load DIN here if latched on falling edge
	 FifoDone <= '0';
	 FIFO_WR_EN <= '1';
	 FIFO_WR_CLK <= '1';
	 FifoCount <= FifoCount;
	  fifo_state 		<= Low;

	When Low =>
	 FifoDone <= '0';
	 FIFO_WR_EN <= '1';
	 FIFO_WR_CLK <= '0';
	 FifoCount <= FifoCount + "00000001"; --increment count here
	  fifo_state 		<= WaitDone;
	  --fifo_state 		<= StartFifo;
	  
	When WaitDone =>
	 FifoDone <= '1';
	 FIFO_WR_EN <= '0';
	 FIFO_WR_CLK <= '0';
	 FIFO_WR_DIN <= (others=>'0');
	 FifoCount <= (others=>'0');
	 if( SAMP_DONE_out = '1' ) then
      fifo_state 		<= Idle;
	 else
		fifo_state 	<= WaitDone;
	 end if;
	 
  When Others =>
    FifoDone <= '0';
	 FIFO_WR_EN <= '0';
	 FIFO_WR_CLK <= '0';
	 FIFO_WR_DIN <= (others=>'0');
	 FifoCount <= (others=>'0');
	 fifo_state 		<= Idle;
	end case;
end if;
end process;

end Behavioral;
