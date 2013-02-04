----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:55:11 11/16/2012 
-- Design Name: 
-- Module Name:    TriggerControl - Behavioral 
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

entity TriggerControl is
    Port ( clk : in  STD_LOGIC;
           rst : in  STD_LOGIC;
           trigReq : in  STD_LOGIC;
           trigControl : in  STD_LOGIC_VECTOR (11 downto 0);
           trigger : out  STD_LOGIC
			  );
end TriggerControl;

architecture Behavioral of TriggerControl is

	type trig_state_type is
	(
	Idle,		
	DelayTrig,
	High,
	WaitLow
	);
	signal trig_state_neg	: trig_state_type;	
	signal trig_state_pos	: trig_state_type;

signal Trigger_pos_out : std_logic := '0';
signal Trigger_neg_out : std_logic := '0';
signal TrigReq_in : std_logic := '0';
signal count_pos : UNSIGNED(11 downto 0);
signal count_neg : UNSIGNED(11 downto 0);

begin

Trigger 
	<= Trigger_pos_out WHEN trigControl(11) = '0' ELSE Trigger_neg_out;
--Trigger <= Trigger_pos_out;

--latch TrigReq
--ignore if trigger signal is synchronous with clk
--process(clk,rst)
--begin
--if (rst = '1') then
--	TrigReq_in <= '0';
--elsif (clk'event and clk = '1') then
--	TrigReq_in <= trigReq;
--end if;
--end process;
TrigReq_in <= trigReq; -- trigger signal is synchronous with clock

--positive clock edge process
process(clk,rst)
begin
if (rst = '1') then
	Trigger_pos_out <= '0';
	trig_state_pos <= Idle;
	count_pos <= (Others => '0');
elsif (clk'event and clk = '1') then
  Case trig_state_pos is
  
  When Idle =>
   Trigger_pos_out <= '0';
	count_pos <= (Others => '0');
	if( TrigReq_in = '1' ) then
		trig_state_pos <= DelayTrig;
	else
		trig_state_pos <= Idle;
	end if;
	
  When DelayTrig =>
	Trigger_pos_out <= '0';
   if( count_pos(7 downto 0) < UNSIGNED( trigControl(7 downto 0) ) ) then 
		count_pos <= count_pos + 1;
		trig_state_pos <= DelayTrig;
	else
		count_pos <= (Others => '0');
		trig_state_pos <= High;
	end if;

  When High =>   
	if( count_pos(2 downto 0) < UNSIGNED( trigControl(10 downto 8) ) ) then 
		Trigger_pos_out <= '1';
		count_pos <= count_pos + 1;
		trig_state_pos <= High;
	else
		Trigger_pos_out <= '0';
		trig_state_pos <= WaitLow;
	end if;

  When WaitLow =>
	Trigger_pos_out <= '0';
	if( TrigReq_in = '0' ) then
		trig_state_pos <= Idle;
	else
		trig_state_pos <= WaitLow;
	end if;
	
 When Others =>
   count_pos <= (Others => '0'); 
   Trigger_pos_out <= '0';
	trig_state_pos <= Idle;
 end case;

end if;
end process;

--negative clock edge process
process(clk,rst)
begin
if (rst = '1') then
	Trigger_neg_out <= '0';
	trig_state_neg <= Idle;
	count_neg <= (Others => '0');
elsif (clk'event and clk = '0') then
  Case trig_state_neg is
  
   When Idle =>
   Trigger_neg_out <= '0';
	count_neg <= (Others => '0');
	if( TrigReq_in = '1' ) then
		trig_state_neg <= DelayTrig;
	else
		trig_state_neg <= Idle;
	end if;
	
  When DelayTrig =>
	Trigger_neg_out <= '0';
   if( count_neg(7 downto 0) < UNSIGNED( trigControl(7 downto 0) ) ) then 
		count_neg <= count_neg + 1;
		trig_state_neg <= DelayTrig;
	else
		count_neg <= (Others => '0');
		trig_state_neg <= High;
	end if;

  When High =>
	if( count_neg(2 downto 0) < UNSIGNED( trigControl(10 downto 8) ) ) then 
		Trigger_neg_out <= '1';
		count_neg <= count_neg + 1;
		trig_state_neg <= High;
	else
		Trigger_neg_out <= '0';
		trig_state_neg <= WaitLow;
	end if;

  When WaitLow =>
	Trigger_neg_out <= '0';
	if( TrigReq_in = '0' ) then
		trig_state_neg <= Idle;
	else
		trig_state_neg <= WaitLow;
	end if;
	
 When Others =>
   count_neg <= (Others => '0'); 
   Trigger_neg_out <= '0';
	trig_state_neg <= Idle;
 end case;

end if;
end process;

end Behavioral;

