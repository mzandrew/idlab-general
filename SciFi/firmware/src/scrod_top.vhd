----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:20:38 10/25/2012 
-- Design Name: 
-- Module Name:    scrod_top - Behavioral 
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
use work.asic_definitions_irs2_carrier_revA.all;
use work.CarrierRevA_DAC_definitions.all;

entity scrod_top is
	Port(
		BOARD_CLOCKP                : in  STD_LOGIC;
		BOARD_CLOCKN                : in  STD_LOGIC;
		LEDS                        : out STD_LOGIC_VECTOR(15 downto 0);
		------------------FTSW pins------------------
		RJ45_ACK_P                  : out std_logic;
		RJ45_ACK_N                  : out std_logic;			  
		RJ45_TRG_P                  : in std_logic;
		RJ45_TRG_N                  : in std_logic;			  			  
		RJ45_RSV_P                  : out std_logic;
		RJ45_RSV_N                  : out std_logic;
		RJ45_CLK_P                  : in std_logic;
		RJ45_CLK_N                  : in std_logic;
		---------Jumper for choosing FTSW clock------
		MONITOR_INPUT               : in  std_logic_vector(0 downto 0);
		------------------I2C pins-------------------
		--Bus A handles SCROD temperature sensor and SCROD EEPROM
		I2C_BUSA_SCL                : inout STD_LOGIC;
		I2C_BUSA_SDA                : inout STD_LOGIC;
		--Bus B handles SCROD fiberoptic transceiver 0
		I2C_BUSB_SCL                : inout STD_LOGIC;
		I2C_BUSB_SDA                : inout STD_LOGIC;
		--Bus C handles SCROD fiberoptic transceiver 1
		I2C_BUSC_SCL                : inout STD_LOGIC;
		I2C_BUSC_SDA                : inout STD_LOGIC;
		--Bus D handles carrier level temperature sensor
		--I2C_BUSD_SCL                : inout STD_LOGIC;
		--I2C_BUSD_SDA                : inout STD_LOGIC;
		
		----------------------------------------------
		------------Fiberoptic Pins-------------------
		----------------------------------------------
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
		FIBER_1_LINK_ERR            : out STD_LOGIC;
		---------------------------------------------
		------------------USB pins-------------------
		---------------------------------------------
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
		
		---------------------------------------------
		-------------SciFi + ASIC pins---------------
		---------------------------------------------
		--SciFi Motherboard Rev A spare pins
		SPARE_PIN						 : out STD_LOGIC_VECTOR(5 downto 0);	
		--Global Bus Signals
		BUS_SCLK                    : out STD_LOGIC;
		BUS_PCLK                    : out STD_LOGIC;
		BUS_REGCLR                  : out STD_LOGIC;
		BUS_TST_START					 : out STD_LOGIC;
		BUS_TST_BOIN_CLR			 	 : out STD_LOGIC;
		--ASIC specific pins
		TDC_CS_DAC						  : out STD_LOGIC_VECTOR(9 downto 0);	
		TDC_SDA_MUX						  : inout STD_LOGIC_VECTOR(9 downto 0);	
		TDC_SDA_MON						  : inout STD_LOGIC_VECTOR(9 downto 0);	
		TDC_SAMPLESEL_ANY				  : out STD_LOGIC_VECTOR(9 downto 0);	
		TDC_SIN						  	  : out STD_LOGIC_VECTOR(9 downto 0);	
		TDC_SHOUT						  : in STD_LOGIC_VECTOR(9 downto 0);	
		TDC_TSTOUT						  : in STD_LOGIC_VECTOR(9 downto 0);	
		TDC_SSPOUT						  : in STD_LOGIC_VECTOR(9 downto 0);	
		TDC_SSPIN						  : out STD_LOGIC_VECTOR(9 downto 0);	
		TDC_SSTIN						  : out STD_LOGIC_VECTOR(9 downto 0);	
		TDC_WR_ADVCLK					  : out STD_LOGIC_VECTOR(9 downto 0);	
		TDC_WR_STRB						  : out STD_LOGIC_VECTOR(9 downto 0);	
		TDC_TRG_1						  : in STD_LOGIC_VECTOR(9 downto 0);
		TDC_TRG_2						  : in STD_LOGIC_VECTOR(9 downto 0);			
		TDC_TRG_3						  : in STD_LOGIC_VECTOR(9 downto 0);
		TDC_TRG_4						  : in STD_LOGIC_VECTOR(9 downto 0);
		TDC_TRG_16						  : in STD_LOGIC_VECTOR(9 downto 0);
		TDC_TRGMON						  : in STD_LOGIC_VECTOR(9 downto 0);
		TDC_RCO							  : in STD_LOGIC_VECTOR(9 downto 0);	
		TDC_SR_CLOCK					  : out STD_LOGIC_VECTOR(9 downto 0)
	);
end scrod_top;

architecture Behavioral of scrod_top is
	signal internal_BOARD_CLOCK      : std_logic;
	signal internal_CLOCK_50MHz_BUFG : std_logic;
	signal internal_CLOCK_4MHz_BUFG  : std_logic;
	signal internal_CLOCK_ENABLE_I2C : std_logic;
	signal internal_CLOCK_SST_BUFG   : std_logic;
	signal internal_CLOCK_4xSST_BUFG : std_logic;
	
	signal internal_OUTPUT_REGISTERS : GPR;
	signal internal_INPUT_REGISTERS  : RR;
	
	--I2C signals
	signal internal_I2C_BUSA_BYTE_TO_SEND     : std_logic_vector(7 downto 0);
	signal internal_I2C_BUSA_BYTE_RECEIVED    : std_logic_vector(7 downto 0);
	signal internal_I2C_BUSA_ACKNOWLEDGED     : std_logic;
	signal internal_I2C_BUSA_SEND_START       : std_logic;
	signal internal_I2C_BUSA_SEND_BYTE        : std_logic;
	signal internal_I2C_BUSA_READ_BYTE        : std_logic;
	signal internal_I2C_BUSA_SEND_ACKNOWLEDGE : std_logic;
	signal internal_I2C_BUSA_SEND_STOP        : std_logic;
	signal internal_I2C_BUSA_BUSY             : std_logic;
	signal internal_I2C_BUSB_BYTE_TO_SEND     : std_logic_vector(7 downto 0);
	signal internal_I2C_BUSB_BYTE_RECEIVED    : std_logic_vector(7 downto 0);
	signal internal_I2C_BUSB_ACKNOWLEDGED     : std_logic;
	signal internal_I2C_BUSB_SEND_START       : std_logic;
	signal internal_I2C_BUSB_SEND_BYTE        : std_logic;
	signal internal_I2C_BUSB_READ_BYTE        : std_logic;
	signal internal_I2C_BUSB_SEND_ACKNOWLEDGE : std_logic;
	signal internal_I2C_BUSB_SEND_STOP        : std_logic;
	signal internal_I2C_BUSB_BUSY             : std_logic;
	signal internal_I2C_BUSC_BYTE_TO_SEND     : std_logic_vector(7 downto 0);
	signal internal_I2C_BUSC_BYTE_RECEIVED    : std_logic_vector(7 downto 0);
	signal internal_I2C_BUSC_ACKNOWLEDGED     : std_logic;
	signal internal_I2C_BUSC_SEND_START       : std_logic;
	signal internal_I2C_BUSC_SEND_BYTE        : std_logic;
	signal internal_I2C_BUSC_READ_BYTE        : std_logic;
	signal internal_I2C_BUSC_SEND_ACKNOWLEDGE : std_logic;
	signal internal_I2C_BUSC_SEND_STOP        : std_logic;
	signal internal_I2C_BUSC_BUSY             : std_logic;
	
	--Trigger readout
	signal internal_SOFTWARE_TRIGGER : std_logic;
	signal internal_HARDWARE_TRIGGER : std_logic;
	--Vetoes for the triggers
	signal internal_SOFTWARE_TRIGGER_VETO : std_logic;
	signal internal_HARDWARE_TRIGGER_VETO : std_logic;
	
	--SciFi- event builder related
	signal internal_WAVEFORM_FIFO_DATA_OUT       : std_logic_vector(31 downto 0);
	signal internal_WAVEFORM_FIFO_EMPTY          : std_logic;
	signal internal_WAVEFORM_FIFO_DATA_VALID     : std_logic;
	signal internal_WAVEFORM_FIFO_READ_CLOCK     : std_logic;
	signal internal_WAVEFORM_FIFO_READ_ENABLE    : std_logic;
	signal internal_WAVEFORM_PACKET_BUILDER_BUSY	: std_logic := '0';
	signal internal_WAVEFORM_PACKET_BUILDER_VETO : std_logic;
	
	--SciFi - ASIC DAC related
	signal SIN_OUT										: std_logic;
	signal SciFi_Trigger_Scaler					: std_logic_vector(15 downto 0);
	signal TDC_TRG_16_d				: std_logic_vector(9 downto 0);
	signal TDC_TRG_4_d					: std_logic_vector(9 downto 0);
	signal TDC_TRG_3_d					: std_logic_vector(9 downto 0);
	signal TDC_TRG_2_d					: std_logic_vector(9 downto 0);
	signal TDC_TRG_1_d					: std_logic_vector(9 downto 0);
	signal TDC_TRG_16_ext				: std_logic_vector(9 downto 0);
	signal TDC_TRG_4_ext					: std_logic_vector(9 downto 0);
	signal TDC_TRG_3_ext					: std_logic_vector(9 downto 0);
	signal TDC_TRG_2_ext					: std_logic_vector(9 downto 0);
	signal TDC_TRG_1_ext					: std_logic_vector(9 downto 0);
begin
	
	--Clock generation
	map_clock_generation : entity work.clock_generation
	port map ( 
		--Raw boad clock input
		BOARD_CLOCKP      => BOARD_CLOCKP,
		BOARD_CLOCKN      => BOARD_CLOCKN,
		--FTSW inputs
		RJ45_ACK_P        => RJ45_ACK_P,
		RJ45_ACK_N        => RJ45_ACK_N,			  
		RJ45_TRG_P        => RJ45_TRG_P,
		RJ45_TRG_N        => RJ45_TRG_N,			  			  
		RJ45_RSV_P        => RJ45_RSV_P,
		RJ45_RSV_N        => RJ45_RSV_N,
		RJ45_CLK_P        => RJ45_CLK_P,
		RJ45_CLK_N        => RJ45_CLK_N,
		--Trigger outputs from FTSW
		FTSW_TRIGGER      => internal_HARDWARE_TRIGGER,
		--Select signal between the two
		USE_LOCAL_CLOCK   => MONITOR_INPUT(0),
		--General output clocks
		CLOCK_50MHz_BUFG  => internal_CLOCK_50MHz_BUFG,
		CLOCK_4MHz_BUFG   => internal_CLOCK_4MHz_BUFG,
		--ASIC control clocks
		CLOCK_SSTx4_BUFG  => internal_CLOCK_4xSST_BUFG,
		CLOCK_SST_BUFG    => internal_CLOCK_SST_BUFG,
		--ASIC output clocks
		ASIC_SST          => open,
		ASIC_SSP          => open,
		ASIC_WR_STRB      => open,
		ASIC_WR_ADDR_LSB  => open,
		ASIC_WR_ADDR_LSB_RAW => open,
		--Output clock enable for I2C things
		I2C_CLOCK_ENABLE  => internal_CLOCK_ENABLE_I2C
	);	
	
	--Interface to I2C bus A
	map_i2c_busA : entity work.i2c_master
	port map(
		I2C_BYTE_TO_SEND  => internal_I2C_BUSA_BYTE_TO_SEND,
		I2C_BYTE_RECEIVED => internal_I2C_BUSA_BYTE_RECEIVED,
		ACKNOWLEDGED      => internal_I2C_BUSA_ACKNOWLEDGED,
		SEND_START        => internal_I2C_BUSA_SEND_START,
		SEND_BYTE         => internal_I2C_BUSA_SEND_BYTE,
		READ_BYTE         => internal_I2C_BUSA_READ_BYTE,
		SEND_ACKNOWLEDGE  => internal_I2C_BUSA_SEND_ACKNOWLEDGE,
		SEND_STOP         => internal_I2C_BUSA_SEND_STOP,
		BUSY              => internal_I2C_BUSA_BUSY,
		CLOCK             => internal_CLOCK_4MHz_BUFG,
		CLOCK_ENABLE      => internal_CLOCK_ENABLE_I2C,
		SCL               => I2C_BUSA_SCL,
		SDA               => I2C_BUSA_SDA
	);	
	--Interface to I2C bus B
	map_i2c_busB : entity work.i2c_master
	port map(
		I2C_BYTE_TO_SEND  => internal_I2C_BUSB_BYTE_TO_SEND,
		I2C_BYTE_RECEIVED => internal_I2C_BUSB_BYTE_RECEIVED,
		ACKNOWLEDGED      => internal_I2C_BUSB_ACKNOWLEDGED,
		SEND_START        => internal_I2C_BUSB_SEND_START,
		SEND_BYTE         => internal_I2C_BUSB_SEND_BYTE,
		READ_BYTE         => internal_I2C_BUSB_READ_BYTE,
		SEND_ACKNOWLEDGE  => internal_I2C_BUSB_SEND_ACKNOWLEDGE,
		SEND_STOP         => internal_I2C_BUSB_SEND_STOP,
		BUSY              => internal_I2C_BUSB_BUSY,
		CLOCK             => internal_CLOCK_4MHz_BUFG,
		CLOCK_ENABLE      => internal_CLOCK_ENABLE_I2C,
		SCL               => I2C_BUSB_SCL,
		SDA               => I2C_BUSB_SDA
	);	
	--Interface to I2C bus C
	map_i2c_busC : entity work.i2c_master
	port map(
		I2C_BYTE_TO_SEND  => internal_I2C_BUSC_BYTE_TO_SEND,
		I2C_BYTE_RECEIVED => internal_I2C_BUSC_BYTE_RECEIVED,
		ACKNOWLEDGED      => internal_I2C_BUSC_ACKNOWLEDGED,
		SEND_START        => internal_I2C_BUSC_SEND_START,
		SEND_BYTE         => internal_I2C_BUSC_SEND_BYTE,
		READ_BYTE         => internal_I2C_BUSC_READ_BYTE,
		SEND_ACKNOWLEDGE  => internal_I2C_BUSC_SEND_ACKNOWLEDGE,
		SEND_STOP         => internal_I2C_BUSC_SEND_STOP,
		BUSY              => internal_I2C_BUSC_BUSY,
		CLOCK             => internal_CLOCK_4MHz_BUFG,
		CLOCK_ENABLE      => internal_CLOCK_ENABLE_I2C,
		SCL               => I2C_BUSC_SCL,
		SDA               => I2C_BUSC_SDA
	);
	-----I2C Control for external DACs on each daughter card-----
	--map_CarrierRevA_I2C_DAC_Control : entity work.CarrierRevA_I2C_DAC_Control
	--	port map ( 
	--		INTENDED_DAC_VALUES	=> internal_DESIRED_DAC_VOLTAGES,
	--		UPDATE_STATUSES      => internal_DAC_UPDATE_STATUSES,
	--		CLK      	         => internal_CLOCK_4MHz_BUFG,
	--		CLK_ENABLE           => internal_CLOCK_ENABLE_I2C,
	--		SCL_C 		  			=> DAC_SCL_C,
	--		SDA_C		  				=> DAC_SDA_C
	--	);
	---------------------------------------------------------

	--Interface to the DAQ devices
	map_readout_interfaces : entity work.readout_interface
	port map ( 
		CLOCK                        => internal_CLOCK_50MHz_BUFG,

		OUTPUT_REGISTERS             => internal_OUTPUT_REGISTERS,
		INPUT_REGISTERS              => internal_INPUT_REGISTERS,
	
		--NOT original implementation - SciFi specific
		WAVEFORM_FIFO_DATA_IN        => internal_WAVEFORM_FIFO_DATA_OUT,
		WAVEFORM_FIFO_EMPTY          => internal_WAVEFORM_FIFO_EMPTY,
		WAVEFORM_FIFO_DATA_VALID     => internal_WAVEFORM_FIFO_DATA_VALID,
		WAVEFORM_FIFO_READ_CLOCK     => internal_WAVEFORM_FIFO_READ_CLOCK,
		WAVEFORM_FIFO_READ_ENABLE    => internal_WAVEFORM_FIFO_READ_ENABLE,
		WAVEFORM_PACKET_BUILDER_BUSY => internal_WAVEFORM_PACKET_BUILDER_BUSY,
		WAVEFORM_PACKET_BUILDER_VETO => internal_WAVEFORM_PACKET_BUILDER_VETO,
		
		--WAVEFORM ROI readout disable for now (SciFi implementation)
		--WAVEFORM_FIFO_DATA_IN        => (others=>'0'),
		--WAVEFORM_FIFO_EMPTY          => '1',
		--WAVEFORM_FIFO_DATA_VALID     => '0',
		--WAVEFORM_FIFO_READ_CLOCK     => open,
		--WAVEFORM_FIFO_READ_ENABLE    => open,
		--WAVEFORM_PACKET_BUILDER_BUSY => '0',
		--WAVEFORM_PACKET_BUILDER_VETO => open,

		FIBER_0_RXP                  => FIBER_0_RXP,
		FIBER_0_RXN                  => FIBER_0_RXN,
		FIBER_1_RXP                  => FIBER_1_RXP,
		FIBER_1_RXN                  => FIBER_1_RXN,
		FIBER_0_TXP                  => FIBER_0_TXP,
		FIBER_0_TXN                  => FIBER_0_TXN,
		FIBER_1_TXP                  => FIBER_1_TXP,
		FIBER_1_TXN                  => FIBER_1_TXN,
		FIBER_REFCLKP                => FIBER_REFCLKP,
		FIBER_REFCLKN                => FIBER_REFCLKN,
		FIBER_0_DISABLE_TRANSCEIVER  => FIBER_0_DISABLE_TRANSCEIVER,
		FIBER_1_DISABLE_TRANSCEIVER  => FIBER_1_DISABLE_TRANSCEIVER,
		FIBER_0_LINK_UP              => FIBER_0_LINK_UP,
		FIBER_1_LINK_UP              => FIBER_1_LINK_UP,
		FIBER_0_LINK_ERR             => FIBER_0_LINK_ERR,
		FIBER_1_LINK_ERR             => FIBER_1_LINK_ERR,

		USB_IFCLK                    => USB_IFCLK,
		USB_CTL0                     => USB_CTL0,
		USB_CTL1                     => USB_CTL1,
		USB_CTL2                     => USB_CTL2,
		USB_FDD                      => USB_FDD,
		USB_PA0                      => USB_PA0,
		USB_PA1                      => USB_PA1,
		USB_PA2                      => USB_PA2,
		USB_PA3                      => USB_PA3,
		USB_PA4                      => USB_PA4,
		USB_PA5                      => USB_PA5,
		USB_PA6                      => USB_PA6,
		USB_PA7                      => USB_PA7,
		USB_RDY0                     => USB_RDY0,
		USB_RDY1                     => USB_RDY1,
		USB_WAKEUP                   => USB_WAKEUP,
		USB_CLKOUT		              => USB_CLKOUT
	);

	--SciFi specific Module and signals
	Inst_SciFiTop: entity work.SciFiTop PORT MAP(
		CLK => internal_CLOCK_50MHz_BUFG,
		--Input/Control
		CONTROL_SCIFI => internal_OUTPUT_REGISTERS(4),
		CONTROL_SCIFI_REG0 => internal_OUTPUT_REGISTERS(5),
		CONTROL_SCIFI_REG1 => internal_OUTPUT_REGISTERS(6),
		CONTROL_SCIFI_REG2 => internal_OUTPUT_REGISTERS(7),
		CONTROL_SCIFI_REG3 => internal_OUTPUT_REGISTERS(8),
		CONTROL_SCIFI_REG4 => internal_OUTPUT_REGISTERS(9),
		--TRIGGER Signals
		TRIGGER_IN => internal_SOFTWARE_TRIGGER,	
		TRIGSCALAR => SciFi_Trigger_Scaler,
		--Global Bus Signals
		BUS_SCLK => BUS_SCLK,
		BUS_PCLK => BUS_PCLK,
		BUS_REGCLR => BUS_REGCLR,
		BUS_TST_START => BUS_TST_START,
		BUS_TST_BOIN_CLR => BUS_TST_BOIN_CLR,
		--ASIC specific
		TDC_CS_DAC => TDC_CS_DAC,
		TDC_SDA_MUX => TDC_SDA_MUX,
		TDC_SDA_MON => TDC_SDA_MON,
		TDC_SAMPLESEL_ANY => TDC_SAMPLESEL_ANY,
		TDC_SIN => TDC_SIN,
		TDC_SHOUT => TDC_SHOUT,
		TDC_TSTOUT => TDC_TSTOUT,
		TDC_SSPOUT => TDC_SSPOUT,
		TDC_SSPIN => TDC_SSPIN,
		TDC_SSTIN => TDC_SSTIN,
		TDC_WR_ADVCLK => TDC_WR_ADVCLK,
		TDC_WR_STRB => TDC_WR_STRB,
		TDC_TRG_1 => TDC_TRG_1,
		TDC_TRG_2 => TDC_TRG_2,
		TDC_TRG_3 => TDC_TRG_3,
		TDC_TRG_4 => TDC_TRG_4,
		TDC_TRG_16 => TDC_TRG_16,
		TDC_TRGMON => TDC_TRGMON,
		TDC_RCO => TDC_RCO,
		TDC_SR_CLOCK => TDC_SR_CLOCK,
		--event builder output
		READOUT_FIFO_DATA_OUT       => internal_WAVEFORM_FIFO_DATA_OUT,
		READOUT_FIFO_EMPTY          => internal_WAVEFORM_FIFO_EMPTY,
		READOUT_FIFO_DATA_VALID     => internal_WAVEFORM_FIFO_DATA_VALID,
		READOUT_FIFO_READ_CLOCK     => internal_WAVEFORM_FIFO_READ_CLOCK,
		READOUT_FIFO_READ_ENABLE    => internal_WAVEFORM_FIFO_READ_ENABLE,
		READOUT_PACKET_BUILDER_BUSY => internal_WAVEFORM_PACKET_BUILDER_BUSY,
		READOUT_PACKET_BUILDER_VETO => internal_WAVEFORM_PACKET_BUILDER_VETO
	);

	--------------------------------------------------
	-------General registers interfaced to DAQ -------
	--------------------------------------------------

	--------Output register mapping-------------------
	LEDS <= internal_OUTPUT_REGISTERS(0);                                               --Register 0: LEDs
	internal_I2C_BUSA_BYTE_TO_SEND         <= internal_OUTPUT_REGISTERS(1)(7 downto 0); --Register 1: I2C BusA interfaces
	internal_I2C_BUSA_SEND_START           <= internal_OUTPUT_REGISTERS(1)(8);
	internal_I2C_BUSA_SEND_BYTE            <= internal_OUTPUT_REGISTERS(1)(9);
	internal_I2C_BUSA_READ_BYTE            <= internal_OUTPUT_REGISTERS(1)(10);
	internal_I2C_BUSA_SEND_ACKNOWLEDGE     <= internal_OUTPUT_REGISTERS(1)(11);
	internal_I2C_BUSA_SEND_STOP            <= internal_OUTPUT_REGISTERS(1)(12);
	internal_I2C_BUSB_BYTE_TO_SEND         <= internal_OUTPUT_REGISTERS(2)(7 downto 0); --Register 2: I2C BusB interfaces
	internal_I2C_BUSB_SEND_START           <= internal_OUTPUT_REGISTERS(2)(8);
	internal_I2C_BUSB_SEND_BYTE            <= internal_OUTPUT_REGISTERS(2)(9);
	internal_I2C_BUSB_READ_BYTE            <= internal_OUTPUT_REGISTERS(2)(10);
	internal_I2C_BUSB_SEND_ACKNOWLEDGE     <= internal_OUTPUT_REGISTERS(2)(11);
	internal_I2C_BUSB_SEND_STOP            <= internal_OUTPUT_REGISTERS(2)(12);
	internal_I2C_BUSC_BYTE_TO_SEND         <= internal_OUTPUT_REGISTERS(3)(7 downto 0); --Register 3: I2C BusC interfaces
	internal_I2C_BUSC_SEND_START           <= internal_OUTPUT_REGISTERS(3)(8);
	internal_I2C_BUSC_SEND_BYTE            <= internal_OUTPUT_REGISTERS(3)(9);
	internal_I2C_BUSC_READ_BYTE            <= internal_OUTPUT_REGISTERS(3)(10);
	internal_I2C_BUSC_SEND_ACKNOWLEDGE     <= internal_OUTPUT_REGISTERS(3)(11);
	internal_I2C_BUSC_SEND_STOP            <= internal_OUTPUT_REGISTERS(3)(12);
	--SciFi Specific - registers 4 to 8, DACs for SciFi
	--...
	internal_SOFTWARE_TRIGGER					<= internal_OUTPUT_REGISTERS(165)(14);
	--...

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
	internal_INPUT_REGISTERS(N_GPR   ) <= internal_I2C_BUSA_ACKNOWLEDGED & internal_I2C_BUSA_BUSY & "000000" & internal_I2C_BUSA_BYTE_RECEIVED; --Register 256: I2C BusA interfaces
	internal_INPUT_REGISTERS(N_GPR+ 1) <= internal_I2C_BUSB_ACKNOWLEDGED & internal_I2C_BUSB_BUSY & "000000" & internal_I2C_BUSB_BYTE_RECEIVED; --Register 257: I2C BusB interfaces
	internal_INPUT_REGISTERS(N_GPR+ 2) <= internal_I2C_BUSC_ACKNOWLEDGED & internal_I2C_BUSC_BUSY & "000000" & internal_I2C_BUSC_BYTE_RECEIVED; --Register 257: I2C BusB interfaces
	--SciFi specific
	internal_INPUT_REGISTERS(N_GPR+ 3) <= SciFi_Trigger_Scaler;
	internal_INPUT_REGISTERS(N_GPR+ 4) <= x"ABCD";
	internal_INPUT_REGISTERS(N_GPR+ 5) <= x"00" & "000" & TDC_TRG_16_ext(0) & TDC_TRG_4_ext(0) & TDC_TRG_3_ext(0) & TDC_TRG_2_ext(0) & TDC_TRG_1_ext(0);
	internal_INPUT_REGISTERS(N_GPR+ 6) <= x"00" & "000" & TDC_TRG_16_ext(1) & TDC_TRG_4_ext(1) & TDC_TRG_3_ext(1) & TDC_TRG_2_ext(1) & TDC_TRG_1_ext(1);
	internal_INPUT_REGISTERS(N_GPR+ 7) <= x"00" & "000" & TDC_TRG_16_ext(2) & TDC_TRG_4_ext(2) & TDC_TRG_3_ext(2) & TDC_TRG_2_ext(2) & TDC_TRG_1_ext(2);
	internal_INPUT_REGISTERS(N_GPR+ 8) <= x"00" & "000" & TDC_TRG_16_ext(3) & TDC_TRG_4_ext(3) & TDC_TRG_3_ext(3) & TDC_TRG_2_ext(3) & TDC_TRG_1_ext(3);
	internal_INPUT_REGISTERS(N_GPR+ 9) <= x"00" & "000" & TDC_TRG_16_ext(4) & TDC_TRG_4_ext(4) & TDC_TRG_3_ext(4) & TDC_TRG_2_ext(4) & TDC_TRG_1_ext(4);
	internal_INPUT_REGISTERS(N_GPR+ 10) <= x"00" & "000" & TDC_TRG_16_ext(5) & TDC_TRG_4_ext(5) & TDC_TRG_3_ext(5) & TDC_TRG_2_ext(5) & TDC_TRG_1_ext(5);
	internal_INPUT_REGISTERS(N_GPR+ 11) <= x"00" & "000" & TDC_TRG_16_ext(6) & TDC_TRG_4_ext(6) & TDC_TRG_3_ext(6) & TDC_TRG_2_ext(6) & TDC_TRG_1_ext(6);
	internal_INPUT_REGISTERS(N_GPR+ 12) <= x"00" & "000" & TDC_TRG_16_ext(7) & TDC_TRG_4_ext(7) & TDC_TRG_3_ext(7) & TDC_TRG_2_ext(7) & TDC_TRG_1_ext(7);
	internal_INPUT_REGISTERS(N_GPR+ 13) <= x"00" & "000" & TDC_TRG_16_ext(8) & TDC_TRG_4_ext(8) & TDC_TRG_3_ext(8) & TDC_TRG_2_ext(8) & TDC_TRG_1_ext(8);
	internal_INPUT_REGISTERS(N_GPR+ 14) <= x"00" & "000" & TDC_TRG_16_ext(9) & TDC_TRG_4_ext(9) & TDC_TRG_3_ext(9) & TDC_TRG_2_ext(9) & TDC_TRG_1_ext(9);
	--...
	
	--extend trigger bit signals
	gen_trig_delay: for i in 0 to 9 generate
		process (internal_CLOCK_50MHz_BUFG) begin
			if(rising_edge(internal_CLOCK_50MHz_BUFG)) then
				TDC_TRG_1_d(i) <= TDC_TRG_1(i);
				TDC_TRG_2_d(i) <= TDC_TRG_2(i);
				TDC_TRG_3_d(i) <= TDC_TRG_3(i);
				TDC_TRG_4_d(i) <= TDC_TRG_4(i);
				TDC_TRG_16_d(i) <= TDC_TRG_16(i);
			end if;
		end process;		
		TDC_TRG_1_ext(i) <= TDC_TRG_1_d(i) or TDC_TRG_1(i);
		TDC_TRG_2_ext(i) <= TDC_TRG_2_d(i) or TDC_TRG_2(i);
		TDC_TRG_3_ext(i) <= TDC_TRG_3_d(i) or TDC_TRG_3(i);
		TDC_TRG_4_ext(i) <= TDC_TRG_4_d(i) or TDC_TRG_4(i);
		TDC_TRG_16_ext(i) <= TDC_TRG_16_d(i) or TDC_TRG_16(i);
	end generate;
	
end Behavioral;
