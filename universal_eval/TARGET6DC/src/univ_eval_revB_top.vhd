----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:20:38 10/25/2012 
-- Design Name: 
-- Module Name:    univ_eval_revB_top - Behavioral 
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
library UNISIM;
use UNISIM.VComponents.all;
use work.readout_definitions.all;

entity univ_eval_revB_top is 
	Port(
		BOARD_40MHz_CLOCK           : in  STD_LOGIC;
		BOARD_150MHz_CLOCK		    : in  STD_LOGIC;
		MON                         : out STD_LOGIC_VECTOR(15 downto 0);

		------------------USB pins-------------------
		USB_IFCLK                   : in  STD_LOGIC;
		USB_CTL0                    : in  STD_LOGIC;
		USB_CTL1                    : in  STD_LOGIC;
		USB_CTL2                    : in  STD_LOGIC;
		USB_FDD                     : inout STD_LOGIC_VECTOR(15 downto 0);
		USB_PA0                     : out STD_LOGIC;
		USB_PA1                     : out STD_LOGIC;
		USB_PA2                     : out STD_LOGIC;
		USB_PA3                     : out STD_LOGIC;
		USB_PA4                     : out STD_LOGIC;
		USB_PA5                     : out STD_LOGIC;
		USB_PA6                     : out STD_LOGIC;
		USB_PA7                     : in  STD_LOGIC;
		USB_RDY0                    : out STD_LOGIC;
		USB_RDY1                    : out STD_LOGIC;
		USB_WAKEUP                  : in  STD_LOGIC;
		USB_CLKOUT		             : in  STD_LOGIC;
		
		--ASIC SIGNALS
		SSPIN								 : out STD_LOGIC;
		SSTIN								 : out STD_LOGIC;
		WR_ADVCLK						 : out STD_LOGIC;
		WR_ADDRCLR						 : out STD_LOGIC;
		WR_STRB							 : out STD_LOGIC;
		WR_ENA							 : out STD_LOGIC;
		
		RAMP								 : out STD_LOGIC;
		START								 : out STD_LOGIC;
		CLR						 		 : out STD_LOGIC;
		RD_ENA							 : out STD_LOGIC;
		RD_RS_S                     : out STD_LOGIC_VECTOR(2 downto 0);
		RD_CS_S                     : out STD_LOGIC_VECTOR(5 downto 0);
		
		TST_START						 :	OUT STD_LOGIC;
		TST_BOICLR				 	 :	OUT STD_LOGIC;
		RCO_SSPOUT						 : in STD_LOGIC;
		
		SIN								 : out STD_LOGIC;
		SCLK								 : out STD_LOGIC;
		PCLK								 : out STD_LOGIC;
		REGCLR							 : out STD_LOGIC;
		SHOUT						 		 : in STD_LOGIC;
		
		DO									 :	IN		STD_LOGIC_VECTOR(15 DOWNTO 0);
		SR_SEL						    :	OUT STD_LOGIC;
		SR_CLOCK							 :	OUT STD_LOGIC;
		SR_CLEAR							 :	OUT STD_LOGIC;
		SAMPLESEL						 :	OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
		SAMPLESEL_ANY					 :	OUT STD_LOGIC;
		
		TRG_16							 : in STD_LOGIC;
		TRG								 : in STD_LOGIC_VECTOR(3 downto 0)
	);
end univ_eval_revB_top;

architecture Behavioral of univ_eval_revB_top is
	
	signal internal_CLOCK_50MHz_BUFG : std_logic;
	signal internal_CLOCK_150MHz_BUFG : std_logic;
	signal internal_OUTPUT_REGISTERS : GPR;
	signal internal_INPUT_REGISTERS  : RR;
	signal internal_SMP_STOP : std_logic := '0';
	signal internal_START_DIG : std_logic := '0';
	signal internal_STARTRAMP_out : std_logic := '0';
	signal internal_TRIGGER_ALL : std_logic := '0';
	signal INTERNAL_COUNTER : std_logic_vector(27 downto 0) :=  x"0000000";
	signal internal_triggerCounter : std_logic_vector(15 downto 0) :=  x"0000";
	signal internal_numTriggers : std_logic_vector(15 downto 0) :=  x"0000";
	
	signal internal_TARGET6_DAC_CONTROL_UPDATE : std_logic := '0';
	signal internal_TARGET6_DAC_CONTROL_REG_DATA : std_logic_vector(17 downto 0) :=  "00" & x"0000" ;
	
begin
	internal_CLOCK_50MHz_BUFG		<= BOARD_40MHz_CLOCK;
	internal_CLOCK_150MHz_BUFG		<= BOARD_150MHz_CLOCK;
	
	internal_TRIGGER_ALL <= TRG_16 OR TRG(0) OR TRG(1) OR TRG(2) OR TRG(3);

	--Interface to the DAQ devices
	map_readout_interfaces : entity work.readout_interface
	port map ( 
		CLOCK                       => internal_CLOCK_50MHz_BUFG,

		OUTPUT_REGISTERS            => internal_OUTPUT_REGISTERS,
		INPUT_REGISTERS             => internal_INPUT_REGISTERS,

		USB_IFCLK                   => USB_IFCLK,
		USB_CTL0                    => USB_CTL0,
		USB_CTL1                    => USB_CTL1,
		USB_CTL2                    => USB_CTL2,
		USB_FDD                     => USB_FDD,
		USB_PA0                     => USB_PA0,
		USB_PA1                     => USB_PA1,
		USB_PA2                     => USB_PA2,
		USB_PA3                     => USB_PA3,
		USB_PA4                     => USB_PA4,
		USB_PA5                     => USB_PA5,
		USB_PA6                     => USB_PA6,
		USB_PA7                     => USB_PA7,
		USB_RDY0                    => USB_RDY0,
		USB_RDY1                    => USB_RDY1,
		USB_WAKEUP                  => USB_WAKEUP,
		USB_CLKOUT		             => USB_CLKOUT
	);

	--------------------------------------------------
	-------General registers interfaced to DAQ -------
	--------------------------------------------------

	--------Output register mapping-------------------
	
	--define output general i/o registers
	--mon <= internal_OUTPUT_REGISTERS(0); 
	mon(15 downto 0) <= internal_OUTPUT_REGISTERS(0)(15 downto 0); 
	--SIN <= internal_OUTPUT_REGISTERS(5)(0);
	--SCLK <= internal_OUTPUT_REGISTERS(6)(0);
	--PCLK <= internal_OUTPUT_REGISTERS(7)(0);
	--REGCLR <= internal_OUTPUT_REGISTERS(8)(0);
	
	--DAC CONTROL SIGNALS
	internal_TARGET6_DAC_CONTROL_UPDATE <= internal_OUTPUT_REGISTERS(5)(0);
	internal_TARGET6_DAC_CONTROL_REG_DATA <= internal_OUTPUT_REGISTERS(7)(5 downto 0) & internal_OUTPUT_REGISTERS(6)(11 downto 0);
	REGCLR <= internal_OUTPUT_REGISTERS(8)(0);
	
	--SAMPLING CONTROL SIGNALS
	internal_SMP_STOP <= internal_OUTPUT_REGISTERS(9)(0);
	
	--DIGITIZATION SIGNALS
	internal_START_DIG <= internal_OUTPUT_REGISTERS(10)(0);

   --SERIAL READOUT SIGNALS
	SR_SEL <= internal_OUTPUT_REGISTERS(11)(0);
	SR_CLOCK	 <= internal_OUTPUT_REGISTERS(12)(0);
	SR_CLEAR	 <= internal_OUTPUT_REGISTERS(13)(0);
	SAMPLESEL <= internal_OUTPUT_REGISTERS(14)(4 downto 0);
	SAMPLESEL_ANY <= internal_OUTPUT_REGISTERS(15)(0);
	
	--GENERIC SIGNALS
	TST_START <= internal_OUTPUT_REGISTERS(16)(0);
	TST_BOICLR <= internal_OUTPUT_REGISTERS(17)(0);
	
	--define input genereal i/o registers
	internal_INPUT_REGISTERS(N_GPR  )(0) <= SHOUT;
	internal_INPUT_REGISTERS(N_GPR + 1 ) <= DO;
	internal_INPUT_REGISTERS(N_GPR + 2 ) <= internal_numTriggers;
	internal_INPUT_REGISTERS(N_GPR + 3 )(0) <= internal_SMP_STOP;
	
	--------Input register mapping--------------------
	--Map the first N_GPR output registers to the first set of read registers
	gen_OUTREG_to_INREG: for i in 0 to N_GPR-1 generate
		gen_BIT: for j in 0 to 15 generate
			map_BUF_RR : BUF 
			port map( 
				I => internal_OUTPUT_REGISTERS(i)(j), 
				O => internal_INPUT_REGISTERS(i)(j) 
			);
		end generate;
	end generate;
	--- The register numbers must be updated for the following if N_GPR is changed.
   --	internal_INPUT_REGISTERS(N_GPR  ) <= internal_I2C_BUSA_ACKNOWLEDGED & internal_I2C_BUSA_BUSY & "000000" & internal_I2C_BUSA_BYTE_RECEIVED; --Register 256: I2C BusA interfaces
   --	internal_INPUT_REGISTERS(N_GPR+1) <= internal_I2C_BUSB_ACKNOWLEDGED & internal_I2C_BUSB_BUSY & "000000" & internal_I2C_BUSB_BYTE_RECEIVED; --Register 257: I2C BusB interfaces
   --	internal_INPUT_REGISTERS(N_GPR+2) <= internal_I2C_BUSC_ACKNOWLEDGED & internal_I2C_BUSC_BUSY & "000000" & internal_I2C_BUSC_BYTE_RECEIVED; --Register 257: I2C BusB interfaces

   --TARGET6 READOUT STATE MACHINES PLACED HERE FOR NOW
	
	--input 150 MHz clock
	--map_board_150MHz_clock : ibufds
	----port map(
	--	I  => BOARD_150MHz_CLOCKP,
	--	IB => BOARD_150MHz_CLOCKN,
	--	O  => internal_CLOCK_150MHz_BUFG
	--);
	
	--TARGET6 DAC Control
   u_TARGET6_DAC_CONTROL: entity work.TARGET6_DAC_CONTROL PORT MAP(
		CLK => internal_CLOCK_50MHz_BUFG,
		UPDATE => internal_TARGET6_DAC_CONTROL_UPDATE,
		REG_DATA => internal_TARGET6_DAC_CONTROL_REG_DATA,
		SIN => SIN,
		SCLK => SCLK,
		PCLK => PCLK
	);
	
	--sampling logic - specifically SSPIN/SSTIN + write address control
	u_SamplingLgc : entity work.SamplingLgc
   Port map (
		clk => internal_CLOCK_150MHz_BUFG,
		stop => internal_SMP_STOP,
		MAIN_CNT_out => open,
		sspin_out => SSPIN,
		sstin_out => SSTIN,
		wr_advclk_out => WR_ADVCLK,
		wr_addrclr_out => WR_ADDRCLR,
		wr_strb_out => WR_STRB,
		wr_ena_out => WR_ENA,
		samp_delay => x"000"
	);
	
	u_DigitizingLgc: entity work.DigitizingLgc PORT MAP(
		clk => internal_CLOCK_50MHz_BUFG,
		StartDig => internal_START_DIG,
		ramp_length => X"400",
		rd_ena => RD_ENA,
		clr => CLR,
		startramp => internal_STARTRAMP_out
	);
	RAMP <= internal_STARTRAMP_out;
	START <= internal_STARTRAMP_out;
	RD_RS_S <= "000";
	RD_CS_S <= "000000";

   --counter process
   process (internal_CLOCK_50MHz_BUFG) begin
		if (rising_edge(internal_CLOCK_50MHz_BUFG)) then
			INTERNAL_COUNTER <= INTERNAL_COUNTER + 1;
      end if;
   end process;
	
	--trigger counter
	process (internal_CLOCK_50MHz_BUFG) begin
		if (rising_edge(internal_CLOCK_50MHz_BUFG)) then
			--if (INTERNAL_COUNTER = x"0000000") then
			--	internal_numTriggers = internal_triggerCounter;
			--end if;
			if (INTERNAL_COUNTER = x"0000000") then
				internal_numTriggers <= internal_triggerCounter;
				internal_triggerCounter <= x"0000";
			else
				if( internal_TRIGGER_ALL = '1' ) then
					internal_triggerCounter <= internal_triggerCounter  + 1;
				end if;
			end if;
      end if;
   end process;

	--trigger control over sampling
	process (internal_CLOCK_50MHz_BUFG) begin
		if (rising_edge(internal_CLOCK_50MHz_BUFG)) then
			--allow sampling to start
			if (internal_OUTPUT_REGISTERS(9)(0) = '0') then
				--internal_SMP_STOP <= '0';
			else
				--allow trigger to stop sampling
				if( internal_TRIGGER_ALL = '1' ) then
					--internal_SMP_STOP <= '1';
				end if;
			end if;
      end if;
   end process;
	
end Behavioral;