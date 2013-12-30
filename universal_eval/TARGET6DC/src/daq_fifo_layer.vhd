----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:11:27 09/17/2012 
-- Design Name: 
-- Module Name:    daq_fifo_layer - Behavioral 
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
--use work.utilities.all;


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity daq_fifo_layer is
	Generic (

		INCLUDE_USB    : integer :=   1
	);
	Port ( 
		--System clock input, used for detecting USB
		SYSTEM_CLOCK        : in STD_LOGIC;

		--FIFO signals for the 4 FIFOs
		FIFO_OUT_0_DATA     : in  STD_LOGIC_VECTOR(31 downto 0);
		FIFO_OUT_0_WR_EN    : in  STD_LOGIC;
		FIFO_OUT_0_WR_CLK   : in  STD_LOGIC;
		FIFO_OUT_0_FULL     : out STD_LOGIC;
		FIFO_INP_0_DATA     : out STD_LOGIC_VECTOR(31 downto 0);
		FIFO_INP_0_RD_EN    : in  STD_LOGIC;
		FIFO_INP_0_RD_CLK   : in  STD_LOGIC;
		FIFO_INP_0_EMPTY    : out STD_LOGIC;
		FIFO_INP_0_VALID    : out STD_LOGIC;
		FIFO_OUT_1_DATA     : in  STD_LOGIC_VECTOR(31 downto 0);
		FIFO_OUT_1_WR_EN    : in  STD_LOGIC;
		FIFO_OUT_1_WR_CLK   : in  STD_LOGIC;
		FIFO_OUT_1_FULL     : out STD_LOGIC;
		FIFO_INP_1_DATA     : out STD_LOGIC_VECTOR(31 downto 0);
		FIFO_INP_1_RD_EN    : in  STD_LOGIC;
		FIFO_INP_1_RD_CLK   : in  STD_LOGIC;
		FIFO_INP_1_EMPTY    : out STD_LOGIC;
		FIFO_INP_1_VALID    : out STD_LOGIC;
		
		--Signals that need to go to the top level for USB
		USB_IFCLK           : in  STD_LOGIC;
		USB_CTL0            : in  STD_LOGIC;
		USB_CTL1            : in  STD_LOGIC;
		USB_CTL2            : in  STD_LOGIC;
		USB_FDD             : inout STD_LOGIC_VECTOR(15 downto 0);
		USB_PA0             : out STD_LOGIC;
		USB_PA1             : out STD_LOGIC;
		USB_PA2             : out STD_LOGIC;
		USB_PA3             : out STD_LOGIC;
		USB_PA4             : out STD_LOGIC;
		USB_PA5             : out STD_LOGIC;
		USB_PA6             : out STD_LOGIC;
		USB_PA7             : in  STD_LOGIC;
		USB_RDY0            : out STD_LOGIC;
		USB_RDY1            : out STD_LOGIC;
		USB_WAKEUP          : in  STD_LOGIC;
		USB_CLKOUT          : in  STD_LOGIC


	);
end daq_fifo_layer;

architecture Behavioral of daq_fifo_layer is
	
	signal internal_USB_PRESENT          : std_logic;

	signal internal_USB_CLOCK                  : std_logic;
	signal internal_USB_RESET                  : std_logic;
	signal internal_USB_EP2_DATA_16BIT         : std_logic_vector(15 downto 0);
	signal internal_USB_EP2_DATA_32BIT         : std_logic_vector(31 downto 0);
	signal internal_USB_EP2_WRITE_ENABLE       : std_logic;
	signal internal_USB_EP2_READ_ENABLE        : std_logic;
	signal internal_USB_EP2_READ_ENABLE_reg    : std_logic;
	signal internal_USB_EP2_FULL               : std_logic;
	signal internal_USB_EP2_EMPTY              : std_logic;
	signal internal_USB_EP4_DATA_16BIT         : std_logic_vector(15 downto 0);
	signal internal_USB_EP4_DATA_32BIT         : std_logic_vector(31 downto 0);
	signal internal_USB_EP4_WRITE_ENABLE       : std_logic;
	signal internal_USB_EP4_READ_ENABLE        : std_logic;
	signal internal_USB_EP4_READ_ENABLE_reg    : std_logic;
	signal internal_USB_EP4_FULL               : std_logic;
	signal internal_USB_EP4_EMPTY              : std_logic;
	signal internal_USB_EP6_DATA_16BIT         : std_logic_vector(15 downto 0);
	signal internal_USB_EP6_DATA_32BIT         : std_logic_vector(31 downto 0);
	signal internal_USB_EP6_READ_ENABLE        : std_logic;
	signal internal_USB_EP6_WRITE_ENABLE       : std_logic;
	signal internal_USB_EP6_WRITE_ENABLE_reg   : std_logic;
	signal internal_USB_EP6_EMPTY              : std_logic;
	signal internal_USB_EP6_FULL               : std_logic;
	signal internal_USB_EP8_DATA_16BIT         : std_logic_vector(15 downto 0);
	signal internal_USB_EP8_DATA_32BIT         : std_logic_vector(31 downto 0);
	signal internal_USB_EP8_READ_ENABLE        : std_logic;
	signal internal_USB_EP8_WRITE_ENABLE       : std_logic;
	signal internal_USB_EP8_WRITE_ENABLE_reg   : std_logic;
	signal internal_USB_EP8_EMPTY              : std_logic;
	signal internal_USB_EP8_FULL               : std_logic;

	signal internal_USB_TX_0_READ_ENABLE       : std_logic;
	signal internal_USB_TX_1_READ_ENABLE       : std_logic;
	signal internal_USB_RX_0_WRITE_ENABLE      : std_logic;
	signal internal_USB_RX_1_WRITE_ENABLE      : std_logic;
	signal internal_USB_RX_0_VALID             : std_logic;
	signal internal_USB_RX_1_VALID             : std_logic;
	
	signal internal_FIFO_OUT_0_READ_CLOCK      : std_logic;
	signal internal_FIFO_OUT_0_READ_ENABLE     : std_logic;
	signal internal_FIFO_OUT_0_EMPTY           : std_logic;
	signal internal_FIFO_OUT_0_FULL            : std_logic;
	signal internal_FIFO_OUT_0_READ_DATA       : std_logic_vector(31 downto 0);
	signal internal_FIFO_OUT_0_VALID           : std_logic;
	signal internal_FIFO_OUT_0_WRITE_ENABLE    : std_logic;
	signal internal_FIFO_OUT_0_WRITE_DATA      : std_logic_vector(31 downto 0);
	signal internal_FIFO_OUT_1_READ_CLOCK      : std_logic;
	signal internal_FIFO_OUT_1_READ_ENABLE     : std_logic;
	signal internal_FIFO_OUT_1_EMPTY           : std_logic;
	signal internal_FIFO_OUT_1_FULL            : std_logic;
	signal internal_FIFO_OUT_1_READ_DATA       : std_logic_vector(31 downto 0);
	signal internal_FIFO_OUT_1_VALID           : std_logic;
	signal internal_FIFO_OUT_1_WRITE_ENABLE    : std_logic;
	signal internal_FIFO_OUT_1_WRITE_DATA      : std_logic_vector(31 downto 0);
	
	signal internal_FIFO_INP_0_WRITE_CLOCK     : std_logic;
	signal internal_FIFO_INP_0_WRITE_ENABLE    : std_logic;
	signal internal_FIFO_INP_0_FULL            : std_logic;
	signal internal_FIFO_INP_0_EMPTY           : std_logic;
	signal internal_FIFO_INP_0_WRITE_DATA      : std_logic_vector(31 downto 0);
	signal internal_FIFO_INP_0_READ_DATA       : std_logic_vector(31 downto 0);
	signal internal_FIFO_INP_0_READ_ENABLE     : std_logic;
	signal internal_FIFO_INP_0_VALID           : std_logic;
	signal internal_FIFO_INP_1_WRITE_CLOCK     : std_logic;
	signal internal_FIFO_INP_1_WRITE_ENABLE    : std_logic;
	signal internal_FIFO_INP_1_FULL            : std_logic;
	signal internal_FIFO_INP_1_EMPTY           : std_logic;
	signal internal_FIFO_INP_1_WRITE_DATA      : std_logic_vector(31 downto 0);
	signal internal_FIFO_INP_1_READ_DATA       : std_logic_vector(31 downto 0);
	signal internal_FIFO_INP_1_READ_ENABLE     : std_logic;
	signal internal_FIFO_INP_1_VALID           : std_logic;
	
	signal internal_USB_EP6_DATA_32BIT_L2H		 : std_logic_vector(31 downto 0);
	signal internal_USB_EP8_DATA_32BIT_L2H		 : std_logic_vector(31 downto 0);
	
	signal internal_FIFO_CLOCK                 : std_logic;
	
	signal internal_CS_ila							: std_logic_vector(35 downto 0);
	signal clk_chipscope								: std_logic;
	signal ila_trigger								: std_logic_vector(33 downto 0);
	
	--SIGNAL internal_USB_FDD							: STD_LOGIC_VECTOR(15 DOWNTO 0);
	
	
	component chipscope
		PORT (
		CONTROL0 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0));

	end component;
	
	component chipscope_ila
		PORT (
		 CONTROL : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
		 CLK : IN STD_LOGIC;
		 TRIG0 : IN STD_LOGIC_VECTOR(33 DOWNTO 0));

	end component;
	
	COMPONENT usb_top
	PORT(
		IFCLK : IN std_logic;
		CTL0 : IN std_logic;
		CTL1 : IN std_logic;
		CTL2 : IN std_logic;
		PA7 : IN std_logic;
		WAKEUP : IN std_logic;
		CLKOUT : IN std_logic;
		EP2_FULL : IN std_logic;
		EP4_FULL : IN std_logic;
		EP6_DATA : IN std_logic_vector(15 downto 0);
		EP6_EMPTY : IN std_logic;
		EP8_DATA : IN std_logic_vector(15 downto 0);
		EP8_EMPTY : IN std_logic;    
		FDD : INOUT std_logic_vector(15 downto 0);      
		PA0 : OUT std_logic;
		PA1 : OUT std_logic;
		PA2 : OUT std_logic;
		PA3 : OUT std_logic;
		PA4 : OUT std_logic;
		PA5 : OUT std_logic;
		PA6 : OUT std_logic;
		RDY0 : OUT std_logic;
		RDY1 : OUT std_logic;
		USB_RESET : OUT std_logic;
		FIFO_CLOCK : OUT std_logic;
		EP2_DATA : OUT std_logic_vector(15 downto 0);
		EP2_WRITE_ENABLE : OUT std_logic;
		EP4_DATA : OUT std_logic_vector(15 downto 0);
		EP4_WRITE_ENABLE : OUT std_logic;
		EP6_READ_ENABLE : OUT std_logic;
		EP8_READ_ENABLE : OUT std_logic
		);
	END COMPONENT;

	
begin
	--Port mapping
	
	FIFO_INP_0_EMPTY <= internal_FIFO_INP_0_EMPTY;
	FIFO_INP_0_DATA <= internal_FIFO_INP_0_READ_DATA;
	FIFO_INP_0_VALID <= internal_FIFO_INP_0_VALID;
	internal_FIFO_INP_0_READ_ENABLE <= FIFO_INP_0_RD_EN;

	FIFO_INP_1_EMPTY <= internal_FIFO_INP_1_EMPTY;
	FIFO_INP_1_DATA <= internal_FIFO_INP_1_READ_DATA;
	FIFO_INP_1_VALID <= internal_FIFO_INP_1_VALID;
	internal_FIFO_INP_1_READ_ENABLE <= FIFO_INP_1_RD_EN;

	FIFO_OUT_0_FULL  <= internal_FIFO_OUT_0_FULL;
	FIFO_OUT_1_FULL  <= internal_FIFO_OUT_1_FULL;
	internal_FIFO_OUT_0_WRITE_ENABLE <= FIFO_OUT_0_WR_EN;
	internal_FIFO_OUT_1_WRITE_ENABLE <= FIFO_OUT_1_WR_EN;
	internal_FIFO_OUT_0_WRITE_DATA <= FIFO_OUT_0_DATA;
	internal_FIFO_OUT_1_WRITE_DATA <= FIFO_OUT_1_DATA;
	
--	--Switch over to fiberoptic if USB connection is not present
--	internal_TOGGLE_DAQ_TO_FIBER <= not(internal_USB_PRESENT);
	internal_USB_RESET <= not(internal_USB_PRESENT);
	--When this happens, disable the transceivers to save power
	
	internal_FIFO_CLOCK <= internal_USB_CLOCK;
--	--Multiplex the fiberoptic and USB signals for the output FIFOs
--	map_clock_select : bufgmux
--	port map(
--		I0 => internal_USB_CLOCK,
--		I1 => internal_FIBER_USER_CLOCK,
--		O  => internal_FIFO_CLOCK,
--		S  => internal_TOGGLE_DAQ_TO_FIBER
--	);
	
	--The following two lines assumed the USER CLOCK can be reused.  This avoids consuming BUFG resources,
	--but I need to verify that this is really okay...
	internal_FIFO_OUT_0_READ_CLOCK <= internal_FIFO_CLOCK;
	internal_FIFO_OUT_1_READ_CLOCK <= internal_FIFO_CLOCK;
												 
	internal_FIFO_OUT_0_READ_ENABLE <= internal_USB_TX_0_READ_ENABLE ;
	internal_FIFO_OUT_1_READ_ENABLE <= internal_USB_TX_1_READ_ENABLE ;

	--Multiplex the fiberoptic and USB signals for the input FIFOs

	--As above, the following two lines assumed the USER CLOCK can be reused.  This avoids consuming BUFG resources,
	--but I need to verify that this is really okay...
	internal_FIFO_INP_0_WRITE_CLOCK <= internal_FIFO_CLOCK;
	internal_FIFO_INP_1_WRITE_CLOCK <= internal_FIFO_CLOCK;

	internal_FIFO_INP_0_WRITE_ENABLE <=  internal_USB_RX_0_WRITE_ENABLE ;
	internal_FIFO_INP_1_WRITE_ENABLE <=  internal_USB_RX_1_WRITE_ENABLE ;
	internal_FIFO_INP_0_WRITE_DATA  <=   (internal_USB_EP2_DATA_32BIT(15 downto 0) & internal_USB_EP2_DATA_32BIT(31 downto 16));
	internal_FIFO_INP_1_WRITE_DATA  <=   (internal_USB_EP4_DATA_32BIT(15 downto 0) & internal_USB_EP4_DATA_32BIT(31 downto 16));
	 
	

	
		
		
	--Instantiate the OUTPUT FIFOs
	map_output_fifo_0 : entity work.FIFO_OUT_0 --(Depth is 2048 32-bit words)
	PORT MAP (
		rst    => '0',
		wr_clk => FIFO_OUT_0_WR_CLK,
		rd_clk => internal_FIFO_OUT_0_READ_CLOCK,
		din    => internal_FIFO_OUT_0_WRITE_DATA,
		wr_en  => internal_FIFO_OUT_0_WRITE_ENABLE,
		rd_en  => internal_FIFO_OUT_0_READ_ENABLE,
		dout   => internal_FIFO_OUT_0_READ_DATA,
		full   => internal_FIFO_OUT_0_FULL,
		empty  => internal_FIFO_OUT_0_EMPTY,
		valid  => internal_FIFO_OUT_0_VALID
	);
	map_output_fifo_1 : entity work.FIFO_OUT_1 --(Depth is 512 32-bit words)
	PORT MAP (
		rst    => '0',
		wr_clk => FIFO_OUT_1_WR_CLK,
		rd_clk => internal_FIFO_OUT_1_READ_CLOCK,
		din    => internal_FIFO_OUT_1_WRITE_DATA,
		wr_en  => internal_FIFO_OUT_1_WRITE_ENABLE,
		rd_en  => internal_FIFO_OUT_1_READ_ENABLE,
		dout   => internal_FIFO_OUT_1_READ_DATA,
		full   => internal_FIFO_OUT_1_FULL,
		empty  => internal_FIFO_OUT_1_EMPTY,
		valid  => internal_FIFO_OUT_1_VALID
	);
	--Instantiate the INPUT FIFOs
	map_input_fifo_0 : entity work.FIFO_INP_0 -- (Depth is 512 32-bit words)
	PORT MAP (
		rst    => '0',
		wr_clk => internal_FIFO_INP_0_WRITE_CLOCK,
		rd_clk => FIFO_INP_0_RD_CLK,
		din    => internal_FIFO_INP_0_WRITE_DATA,
		wr_en  => internal_FIFO_INP_0_WRITE_ENABLE,
		rd_en  => internal_FIFO_INP_0_READ_ENABLE,
		dout   => internal_FIFO_INP_0_READ_DATA,
		full   => internal_FIFO_INP_0_FULL,
		empty  => internal_FIFO_INP_0_EMPTY,
		valid  => internal_FIFO_INP_0_VALID
	);
	map_input_fifo_1 : entity work.FIFO_INP_0 -- (Depth is 512 32-bit words) [same as the other input FIFO, for now]
	PORT MAP (
		rst    => '0',
		wr_clk => internal_FIFO_INP_1_WRITE_CLOCK,
		rd_clk => FIFO_INP_1_RD_CLK,
		din    => internal_FIFO_INP_1_WRITE_DATA,
		wr_en  => internal_FIFO_INP_1_WRITE_ENABLE,
		rd_en  => internal_FIFO_INP_1_READ_ENABLE,
		dout   => internal_FIFO_INP_1_READ_DATA,
		full   => internal_FIFO_INP_1_FULL,  
		empty  => internal_FIFO_INP_1_EMPTY,
		valid  => internal_FIFO_INP_1_VALID
	);



	--Synthesize with the USB interface
	synthesize_with_usb : if INCLUDE_USB = 1 generate
		--We need some logic here that interfaces between the 16-bit USB
		--bus and the 32-bit FIFOs.  This is for now implemented with
		--relatively small 16 <--> 32 FIFOs.
		-------Endpoint 2------
		map_fifo_wr16_rd32_EP2 : entity work.fifo_wr16_rd32
		port map(
			rst    => internal_USB_RESET,
			wr_clk => internal_USB_CLOCK,
			rd_clk => internal_USB_CLOCK,
			din    => internal_USB_EP2_DATA_16BIT,
			wr_en  => internal_USB_EP2_WRITE_ENABLE,
			rd_en  => internal_USB_EP2_READ_ENABLE_reg,
			dout   => internal_USB_EP2_DATA_32BIT,
			full   => internal_USB_EP2_FULL,
			empty  => internal_USB_EP2_EMPTY,
			valid  => internal_USB_RX_0_VALID
		);
		internal_USB_EP2_READ_ENABLE <= (not(internal_USB_EP2_EMPTY)) and (not(internal_FIFO_INP_0_FULL));
		internal_USB_RX_0_WRITE_ENABLE <= internal_USB_RX_0_VALID;
		process(internal_USB_CLOCK) begin
			if (rising_edge(internal_USB_CLOCK)) then
				internal_USB_EP2_READ_ENABLE_reg <= internal_USB_EP2_READ_ENABLE;
			end if;
		end process;
		-------Endpoint 4------
		map_fifo_wr16_rd32_EP4 : entity work.fifo_wr16_rd32
		port map(
			rst    => internal_USB_RESET,
			wr_clk => internal_USB_CLOCK,
			rd_clk => internal_USB_CLOCK,
			din    => internal_USB_EP4_DATA_16BIT,
			wr_en  => internal_USB_EP4_WRITE_ENABLE,
			rd_en  => internal_USB_EP4_READ_ENABLE_reg,
			dout   => internal_USB_EP4_DATA_32BIT,
			full   => internal_USB_EP4_FULL,
			empty  => internal_USB_EP4_EMPTY,
			valid  => internal_USB_RX_1_VALID
		);
		internal_USB_EP4_READ_ENABLE <= (not(internal_USB_EP4_EMPTY)) and (not(internal_FIFO_INP_1_FULL));
		internal_USB_RX_1_WRITE_ENABLE <= internal_USB_RX_1_VALID;
		process(internal_USB_CLOCK) begin
			if (rising_edge(internal_USB_CLOCK)) then
				internal_USB_EP4_READ_ENABLE_reg <= internal_USB_EP4_READ_ENABLE;
			end if;
		end process;
		-------Endpoint 6------
		map_fifo_wr32_rd16_EP6 : entity work.fifo_wr32_rd16
		port map(
			rst    => internal_USB_RESET,
			wr_clk => internal_USB_CLOCK,
			rd_clk => internal_USB_CLOCK,
			din    => internal_USB_EP6_DATA_32BIT_L2H,
			wr_en  => internal_USB_EP6_WRITE_ENABLE_reg,
			rd_en  => internal_USB_EP6_READ_ENABLE,
			dout   => internal_USB_EP6_DATA_16BIT,
			full   => internal_USB_EP6_FULL,
			empty  => internal_USB_EP6_EMPTY,
			valid  => open
		);
		
		internal_USB_EP6_DATA_32BIT_L2H <= (internal_USB_EP6_DATA_32BIT(15 downto 0) & internal_USB_EP6_DATA_32BIT(31 downto 16));
		
		internal_USB_EP6_DATA_32BIT <= internal_FIFO_OUT_0_READ_DATA;
		internal_USB_EP6_WRITE_ENABLE <= internal_FIFO_OUT_0_VALID;
		process(internal_USB_CLOCK) begin
			if (rising_edge(internal_USB_CLOCK)) then
				internal_USB_EP6_WRITE_ENABLE_reg <= internal_USB_EP6_WRITE_ENABLE;
			end if;
		end process;
		internal_USB_TX_0_READ_ENABLE <= (not(internal_FIFO_OUT_0_EMPTY)) and (not(internal_USB_EP6_FULL));
		-------Endpoint 8------
		map_fifo_wr32_rd16_EP8 : entity work.fifo_wr32_rd16
		port map(
			rst    => internal_USB_RESET,
			wr_clk => internal_USB_CLOCK,
			rd_clk => internal_USB_CLOCK,
			din    => internal_USB_EP8_DATA_32BIT_L2H,
			wr_en  => internal_USB_EP8_WRITE_ENABLE_reg,
			rd_en  => internal_USB_EP8_READ_ENABLE,
			dout   => internal_USB_EP8_DATA_16BIT,
			full   => internal_USB_EP8_FULL,
			empty  => internal_USB_EP8_EMPTY,
			valid  => open
		);
		
		internal_USB_EP8_DATA_32BIT_L2H <= internal_USB_EP8_DATA_32BIT(15 downto 0) & internal_USB_EP8_DATA_32BIT(31 downto 16);
		
		internal_USB_EP8_DATA_32BIT <= internal_FIFO_OUT_1_READ_DATA;
		internal_USB_EP8_WRITE_ENABLE <= internal_FIFO_OUT_1_VALID;
		process(internal_USB_CLOCK) begin
			if (rising_edge(internal_USB_CLOCK)) then
				internal_USB_EP8_WRITE_ENABLE_reg <= internal_USB_EP8_WRITE_ENABLE;
			end if;
		end process;
		internal_USB_TX_1_READ_ENABLE <= (not(internal_FIFO_OUT_1_EMPTY)) and (not(internal_USB_EP8_FULL));
		--Instantiate the USB top module
--		map_usb_interface : entity work.usb_top
		map_usb_interface : usb_top
		port map(
			IFCLK            => USB_IFCLK,
			CTL0             => USB_CTL0,
			CTL1             => USB_CTL1,
			CTL2             => USB_CTL2,
			FDD              => USB_FDD,
			PA0              => USB_PA0,
			PA1              => USB_PA1,
			PA2              => USB_PA2,
			PA3              => USB_PA3,
			PA4              => USB_PA4,
			PA5              => USB_PA5,
			PA6              => USB_PA6,
			PA7              => USB_PA7,
			RDY0             => USB_RDY0,
			RDY1             => USB_RDY1,
			WAKEUP           => USB_WAKEUP,
			CLKOUT           => USB_CLKOUT,
			--Reset signal from the USB code
			USB_RESET        => open,
			--Signals for interfacing to FIFOs
			FIFO_CLOCK       => internal_USB_CLOCK,
			EP2_DATA         => internal_USB_EP2_DATA_16BIT,
			EP2_WRITE_ENABLE => internal_USB_EP2_WRITE_ENABLE, 
			EP2_FULL         => internal_USB_EP2_FULL,
			EP4_DATA         => internal_USB_EP4_DATA_16BIT,
			EP4_WRITE_ENABLE => internal_USB_EP4_WRITE_ENABLE,
			EP4_FULL         => internal_USB_EP4_FULL,
			EP6_DATA         => internal_USB_EP6_DATA_16BIT,
			EP6_READ_ENABLE  => internal_USB_EP6_READ_ENABLE,
			EP6_EMPTY        => internal_USB_EP6_EMPTY,
			EP8_DATA         => internal_USB_EP8_DATA_16BIT,
			EP8_READ_ENABLE  => internal_USB_EP8_READ_ENABLE,
			EP8_EMPTY        => internal_USB_EP8_EMPTY
		);

	map_detect_usb : entity work.detect_usb
	port map(
		USB_CLOCK    => internal_USB_CLOCK,
		SYSTEM_CLOCK => SYSTEM_CLOCK,
		USB_PRESENT  => internal_USB_PRESENT
	);
	end generate synthesize_with_usb;
		
	cs_vio	:  chipscope
		port map(
		CONTROL0 => internal_cs_ila);


	
	cs_ila	:  chipscope_ila
		port map (
		 CONTROL => internal_cs_ila,
		 CLK 		=> clk_chipscope,
		 TRIG0 	=> ila_trigger);

	clk_chipscope 	<= SYSTEM_CLOCK;
	--ila_trigger		<= internal_USB_CLOCK & "0" & internal_FIFO_OUT_0_WRITE_DATA;
	
	--ila_trigger		<= internal_USB_CLOCK & "0" & internal_FIFO_INP_1_READ_DATA;
	
	
	
	

end Behavioral;

