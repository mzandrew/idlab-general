`timescale 1ns/1ps

module usb_top
(
 //Cypress signal pins
 input IFCLK,
 input CTL0,
 input CTL1,
 input CTL2,
 inout[15:0] FDD,
 output PA0,
 output PA1,
 output PA2,
 output PA3,
 output PA4,
 output PA5,
 output PA6,
 input PA7,
 output RDY0,
 output RDY1,
 input WAKEUP,
 input CLKOUT,
 //Reset signal generated from wakeup
 output USB_RESET,
 //Signals for the FIFO interfacing
 output FIFO_CLOCK,
 output[15:0] EP2_DATA,
 output       EP2_WRITE_ENABLE,
 input        EP2_FULL,
 output[15:0] EP4_DATA,
 output       EP4_WRITE_ENABLE,
 input        EP4_FULL,
 input[15:0]  EP6_DATA,
 output       EP6_READ_ENABLE,
 input        EP6_EMPTY,
 input[15:0]  EP8_DATA,
 output       EP8_READ_ENABLE,
 input        EP8_EMPTY
);

wire rst_usb_clk;
wire rst;

wire usb_buffed_ifclk_in;
wire usb_locked_ifclk_in;
wire usb_ifclk_in_locked;
wire usb_flagA_in;
wire usb_flagB_in;
wire usb_flagC_in;
wire usb_flagD_in;

wire [15:0] usb_fd_out;
wire [15:0] usb_fd_in;
wire usb_sloe;
wire [1:0] usb_fifo_adr;
wire usb_pktend;
wire usb_slrd;
wire usb_slwr;
wire usb_wakeup_in;

wire[15:0] wr_cs_fifo_data;
wire wr_cs_fifo_full;
wire wr_cs_fifo_we;

wire[15:0] wr_data_fifo_data;
wire wr_data_fifo_full;
wire wr_data_fifo_we;

wire rd_data_fifo_empty;
wire[15:0] rd_data_fifo_data; 
wire rd_data_fifo_re;

wire rd_cs_fifo_empty;
wire[15:0] rd_cs_fifo_data; 
wire rd_cs_fifo_re;

wire rst_external;

wire fpga2usb_data_req;
wire fpga2usb_cs_req;

wire sl_cs_fifo_empty;
wire sl_data_fifo_empty;
wire sl_cs_fifo_full;
wire sl_data_fifo_full;

assign sl_cs_fifo_empty= usb_flagA_in; //connect to the empty flag of EP4
assign sl_data_fifo_empty= usb_flagB_in; //connect to the empty flag of EP2
assign sl_cs_fifo_full= usb_flagC_in; //connect to the full flag of EP8
assign sl_data_fifo_full= usb_flagD_in; //connect to the full flag of EP6

assign FIFO_CLOCK = usb_locked_ifclk_in;

assign EP2_DATA = wr_data_fifo_data;
assign wr_data_fifo_full = EP2_FULL;
assign EP2_WRITE_ENABLE = wr_data_fifo_we;

assign EP4_DATA = wr_cs_fifo_data;
assign wr_cs_fifo_full = EP4_FULL;
assign EP4_WRITE_ENABLE = wr_cs_fifo_we;

assign rd_data_fifo_data = EP6_DATA;
assign rd_data_fifo_empty = EP6_EMPTY;
assign EP6_READ_ENABLE = rd_data_fifo_re;

assign rd_cs_fifo_data = EP8_DATA;
assign rd_cs_fifo_empty = EP8_EMPTY;
assign EP8_READ_ENABLE = rd_cs_fifo_re;

assign fpga2usb_data_req=1'b1;
assign fpga2usb_cs_req=1'b1;

assign USB_RESET = rst;

usb_slave_fifo_interface_io u_usb_slave_fifo_interface_io(
    .rst(rst_usb_clk), 
    .IFCLK(IFCLK), 
    .usb_buffed_ifclk_in(usb_buffed_ifclk_in), 
    .usb_locked_ifclk_in(usb_locked_ifclk_in), 
    .usb_ifclk_in_locked(usb_ifclk_in_locked), 
    .CTL0(CTL0), 
    .CTL1(CTL1), 
    .CTL2(CTL2), 
    .usb_flagA_in(usb_flagA_in), 
    .usb_flagB_in(usb_flagB_in), 
    .usb_flagC_in(usb_flagC_in), 
    .usb_flagD_in(usb_flagD_in),
    .FDD(FDD), 
    .usb_fd_out(usb_fd_out), 
    .usb_fd_in(usb_fd_in), 
    .PA2(PA2), 
    .usb_sloe(usb_sloe), 
    .PA4(PA4), 
    .PA5(PA5), 
    .usb_fifo_adr(usb_fifo_adr), 
    .PA6(PA6), 
    .usb_pktend(usb_pktend), 
    .RDY0(RDY0), 
    .usb_slrd(usb_slrd), 
    .RDY1(RDY1), 
    .usb_slwr(usb_slwr), 
    .WAKEUP(WAKEUP), 
    .usb_wakeup_in(usb_wakeup_in), 
    .PA0(PA0), 
    .PA1(PA1), 
    .PA3(PA3), 
    .PA7(PA7), 
    .CLKOUT(CLKOUT)
    );

usb_slave_fifo_interface u_usb_slave_fifo_interface (
    .clk(usb_locked_ifclk_in), 
    .rst(rst), 

    .fpga2usb_data_req(fpga2usb_data_req), 
    .fpga2usb_cs_req(fpga2usb_cs_req), 

    .sl_data_fifo_empty(sl_data_fifo_empty), 
    .sl_cs_fifo_empty(sl_cs_fifo_empty),

    .sl_rd(usb_slrd), 
    .sl_rd_data(usb_fd_in), 

    .sl_data_fifo_full(sl_data_fifo_full), 
    .sl_cs_fifo_full(sl_cs_fifo_full),

    .sl_wr(usb_slwr), 
    .sl_wr_data(usb_fd_out), 
    .sl_pktend(usb_pktend), 
    .sl_fifo_adr(usb_fifo_adr), 
    .sl_oe(usb_sloe), 

    .wr_cs_fifo_data(wr_cs_fifo_data), 
    .wr_cs_fifo_full(wr_cs_fifo_full), 
    .wr_cs_fifo_we(wr_cs_fifo_we), 

    .wr_data_fifo_data(wr_data_fifo_data), 
    .wr_data_fifo_full(wr_data_fifo_full), 
    .wr_data_fifo_we(wr_data_fifo_we), 

    .rd_data_fifo_empty(rd_data_fifo_empty), 
    .rd_data_fifo_data(rd_data_fifo_data), 
    .rd_data_fifo_re(rd_data_fifo_re), 

    .rd_cs_fifo_empty(rd_cs_fifo_empty), 
    .rd_cs_fifo_data(rd_cs_fifo_data), 
    .rd_cs_fifo_re(rd_cs_fifo_re)
    );

usb_init u_init(
    .clk(usb_buffed_ifclk_in), 
    .wakeup(usb_wakeup_in),

    .usb_clk_lock(usb_ifclk_in_locked), 
    .usb_clk_rst(rst_usb_clk),

    .rst(rst_external), 
    .n_ready(rst)
    );

//----------------------------------------------------- for test ------------------------------------------------------

endmodule

