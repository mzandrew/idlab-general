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
use work.utilities.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity daq_fifo_layer is
	Generic (
		INCLUDE_AURORA : integer :=   1;
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
		USB_CLKOUT          : in  STD_LOGIC;

		--Signals that need to go to the top level for fiberoptic
		FIBER_0_RXP                 : in  STD_LOGIC;
		FIBER_0_RXN                 : in  STD_LOGIC;
		FIBER_1_RXP                 : in  STD_LOGIC;
		FIBER_1_RXN                 : in  STD_LOGIC;
		FIBER_0_TXP                 : out STD_LOGIC;
		FIBER_0_TXN                 : out STD_LOGIC;
		FIBER_1_TXP                 : out STD_LOGIC;
		FIBER_1_TXN                 : out STD_LOGIC;
		FIBER_REFCLKP               : in  STD_LOGIC;
		FIBER_REFCLKN               : in  STD_LOGIC;
		FIBER_0_DISABLE_TRANSCEIVER : out STD_LOGIC;
		FIBER_1_DISABLE_TRANSCEIVER : out STD_LOGIC;
		FIBER_0_LINK_UP             : out STD_LOGIC;
		FIBER_1_LINK_UP             : out STD_LOGIC;
		FIBER_0_LINK_ERR            : out STD_LOGIC;
		FIBER_1_LINK_ERR            : out STD_LOGIC

	);
end daq_fifo_layer;

architecture Behavioral of daq_fifo_layer is
	signal internal_TOGGLE_DAQ_TO_FIBER  : std_logic;

	signal internal_USB_PRESENT          : std_logic;

	signal internal_FIBER_0_LANE_UP      : std_logic;
	signal internal_FIBER_1_LANE_UP      : std_logic;
	signal internal_FIBER_0_CHANNEL_UP   : std_logic;
	signal internal_FIBER_1_CHANNEL_UP   : std_logic;
	signal internal_FIBER_0_LINK_UP      : std_logic;
	signal internal_FIBER_1_LINK_UP      : std_logic;
	signal internal_FIBER_0_LINK_ERR     : std_logic;
	signal internal_FIBER_1_LINK_ERR     : std_logic;
	signal internal_FIBER_0_HARD_ERR     : std_logic;
	signal internal_FIBER_1_HARD_ERR     : std_logic;
	signal internal_FIBER_0_SOFT_ERR     : std_logic;
	signal internal_FIBER_1_SOFT_ERR     : std_logic;
	signal internal_FIBER_0_TX_DATA_LSB_TO_MSB : std_logic_vector(0 to 31);
	signal internal_FIBER_1_TX_DATA_LSB_TO_MSB : std_logic_vector(0 to 31);
	signal internal_FIBER_0_RX_DATA_LSB_TO_MSB : std_logic_vector(0 to 31);
	signal internal_FIBER_1_RX_DATA_LSB_TO_MSB : std_logic_vector(0 to 31);
	signal internal_FIBER_0_TX_DATA_MSB_TO_LSB : std_logic_vector(31 downto 0);
	signal internal_FIBER_1_TX_DATA_MSB_TO_LSB : std_logic_vector(31 downto 0);
	signal internal_FIBER_0_RX_DATA_MSB_TO_LSB : std_logic_vector(31 downto 0);
	signal internal_FIBER_1_RX_DATA_MSB_TO_LSB : std_logic_vector(31 downto 0);
	signal internal_FIBER_0_TX_DATA_TVALID     : std_logic;
	signal internal_FIBER_1_TX_DATA_TVALID     : std_logic;
	signal internal_FIBER_0_TX_DATA_TREADY     : std_logic;
	signal internal_FIBER_1_TX_DATA_TREADY     : std_logic;
	signal internal_FIBER_0_TX_READ_ENABLE     : std_logic;
	signal internal_FIBER_1_TX_READ_ENABLE     : std_logic;
	signal internal_FIBER_0_RX_DATA_TVALID     : std_logic;
	signal internal_FIBER_1_RX_DATA_TVALID     : std_logic;
--	signal internal_FIBER_0_USER_CLOCK         : std_logic;
--	signal internal_FIBER_1_USER_CLOCK         : std_logic;
	signal internal_FIBER_USER_CLOCK           : std_logic;
	signal internal_FIBER_0_TX_DATA_TVALID_STATE_reg : std_logic_vector(1 downto 0) := (others => '0');
	signal internal_FIBER_1_TX_DATA_TVALID_STATE_reg : std_logic_vector(1 downto 0) := (others => '0');
	signal internal_FIBER_0_TX_DATA_TVALID_NEXT_STATE : std_logic_vector(1 downto 0) := (others => '0');
	signal internal_FIBER_1_TX_DATA_TVALID_NEXT_STATE : std_logic_vector(1 downto 0) := (others => '0');
	
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

	signal internal_FIFO_CLOCK                 : std_logic;

	signal internal_CHIPSCOPE_CONTROL          : std_logic_vector(35 downto 0);
	signal internal_CHIPSCOPE_SYNC_IN          : std_logic_vector(63 downto 0);
	signal internal_CHIPSCOPE_SYNC_OUT         : std_logic_vector(15 downto 0);
	signal internal_CHIPSCOPE_ILA              : std_logic_vector(127 downto 0);
	
begin
	--Port mapping
	FIBER_0_LINK_UP <= internal_FIBER_0_LINK_UP;
	FIBER_0_LINK_ERR <= internal_FIBER_0_LINK_ERR;
	FIBER_1_LINK_UP <= internal_FIBER_1_LINK_UP;
	FIBER_1_LINK_ERR <= internal_FIBER_1_LINK_ERR;

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
	
	--Switch over to fiberoptic if USB connection is not present
	internal_TOGGLE_DAQ_TO_FIBER <= not(internal_USB_PRESENT);
	internal_USB_RESET <= not(internal_USB_PRESENT);
	--When this happens, disable the transceivers to save power
	FIBER_0_DISABLE_TRANSCEIVER <= not(internal_TOGGLE_DAQ_TO_FIBER);
	FIBER_1_DISABLE_TRANSCEIVER <= not(internal_TOGGLE_DAQ_TO_FIBER);

	--Multiplex the fiberoptic and USB signals for the output FIFOs
	map_clock_select : bufgmux
	port map(
		I0 => internal_USB_CLOCK,
		I1 => internal_FIBER_USER_CLOCK,
		O  => internal_FIFO_CLOCK,
		S  => internal_TOGGLE_DAQ_TO_FIBER
	);
	
	--The following two lines assumed the USER CLOCK can be reused.  This avoids consuming BUFG resources,
	--but I need to verify that this is really okay...
	internal_FIFO_OUT_0_READ_CLOCK <= internal_FIFO_CLOCK;
	internal_FIFO_OUT_1_READ_CLOCK <= internal_FIFO_CLOCK;
												 
	internal_FIFO_OUT_0_READ_ENABLE <= internal_FIBER_0_TX_READ_ENABLE when (internal_TOGGLE_DAQ_TO_FIBER = '1') else
	                                   internal_USB_TX_0_READ_ENABLE when (internal_TOGGLE_DAQ_TO_FIBER = '0') else
                                      'X';
	internal_FIFO_OUT_1_READ_ENABLE <= internal_FIBER_1_TX_READ_ENABLE when (internal_TOGGLE_DAQ_TO_FIBER = '1') else
	                                   internal_USB_TX_1_READ_ENABLE when (internal_TOGGLE_DAQ_TO_FIBER = '0') else
                                      'X';

	--Multiplex the fiberoptic and USB signals for the input FIFOs

	--As above, the following two lines assumed the USER CLOCK can be reused.  This avoids consuming BUFG resources,
	--but I need to verify that this is really okay...
	internal_FIFO_INP_0_WRITE_CLOCK <= internal_FIFO_CLOCK;
	internal_FIFO_INP_1_WRITE_CLOCK <= internal_FIFO_CLOCK;

	internal_FIFO_INP_0_WRITE_ENABLE <= internal_FIBER_0_RX_DATA_TVALID when (internal_TOGGLE_DAQ_TO_FIBER = '1') else
	                                    internal_USB_RX_0_WRITE_ENABLE when (internal_TOGGLE_DAQ_TO_FIBER = '0') else
												  'X';
	internal_FIFO_INP_1_WRITE_ENABLE <= internal_FIBER_1_RX_DATA_TVALID when (internal_TOGGLE_DAQ_TO_FIBER = '1') else
	                                    internal_USB_RX_1_WRITE_ENABLE when (internal_TOGGLE_DAQ_TO_FIBER = '0') else
												  'X';
	internal_FIFO_INP_0_WRITE_DATA  <=  internal_FIBER_0_RX_DATA_MSB_TO_LSB when (internal_TOGGLE_DAQ_TO_FIBER = '1') else
	                                    (internal_USB_EP2_DATA_32BIT(15 downto 0) & internal_USB_EP2_DATA_32BIT(31 downto 16)) when (internal_TOGGLE_DAQ_TO_FIBER = '0') else
													(others => 'X');
	internal_FIFO_INP_1_WRITE_DATA  <=  internal_FIBER_1_RX_DATA_MSB_TO_LSB when (internal_TOGGLE_DAQ_TO_FIBER = '1') else
	                                    (internal_USB_EP4_DATA_32BIT(15 downto 0) & internal_USB_EP4_DATA_32BIT(31 downto 16))  when (internal_TOGGLE_DAQ_TO_FIBER = '0') else
													(others => 'X');

	
	--Instantiate the OUTPUT FIFOs
	map_output_fifo_0 : entity work.FIFO_OUT_0 --(Depth is 32k 32-bit words)
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

	--Synthesize with an Aurora Core
	synthesize_with_aurora : if INCLUDE_AURORA = 1 generate
		--We need some bridge logic between the Aurora AXI signals and the native FIFO signals
		--State machines to handle the read_enable and valid signals.
		--Fiber0: Asynchronous state logic for outputs
		process (internal_FIBER_0_TX_DATA_TVALID_STATE_reg, internal_FIBER_0_TX_DATA_TREADY, internal_FIFO_OUT_0_EMPTY) begin
			case(internal_FIBER_0_TX_DATA_TVALID_STATE_reg) is
				when "00" => --Idle state
					internal_FIBER_0_TX_READ_ENABLE <= '0';
					internal_FIBER_0_TX_DATA_TVALID <= '0';
				when "01" => --Fetch data
					internal_FIBER_0_TX_READ_ENABLE <= '1';
					internal_FIBER_0_TX_DATA_TVALID <= '0';
				when "10" => --Should now have valid data on the bus, see if it's accepted
					internal_FIBER_0_TX_DATA_TVALID <= '1';
					if (internal_FIBER_0_TX_DATA_TREADY = '1' and internal_FIFO_OUT_0_EMPTY = '0') then
						internal_FIBER_0_TX_READ_ENABLE <= '1';
					else 
						internal_FIBER_0_TX_READ_ENABLE <= '0';
					end if;
				when "11" => --Pause to wait for transmission of this word
					internal_FIBER_0_TX_READ_ENABLE <= '0';
					internal_FIBER_0_TX_DATA_TVALID <= '1';
				when others =>
					internal_FIBER_0_TX_READ_ENABLE <= '0';
					internal_FIBER_0_TX_DATA_TVALID <= '0';
			end case;
		end process;
		--Fiber0: Next state logic
		process (internal_FIBER_0_TX_DATA_TVALID_STATE_reg, internal_FIFO_OUT_0_EMPTY, internal_FIBER_0_TX_DATA_TREADY) begin
			case(internal_FIBER_0_TX_DATA_TVALID_STATE_reg) is
				when "00" => --Idle state
					if (internal_FIFO_OUT_0_EMPTY = '0') then
						internal_FIBER_0_TX_DATA_TVALID_NEXT_STATE <= "01";
					else 
						internal_FIBER_0_TX_DATA_TVALID_NEXT_STATE <= "00";
					end if;
				when "01" => --Fetch data
					internal_FIBER_0_TX_DATA_TVALID_NEXT_STATE <= "10";
				when "10" =>
					if (internal_FIBER_0_TX_DATA_TREADY = '1' and internal_FIFO_OUT_0_EMPTY = '0') then
						internal_FIBER_0_TX_DATA_TVALID_NEXT_STATE <= "10";
					elsif (internal_FIBER_0_TX_DATA_TREADY = '0') then
						internal_FIBER_0_TX_DATA_TVALID_NEXT_STATE <= "11";			
					else
						internal_FIBER_0_TX_DATA_TVALID_NEXT_STATE <= "00";
					end if;
				when "11" => --Pause
					if (internal_FIBER_0_TX_DATA_TREADY = '0') then
						internal_FIBER_0_TX_DATA_TVALID_NEXT_STATE <= "11";
					elsif (internal_FIFO_OUT_0_EMPTY = '0') then
						internal_FIBER_0_TX_DATA_TVALID_NEXT_STATE <= "01";
					else
						internal_FIBER_0_TX_DATA_TVALID_NEXT_STATE <= "00";
					end if;
				when others => 
					internal_FIBER_0_TX_DATA_TVALID_NEXT_STATE <= "00";
			end case;
		end process;
		--Fiber0: Next state register
		process (internal_FIBER_USER_CLOCK) begin
			if (rising_edge(internal_FIBER_USER_CLOCK)) then
				internal_FIBER_0_TX_DATA_TVALID_STATE_reg <= internal_FIBER_0_TX_DATA_TVALID_NEXT_STATE;
			end if;
		end process;
		--Fiber1: Asynchronous state logic for outputs
		process (internal_FIBER_1_TX_DATA_TVALID_STATE_reg, internal_FIBER_1_TX_DATA_TREADY, internal_FIFO_OUT_1_EMPTY) begin
			case(internal_FIBER_1_TX_DATA_TVALID_STATE_reg) is
				when "00" => --Idle state
					internal_FIBER_1_TX_READ_ENABLE <= '0';
					internal_FIBER_1_TX_DATA_TVALID <= '0';
				when "01" => --Fetch data
					internal_FIBER_1_TX_READ_ENABLE <= '1';
					internal_FIBER_1_TX_DATA_TVALID <= '0';
				when "10" => --Should now have valid data on the bus, see if it's accepted
					internal_FIBER_1_TX_DATA_TVALID <= '1';
					if (internal_FIBER_1_TX_DATA_TREADY = '1' and internal_FIFO_OUT_1_EMPTY = '0') then
						internal_FIBER_1_TX_READ_ENABLE <= '1';
					else 
						internal_FIBER_1_TX_READ_ENABLE <= '0';
					end if;
				when "11" => --Pause to wait for transmission of this word
					internal_FIBER_1_TX_READ_ENABLE <= '0';
					internal_FIBER_1_TX_DATA_TVALID <= '1';
				when others =>
					internal_FIBER_1_TX_READ_ENABLE <= '0';
					internal_FIBER_1_TX_DATA_TVALID <= '0';
			end case;
		end process;
		--Fiber1: Next state logic
		process (internal_FIBER_1_TX_DATA_TVALID_STATE_reg, internal_FIFO_OUT_1_EMPTY, internal_FIBER_1_TX_DATA_TREADY) begin
			case(internal_FIBER_1_TX_DATA_TVALID_STATE_reg) is
				when "00" => --Idle state
					if (internal_FIFO_OUT_1_EMPTY = '0') then
						internal_FIBER_1_TX_DATA_TVALID_NEXT_STATE <= "01";
					else 
						internal_FIBER_1_TX_DATA_TVALID_NEXT_STATE <= "00";
					end if;
				when "01" => --Fetch data
					internal_FIBER_1_TX_DATA_TVALID_NEXT_STATE <= "10";
				when "10" =>
					if (internal_FIBER_1_TX_DATA_TREADY = '1' and internal_FIFO_OUT_1_EMPTY = '0') then
						internal_FIBER_1_TX_DATA_TVALID_NEXT_STATE <= "10";
					elsif (internal_FIBER_1_TX_DATA_TREADY = '0') then
						internal_FIBER_1_TX_DATA_TVALID_NEXT_STATE <= "11";			
					else
						internal_FIBER_1_TX_DATA_TVALID_NEXT_STATE <= "00";
					end if;
				when "11" => --Pause
					if (internal_FIBER_1_TX_DATA_TREADY = '0') then
						internal_FIBER_1_TX_DATA_TVALID_NEXT_STATE <= "11";
					elsif (internal_FIFO_OUT_1_EMPTY = '0') then
						internal_FIBER_1_TX_DATA_TVALID_NEXT_STATE <= "01";
					else
						internal_FIBER_1_TX_DATA_TVALID_NEXT_STATE <= "00";
					end if;
				when others => 
					internal_FIBER_1_TX_DATA_TVALID_NEXT_STATE <= "00";
			end case;
		end process;
		--Fiber1: Next state register
		process (internal_FIBER_USER_CLOCK) begin
			if (rising_edge(internal_FIBER_USER_CLOCK)) then
				internal_FIBER_1_TX_DATA_TVALID_STATE_reg <= internal_FIBER_1_TX_DATA_TVALID_NEXT_STATE;
			end if;
		end process;		
		--The bit ordering of AXI is the reverse of the FIFO (and what we usually use)
		internal_FIBER_0_TX_DATA_MSB_TO_LSB <= internal_FIFO_OUT_0_READ_DATA;  
		internal_FIBER_1_TX_DATA_MSB_TO_LSB <= internal_FIFO_OUT_1_READ_DATA;  
		--We need to do some bit reversing since the Aurora protocol goes LSB to MSB, and 
		--we typically go the other way around.
			--2012-11-06: data is coming out bit reversed... does Aurora do this reverse for us?  Removing the reverses.
			--            This fixed the problem.  But I still would like to delve into Aurora to see why this isn't necessary.  -KN
--		internal_FIBER_0_TX_DATA_LSB_TO_MSB <= reverse(internal_FIBER_0_TX_DATA_MSB_TO_LSB);
--		internal_FIBER_1_TX_DATA_LSB_TO_MSB <= reverse(internal_FIBER_1_TX_DATA_MSB_TO_LSB);
--		internal_FIBER_0_RX_DATA_MSB_TO_LSB <= reverse(internal_FIBER_0_RX_DATA_LSB_TO_MSB);
--		internal_FIBER_1_RX_DATA_MSB_TO_LSB <= reverse(internal_FIBER_1_RX_DATA_LSB_TO_MSB);
		internal_FIBER_0_TX_DATA_LSB_TO_MSB <= internal_FIBER_0_TX_DATA_MSB_TO_LSB;
		internal_FIBER_1_TX_DATA_LSB_TO_MSB <= internal_FIBER_1_TX_DATA_MSB_TO_LSB;
		internal_FIBER_0_RX_DATA_MSB_TO_LSB <= internal_FIBER_0_RX_DATA_LSB_TO_MSB;
		internal_FIBER_1_RX_DATA_MSB_TO_LSB <= internal_FIBER_1_RX_DATA_LSB_TO_MSB;
		--Combine the diagnostic signals into single bits (this can be undone later if we really need
		--access to the individual bits
		internal_FIBER_0_LINK_UP  <= internal_FIBER_0_LANE_UP and internal_FIBER_0_CHANNEL_UP;
		internal_FIBER_1_LINK_UP  <= internal_FIBER_1_LANE_UP and internal_FIBER_1_CHANNEL_UP;
		internal_FIBER_0_LINK_ERR <= internal_FIBER_0_HARD_ERR or internal_FIBER_0_SOFT_ERR;
		internal_FIBER_1_LINK_ERR <= internal_FIBER_1_HARD_ERR or internal_FIBER_1_SOFT_ERR;
		--Instantiate the Aurora interfaces
		map_two_lane_aurora_interface : entity work.two_lane_aurora_interface
		generic map(
			USE_CHIPSCOPE          => 0,
			SIM_GTPRESET_SPEEDUP   => 1 --Set to 1 to speed up sim reset
		)
		port map (
		-- User I/O
			HARD_ERR_0          => internal_FIBER_0_HARD_ERR,   --out
			HARD_ERR_1          => internal_FIBER_1_HARD_ERR,   --out
			SOFT_ERR_0          => internal_FIBER_0_SOFT_ERR,   --out
			SOFT_ERR_1          => internal_FIBER_1_SOFT_ERR,   --out
			LANE_UP_0           => internal_FIBER_0_LANE_UP,    --out
			LANE_UP_1           => internal_FIBER_1_LANE_UP,    --out
			CHANNEL_UP_0        => internal_FIBER_0_CHANNEL_UP, --out
			CHANNEL_UP_1        => internal_FIBER_1_CHANNEL_UP, --out
			TX_DATA_0           => internal_FIBER_0_TX_DATA_LSB_TO_MSB, --in
			TX_DATA_1           => internal_FIBER_1_TX_DATA_LSB_TO_MSB, --in
			TX_DATA_TVALID_0    => internal_FIBER_0_TX_DATA_TVALID, --in
			TX_DATA_TVALID_1    => internal_FIBER_1_TX_DATA_TVALID, --in
			TX_DATA_TREADY_0    => internal_FIBER_0_TX_DATA_TREADY, --out
			TX_DATA_TREADY_1    => internal_FIBER_1_TX_DATA_TREADY, --out
			RX_DATA_0           => internal_FIBER_0_RX_DATA_LSB_TO_MSB, --out
			RX_DATA_1           => internal_FIBER_1_RX_DATA_LSB_TO_MSB, --out
			RX_DATA_TVALID_0    => internal_FIBER_0_RX_DATA_TVALID, --out
			RX_DATA_TVALID_1    => internal_FIBER_1_RX_DATA_TVALID, --out
			USER_CLOCK_0        => internal_FIBER_USER_CLOCK,
			USER_CLOCK_1        => open,
--			RESET               => , --in
--			INIT_CLK            => , --in
--			GT_RESET_IN         => , --in
		-- Clocks
			GTPD2_P             => FIBER_REFCLKP, --in
			GTPD2_N             => FIBER_REFCLKN, --in
		-- GT I/O
			RXP_0               => FIBER_0_RXP, --in
			RXN_0               => FIBER_0_RXN, --in
			RXP_1               => FIBER_1_RXP, --in
			RXN_1               => FIBER_1_RXN, --in
			TXP_0               => FIBER_0_TXP, --out
			TXN_0               => FIBER_0_TXN, --out
			TXP_1               => FIBER_1_TXP, --out
			TXN_1               => FIBER_1_TXN --out
		);
	end generate synthesize_with_aurora;



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
			din    => (internal_USB_EP6_DATA_32BIT(15 downto 0) & internal_USB_EP6_DATA_32BIT(31 downto 16)),
			wr_en  => internal_USB_EP6_WRITE_ENABLE_reg,
			rd_en  => internal_USB_EP6_READ_ENABLE,
			dout   => internal_USB_EP6_DATA_16BIT,
			full   => internal_USB_EP6_FULL,
			empty  => internal_USB_EP6_EMPTY,
			valid  => open
		);
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
			din    => (internal_USB_EP8_DATA_32BIT(15 downto 0) & internal_USB_EP8_DATA_32BIT(31 downto 16)),
			wr_en  => internal_USB_EP8_WRITE_ENABLE_reg,
			rd_en  => internal_USB_EP8_READ_ENABLE,
			dout   => internal_USB_EP8_DATA_16BIT,
			full   => internal_USB_EP8_FULL,
			empty  => internal_USB_EP8_EMPTY,
			valid  => open
		);
		internal_USB_EP8_DATA_32BIT <= internal_FIFO_OUT_1_READ_DATA;
		internal_USB_EP8_WRITE_ENABLE <= internal_FIFO_OUT_1_VALID;
		process(internal_USB_CLOCK) begin
			if (rising_edge(internal_USB_CLOCK)) then
				internal_USB_EP8_WRITE_ENABLE_reg <= internal_USB_EP8_WRITE_ENABLE;
			end if;
		end process;
		internal_USB_TX_1_READ_ENABLE <= (not(internal_FIFO_OUT_1_EMPTY)) and (not(internal_USB_EP8_FULL));
		--Instantiate the USB top module
		map_usb_interface : entity work.usb_top
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
	
	synthesize_without_usb : if INCLUDE_USB = 0 generate
		internal_USB_PRESENT <= '0';
	end generate synthesize_without_USB;


--	i_icon : entity work.s6_icon
--	port map(
--		CONTROL0 => internal_CHIPSCOPE_CONTROL
--	);
--	
--	i_vio : entity work.s6_vio
--	port map(
--		CONTROL  => internal_CHIPSCOPE_CONTROL,
--		CLK      => internal_FIFO_CLOCK,
--		SYNC_IN  => internal_CHIPSCOPE_SYNC_IN,
--		SYNC_OUT => internal_CHIPSCOPE_SYNC_OUT
--	);
--	
--	i_ila : entity work.s6_ila
--	port map(
--		CONTROL => internal_CHIPSCOPE_CONTROL,
--		CLK     => internal_FIFO_CLOCK,
--		TRIG0   => internal_CHIPSCOPE_ILA
--	);
--
--	internal_CHIPSCOPE_SYNC_IN(0)  <= internal_TOGGLE_DAQ_TO_FIBER;
--	internal_CHIPSCOPE_SYNC_IN(1)  <= internal_FIFO_OUT_0_EMPTY;
--	internal_CHIPSCOPE_SYNC_IN(2)  <= internal_FIFO_OUT_1_EMPTY;
--	internal_CHIPSCOPE_SYNC_IN(3)  <= internal_FIFO_INP_0_FULL;
--	internal_CHIPSCOPE_SYNC_IN(4)  <= internal_FIFO_INP_1_FULL;
--	internal_CHIPSCOPE_SYNC_IN(5)  <= internal_USB_EP2_FULL;
--	internal_CHIPSCOPE_SYNC_IN(6)  <= internal_USB_EP2_EMPTY;
--	internal_CHIPSCOPE_SYNC_IN(7)  <= internal_USB_EP4_FULL;
--	internal_CHIPSCOPE_SYNC_IN(8)  <= internal_USB_EP4_EMPTY;
--	internal_CHIPSCOPE_SYNC_IN(9)  <= internal_USB_EP6_FULL;
--	internal_CHIPSCOPE_SYNC_IN(10) <= internal_USB_EP6_EMPTY;
--	internal_CHIPSCOPE_SYNC_IN(11) <= internal_USB_EP8_FULL;
--	internal_CHIPSCOPE_SYNC_IN(12) <= internal_USB_EP8_EMPTY;
--	internal_CHIPSCOPE_SYNC_IN(28 downto 13) <= internal_USB_EP2_DATA_16BIT;
--	internal_CHIPSCOPE_SYNC_IN(44 downto 29) <= internal_USB_EP6_DATA_16BIT;
--
--	internal_CHIPSCOPE_ILA(0)             <= internal_TOGGLE_DAQ_TO_FIBER;
--	internal_CHIPSCOPE_ILA(1)             <= internal_FIFO_OUT_0_EMPTY;
--	internal_CHIPSCOPE_ILA(2)             <= internal_FIFO_OUT_0_FULL;
--	internal_CHIPSCOPE_ILA(3)             <= internal_FIFO_OUT_0_READ_ENABLE;
--	internal_CHIPSCOPE_ILA(4)             <= internal_FIFO_OUT_0_WRITE_ENABLE;
--	internal_CHIPSCOPE_ILA(5)             <= internal_FIFO_OUT_0_VALID;
--	internal_CHIPSCOPE_ILA(19 downto 18)  <= internal_FIBER_0_TX_DATA_TVALID_NEXT_STATE;
--	internal_CHIPSCOPE_ILA(21 downto 20)  <= internal_FIBER_0_TX_DATA_TVALID_STATE_reg;
--	internal_CHIPSCOPE_ILA(53 downto 22)  <= internal_FIFO_INP_0_WRITE_DATA;
--	internal_CHIPSCOPE_ILA(54)            <= internal_FIFO_INP_0_EMPTY;
--	internal_CHIPSCOPE_ILA(55)            <= internal_FIFO_INP_0_FULL;
--	internal_CHIPSCOPE_ILA(56)            <= internal_FIFO_INP_0_READ_ENABLE;
--	internal_CHIPSCOPE_ILA(57)            <= internal_FIFO_INP_0_WRITE_ENABLE;
--	internal_CHIPSCOPE_ILA(58)            <= internal_FIFO_INP_0_VALID;
--	internal_CHIPSCOPE_ILA(90 downto 59)  <= internal_FIBER_0_RX_DATA_LSB_TO_MSB;
--	internal_CHIPSCOPE_ILA(91)            <= internal_FIBER_0_TX_READ_ENABLE;
--	internal_CHIPSCOPE_ILA(92)            <= internal_FIBER_0_TX_DATA_TVALID;
--	internal_CHIPSCOPE_ILA(124 downto 93) <= internal_FIFO_OUT_0_READ_DATA;
--	internal_CHIPSCOPE_ILA(125)           <= internal_FIBER_0_TX_DATA_TREADY;
--	internal_CHIPSCOPE_ILA(126)           <= internal_FIBER_0_RX_DATA_TVALID;
--	internal_CHIPSCOPE_ILA(127)           <= internal_FIBER_0_LINK_ERR;


end Behavioral;

