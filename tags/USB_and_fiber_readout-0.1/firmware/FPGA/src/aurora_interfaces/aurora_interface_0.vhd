------------------------------------------------------------------------------
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
------------------------------------------------------------------------------
--
--  aurora_interface_0
--
--
--  Description: This is the top level module for a 1 4-byte lane Aurora
--               reference design module. This module supports the following features:
--
--               * Supports Virtex 5 GTX 
--------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_MISC.all;
-- synthesis translate_off
library UNISIM;
use UNISIM.all;
--synthesis translate_on

entity aurora_interface_0 is
generic 
(                    
           SIM_GTPRESET_SPEEDUP   :integer :=   0      --Set to 1 to speed up sim reset
);
port
(
    -- TX Stream Interface
    S_AXI_TX_TDATA_0             : in  std_logic_vector(0 to 31);
    S_AXI_TX_TDATA_1             : in  std_logic_vector(0 to 31);
    S_AXI_TX_TVALID_0            : in  std_logic;
    S_AXI_TX_TVALID_1            : in  std_logic;
    S_AXI_TX_TREADY_0            : out std_logic;
    S_AXI_TX_TREADY_1            : out std_logic;

    -- RX Stream Interface
    M_AXI_RX_TDATA_0             : out std_logic_vector(0 to 31);
    M_AXI_RX_TDATA_1             : out std_logic_vector(0 to 31);
    M_AXI_RX_TVALID_0            : out std_logic;
    M_AXI_RX_TVALID_1            : out std_logic;

    -- Clock Correction Interface
    DO_CC_0           : in  std_logic;
    DO_CC_1           : in  std_logic;
    WARN_CC_0         : in  std_logic;           
    WARN_CC_1         : in  std_logic;           
            
    --GTX Serial I/O
    RXP_0             : in  std_logic;
    RXP_1             : in  std_logic;
    RXN_0             : in  std_logic;
    RXN_1             : in  std_logic;
    TXP_0             : out std_logic;
    TXP_1             : out std_logic;
    TXN_0             : out std_logic;
    TXN_1             : out std_logic;

    --GTX Reference Clock Interface
    GTPD2      : in std_logic;

    --Error Detection Interface
    HARD_ERR_0      : out std_logic;
    HARD_ERR_1      : out std_logic;
    SOFT_ERR_0      : out std_logic;
    SOFT_ERR_1      : out std_logic;

    --Status
    CHANNEL_UP_0      : out std_logic;
	 CHANNEL_UP_1      : out std_logic;
    LANE_UP_0         : out std_logic;
	 LANE_UP_1         : out std_logic;

    --System Interface
    USER_CLK_0        : in  std_logic;
    USER_CLK_1        : in  std_logic;
    SYNC_CLK_0        : in  std_logic;
    SYNC_CLK_1        : in  std_logic;
    RESET           : in  std_logic;
    POWER_DOWN_0      : in  std_logic;
    POWER_DOWN_1      : in  std_logic;
    LOOPBACK_0        : in  std_logic_vector(2 downto 0);  
    LOOPBACK_1        : in  std_logic_vector(2 downto 0);  
    GT_RESET        : in  std_logic;
    GTPCLKOUT_0       : out std_logic;
    GTPCLKOUT_1       : out std_logic;
    TX_LOCK_0         : out std_logic;         
    TX_LOCK_1         : out std_logic         
);

end aurora_interface_0;


architecture MAPPED of aurora_interface_0 is
  attribute core_generation_info           : string;
  attribute core_generation_info of MAPPED : architecture is "aurora_interface_0,aurora_8b10b_v6_2,{user_interface=AXI_4_Streaming, backchannel_mode=Sidebands, c_aurora_lanes=1, c_column_used=None, c_gt_clock_1=GTPD2, c_gt_clock_2=None, c_gt_loc_1=X, c_gt_loc_10=X, c_gt_loc_11=X, c_gt_loc_12=X, c_gt_loc_13=X, c_gt_loc_14=X, c_gt_loc_15=X, c_gt_loc_16=X, c_gt_loc_17=X, c_gt_loc_18=X, c_gt_loc_19=X, c_gt_loc_2=X, c_gt_loc_20=X, c_gt_loc_21=X, c_gt_loc_22=X, c_gt_loc_23=X, c_gt_loc_24=X, c_gt_loc_25=X, c_gt_loc_26=X, c_gt_loc_27=X, c_gt_loc_28=X, c_gt_loc_29=X, c_gt_loc_3=X, c_gt_loc_30=X, c_gt_loc_31=X, c_gt_loc_32=X, c_gt_loc_33=X, c_gt_loc_34=X, c_gt_loc_35=X, c_gt_loc_36=X, c_gt_loc_37=X, c_gt_loc_38=X, c_gt_loc_39=X, c_gt_loc_4=X, c_gt_loc_40=X, c_gt_loc_41=X, c_gt_loc_42=X, c_gt_loc_43=X, c_gt_loc_44=X, c_gt_loc_45=X, c_gt_loc_46=X, c_gt_loc_47=X, c_gt_loc_48=X, c_gt_loc_5=1, c_gt_loc_6=X, c_gt_loc_7=X, c_gt_loc_8=X, c_gt_loc_9=X, c_lane_width=4, c_line_rate=3.125, c_nfc=false, c_nfc_mode=IMM, c_refclk_frequency=156.25, c_simplex=false, c_simplex_mode=TX, c_stream=true, c_ufc=false, flow_mode=None, interface_mode=Streaming, dataflow_config=Duplex}";
    
--*********************************Signal Declarations**********************************

    signal ch_bond_done_i_unused           : std_logic; 



    signal ch_bond_done_i           : std_logic;
    signal ch_bond_done_r1          : std_logic;
    signal ch_bond_done_r2          : std_logic;
    signal rx_status_float_i        : std_logic_vector(4 downto 0);
    signal ch_bond_load_not_used_i  : std_logic;
    signal channel_up_0_i             : std_logic;
    signal channel_up_1_i             : std_logic;
    signal chbondi_not_used_i       : std_logic_vector(4 downto 0);         
    signal chbondo_not_used_i       : std_logic_vector(4 downto 0);          
    signal combus_in_not_used_i     : std_logic_vector(15 downto 0);            
    signal combusout_out_not_used_i : std_logic_vector(15 downto 0);            
    signal en_chan_sync_i           : std_logic;
    signal ena_comma_align_0_i        : std_logic;
    signal ena_comma_align_1_i        : std_logic;
    signal gen_a_0_i                  : std_logic;
    signal gen_a_1_i                  : std_logic;
    signal gen_cc_0_i                 : std_logic;
    signal gen_cc_1_i                 : std_logic;
    signal gen_ecp_0_i                : std_logic;
    signal gen_ecp_1_i                : std_logic;
    signal gen_ecp_striped_0_i        : std_logic_vector(0 to 1);
    signal gen_ecp_striped_1_i        : std_logic_vector(0 to 1);
    signal gen_k_0_i                  : std_logic_vector(0 to 3);
    signal gen_k_1_i                  : std_logic_vector(0 to 3);
    signal gen_pad_0_i                : std_logic_vector(0 to 1);
    signal gen_pad_1_i                : std_logic_vector(0 to 1);
    signal gen_pad_striped_0_i        : std_logic_vector(0 to 1);
    signal gen_pad_striped_1_i        : std_logic_vector(0 to 1);
    signal gen_r_0_i                  : std_logic_vector(0 to 3);
    signal gen_r_1_i                  : std_logic_vector(0 to 3);
    signal gen_scp_0_i                : std_logic;
    signal gen_scp_1_i                : std_logic;
    signal gen_scp_striped_0_i        : std_logic_vector(0 to 1);
    signal gen_scp_striped_1_i        : std_logic_vector(0 to 1);
    signal gen_v_0_i                  : std_logic_vector(0 to 3);
    signal gen_v_1_i                  : std_logic_vector(0 to 3);
    signal got_a_0_i                  : std_logic_vector(0 to 3);
    signal got_a_1_i                  : std_logic_vector(0 to 3);
    signal got_v_0_i                  : std_logic;
    signal got_v_1_i                  : std_logic;
    signal hard_err_0_i             : std_logic;
    signal hard_err_1_i             : std_logic;
    signal lane_up_0_i                : std_logic;
    signal lane_up_1_i                : std_logic;
    signal pma_rx_lock_i            : std_logic;
    signal reset_lanes_i            : std_logic;
    signal rx_buf_err_0_i             : std_logic;
    signal rx_buf_err_1_i             : std_logic;
    signal rx_char_is_comma_0_i       : std_logic_vector(3 downto 0);
    signal rx_char_is_comma_1_i       : std_logic_vector(3 downto 0);
    signal rx_char_is_k_0_i           : std_logic_vector(3 downto 0);
    signal rx_char_is_k_1_i           : std_logic_vector(3 downto 0);
    signal rx_clk_cor_cnt_i         : std_logic_vector(2 downto 0);
    signal rx_data_0_i                : std_logic_vector(31 downto 0);
    signal rx_data_1_i                : std_logic_vector(31 downto 0);
    signal rx_disp_err_0_i            : std_logic_vector(3 downto 0);
    signal rx_disp_err_1_i            : std_logic_vector(3 downto 0);
    signal rx_ecp_0_i                 : std_logic_vector(0 to 1);
    signal rx_ecp_1_i                 : std_logic_vector(0 to 1);
    signal rx_ecp_striped_0_i         : std_logic_vector(0 to 1);
    signal rx_ecp_striped_1_i         : std_logic_vector(0 to 1);
    signal rx_not_in_table_0_i        : std_logic_vector(3 downto 0);
    signal rx_not_in_table_1_i        : std_logic_vector(3 downto 0);
    signal rx_pad_0_i                 : std_logic_vector(0 to 1);
    signal rx_pad_1_i                 : std_logic_vector(0 to 1);
    signal rx_pad_striped_0_i         : std_logic_vector(0 to 1);
    signal rx_pad_striped_1_i         : std_logic_vector(0 to 1);
    signal rx_pe_data_0_i             : std_logic_vector(0 to 31);
    signal rx_pe_data_1_i             : std_logic_vector(0 to 31);
    signal rx_pe_data_striped_0_i     : std_logic_vector(0 to 31);
    signal rx_pe_data_striped_1_i     : std_logic_vector(0 to 31);
    signal rx_pe_data_v_0_i           : std_logic_vector(0 to 1);
    signal rx_pe_data_v_1_i           : std_logic_vector(0 to 1);
    signal rx_pe_data_v_striped_0_i   : std_logic_vector(0 to 1);
    signal rx_pe_data_v_striped_1_i   : std_logic_vector(0 to 1);
    signal rx_polarity_0_i            : std_logic;
    signal rx_polarity_1_i            : std_logic;
    signal rx_realign_0_i             : std_logic;
    signal rx_realign_1_i             : std_logic;
    signal rx_reset_0_i               : std_logic;
    signal rx_reset_1_i               : std_logic;
    signal rx_scp_0_i                 : std_logic_vector(0 to 1);
    signal rx_scp_1_i                 : std_logic_vector(0 to 1);
    signal rx_scp_striped_0_i         : std_logic_vector(0 to 1);
    signal rx_scp_striped_1_i         : std_logic_vector(0 to 1);
    signal soft_err_0_i             : std_logic_vector(0 to 1);
    signal soft_err_1_i             : std_logic_vector(0 to 1);
    signal all_soft_err_0_i         : std_logic;
	 signal all_soft_err_1_i         : std_logic;
    signal start_rx_0_i               : std_logic;
    signal start_rx_1_i               : std_logic;
    signal tied_to_ground_i         : std_logic;
    signal tied_to_ground_vec_i     : std_logic_vector(31 downto 0);
    signal tied_to_vcc_i            : std_logic;
    signal tx_buf_err_0_i             : std_logic;
    signal tx_buf_err_1_i             : std_logic;
    signal tx_char_is_k_0_i           : std_logic_vector(3 downto 0);
    signal tx_char_is_k_1_i           : std_logic_vector(3 downto 0);
    signal tx_data_0_i                : std_logic_vector(31 downto 0);
    signal tx_data_1_i                : std_logic_vector(31 downto 0);
    signal tx_lock_0_i                : std_logic;
    signal tx_lock_1_i                : std_logic;
    signal buf_gtpclkout_i          : std_logic;
    signal raw_gtpclkout_0_i             :   std_logic_vector(1 downto 0);
    signal raw_gtpclkout_1_i             :   std_logic_vector(1 downto 0);
    signal tx_pe_data_0_i             : std_logic_vector(0 to 31);
    signal tx_pe_data_1_i             : std_logic_vector(0 to 31);
    signal tx_pe_data_striped_0_i     : std_logic_vector(0 to 31);
    signal tx_pe_data_striped_1_i     : std_logic_vector(0 to 31);
    signal tx_pe_data_v_0_i           : std_logic_vector(0 to 1);
    signal tx_pe_data_v_1_i           : std_logic_vector(0 to 1);
    signal tx_pe_data_v_striped_0_i   : std_logic_vector(0 to 1);
    signal tx_pe_data_v_striped_1_i   : std_logic_vector(0 to 1);
    signal tx_reset_0_i               : std_logic;
    signal tx_reset_1_i               : std_logic;
    signal txoutclk2_out_not_used_i : std_logic;            
    signal txpcshclkout_not_used_i  : std_logic;            

    signal tied_to_gnd_vec_i            :   std_logic_vector(0 to 31);
    -- TX AXI PDU I/F wires
    signal tx_data_0                      :   std_logic_vector(0 to 31);
    signal tx_data_1                      :   std_logic_vector(0 to 31);
    signal tx_src_rdy_0                   :   std_logic;
    signal tx_src_rdy_1                   :   std_logic;
    signal tx_dst_rdy_0                   :   std_logic;
    signal tx_dst_rdy_1                   :   std_logic;

    -- RX AXI PDU I/F wires
    signal rx_data_0                      :   std_logic_vector(0 to 31);
    signal rx_data_1                      :   std_logic_vector(0 to 31);
    signal rx_src_rdy_0                   :   std_logic;
    signal rx_src_rdy_1                   :   std_logic;

begin
--*********************************Main Body of Code**********************************
    
    --Tie off top level constants
    tied_to_ground_vec_i    <=  (others => '0');
    tied_to_ground_i        <=  '0';
    tied_to_vcc_i           <=  '1';

     all_soft_err_0_i        <= soft_err_0_i(0) or soft_err_0_i(1);
     all_soft_err_1_i        <= soft_err_1_i(0) or soft_err_1_i(1);

    --Connect top level logic
    CHANNEL_UP_0          <=  channel_up_0_i;
	 CHANNEL_UP_1          <=  channel_up_1_i;
    GTPCLKOUT_0   <=   raw_gtpclkout_0_i(0);
    GTPCLKOUT_1   <=   raw_gtpclkout_1_i(0);

    -- Connect TX_LOCK to tx_lock_i from lane 0
    TX_LOCK_0    <=  tx_lock_0_i;
    TX_LOCK_1    <=  tx_lock_1_i;

    --_________________________Instantiate Lane 0______________________________

    LANE_UP_0 <= lane_up_0_i;

    --Aurora lane striping rules require each 4-byte lane to carry 2 bytes from the first 
    --half of the overall word, and 2 bytes from the second half. This ensures that the 
    --data will be ordered correctly if it is send to a 2-byte lane. Here we perform the 
    --required concatenation
    gen_scp_striped_0_i <= gen_scp_0_i & '0';
    gen_ecp_striped_0_i <= '0' & gen_ecp_0_i;
    gen_pad_striped_0_i(0 to 1) <= gen_pad_0_i(0) & gen_pad_0_i(1);
    tx_pe_data_striped_0_i(0 to 31) <= tx_pe_data_0_i(0 to 15) & tx_pe_data_0_i(16 to 31);
    tx_pe_data_v_striped_0_i(0 to 1) <= tx_pe_data_v_0_i(0) & tx_pe_data_v_0_i(1);
    rx_pad_0_i(0) <= rx_pad_striped_0_i(0); 
    rx_pad_0_i(1) <= rx_pad_striped_0_i(1);
    rx_pe_data_0_i(0 to 15) <= rx_pe_data_striped_0_i(0 to 15);
    rx_pe_data_0_i(16 to 31) <= rx_pe_data_striped_0_i(16 to 31);
    rx_pe_data_v_0_i(0) <= rx_pe_data_v_striped_0_i(0);
    rx_pe_data_v_0_i(1) <= rx_pe_data_v_striped_0_i(1);
    rx_scp_0_i(0) <= rx_scp_striped_0_i(0);
    rx_scp_0_i(1) <= rx_scp_striped_0_i(1);
    rx_ecp_0_i(0) <= rx_ecp_striped_0_i(0);
    rx_ecp_0_i(1) <= rx_ecp_striped_0_i(1);

    aurora_interface_0_aurora_lane_4byte_0_i : entity work.aurora_interface_0_AURORA_LANE_4BYTE 
    port map
    (
        --GTX Interface
        RX_DATA             => rx_data_0_i(31 downto 0),
        RX_NOT_IN_TABLE     => rx_not_in_table_0_i(3 downto 0),
        RX_DISP_ERR         => rx_disp_err_0_i(3 downto 0),
        RX_CHAR_IS_K        => rx_char_is_k_0_i(3 downto 0),
        RX_CHAR_IS_COMMA    => rx_char_is_comma_0_i(3 downto 0),
        RX_STATUS           => tied_to_ground_vec_i(5 downto 0),
        TX_BUF_ERR          => tx_buf_err_0_i,
        RX_BUF_ERR          => rx_buf_err_0_i,
        RX_REALIGN          => rx_realign_0_i,
        RX_POLARITY         => rx_polarity_0_i,
        RX_RESET            => rx_reset_0_i,
        TX_CHAR_IS_K        => tx_char_is_k_0_i(3 downto 0),
        TX_DATA             => tx_data_0_i(31 downto 0),
        TX_RESET            => tx_reset_0_i,
        
       --Comma Detect Phase Align Interface
        ENA_COMMA_ALIGN     => ena_comma_align_0_i,

        --TX_LL Interface
        GEN_SCP             => gen_scp_striped_0_i,
        GEN_ECP             => gen_ecp_striped_0_i,
        GEN_PAD             => gen_pad_striped_0_i(0 to 1),
        TX_PE_DATA          => tx_pe_data_striped_0_i(0 to 31),
        TX_PE_DATA_V        => tx_pe_data_v_striped_0_i(0 to 1),
        GEN_CC              => gen_cc_0_i,

        --RX_LL Interface
        RX_PAD              => rx_pad_striped_0_i(0 to 1),
        RX_PE_DATA          => rx_pe_data_striped_0_i(0 to 31),
        RX_PE_DATA_V        => rx_pe_data_v_striped_0_i(0 to 1),
        RX_SCP              => rx_scp_striped_0_i(0 to 1),
        RX_ECP              => rx_ecp_striped_0_i(0 to 1),

        --Global Logic Interface
        GEN_A               => gen_a_0_i,
        GEN_K               => gen_k_0_i(0 to 3),
        GEN_R               => gen_r_0_i(0 to 3),
        GEN_V               => gen_v_0_i(0 to 3),
        LANE_UP           => lane_up_0_i,
        SOFT_ERR          => soft_err_0_i(0 to 1),
        HARD_ERR          => hard_err_0_i,
        CHANNEL_BOND_LOAD   => ch_bond_load_not_used_i,
        GOT_A               => got_a_0_i(0 to 3),
        GOT_V               => got_v_0_i,

        --System Interface
        USER_CLK            => USER_CLK_0,
        RESET_SYMGEN        => RESET,
        RESET               => reset_lanes_i
    );

    --_________________________Instantiate Lane 1______________________________

    LANE_UP_1 <= lane_up_1_i;

    --Aurora lane striping rules require each 4-byte lane to carry 2 bytes from the first 
    --half of the overall word, and 2 bytes from the second half. This ensures that the 
    --data will be ordered correctly if it is send to a 2-byte lane. Here we perform the 
    --required concatenation
    gen_scp_striped_1_i <= gen_scp_1_i & '0';
    gen_ecp_striped_1_i <= '0' & gen_ecp_1_i;
    gen_pad_striped_1_i(0 to 1) <= gen_pad_1_i(0) & gen_pad_1_i(1);
    tx_pe_data_striped_1_i(0 to 31) <= tx_pe_data_1_i(0 to 15) & tx_pe_data_1_i(16 to 31);
    tx_pe_data_v_striped_1_i(0 to 1) <= tx_pe_data_v_1_i(0) & tx_pe_data_v_1_i(1);
    rx_pad_1_i(0) <= rx_pad_striped_1_i(0); 
    rx_pad_1_i(1) <= rx_pad_striped_1_i(1);
    rx_pe_data_1_i(0 to 15) <= rx_pe_data_striped_1_i(0 to 15);
    rx_pe_data_1_i(16 to 31) <= rx_pe_data_striped_1_i(16 to 31);
    rx_pe_data_v_1_i(0) <= rx_pe_data_v_striped_1_i(0);
    rx_pe_data_v_1_i(1) <= rx_pe_data_v_striped_1_i(1);
    rx_scp_1_i(0) <= rx_scp_striped_1_i(0);
    rx_scp_1_i(1) <= rx_scp_striped_1_i(1);
    rx_ecp_1_i(0) <= rx_ecp_striped_1_i(0);
    rx_ecp_1_i(1) <= rx_ecp_striped_1_i(1);

    aurora_interface_1_aurora_lane_4byte_0_i : entity work.aurora_interface_0_AURORA_LANE_4BYTE 
    port map
    (
        --GTX Interface
        RX_DATA             => rx_data_1_i(31 downto 0),
        RX_NOT_IN_TABLE     => rx_not_in_table_1_i(3 downto 0),
        RX_DISP_ERR         => rx_disp_err_1_i(3 downto 0),
        RX_CHAR_IS_K        => rx_char_is_k_1_i(3 downto 0),
        RX_CHAR_IS_COMMA    => rx_char_is_comma_1_i(3 downto 0),
        RX_STATUS           => tied_to_ground_vec_i(5 downto 0),
        TX_BUF_ERR          => tx_buf_err_1_i,
        RX_BUF_ERR          => rx_buf_err_1_i,
        RX_REALIGN          => rx_realign_1_i,
        RX_POLARITY         => rx_polarity_1_i,
        RX_RESET            => rx_reset_1_i,
        TX_CHAR_IS_K        => tx_char_is_k_1_i(3 downto 0),
        TX_DATA             => tx_data_1_i(31 downto 0),
        TX_RESET            => tx_reset_1_i,
        
       --Comma Detect Phase Align Interface
        ENA_COMMA_ALIGN     => ena_comma_align_1_i,

        --TX_LL Interface
        GEN_SCP             => gen_scp_striped_1_i,
        GEN_ECP             => gen_ecp_striped_1_i,
        GEN_PAD             => gen_pad_striped_1_i(0 to 1),
        TX_PE_DATA          => tx_pe_data_striped_1_i(0 to 31),
        TX_PE_DATA_V        => tx_pe_data_v_striped_1_i(0 to 1),
        GEN_CC              => gen_cc_1_i,

        --RX_LL Interface
        RX_PAD              => rx_pad_striped_1_i(0 to 1),
        RX_PE_DATA          => rx_pe_data_striped_1_i(0 to 31),
        RX_PE_DATA_V        => rx_pe_data_v_striped_1_i(0 to 1),
        RX_SCP              => rx_scp_striped_1_i(0 to 1),
        RX_ECP              => rx_ecp_striped_1_i(0 to 1),

        --Global Logic Interface
        GEN_A               => gen_a_1_i,
        GEN_K               => gen_k_1_i(0 to 3),
        GEN_R               => gen_r_1_i(0 to 3),
        GEN_V               => gen_v_1_i(0 to 3),
        LANE_UP           => lane_up_1_i,
        SOFT_ERR          => soft_err_1_i(0 to 1),
        HARD_ERR          => hard_err_1_i,
        CHANNEL_BOND_LOAD   => ch_bond_load_not_used_i,
        GOT_A               => got_a_1_i(0 to 3),
        GOT_V               => got_v_1_i,

        --System Interface
        USER_CLK            => USER_CLK_1,
        RESET_SYMGEN        => RESET,
        RESET               => reset_lanes_i
    );

    --_________________________Instantiate GTX Wrapper______________________________

    gtp_wrapper_i : entity work.aurora_interface_0_GTP_WRAPPER  
    generic map(
                  SIM_GTPRESET_SPEEDUP  => SIM_GTPRESET_SPEEDUP
               )
    port map   (   
        --Aurora Lane Interface
        RXPOLARITY_IN_0         => rx_polarity_0_i,
        RXPOLARITY_IN_1         => rx_polarity_1_i,		  
        RXRESET_IN_0            => rx_reset_0_i,
        RXRESET_IN_1            => rx_reset_1_i,
        TXCHARISK_IN_0          => tx_char_is_k_0_i(3 downto 0),
        TXCHARISK_IN_1          => tx_char_is_k_1_i(3 downto 0),
        TXDATA_IN_0             => tx_data_0_i(31 downto 0),
        TXDATA_IN_1             => tx_data_1_i(31 downto 0),
        TXRESET_IN_0            => tx_reset_0_i,
        TXRESET_IN_1            => tx_reset_1_i,
        RXDATA_OUT_0            => rx_data_0_i(31 downto 0),
        RXDATA_OUT_1            => rx_data_1_i(31 downto 0),
        RXNOTINTABLE_OUT_0      => rx_not_in_table_0_i(3 downto 0),
        RXNOTINTABLE_OUT_1      => rx_not_in_table_1_i(3 downto 0),
        RXDISPERR_OUT_0         => rx_disp_err_0_i(3 downto 0),
        RXDISPERR_OUT_1         => rx_disp_err_1_i(3 downto 0),
        RXCHARISK_OUT_0         => rx_char_is_k_0_i(3 downto 0),
        RXCHARISK_OUT_1         => rx_char_is_k_1_i(3 downto 0),
        RXCHARISCOMMA_OUT_0     => rx_char_is_comma_0_i(3 downto 0),
        RXCHARISCOMMA_OUT_1     => rx_char_is_comma_1_i(3 downto 0),
        TXBUFERR_OUT_0          => tx_buf_err_0_i,
        TXBUFERR_OUT_1          => tx_buf_err_1_i,
        RXBUFERR_OUT_0          => rx_buf_err_0_i,
        RXBUFERR_OUT_1          => rx_buf_err_1_i,
        RXREALIGN_OUT_0         => rx_realign_0_i,
        RXREALIGN_OUT_1         => rx_realign_1_i,

        -- Phase Align Interface
        ENMCOMMAALIGN_IN_0        => ena_comma_align_0_i,
        ENMCOMMAALIGN_IN_1        => ena_comma_align_1_i,
        ENPCOMMAALIGN_IN_0        => ena_comma_align_0_i,
        ENPCOMMAALIGN_IN_1        => ena_comma_align_1_i,
        RXRECCLK1_OUT           =>  open,
        RXRECCLK2_OUT           =>  open,

        --Global Logic Interface
        ENCHANSYNC_IN           => en_chan_sync_i,
        CHBONDDONE_OUT          => ch_bond_done_i,

        --Serial IO
        RX1N_IN_0        => RXN_0,
        RX1N_IN_1        => RXN_1,
        RX1P_IN_0        => RXP_0,
        RX1P_IN_1        => RXP_1,
        TX1N_OUT_0       => TXN_0,
        TX1N_OUT_1       => TXN_1,
        TX1P_OUT_0       => TXP_0,
        TX1P_OUT_1       => TXP_1,

       --Reference Clocks and User Clock
        RXUSRCLK_IN_0             => SYNC_CLK_0,
        RXUSRCLK_IN_1             => SYNC_CLK_1,
        RXUSRCLK2_IN_0            => USER_CLK_0,
        RXUSRCLK2_IN_1            => USER_CLK_1,
        TXUSRCLK_IN_0             => SYNC_CLK_0,
        TXUSRCLK_IN_1             => SYNC_CLK_1,
        TXUSRCLK2_IN_0            => USER_CLK_0,
        TXUSRCLK2_IN_1            => USER_CLK_1,
        REFCLK                  =>  GTPD2,

        GTPCLKOUT_OUT_0 => raw_gtpclkout_0_i,
        GTPCLKOUT_OUT_1 => raw_gtpclkout_1_i,
        PLLLKDET_OUT_0            => tx_lock_0_i,       
        PLLLKDET_OUT_1            => tx_lock_1_i,       
        --System Interface
        GTPRESET_IN                                     => GT_RESET,
        LOOPBACK_IN_0                                         => LOOPBACK_0,
        LOOPBACK_IN_1                                         => LOOPBACK_1,

---------------- Receive Ports - Channel Bonding Ports -----------------
        CHBONDDONE_OUT_unused    => ch_bond_done_i_unused,

 
        POWERDOWN_IN_0                                      => POWER_DOWN_0,
        POWERDOWN_IN_1                                      => POWER_DOWN_1
    );

    --__________Instantiate Global Logic to combine Lanes into a Channel______

    aurora_interface_0_global_logic_i : entity work.aurora_interface_0_GLOBAL_LOGIC
   
    port map 
    (
        -- GTX Interface
        CH_BOND_DONE            => ch_bond_done_i,
        EN_CHAN_SYNC            => en_chan_sync_i,


        -- Aurora Lane Interface
        LANE_UP                 => lane_up_0_i,
        SOFT_ERR              => soft_err_0_i,
        HARD_ERR              => hard_err_0_i,
        CHANNEL_BOND_LOAD       => ch_bond_done_i,
        GOT_A                   => got_a_0_i,
        GOT_V                   => got_v_0_i,
        GEN_A                   => gen_a_0_i,
        GEN_K                   => gen_k_0_i,
        GEN_R                   => gen_r_0_i,
        GEN_V                   => gen_v_0_i,
        RESET_LANES             => reset_lanes_i,
        
        
        -- System Interface
        USER_CLK                => USER_CLK_0,
        RESET                   => RESET,
        POWER_DOWN              => POWER_DOWN_0,
        CHANNEL_UP              => channel_up_0_i,
        START_RX                => start_rx_0_i,
        CHANNEL_SOFT_ERR      => SOFT_ERR_0,
        CHANNEL_HARD_ERR      => HARD_ERR_0
    );

    --__________Instantiate Global Logic to combine Lanes into a Channel______

    aurora_interface_1_global_logic_i : entity work.aurora_interface_0_GLOBAL_LOGIC
   
    port map 
    (
        -- GTX Interface
        CH_BOND_DONE            => ch_bond_done_i,
        EN_CHAN_SYNC            => open,


        -- Aurora Lane Interface
        LANE_UP                 => lane_up_1_i,
        SOFT_ERR              => soft_err_1_i,
        HARD_ERR              => hard_err_1_i,
        CHANNEL_BOND_LOAD       => ch_bond_done_i,
        GOT_A                   => got_a_1_i,
        GOT_V                   => got_v_1_i,
        GEN_A                   => gen_a_1_i,
        GEN_K                   => gen_k_1_i,
        GEN_R                   => gen_r_1_i,
        GEN_V                   => gen_v_1_i,
        RESET_LANES             => open,
        
        
        -- System Interface
        USER_CLK                => USER_CLK_1,
        RESET                   => RESET,
        POWER_DOWN              => POWER_DOWN_1,
        CHANNEL_UP              => channel_up_1_i,
        START_RX                => start_rx_1_i,
        CHANNEL_SOFT_ERR      => SOFT_ERR_1,
        CHANNEL_HARD_ERR      => HARD_ERR_1
    );



    --_____________________________ TX AXI SHIM _______________________________
    axi_to_ll_pdu_0_i : entity work.aurora_interface_0_AXI_TO_LL 
    generic map 
    (
       DATA_WIDTH           => 32,
       STRB_WIDTH           => 4,
       REM_WIDTH            => 2,
       USE_UFC_REM          => 0
    )

    port map 
    (
      AXI4_S_IP_TX_TVALID   => S_AXI_TX_TVALID_0,
      AXI4_S_IP_TX_TDATA    => S_AXI_TX_TDATA_0,
      AXI4_S_IP_TX_TKEEP    => "0000",
      AXI4_S_IP_TX_TLAST    => tied_to_ground_i,
      AXI4_S_OP_TX_TREADY   => S_AXI_TX_TREADY_0,

      LL_OP_DATA            => tx_data_0,
      LL_OP_SOF_N           => OPEN,
      LL_OP_EOF_N           => OPEN,
      LL_OP_REM             => OPEN,
      LL_OP_SRC_RDY_N       => tx_src_rdy_0,
      LL_IP_DST_RDY_N       => tx_dst_rdy_0,

      -- System Interface
      USER_CLK              => USER_CLK_0,
      RESET                 => RESET,  
      CHANNEL_UP            => channel_up_0_i
    );

    axi_to_ll_pdu_1_i : entity work.aurora_interface_0_AXI_TO_LL 
    generic map 
    (
       DATA_WIDTH           => 32,
       STRB_WIDTH           => 4,
       REM_WIDTH            => 2,
       USE_UFC_REM          => 0
    )

    port map 
    (
      AXI4_S_IP_TX_TVALID   => S_AXI_TX_TVALID_1,
      AXI4_S_IP_TX_TDATA    => S_AXI_TX_TDATA_1,
      AXI4_S_IP_TX_TKEEP    => "0000",
      AXI4_S_IP_TX_TLAST    => tied_to_ground_i,
      AXI4_S_OP_TX_TREADY   => S_AXI_TX_TREADY_1,

      LL_OP_DATA            => tx_data_1,
      LL_OP_SOF_N           => OPEN,
      LL_OP_EOF_N           => OPEN,
      LL_OP_REM             => OPEN,
      LL_OP_SRC_RDY_N       => tx_src_rdy_1,
      LL_IP_DST_RDY_N       => tx_dst_rdy_1,

      -- System Interface
      USER_CLK              => USER_CLK_1,
      RESET                 => RESET,  
      CHANNEL_UP            => channel_up_1_i
    );



    --_____________________________Instantiate TX_STREAM___________________________

    aurora_interface_0_tx_stream_i : entity work.aurora_interface_0_TX_STREAM
    port map
    (
        -- Data interface
        TX_D            =>  tx_data_0,
        TX_SRC_RDY_N    =>  tx_src_rdy_0,
        TX_DST_RDY_N    =>  tx_dst_rdy_0,

        -- Global Logic Interface
        CHANNEL_UP      =>  channel_up_0_i,


        -- Clock Correction Interface
        DO_CC           =>  DO_CC_0,
        WARN_CC         =>  WARN_CC_0,


        -- Aurora Lane Interface
        GEN_SCP         =>  gen_scp_0_i,
        GEN_ECP         =>  gen_ecp_0_i,
        TX_PE_DATA_V    =>  tx_pe_data_v_0_i,
        GEN_PAD         =>  gen_pad_0_i,
        TX_PE_DATA      =>  tx_pe_data_0_i,
        GEN_CC          =>  gen_cc_0_i,


        -- System Interface
        USER_CLK        =>  USER_CLK_0 

    );

    aurora_interface_1_tx_stream_i : entity work.aurora_interface_0_TX_STREAM
    port map
    (
        -- Data interface
        TX_D            =>  tx_data_1,
        TX_SRC_RDY_N    =>  tx_src_rdy_1,
        TX_DST_RDY_N    =>  tx_dst_rdy_1,

        -- Global Logic Interface
        CHANNEL_UP      =>  channel_up_1_i,


        -- Clock Correction Interface
        DO_CC           =>  DO_CC_1,
        WARN_CC         =>  WARN_CC_1,


        -- Aurora Lane Interface
        GEN_SCP         =>  gen_scp_1_i,
        GEN_ECP         =>  gen_ecp_1_i,
        TX_PE_DATA_V    =>  tx_pe_data_v_1_i,
        GEN_PAD         =>  gen_pad_1_i,
        TX_PE_DATA      =>  tx_pe_data_1_i,
        GEN_CC          =>  gen_cc_1_i,


        -- System Interface
        USER_CLK        =>  USER_CLK_1 

    );


    --_____________________________ RX AXI SHIM _______________________________
    ll_to_axi_pdu_0_i : entity work.aurora_interface_0_LL_TO_AXI 
    generic map 
    (
       DATA_WIDTH           => 32,
       STRB_WIDTH           => 4,
       REM_WIDTH            => 2
    )

    port map 
    (
      LL_IP_DATA            => rx_data_0,
      LL_IP_SOF_N           => tied_to_ground_i,
      LL_IP_EOF_N           => tied_to_ground_i,
      LL_IP_REM             => "00",
      LL_IP_SRC_RDY_N       => rx_src_rdy_0,
      LL_OP_DST_RDY_N       => OPEN,

      AXI4_S_OP_TVALID      => M_AXI_RX_TVALID_0,
      AXI4_S_OP_TDATA       => M_AXI_RX_TDATA_0,
      AXI4_S_OP_TKEEP       => OPEN,
      AXI4_S_OP_TLAST       => OPEN,
      AXI4_S_IP_TREADY      => tied_to_ground_i

    );

    --_____________________________ RX AXI SHIM _______________________________
    ll_to_axi_pdu_1_i : entity work.aurora_interface_0_LL_TO_AXI 
    generic map 
    (
       DATA_WIDTH           => 32,
       STRB_WIDTH           => 4,
       REM_WIDTH            => 2
    )

    port map 
    (
      LL_IP_DATA            => rx_data_1,
      LL_IP_SOF_N           => tied_to_ground_i,
      LL_IP_EOF_N           => tied_to_ground_i,
      LL_IP_REM             => "00",
      LL_IP_SRC_RDY_N       => rx_src_rdy_1,
      LL_OP_DST_RDY_N       => OPEN,

      AXI4_S_OP_TVALID      => M_AXI_RX_TVALID_1,
      AXI4_S_OP_TDATA       => M_AXI_RX_TDATA_1,
      AXI4_S_OP_TKEEP       => OPEN,
      AXI4_S_OP_TLAST       => OPEN,
      AXI4_S_IP_TREADY      => tied_to_ground_i

    );

    --______________________________________Instantiate RX_STREAM__________________________________

    aurora_interface_0_rx_stream_i : entity work.aurora_interface_0_RX_STREAM
    port map
    (
        -- AXI PDU Interface
        RX_D                =>  rx_data_0, 
        RX_SRC_RDY_N        =>  rx_src_rdy_0,


        -- Global Logic Interface
        START_RX        =>  start_rx_0_i,


        -- Aurora Lane Interface
        RX_PAD          =>  rx_pad_0_i,
        RX_PE_DATA      =>  rx_pe_data_0_i,
        RX_PE_DATA_V    =>  rx_pe_data_v_0_i,
        RX_SCP          =>  rx_scp_0_i,
        RX_ECP          =>  rx_ecp_0_i,


        -- System Interface
        USER_CLK        =>  USER_CLK_0

    );

    aurora_interface_1_rx_stream_i : entity work.aurora_interface_0_RX_STREAM
    port map
    (
        -- AXI PDU Interface
        RX_D                =>  rx_data_1, 
        RX_SRC_RDY_N        =>  rx_src_rdy_1,


        -- Global Logic Interface
        START_RX        =>  start_rx_1_i,


        -- Aurora Lane Interface
        RX_PAD          =>  rx_pad_1_i,
        RX_PE_DATA      =>  rx_pe_data_1_i,
        RX_PE_DATA_V    =>  rx_pe_data_v_1_i,
        RX_SCP          =>  rx_scp_1_i,
        RX_ECP          =>  rx_ecp_1_i,


        -- System Interface
        USER_CLK        =>  USER_CLK_1

    );



end MAPPED;
