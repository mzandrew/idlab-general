-- (c) Copyright 2008 Xilinx, Inc. All rights reserved.
--
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
--
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
--
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
-- 
-- 
---------------------------------------------------------------------------------------------
--  AURORA_EXAMPLE
--
--  Aurora Generator
--
--
--
--  Description: Sample Instantiation of a 1 4-byte lane module.
--               Only tests initialization in hardware.
--
--         

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_MISC.all;
use WORK.AURORA_PKG.all;

-- synthesis translate_off
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
-- synthesis translate_on

entity two_lane_aurora_interface is
   generic(
           USE_CHIPSCOPE          : integer :=   1;
           SIM_GTPRESET_SPEEDUP   : integer :=   1      --Set to 1 to speed up sim reset
         );
    port (

    -- User I/O

--            RESET             : in std_logic;
            HARD_ERR_0          : out std_logic;
            HARD_ERR_1          : out std_logic;
            SOFT_ERR_0          : out std_logic;
            SOFT_ERR_1          : out std_logic;
            LANE_UP_0           : out std_logic;
            LANE_UP_1           : out std_logic;
            CHANNEL_UP_0        : out std_logic;
            CHANNEL_UP_1        : out std_logic;
--           INIT_CLK           : in std_logic;
--            GT_RESET_IN       : in  std_logic;

				TX_DATA_0           : in  std_logic_vector(0 to 31);
				TX_DATA_1           : in  std_logic_vector(0 to 31);
				TX_DATA_TVALID_0    : in  std_logic;
				TX_DATA_TVALID_1    : in  std_logic;
				TX_DATA_TREADY_0    : out std_logic;
				TX_DATA_TREADY_1    : out std_logic;

				RX_DATA_0           : out std_logic_vector(0 to 31);
				RX_DATA_1           : out std_logic_vector(0 to 31);
				RX_DATA_TVALID_0    : out std_logic;
				RX_DATA_TVALID_1    : out std_logic;
				
				USER_CLOCK_0        : out std_logic;
				USER_CLOCK_1        : out std_logic;

    -- Clocks

           GTPD2_P    : in  std_logic;
           GTPD2_N    : in  std_logic;

   -- GT I/O

            RXP_0               : in std_logic;
            RXN_0               : in std_logic;
            RXP_1               : in std_logic;
            RXN_1               : in std_logic;
            TXP_0               : out std_logic;
            TXN_0               : out std_logic;
            TXP_1               : out std_logic;
            TXN_1               : out std_logic

         );

end two_lane_aurora_interface;

architecture MAPPED of two_lane_aurora_interface is
  attribute core_generation_info           : string;
  attribute core_generation_info of MAPPED : architecture is "aurora_interface_0,aurora_8b10b_v6_2,{user_interface=AXI_4_Streaming, backchannel_mode=Sidebands, c_aurora_lanes=1, c_column_used=None, c_gt_clock_1=GTPD2, c_gt_clock_2=None, c_gt_loc_1=X, c_gt_loc_10=X, c_gt_loc_11=X, c_gt_loc_12=X, c_gt_loc_13=X, c_gt_loc_14=X, c_gt_loc_15=X, c_gt_loc_16=X, c_gt_loc_17=X, c_gt_loc_18=X, c_gt_loc_19=X, c_gt_loc_2=X, c_gt_loc_20=X, c_gt_loc_21=X, c_gt_loc_22=X, c_gt_loc_23=X, c_gt_loc_24=X, c_gt_loc_25=X, c_gt_loc_26=X, c_gt_loc_27=X, c_gt_loc_28=X, c_gt_loc_29=X, c_gt_loc_3=X, c_gt_loc_30=X, c_gt_loc_31=X, c_gt_loc_32=X, c_gt_loc_33=X, c_gt_loc_34=X, c_gt_loc_35=X, c_gt_loc_36=X, c_gt_loc_37=X, c_gt_loc_38=X, c_gt_loc_39=X, c_gt_loc_4=X, c_gt_loc_40=X, c_gt_loc_41=X, c_gt_loc_42=X, c_gt_loc_43=X, c_gt_loc_44=X, c_gt_loc_45=X, c_gt_loc_46=X, c_gt_loc_47=X, c_gt_loc_48=X, c_gt_loc_5=1, c_gt_loc_6=X, c_gt_loc_7=X, c_gt_loc_8=X, c_gt_loc_9=X, c_lane_width=4, c_line_rate=3.125, c_nfc=false, c_nfc_mode=IMM, c_refclk_frequency=156.25, c_simplex=false, c_simplex_mode=TX, c_stream=true, c_ufc=false, flow_mode=None, interface_mode=Streaming, dataflow_config=Duplex}";

-- Parameter Declarations --

    constant DLY : time := 1 ns;

-- External Register Declarations --

    signal HARD_ERR_0_Buffer    : std_logic;
    signal HARD_ERR_1_Buffer    : std_logic;
    signal SOFT_ERR_0_Buffer    : std_logic;
    signal SOFT_ERR_1_Buffer    : std_logic;
    signal LANE_UP_0_Buffer     : std_logic;
    signal LANE_UP_1_Buffer     : std_logic;
    signal CHANNEL_UP_0_Buffer  : std_logic;
    signal CHANNEL_UP_1_Buffer  : std_logic;
    signal TXP_0_Buffer         : std_logic;
    signal TXN_0_Buffer         : std_logic;
    signal TXP_1_Buffer         : std_logic;
    signal TXN_1_Buffer         : std_logic;

-- Internal Register Declarations --

    signal gt_reset_i         : std_logic; 
    signal system_reset_i     : std_logic;
 
-- Wire Declarations --

    -- Stream TX Interface

--    signal tx_d_0_i             : std_logic_vector(0 to 31);
--    signal tx_d_1_i             : std_logic_vector(0 to 31);

    -- Stream RX Interface

--    signal rx_d_0_i             : std_logic_vector(0 to 31);
--    signal rx_d_1_i             : std_logic_vector(0 to 31);


    -- V5 Reference Clock Interface
    signal GTPD2_left_i      : std_logic;

    -- Error Detection Interface

    signal hard_err_0_i       : std_logic;
    signal hard_err_1_i       : std_logic;
    signal soft_err_0_i       : std_logic;
    signal soft_err_1_i       : std_logic;

    -- Status

    signal channel_up_0_i       : std_logic;
    signal channel_up_1_i       : std_logic;
    signal lane_up_0_i          : std_logic;
    signal lane_up_1_i          : std_logic;

    -- Clock Compensation Control Interface

    signal warn_cc_0_i          : std_logic;
    signal warn_cc_1_i          : std_logic;
    signal do_cc_0_i            : std_logic;
    signal do_cc_1_i            : std_logic;

    -- System Interface

    signal pll_not_locked_0_i   : std_logic;
    signal pll_not_locked_1_i   : std_logic;
    signal user_clk_0_i         : std_logic;
    signal user_clk_1_i         : std_logic;
    signal sync_clk_0_i         : std_logic;
    signal sync_clk_1_i         : std_logic;
    signal reset_i            : std_logic;
    signal power_down_0_i       : std_logic;
    signal power_down_1_i       : std_logic;
    signal loopback_0_i         : std_logic_vector(2 downto 0);
    signal loopback_1_i         : std_logic_vector(2 downto 0);
    signal tx_lock_0_i          : std_logic;
    signal tx_lock_1_i          : std_logic;
    signal gtpclkout_0_i        : std_logic;
    signal gtpclkout_1_i        : std_logic;
    signal buf_gtpclkout_0_i    : std_logic;
    signal buf_gtpclkout_1_i    : std_logic;

-- VIO Signals
   signal icon_to_vio_i       : std_logic_vector (35 downto 0);
   signal sync_in_i           : std_logic_vector (63 downto 0);
   signal sync_out_i          : std_logic_vector (15 downto 0);


   signal lane_up_0_i_i  	      : std_logic;
   signal lane_up_1_i_i  	      : std_logic;
   signal tx_lock_0_i_i  	      : std_logic;
   signal tx_lock_1_i_i  	      : std_logic;
   signal lane_up_reduce_0_i    : std_logic;
   signal lane_up_reduce_1_i    : std_logic;
   signal rst_cc_module_0_i     : std_logic;
   signal rst_cc_module_1_i     : std_logic;

   signal tied_to_ground_i    :   std_logic;   
   signal tied_to_gnd_vec_i   :   std_logic_vector(0 to 31);

   -- TX AXI PDU I/F signals
   signal tx_data_0_i           :   std_logic_vector(0 to 31);
   signal tx_data_1_i           :   std_logic_vector(0 to 31);
   signal tx_tvalid_0_i         :   std_logic;
   signal tx_tvalid_1_i         :   std_logic;
   signal tx_tready_0_i         :   std_logic;
   signal tx_tready_1_i         :   std_logic;


   -- RX AXI PDU I/F signals
   signal rx_data_0_i           :   std_logic_vector(0 to 31);
   signal rx_data_1_i           :   std_logic_vector(0 to 31);
   signal rx_tvalid_0_i         :   std_logic;
   signal rx_tvalid_1_i         :   std_logic;
   attribute ASYNC_REG        : string;
   attribute ASYNC_REG of tx_lock_0_i  : signal is "TRUE";
   attribute ASYNC_REG of tx_lock_1_i  : signal is "TRUE";

   -- I'm bypassing the ports we commented out at the top here
	signal GT_RESET_IN : std_logic;
	signal RESET : std_logic;

-- Component Declarations --
    component IBUFDS
	 port(
	   I  : IN std_logic;
		IB : IN std_logic;
		O  : OUT std_logic
	 );
	 end component;

    component BUFIO2 

    generic(

      DIVIDE_BYPASS : boolean := TRUE;  -- TRUE, FALSE
      DIVIDE        : integer := 1;     -- {1..8}
      I_INVERT      : boolean := FALSE; -- TRUE, FALSE
      USE_DOUBLER   : boolean := FALSE  -- TRUE, FALSE
      );

    port(
      DIVCLK       : out std_ulogic;
      IOCLK        : out std_ulogic;
      SERDESSTROBE : out std_ulogic;

      I            : in  std_ulogic
    );
    end component;

  -------------------------------------------------------------------
  --  ICON core component declaration
  -------------------------------------------------------------------
  component s6_icon
  
    port
    (
      control0    :   out std_logic_vector(35 downto 0)
    );
  end component;

  -------------------------------------------------------------------
  --  VIO core component declaration
  -------------------------------------------------------------------
  component s6_vio
  
    port
    (
      control     : in    std_logic_vector(35 downto 0);
      clk         : in    std_logic;
      sync_in     : in    std_logic_vector(63 downto 0);
      sync_out    : out   std_logic_vector(15 downto 0)
    );
  end component;

                                                                                
begin

	tx_data_0_i <= TX_DATA_0;
	tx_data_1_i <= TX_DATA_1;
	tx_tvalid_0_i <= TX_DATA_TVALID_0;
	tx_tvalid_1_i <= TX_DATA_TVALID_1;
	TX_DATA_TREADY_0 <= tx_tready_0_i;
	TX_DATA_TREADY_1 <= tx_tready_1_i;
	
	RX_DATA_0 <= rx_data_0_i;
	RX_DATA_1 <= rx_data_1_i;
	RX_DATA_TVALID_0 <= rx_tvalid_0_i;
	RX_DATA_TVALID_1 <= rx_tvalid_1_i;

	USER_CLOCK_0 <= user_clk_0_i;
	USER_CLOCK_1 <= user_clk_1_i;
	user_clk_1_i <= user_clk_0_i;  --Trying to share a single user_clock here
	sync_clk_1_i <= sync_clk_0_i;

   GT_RESET_IN <= '0';
   RESET <= '0';
	system_reset_i <= sync_out_i(1);
	gt_reset_i <= sync_out_i(2);

    tied_to_ground_i    <= '0';

    lane_up_reduce_0_i    <=  lane_up_0_i;
    lane_up_reduce_1_i    <=  lane_up_1_i;
    rst_cc_module_0_i     <=  not lane_up_reduce_0_i;  
    rst_cc_module_1_i     <=  not lane_up_reduce_1_i;  

    HARD_ERR_0  <= HARD_ERR_0_Buffer;
    HARD_ERR_1  <= HARD_ERR_1_Buffer;
    SOFT_ERR_0  <= SOFT_ERR_0_Buffer;
    SOFT_ERR_1  <= SOFT_ERR_1_Buffer;
    LANE_UP_0     <= LANE_UP_0_Buffer;
    LANE_UP_1     <= LANE_UP_1_Buffer;
    CHANNEL_UP_0  <= CHANNEL_UP_0_Buffer;
    CHANNEL_UP_1  <= CHANNEL_UP_1_Buffer;
    TXP_0         <= TXP_0_Buffer;
    TXN_0         <= TXN_0_Buffer;
    TXP_1         <= TXP_1_Buffer;
    TXN_1         <= TXN_1_Buffer;

    -- ___________________________Clock Buffers________________________
      IBUFDS_i :  IBUFDS
      port map (
           I  => GTPD2_P ,
           IB => GTPD2_N ,
           O  => GTPD2_left_i
               );

    BUFIO2_0_i : BUFIO2
    generic map
    (
        DIVIDE                          =>      1,
        DIVIDE_BYPASS                   =>      TRUE
    )
    port map
    (
        I                               =>      gtpclkout_0_i,
        DIVCLK                          =>      buf_gtpclkout_0_i,
        IOCLK                           =>      open,
        SERDESSTROBE                    =>      open
    );

    BUFIO2_1_i : BUFIO2
    generic map
    (
        DIVIDE                          =>      1,
        DIVIDE_BYPASS                   =>      TRUE
    )
    port map
    (
        I                               =>      gtpclkout_1_i,
        DIVCLK                          =>      buf_gtpclkout_1_i,
        IOCLK                           =>      open,
        SERDESSTROBE                    =>      open
    );

    -- Instantiate a clock module for clock division

    clock_module_0_i : entity work.aurora_interface_0_CLOCK_MODULE
        port map (

                    GT_CLK              => buf_gtpclkout_0_i,
                    GT_CLK_LOCKED       => tx_lock_0_i,
                    USER_CLK            => user_clk_0_i,
                    SYNC_CLK            => sync_clk_0_i,
                    PLL_NOT_LOCKED      => pll_not_locked_0_i
                 );

--    clock_module_1_i : entity work.aurora_interface_0_CLOCK_MODULE
--        port map (
--
--                    GT_CLK              => buf_gtpclkout_1_i,
--                    GT_CLK_LOCKED       => tx_lock_1_i,
--                    USER_CLK            => user_clk_1_i,
--                    SYNC_CLK            => sync_clk_1_i,
--                    PLL_NOT_LOCKED      => pll_not_locked_1_i
--                 );


    -- Register User I/O --

    -- Register User Outputs from core.

    process (user_clk_0_i)

    begin

        if (user_clk_0_i 'event and user_clk_0_i = '1') then

            HARD_ERR_0_Buffer  <= hard_err_0_i;
            SOFT_ERR_0_Buffer  <= soft_err_0_i;
            LANE_UP_0_Buffer     <= lane_up_0_i;
            CHANNEL_UP_0_Buffer  <= channel_up_0_i;

        end if;

    end process;

    process (user_clk_1_i)

    begin

        if (user_clk_1_i 'event and user_clk_1_i = '1') then

            HARD_ERR_1_Buffer  <= hard_err_1_i;
            SOFT_ERR_1_Buffer  <= soft_err_1_i;
            LANE_UP_1_Buffer     <= lane_up_1_i;
            CHANNEL_UP_1_Buffer  <= channel_up_1_i;

        end if;

    end process;


    -- System Interface

    power_down_0_i     <= '0';
    power_down_1_i     <= '0';
    loopback_0_i       <= "000";
    loopback_1_i       <= "000";

    -- _______________________________ Module Instantiations ________________________--

    -- Module Instantiations --

    aurora_module_i : entity work.aurora_interface_0
        generic map(
                    SIM_GTPRESET_SPEEDUP => SIM_GTPRESET_SPEEDUP
                   )
        port map   (
        -- AXI TX Interface

                    S_AXI_TX_TDATA_0         => tx_data_0_i,
                    S_AXI_TX_TVALID_0        => tx_tvalid_0_i,
                    S_AXI_TX_TREADY_0        => tx_tready_0_i,
                    S_AXI_TX_TDATA_1         => tx_data_1_i,
                    S_AXI_TX_TVALID_1        => tx_tvalid_1_i,
                    S_AXI_TX_TREADY_1        => tx_tready_1_i,

        --  AXI RX Interface

                    M_AXI_RX_TDATA_0        => rx_data_0_i,
                    M_AXI_RX_TVALID_0       => rx_tvalid_0_i,
                    M_AXI_RX_TDATA_1        => rx_data_1_i,
                    M_AXI_RX_TVALID_1       => rx_tvalid_1_i,
						  
        -- GT Serial I/O

                    RXP_0              => RXP_0,
                    RXN_0              => RXN_0,
                    TXP_0              => TXP_0_Buffer,
                    TXN_0              => TXN_0_Buffer,
                    RXP_1              => RXP_1,
                    RXN_1              => RXN_1,
                    TXP_1              => TXP_1_Buffer,
                    TXN_1              => TXN_1_Buffer,

        -- GT Reference Clock Interface
                   GTPD2    => GTPD2_left_i,

        -- Error Detection Interface

                    HARD_ERR_0       => hard_err_0_i,
                    SOFT_ERR_0       => soft_err_0_i,
                    HARD_ERR_1       => hard_err_1_i,
                    SOFT_ERR_1       => soft_err_1_i,

        -- Status

                    CHANNEL_UP_0       => channel_up_0_i,
                    LANE_UP_0          => lane_up_0_i,
                    CHANNEL_UP_1       => channel_up_1_i,
                    LANE_UP_1          => lane_up_1_i,

        -- Clock Compensation Control Interface

                    WARN_CC_0          => warn_cc_0_i,
                    DO_CC_0            => do_cc_0_i,
                    WARN_CC_1          => warn_cc_1_i,
                    DO_CC_1            => do_cc_1_i,

        -- System Interface

                    USER_CLK_0         => user_clk_0_i,
                    USER_CLK_1         => user_clk_1_i,
                    SYNC_CLK_0         => sync_clk_0_i,
                    SYNC_CLK_1         => sync_clk_1_i,
                    RESET            => reset_i,
                    POWER_DOWN_0       => power_down_0_i,
                    POWER_DOWN_1       => power_down_1_i,
                    LOOPBACK_0         => loopback_0_i,
                    LOOPBACK_1         => loopback_1_i,
                    GT_RESET         => gt_reset_i,
                    GTPCLKOUT_0        => gtpclkout_0_i,
                    GTPCLKOUT_1        => gtpclkout_1_i,
                    TX_LOCK_0          => tx_lock_0_i,
                    TX_LOCK_1          => tx_lock_1_i
                 );

    standard_cc_module_0_i : entity work.aurora_interface_0_STANDARD_CC_MODULE

        port map (

        -- Clock Compensation Control Interface

                    WARN_CC        => warn_cc_0_i,
                    DO_CC          => do_cc_0_i,

        -- System Interface

                    PLL_NOT_LOCKED => pll_not_locked_0_i,
                    USER_CLK       => user_clk_0_i,
                    RESET          => rst_cc_module_0_i 

                 );

    standard_cc_module_1_i : entity work.aurora_interface_0_STANDARD_CC_MODULE

        port map (

        -- Clock Compensation Control Interface

                    WARN_CC        => warn_cc_1_i,
                    DO_CC          => do_cc_1_i,

        -- System Interface

                    PLL_NOT_LOCKED => pll_not_locked_1_i,
                    USER_CLK       => user_clk_1_i,
                    RESET          => rst_cc_module_1_i 

                 );

 chipscope1 : if USE_CHIPSCOPE = 1 generate

   lane_up_0_i_i    <=  lane_up_0_i;
   lane_up_1_i_i    <=  lane_up_1_i;
   tx_lock_0_i_i    <= '1'  and tx_lock_0_i;
   tx_lock_1_i_i    <= '1'  and tx_lock_1_i;

  --Shared VIO Inputs
   sync_in_i(15 downto 0)  <= tx_data_0_i(0 to 15);
   sync_in_i(31 downto 16) <= rx_data_0_i(0 to 15);
   sync_in_i(47 downto 32) <= tx_data_1_i(0 to 15);
   sync_in_i(52)           <= soft_err_1_i;
   sync_in_i(53)           <= hard_err_1_i;
   sync_in_i(54)           <= tx_lock_1_i_i;
   sync_in_i(55)           <= pll_not_locked_1_i;
   sync_in_i(56)           <= lane_up_1_i_i;
   sync_in_i(57)           <= channel_up_1_i;
   sync_in_i(58)           <= soft_err_0_i;
   sync_in_i(59)           <= hard_err_0_i;
   sync_in_i(60)           <= tx_lock_0_i_i;
   sync_in_i(61)           <= pll_not_locked_0_i;
   sync_in_i(62)           <= lane_up_0_i_i;
   sync_in_i(63)           <= channel_up_0_i;

 

  -------------------------------------------------------------------
  --  ICON core instance
  -------------------------------------------------------------------
  i_icon : entity work.s6_icon
  
    port map
    (
      control0    => icon_to_vio_i
    );

 
  -------------------------------------------------------------------
  --  VIO core instance
  -------------------------------------------------------------------
  i_vio : entity work.s6_vio
  
    port map
    (
      control   => icon_to_vio_i,
      clk       => user_clk_0_i,
      sync_in   => sync_in_i,
      sync_out  => sync_out_i
    );
end generate chipscope1;

no_chipscope1 : if USE_CHIPSCOPE = 0 generate
   sync_in_i  <= (others=>'0');
end generate no_chipscope1;

chipscope2 : if USE_CHIPSCOPE = 1 generate
 -- Shared VIO Outputs
    reset_i <= system_reset_i or sync_out_i(0);
end generate chipscope2;

no_chipscope2 : if USE_CHIPSCOPE = 0 generate
 -- Shared VIO Outputs
    reset_i <= system_reset_i;
end generate no_chipscope2;

end MAPPED;
