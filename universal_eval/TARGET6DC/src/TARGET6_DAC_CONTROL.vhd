----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:40:31 10/25/2013 
-- Design Name: 
-- Module Name:    TARGET6_DAC_CONTROL - Behavioral 
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

entity TARGET6_DAC_CONTROL is
    generic (
		constant REGISTER_WIDTH : integer := 18
	 );
    Port ( CLK : in  STD_LOGIC;
			  UPDATE : in  STD_LOGIC;
			  REG_DATA : in  STD_LOGIC_VECTOR(17 downto 0);
           SIN : out  STD_LOGIC;
           SCLK : out  STD_LOGIC;
           PCLK : out  STD_LOGIC);
end TARGET6_DAC_CONTROL;

architecture Behavioral of TARGET6_DAC_CONTROL is

   --STATES
   type state_type is (
			IDLE, 
			LOAD_DAC_LOW_SET0,
			LOAD_DAC_LOW_WAIT0, 
			LOAD_DAC_LOW_MID, 
			LOAD_DAC_LOW_SET1,
			LOAD_DAC_LOW_WAIT1,
			LOAD_DAC_HIGH_SET0,
			LOAD_DAC_HIGH_WAIT0,
			LOAD_DAC_HIGH_MID,
			LOAD_DAC_HIGH_SET1,
			LOAD_DAC_HIGH_WAIT1,
			LATCH_SET0,
			LATCH_WAIT0,
			LATCH_SET1,
			LATCH_WAIT1,
			LATCH_SET2,
			LATCH_WAIT2,
			LATCH_SET3,
			LATCH_WAIT3,
			LATCH_SET4,
			LATCH_WAIT4,
			LATCH_SET5,
			LATCH_WAIT5,
			LATCH_SET6,
			LATCH_WAIT6
			); 
   signal STATE : state_type := IDLE;

   --Internal signals for all outputs of the state-machine
	signal SIN_i : std_logic := '0';
	signal SCLK_i : std_logic := '0';
	signal PCLK_i : std_logic := '0';
	
	--Nomal variables
	SIGNAL cnt  : integer := 0;
	signal ENABLE_COUNTER : std_logic := '0';
	signal INTERNAL_COUNTER	: UNSIGNED(15 downto 0) := x"0000";
	signal UPDATE_REG : std_logic_vector(1 downto 0 ) := "00";
	signal UPDATE_START : std_logic := '1';
	
	--constants
	signal DAC_LOADING_PERIOD  	: UNSIGNED(15 downto 0) := x"0040";
	signal LATCH_LOADING_PERIOD  	: UNSIGNED(15 downto 0) := x"0040";

begin

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
 
	--OVERALL STATE MACHINE
   SYNC_PROC: process (CLK)
   begin
      if (CLK'event and CLK = '1') then
			SIN <= SIN_i;
			SCLK <= SCLK_i;
			PCLK <= PCLK_i;
      end if;
   end process;
	
	--Edge detector for key internal signals
	process (CLK) begin
		if (falling_edge(CLK)) then	
			UPDATE_REG(1) <= UPDATE_REG(0);
			UPDATE_REG(0) <= UPDATE;
		end if;
	end process;
	UPDATE_START <= '1' when (UPDATE_REG = "01") else
	                    '0';
 
   --process to load DACs to ASIC
	DAC_REGISTER_UPDATE_TARGET6 : PROCESS(CLK)
	BEGIN
		------------------------------------------------------------
		IF RISING_EDGE(CLK) THEN
			CASE STATE IS
				--------------------------------
				WHEN IDLE =>
				   SIN_i <= '0';
					SCLK_i <= '0';
					PCLK_i <= '0';
					cnt 		<= 0;
					ENABLE_COUNTER <= '0';
					if UPDATE_START = '1' then
						STATE <= LOAD_DAC_LOW_SET0;
					else
						STATE <= IDLE;
					end if;
				--------------------------------
				
				WHEN LOAD_DAC_LOW_SET0 =>
					SCLK_i <= '0';
					ENABLE_COUNTER <= '0';
					STATE <= LOAD_DAC_LOW_WAIT0;
				
				WHEN LOAD_DAC_LOW_WAIT0 =>
					SCLK_i <= '0';
					ENABLE_COUNTER <= '1';
					STATE <= LOAD_DAC_LOW_WAIT0;
					if INTERNAL_COUNTER > UNSIGNED(DAC_LOADING_PERIOD) then
						ENABLE_COUNTER <= '0';
						state <= LOAD_DAC_LOW_MID;
					end if;
				
				WHEN LOAD_DAC_LOW_MID =>
					SCLK_i <= '0';
					ENABLE_COUNTER <= '0';
					if cnt < REGISTER_WIDTH then
						STATE <= LOAD_DAC_LOW_SET1;
						SIN_i <= REG_DATA(cnt);	--SLB is sent first as "cnt" increasing.
					else
						STATE <= LATCH_SET0; --DONE LOADING REGISTER
						cnt <= 0;
					end if;
					
				WHEN LOAD_DAC_LOW_SET1 =>
					SCLK_i <= '0';
					ENABLE_COUNTER <= '0';
					STATE <= LOAD_DAC_LOW_WAIT1;
					
				WHEN LOAD_DAC_LOW_WAIT1 =>
					SCLK_i <= '0';
					ENABLE_COUNTER <= '1';
					STATE <= LOAD_DAC_LOW_WAIT1;
					if INTERNAL_COUNTER > UNSIGNED(DAC_LOADING_PERIOD) then
						ENABLE_COUNTER <= '0';
						STATE <= LOAD_DAC_HIGH_SET0;
					end if;
					
				WHEN LOAD_DAC_HIGH_SET0 =>
					SCLK_i <= '1';
					ENABLE_COUNTER <= '0';
					STATE <= LOAD_DAC_HIGH_WAIT0;
					
				WHEN LOAD_DAC_HIGH_WAIT0 =>
					SCLK_i <= '1';
					ENABLE_COUNTER <= '1';
					STATE <= LOAD_DAC_HIGH_WAIT0;
					if INTERNAL_COUNTER > UNSIGNED(DAC_LOADING_PERIOD) then
						ENABLE_COUNTER <= '0';
						state <= LOAD_DAC_HIGH_MID;
					end if;	
					
				WHEN LOAD_DAC_HIGH_MID =>
					SCLK_i <= '1';
					ENABLE_COUNTER <= '0';
					STATE <= LOAD_DAC_HIGH_SET1;
					cnt <= cnt + 1;
				
				WHEN LOAD_DAC_HIGH_SET1 =>
					SCLK_i <= '1';
					ENABLE_COUNTER <= '0';
					STATE <= LOAD_DAC_HIGH_WAIT1;
				
				WHEN LOAD_DAC_HIGH_WAIT1 =>
					SCLK_i <= '1';
					ENABLE_COUNTER <= '1';
					STATE <= LOAD_DAC_HIGH_WAIT1;
					if INTERNAL_COUNTER > UNSIGNED(DAC_LOADING_PERIOD) then
						ENABLE_COUNTER <= '0';
						STATE <= LOAD_DAC_LOW_SET0;
					end if;	
					
				WHEN LATCH_SET0 =>
				   SIN_i <= '0';
					SCLK_i <= '0';
					PCLK_i <= '0';
					ENABLE_COUNTER <= '0';
					STATE <= LATCH_WAIT0;
					
				WHEN LATCH_WAIT0 =>
				   SIN_i <= '0';
					SCLK_i <= '0';
					PCLK_i <= '0';
					ENABLE_COUNTER <= '1';
					STATE <= LATCH_WAIT0;
					if INTERNAL_COUNTER > UNSIGNED(LATCH_LOADING_PERIOD) then
						ENABLE_COUNTER <= '0';
						STATE <= LATCH_SET1;
					end if;
				
				WHEN LATCH_SET1 =>
				   SIN_i <= '0';
					SCLK_i <= '0';
					PCLK_i <= '1';
					ENABLE_COUNTER <= '0';
					STATE <= LATCH_WAIT1;		
					
				WHEN LATCH_WAIT1 =>
				   SIN_i <= '0';
					SCLK_i <= '0';
					PCLK_i <= '1';
					ENABLE_COUNTER <= '1';
					STATE <= LATCH_WAIT1;
					if INTERNAL_COUNTER > UNSIGNED(LATCH_LOADING_PERIOD) then
						ENABLE_COUNTER <= '0';
						STATE <= LATCH_SET2;
					end if;
					
				WHEN LATCH_SET2 =>
				   SIN_i <= '0';
					SCLK_i <= '0';
					PCLK_i <= '0';
					ENABLE_COUNTER <= '0';
					STATE <= LATCH_WAIT2;
					
				WHEN LATCH_WAIT2 =>
				   SIN_i <= '0';
					SCLK_i <= '0';
					PCLK_i <= '0';
					ENABLE_COUNTER <= '1';
					STATE <= LATCH_WAIT2;
					if INTERNAL_COUNTER > UNSIGNED(LATCH_LOADING_PERIOD) then
						ENABLE_COUNTER <= '0';
						STATE <= LATCH_SET3;
					end if;
				
				WHEN LATCH_SET3 =>
				   SIN_i <= '1';
					SCLK_i <= '0';
					PCLK_i <= '0';
					ENABLE_COUNTER <= '0';
					STATE <= LATCH_WAIT3;
				
				WHEN LATCH_WAIT3 =>
				   SIN_i <= '1';
					SCLK_i <= '0';
					PCLK_i <= '0';
					ENABLE_COUNTER <= '1';
					STATE <= LATCH_WAIT3;
					if INTERNAL_COUNTER > UNSIGNED(LATCH_LOADING_PERIOD) then
						ENABLE_COUNTER <= '0';
						STATE <= LATCH_SET4;
					end if;
				
				WHEN LATCH_SET4 =>
				   SIN_i <= '1';
					SCLK_i <= '0';
					PCLK_i <= '1';
					ENABLE_COUNTER <= '0';
					STATE <= LATCH_WAIT4;
				
				WHEN LATCH_WAIT4 =>
				   SIN_i <= '1';
					SCLK_i <= '0';
					PCLK_i <= '1';
					ENABLE_COUNTER <= '1';
					STATE <= LATCH_WAIT4;
					if INTERNAL_COUNTER > UNSIGNED(LATCH_LOADING_PERIOD) then
						ENABLE_COUNTER <= '0';
						STATE <= LATCH_SET5;
					end if;
				
				WHEN LATCH_SET5 =>
				   SIN_i <= '1';
					SCLK_i <= '0';
					PCLK_i <= '0';
					ENABLE_COUNTER <= '0';
					STATE <= LATCH_WAIT5;
					
			   WHEN LATCH_WAIT5 =>
				   SIN_i <= '1';
					SCLK_i <= '0';
					PCLK_i <= '0';
					ENABLE_COUNTER <= '1';
					STATE <= LATCH_WAIT5;
					if INTERNAL_COUNTER > UNSIGNED(LATCH_LOADING_PERIOD) then
						ENABLE_COUNTER <= '0';
						STATE <= LATCH_SET6;
					end if;
				
				WHEN LATCH_SET6 =>
				   SIN_i <= '0';
					SCLK_i <= '0';
					PCLK_i <= '0';
					ENABLE_COUNTER <= '0';
					STATE <= LATCH_WAIT6;
				
				WHEN LATCH_WAIT6 =>
				   SIN_i <= '0';
					SCLK_i <= '0';
					PCLK_i <= '0';
					ENABLE_COUNTER <= '1';
					STATE <= LATCH_WAIT6;
					if INTERNAL_COUNTER > UNSIGNED(LATCH_LOADING_PERIOD) then
						ENABLE_COUNTER <= '0';
						STATE <= IDLE;
					end if;
					
				--------------------------------
				WHEN OTHERS =>
					STATE <= IDLE;
			END CASE;
			------------------------------------------------------------
		END IF;
		------------------------------------------------------------
	END PROCESS DAC_REGISTER_UPDATE_TARGET6;

end Behavioral;

