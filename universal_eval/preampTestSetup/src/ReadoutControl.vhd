----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:19:35 10/20/2012 
-- Design Name: 
-- Module Name:    ReadoutControl - Behavioral 
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

Library work;
use work.all;
--use work.Target2Package.all;

Library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
--Library synplify;
--use synplify.attributes.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ReadoutControl is
    Port ( clk : in  STD_LOGIC;
           rst : in  STD_LOGIC;
           trigger : in  STD_LOGIC;
			  read_req : in  STD_LOGIC;
           ramp_done : in  STD_LOGIC;
           samp_done : in  STD_LOGIC;
           fifo_full : in  STD_LOGIC;
			  trig_delay : in  STD_LOGIC_VECTOR(11 downto 0);
			  --TRIG_DATA			 : in 	std_logic_vector(15 downto 0);
			  CHAN_DATA			 : in 	std_logic_vector(15 downto 0);
           stop_smp : out  STD_LOGIC;
           start_dig : out  STD_LOGIC;
           start_srout : out  STD_LOGIC;
           samplesel : out  STD_LOGIC_VECTOR(5 downto 0)
	  );
end ReadoutControl;

architecture Behavioral of ReadoutControl is

type trig_state_type is
	(
	Idle,
	DELAY,
	WAIT_DONE
	);
signal next_trig_state	: trig_state_type;

type read_state_type is
	(
	Idle,
	DELAY,
	DIG,
	SROUT_LOOP,
	SROUT,
	SROUT_WAIT,
	WAIT_DONE
	);
signal next_read_state	: read_state_type;

signal count_trig  : STD_LOGIC_VECTOR(11 downto 0);
signal count_read : STD_LOGIC_VECTOR(11 downto 0);
--signal trig_delay : STD_LOGIC_VECTOR(11 downto 0);

begin

--process governing trigger + sampling, stop_smp signal
process(clk,rst)
begin
if (rst = '1') then
	count_trig <= (Others => '0');
	stop_smp <= '0';
	next_trig_state <= Idle;
elsif (clk'event and clk = '1') then
	Case next_trig_state is
	
	--detect trigger word
	When Idle =>
	count_trig <= (Others => '0');
	stop_smp <= '0';
	if( trigger = '1' ) then 
		next_trig_state <= DELAY;
	else
		next_trig_state <= Idle;
	end if;
	
	--optionally delay sampling stop
	When DELAY =>
	if( count_trig < trig_delay ) then 
		count_trig <= count_trig + 1;
		stop_smp <= '1'; --should be 0, can be 1 in test mode
		next_trig_state <= DELAY;
	else
		stop_smp <= '1'; --should be 1, stop sampling after delay
		count_trig <= (Others => '0');
		next_trig_state <= WAIT_DONE;
	end if;
	
	--wait until sampling unsuspended
	When WAIT_DONE =>
	count_trig <= (Others => '0');
	stop_smp <= '1';
	if( trigger = '0' ) then 
		next_trig_state <= Idle;
	else
		next_trig_state <= WAIT_DONE;
	end if;
	
	When Others =>
	count_trig <= (Others => '0');
	stop_smp <= '0';
	next_trig_state <= Idle;
	end Case;
	
end if;
end process;

--process governing sample readout
process(clk,rst)
begin
if (rst = '1') then
	count_read <= (Others => '0');
	start_dig <= '0';
	start_srout <= '0';
	samplesel <= (Others => '0');
	next_read_state <= Idle;
elsif (clk'event and clk = '1') then
	Case next_read_state is
	
	When Idle =>
	count_read <= (Others => '0');
	start_dig <= '0';
	start_srout <= '0';
	samplesel <= (Others => '0');
	if( read_req = '1' ) then 
		next_read_state <= DELAY;
	else
		next_read_state <= Idle;
	end if;
	
	When DELAY =>
	start_dig <= '0';
	start_srout <= '0';
	if( count_read < trig_delay ) then 
		count_read <= count_read + 1;
		next_read_state <= DELAY;
	else
		count_read <= (Others => '0');
		next_read_state <= DIG;
	end if;
	
	When DIG =>
	count_read <= (Others => '0');
	start_dig <= '1';
	start_srout <= '0';
	if ( ramp_done = '1' ) then 
		next_read_state <= SROUT_LOOP;
	else
		next_read_state <= DIG;
	end if;

	When SROUT_LOOP =>
	start_dig <= '1';
	start_srout <= '0';
	--if ( count_read(5 downto 0) < "100001" ) then
	if ( count_read(5 downto 0) < "100000" ) then
		samplesel <= count_read(5 downto 0);	
		next_read_state <= SROUT;
	else
		samplesel <= (Others => '0');
		next_read_state <= WAIT_DONE;
	end if;	
	
	When SROUT =>
	start_dig <= '1';
	start_srout <= '1';
	if( samp_done = '1' ) then --serial readout completed, sample stored
		count_read(5 downto 0) <= count_read(5 downto 0)+"000001";
		next_read_state <= SROUT_WAIT;
	else
		count_read(5 downto 0) <= count_read(5 downto 0);
		next_read_state <= SROUT;
	end if;
	
	When SROUT_WAIT => --wait for serial readout module to return to reset
	start_dig <= '1';
	start_srout <= '0';
	if( samp_done = '0' ) then --serial readout module in idle state
		next_read_state <= SROUT_LOOP;
	else
		next_read_state <= SROUT_WAIT;
	end if;
	
	When WAIT_DONE =>
	count_read <= (Others => '0');
	start_dig <= '1';
	start_srout <= '0';
	if( read_req = '0' ) then 
		next_read_state <= Idle;
	else
		next_read_state <= WAIT_DONE;
	end if;
	
	When Others =>
	count_read <= (Others => '0');
	start_dig <= '0';
	start_srout <= '0';
	next_read_state <= Idle;
	end Case;
	
end if;
end process;

end Behavioral;

