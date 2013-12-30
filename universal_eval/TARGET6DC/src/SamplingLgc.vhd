-------------------------------------------------------------------------------
Library work;
use work.all;
--use work.Target2Package.all;

Library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
--Library synplify;
--use synplify.attributes.all;

entity SamplingLgc is
   port (
			clk		 			    : in   std_logic;
			stop	 			      : in   std_logic;  -- hold operation
			IDLE_status				: out 	std_logic := '1';
			MAIN_CNT_out			: out 	std_logic_vector(10 downto 0);
			sspin_out            : out   std_logic; --SCA control signals
			sstin_out            : out   std_logic; --SCA control signals
			wr_advclk_out        : out   std_logic; --Write Address Increment Clock 
			wr_addrclr_out       : out   std_logic; --Clear Write Address Counter
			wr_strb_out          : out   std_logic; --Pulse to transfer samples to store
			wr_ena_out           : out   std_logic; --Enable Write procedure
			samp_delay				: in  STD_LOGIC_VECTOR (11 downto 0)
	);
end SamplingLgc;

architecture Behavioral of SamplingLgc is

type state_type is
	(
	Idle,				  -- Idling until command start bit
	SampleDelay,
   Sampling0,		-- state 0 of init high processing
	Sampling0a,		-- state 0 of init high processing
   Sampling1,		-- state 1 of init high processing
	Sampling1a,		-- state 1 of init high processing
   Sampling2,		-- state 2 of init high processing
	Sampling2a,		-- state 2 of init high processing
	Sampling3,	  -- state 3 of init high processing
	Sampling3a,	  -- state 3 of init high processing
	Sampling4,	  -- state 4 of init high processing
	Sampling4a,	  -- state 4 of init high processing
	Sampling5,	  -- state 5 of init high processing
	Sampling5a,	  -- state 5 of init high processing
	Sampling6,	  -- state 0 of normal low processing
	Sampling6a,	  -- state 0 of normal low processing
	Sampling7,	  -- state 1 of normal low processing
	Sampling7a,	  -- state 1 of normal low processing
	Sampling8,	  -- state 2 of normal low processing
	Sampling8a,	  -- state 2 of normal low processing
	Sampling9,	  -- state 3 of normal low processing
	Sampling9a,	  -- state 3 of normal low processing
	Sampling10,	  -- state 0 of normal high processing
	Sampling10a,	  -- state 0 of normal high processing
	Sampling11,	  -- state 1 of normal high processing
	Sampling11a,	  -- state 1 of normal high processing
	Sampling12,	  -- state 2 of normal high processing
	Sampling12a,	  -- state 2 of normal high processing
	Sampling13,	  -- state 3 of normal high processing
	Sampling13a,	  -- state 3 of normal high processing
	Sampling14,	  -- state 3 of normal high processing
	Sampling14a,	  -- state 3 of normal high processing
	Sampling15,	  -- state 3 of normal high processing
	Sampling15a,	  -- state 3 of normal high processing
	Sampling16,	  -- state 3 of normal high processing
	Sampling16a,	  -- state 3 of normal high processing
	Sampling17,	  -- state 3 of normal high processing
	Sampling17a,	  -- state 3 of normal high processing
	Sampling18
	);

	signal next_state		: state_type := Idle;
	signal MAIN_CNT		: std_logic_vector(10 downto 0) := "00000000000";
	
	--output connecting signals
	signal sspin     : std_logic := '0'; --SCA control signals
	signal sstin     : std_logic := '0'; --SCA control signals
	signal wr_advclk : std_logic := '0'; --Write Address Increment Clock 
	signal wr_addrclr : std_logic := '1'; --Clear Write Address Counter
	signal wr_strb   : std_logic := '0'; --Pulse to transfer samples to store
	signal wr_ena    : std_logic := '0'; --Enable Write procedure

	signal stop_in : std_logic := '0';
	signal count : std_logic_vector(11 downto 0) := x"000";
--------------------------------------------------------------------------------
begin

--usual sampling signals
--MAIN_CNT_out <= MAIN_CNT; --output full counter
MAIN_CNT_out <= "00" & MAIN_CNT(10 downto 2); --output only row + colum sections
sspin_out <= sspin;
sstin_out <= sstin;
wr_advclk_out <= wr_advclk;
wr_addrclr_out <= wr_addrclr;
wr_strb_out <= wr_strb;
wr_ena_out <= wr_ena;

--latch stop to local clock domain
process(clk)
begin
if (clk'event and clk = '1') then
	stop_in <= stop;
end if;
end process;

--process(Clk,rst)
process(Clk)
begin
--if (rst = '1') then
-- IDLE_status <= '1';
--  TestTrig <= '0';
--  MAIN_CNT <= (Others => '0');
--  sspin             <= '0';
--  sstin             <= '0';
--  wr_advclk         <= '0';
--  wr_addrclr        <= '1';
--  wr_strb           <= '0';
--  wr_ena            <= '0';
--  count <= (Others => '0');
 -- next_state <= Idle;
if (Clk'event and Clk = '1') then
  Case next_state is
  
  When Idle =>
    IDLE_status <= '1';
    sspin          <= '0';
    sstin          <= '0';
    wr_advclk      <= '0';    
    wr_strb        <= '0';
	 count <= (Others => '0');
    if ( stop_in = '1') then   --begin single shot readout
	 --if ( stop_in = '1' OR stop_in = '0') then   --begin single shot readout
		MAIN_CNT <= (Others => '0');
		wr_addrclr        <= '0';
		wr_ena            <= '1';
      --next_state 	<= SampleDelay;
		next_state 	<= Sampling0;
    else
		MAIN_CNT <= MAIN_CNT;
		wr_addrclr        <= '1';
		wr_ena            <= '0';
      next_state 	<= Idle;
    end if;
	 
  When SampleDelay =>
   if( count(11 downto 0) < samp_delay(11 downto 0) ) then 
		count <= count + 1;
		next_state <= SampleDelay;
	else
		next_state <= Sampling0;
	end if;
	 
  When Sampling0 =>
	 IDLE_status <= '0';
    MAIN_CNT <= MAIN_CNT;
    sspin             <= '1';
    sstin             <= '0';
    wr_advclk         <= '0';
    wr_addrclr        <= '0';
    wr_strb           <= '0';
    wr_ena            <= '1';
      next_state 	<= Sampling0a;
		--next_state 	<= Sampling2;

  When Sampling0a =>
	 IDLE_status <= '0';
    MAIN_CNT <= MAIN_CNT;
    sspin             <= '1';
    sstin             <= '0';
    wr_advclk         <= '0';
    wr_addrclr        <= '0';
    wr_strb           <= '0';
    wr_ena            <= '1';
      next_state 	<= Sampling1;

  When Sampling1 =>
    MAIN_CNT <= MAIN_CNT;
    sspin         <= '1';
    sstin             <= '0';
    wr_advclk         <= '0';
    wr_addrclr        <= '0';
    wr_strb        <= '0';
    wr_ena            <= '1';
      next_state 	<= Sampling1a;

  When Sampling1a =>
    MAIN_CNT <= MAIN_CNT;
    sspin         <= '1';
    sstin             <= '0';
    wr_advclk         <= '0';
    wr_addrclr        <= '0';
    wr_strb        <= '0';
    wr_ena            <= '1';
      next_state 	<= Sampling2;

  When Sampling2 =>   
    MAIN_CNT <= MAIN_CNT ;
    sspin             <= '1';
    sstin             <= '1';
    wr_advclk         <= '0';
    wr_addrclr        <= '0';
    wr_strb           <= '0';
    wr_ena            <= '1';
      next_state 	<= Sampling2a;
		--next_state 	<= Sampling4;

  When Sampling2a =>   
    MAIN_CNT <= MAIN_CNT ;
    sspin             <= '1';
    sstin             <= '1';
    wr_advclk         <= '0';
    wr_addrclr        <= '0';
    wr_strb           <= '0';
    wr_ena            <= '1';
      next_state 	<= Sampling3;		

  When Sampling3 =>
    MAIN_CNT <= MAIN_CNT;
    sspin             <= '1';
    sstin             <= '1';
    wr_advclk         <= '0';
    wr_addrclr        <= '0';
    wr_strb           <= '0';
    wr_ena            <= '1';
      next_state 	<= Sampling3a;
		
  When Sampling3a =>
    MAIN_CNT <= MAIN_CNT;
    sspin             <= '1';
    sstin             <= '1';
    wr_advclk         <= '0';
    wr_addrclr        <= '0';
    wr_strb           <= '0';
    wr_ena            <= '1';
      next_state 	<= Sampling4;		

  When Sampling4 =>
    MAIN_CNT <= MAIN_CNT ;
    sspin             <= '0';
    sstin             <= '1';
    wr_advclk         <= '0';
    wr_addrclr        <= '0';
    wr_strb           <= '0';
    wr_ena            <= '1';
      next_state 	<= Sampling4a;
		--next_state 	<= Sampling6;
	
  When Sampling4a =>
    MAIN_CNT <= MAIN_CNT ;
    sspin             <= '0';
    sstin             <= '1';
    wr_advclk         <= '0';
    wr_addrclr        <= '0';
    wr_strb           <= '0';
    wr_ena            <= '1';
      next_state 	<= Sampling5;	

  When Sampling5 =>
    MAIN_CNT <= MAIN_CNT;
    sspin             <= '0';
    sstin             <= '1';
    wr_advclk         <= '0';
    wr_addrclr        <= '0';
    wr_strb           <= '0';
    wr_ena            <= '1';
      next_state 	<= Sampling5a;
		
  When Sampling5a =>
    MAIN_CNT <= MAIN_CNT;
    sspin             <= '0';
    sstin             <= '1';
    wr_advclk         <= '0';
    wr_addrclr        <= '0';
    wr_strb           <= '0';
    wr_ena            <= '1';
      next_state 	<= Sampling6;		
  
  --start of regular sampling sequence	
  When Sampling6 => 
    MAIN_CNT <= MAIN_CNT + '1';
    sspin             <= '0';
    sstin             <= '0';
    wr_advclk         <= '0';
    wr_addrclr        <= '0';
    wr_strb           <= '1';
    wr_ena            <= '1';
      next_state 	<= Sampling6a;
		--next_state 	<= Sampling8;
		
  When Sampling6a => 
    MAIN_CNT <= MAIN_CNT + '1';
    sspin             <= '0';
    sstin             <= '0';
    wr_advclk         <= '0';
    wr_addrclr        <= '0';
    wr_strb           <= '1';
    wr_ena            <= '1';
      next_state 	<= Sampling7;

  When Sampling7 =>
    MAIN_CNT <= MAIN_CNT + '1';
    sspin             <= '0';
    sstin             <= '0';
    wr_advclk         <= '0';
    wr_addrclr        <= '0';
    wr_strb           <= '1';
    wr_ena            <= '1';
      next_state 	<= Sampling7a;
		
  When Sampling7a =>
    MAIN_CNT <= MAIN_CNT + '1';
    sspin             <= '0';
    sstin             <= '0';
    wr_advclk         <= '0';
    wr_addrclr        <= '0';
    wr_strb           <= '1';
    wr_ena            <= '1';
      next_state 	<= Sampling8;

  When Sampling8 =>
    MAIN_CNT <= MAIN_CNT + '1';
    sspin             <= '0';
    sstin             <= '0';
    wr_advclk         <= '1';
    wr_addrclr        <= '0';
    wr_strb           <= '0';
    wr_ena            <= '1';
      next_state 	<= Sampling8a;
		--next_state 	<= Sampling10;
		
  When Sampling8a =>
    MAIN_CNT <= MAIN_CNT + '1';
    sspin             <= '0';
    sstin             <= '0';
    wr_advclk         <= '1';
    wr_addrclr        <= '0';
    wr_strb           <= '0';
    wr_ena            <= '1';
      next_state 	<= Sampling9;

  When Sampling9 =>
    MAIN_CNT <= MAIN_CNT + '1';
    sspin             <= '0';
    sstin             <= '0';
    wr_advclk         <= '1';
    wr_addrclr        <= '0';
    wr_strb           <= '0';
    wr_ena            <= '1';
      next_state 	<= Sampling9a;

  When Sampling9a =>
    MAIN_CNT <= MAIN_CNT + '1';
    sspin             <= '0';
    sstin             <= '0';
    wr_advclk         <= '1';
    wr_addrclr        <= '0';
    wr_strb           <= '0';
    wr_ena            <= '1';
      next_state 	<= Sampling10;

  When Sampling10 =>   -- sstin high for 32 ns,sspin_i0 stay for 32ns high
    MAIN_CNT <= MAIN_CNT + '1';
    sspin             <= '0';
    sstin             <= '0';
    wr_advclk         <= '0';
    wr_addrclr        <= '0';
    wr_strb           <= '1';
    wr_ena            <= '1';
      next_state 	<= Sampling10a;
		--next_state 	<= Sampling12;
		
  When Sampling10a =>   -- sstin high for 32 ns,sspin_i0 stay for 32ns high
    MAIN_CNT <= MAIN_CNT + '1';
    sspin             <= '0';
    sstin             <= '0';
    wr_advclk         <= '0';
    wr_addrclr        <= '0';
    wr_strb           <= '1';
    wr_ena            <= '1';
      next_state 	<= Sampling11;
		
  When Sampling11 =>   -- sstin high for 32 ns,sspin_i0 stay for 32ns high
    MAIN_CNT <= MAIN_CNT + '1';
    sspin             <= '0';
    sstin             <= '0';
    wr_advclk         <= '0';
    wr_addrclr        <= '0';
    wr_strb           <= '1';
    wr_ena            <= '1';
      next_state 	<= Sampling11a;
		
  When Sampling11a =>   -- sstin high for 32 ns,sspin_i0 stay for 32ns high
    MAIN_CNT <= MAIN_CNT + '1';
    sspin             <= '0';
    sstin             <= '0';
    wr_advclk         <= '0';
    wr_addrclr        <= '0';
    wr_strb           <= '1';
    wr_ena            <= '1';
      next_state 	<= Sampling12;

  When Sampling12 =>   -- sstin high for 32 ns,sspin_i0 stay for 32ns high
    MAIN_CNT <= MAIN_CNT + '1';
    sspin             <= '0';
    sstin             <= '0';
    wr_advclk         <= '1';
    wr_addrclr        <= '0';
    wr_strb           <= '0';
    wr_ena            <= '1';
      next_state 	<= Sampling12a;
		--next_state 	<= Sampling14;
		
  When Sampling12a =>   -- sstin high for 32 ns,sspin_i0 stay for 32ns high
    MAIN_CNT <= MAIN_CNT + '1';
    sspin             <= '0';
    sstin             <= '0';
    wr_advclk         <= '1';
    wr_addrclr        <= '0';
    wr_strb           <= '0';
    wr_ena            <= '1';
      next_state 	<= Sampling13;

  When Sampling13 =>   -- sstin high for 32 ns,sspin_i0 stay for 32ns high
    MAIN_CNT <= MAIN_CNT + '1';
    sspin             <= '0';
    sstin             <= '0';
    wr_advclk         <= '1';
    wr_addrclr        <= '0';
    wr_strb           <= '0';
    wr_ena            <= '1';
      next_state 	<= Sampling13a;
		
  When Sampling13a =>   -- sstin high for 32 ns,sspin_i0 stay for 32ns high
    MAIN_CNT <= MAIN_CNT + '1';
    sspin             <= '0';
    sstin             <= '0';
    wr_advclk         <= '1';
    wr_addrclr        <= '0';
    wr_strb           <= '0';
    wr_ena            <= '1';
      next_state 	<= Sampling14;		
		
  When Sampling14 =>   -- sstin high for 32 ns,sspin_i0 stay for 32ns high
    MAIN_CNT <= MAIN_CNT + '1';
    sspin             <= '0';
    sstin             <= '0';
    wr_advclk         <= '0';
    wr_addrclr        <= '0';
    wr_strb           <= '0';
    wr_ena            <= '1';
      next_state 	<= Sampling14a;
		--next_state 	<= Sampling16;
		
  When Sampling14a =>   -- sstin high for 32 ns,sspin_i0 stay for 32ns high
    MAIN_CNT <= MAIN_CNT + '1';
    sspin             <= '0';
    sstin             <= '0';
    wr_advclk         <= '0';
    wr_addrclr        <= '0';
    wr_strb           <= '0';
    wr_ena            <= '1';
      next_state 	<= Sampling15;

  When Sampling15 =>   -- sstin high for 32 ns,sspin_i0 stay for 32ns high
    MAIN_CNT <= MAIN_CNT + '1';
    sspin             <= '0';
    sstin             <= '0';
    wr_advclk         <= '0';
    wr_addrclr        <= '0';
    wr_strb           <= '0';
    wr_ena            <= '1';
      next_state 	<= Sampling15a;
		
  When Sampling15a =>   -- sstin high for 32 ns,sspin_i0 stay for 32ns high
    MAIN_CNT <= MAIN_CNT + '1';
    sspin             <= '0';
    sstin             <= '0';
    wr_advclk         <= '0';
    wr_addrclr        <= '0';
    wr_strb           <= '0';
    wr_ena            <= '1';
      next_state 	<= Sampling16;

  When Sampling16 =>   -- sstin high for 32 ns,sspin_i0 stay for 32ns high
    MAIN_CNT <= MAIN_CNT + '1';
    sspin             <= '0';
    sstin             <= '0';
    wr_advclk         <= '0';
    wr_addrclr        <= '0';
    wr_strb           <= '0';
    wr_ena            <= '1';
      next_state 	<= Sampling16a;
		--next_state 	<= Sampling18;
		
  When Sampling16a =>   -- sstin high for 32 ns,sspin_i0 stay for 32ns high
    MAIN_CNT <= MAIN_CNT + '1';
    sspin             <= '0';
    sstin             <= '0';
    wr_advclk         <= '0';
    wr_addrclr        <= '0';
    wr_strb           <= '0';
    wr_ena            <= '1';
      next_state 	<= Sampling17;

  When Sampling17 =>   -- sstin high for 32 ns,sspin_i0 stay for 32ns high
    MAIN_CNT <= MAIN_CNT + '1';
    sspin             <= '0';
    sstin             <= '0';
    wr_advclk         <= '0';
    wr_addrclr        <= '0';
    wr_strb           <= '0';
    wr_ena            <= '1';
      next_state 	<= Sampling17a;
		
  When Sampling17a =>   -- sstin high for 32 ns,sspin_i0 stay for 32ns high
    MAIN_CNT <= MAIN_CNT + '1';
    sspin             <= '0';
    sstin             <= '0';
    wr_advclk         <= '0';
    wr_addrclr        <= '0';
    wr_strb           <= '0';
    wr_ena            <= '1';
      next_state 	<= Sampling18;

  When Sampling18 =>
    MAIN_CNT <= MAIN_CNT + '1';
    sspin             <= '0';
    sstin             <= '0';
    wr_advclk         <= '0';
    wr_addrclr        <= '1';
	 wr_strb           <= '0';
    wr_ena            <= '0';
    if (stop_in = '0') then   --singleshot mode - go back to IDLE after readout done
      next_state 	<= Idle;
    else
      next_state 	<= Sampling18;
    end if;
		 
  When Others =>
  MAIN_CNT <= (Others => '0');
  sspin             <= '0';
  sstin             <= '0';
  wr_advclk         <= '0';
  wr_addrclr        <= '1';
  wr_strb           <= '0';
  wr_ena            <= '0';
	next_state <= Idle;
  end Case;
end if;
end process;

end Behavioral;