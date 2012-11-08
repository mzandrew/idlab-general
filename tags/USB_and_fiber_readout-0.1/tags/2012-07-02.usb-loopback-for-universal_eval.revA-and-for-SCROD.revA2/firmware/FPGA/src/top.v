`timescale 1ns/1ps

module top
(
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
 input CLKOUT
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

wire sl_cs_fifo_empty;
wire sl_data_fifo_empty;
wire sl_cs_fifo_full;
wire sl_data_fifo_full;

assign sl_cs_fifo_empty= usb_flagA_in; //connect to the empty flag of EP4
assign sl_data_fifo_empty= usb_flagB_in; //connect to the empty flag of EP2
assign sl_cs_fifo_full= usb_flagC_in; //connect to the full flag of EP8
assign sl_data_fifo_full= usb_flagD_in; //connect to the full flag of EP6

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

    .fpga2usb_data_req(1'b1), 
    .fpga2usb_cs_req(1'b1), 

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

init u_init(
    .clk(usb_buffed_ifclk_in),
    .wakeup(usb_wakeup_in),
    .usb_clk_lock(usb_ifclk_in_locked), 
    .usb_clk_rst(rst_usb_clk),
    .rst(1'b0), 
    .n_ready(rst)
    );

//----------------------------------------------------- for test ------------------------------------------------------

//FIFOs for test 

test_usb_fifo u_test_usb_fifo_data (
  .clk(usb_locked_ifclk_in), // input clk
  .rst(rst), // input rst
  .din(wr_data_fifo_data), // input [15 : 0] din
  .wr_en(wr_data_fifo_we), // input wr_en
  .rd_en(rd_data_fifo_re), // input rd_en
  .dout(rd_data_fifo_data), // output [15 : 0] dout
  .full(wr_data_fifo_full), // output full
  .empty(rd_data_fifo_empty) // output empty
);

test_usb_fifo u_test_usb_fifo_cs (
  .clk(usb_locked_ifclk_in), // input clk
  .rst(rst), // input rst
  .din(wr_cs_fifo_data), // input [15 : 0] din
  .wr_en(wr_cs_fifo_we), // input wr_en
  .rd_en(rd_cs_fifo_re), // input rd_en
  .dout(rd_cs_fifo_data), // output [15 : 0] dout
  .full(wr_cs_fifo_full), // output full
  .empty(rd_cs_fifo_empty) // output empty
);

//debug units

//icon

wire [35:0] control0,control1,control2;

u_icon u_u_icon(
    .CONTROL0(control0), // INOUT BUS [35:0]
    .CONTROL1(control1), // INOUT BUS [35:0]
    .CONTROL2(control2) // INOUT BUS [35:0]
);

//usb interface capture 

wire [63:0] usb_ila_data;
reg [63:0] usb_ila_data_reg;

assign usb_ila_data[15:0]=usb_fd_in;
assign usb_ila_data[31:16]=usb_fd_out;
assign usb_ila_data[32]=usb_flagC_in;
assign usb_ila_data[33]=usb_slrd;
assign usb_ila_data[34]=usb_flagB_in;
assign usb_ila_data[35]=usb_slwr;
assign usb_ila_data[36]=usb_pktend;
assign usb_ila_data[38:37]=usb_fifo_adr;
assign usb_ila_data[39]=usb_sloe;
assign usb_ila_data[40]=usb_flagA_in;
assign usb_ila_data[41]=usb_flagD_in;
assign usb_ila_data[63:42]=22'b0;

always@(posedge usb_buffed_ifclk_in) begin
	usb_ila_data_reg<=usb_ila_data;
end

usb_ila u_usb_ila(
    .CONTROL(control0), // INOUT BUS [35:0]
    .CLK(usb_buffed_ifclk_in), // IN
    .TRIG0(usb_ila_data_reg) // IN BUS [63:0]
);

//internal fifo 1 interface capture

wire [63:0] fifo1_ila_data;
reg  [63:0] fifo1_ila_data_reg;

assign fifo1_ila_data[15:0]=wr_data_fifo_data;
assign fifo1_ila_data[31:16]=rd_data_fifo_data;
assign fifo1_ila_data[32]=wr_data_fifo_we;
assign fifo1_ila_data[33]=wr_data_fifo_full;
assign fifo1_ila_data[34]=rd_data_fifo_re;
assign fifo1_ila_data[35]=rd_data_fifo_empty;
assign fifo1_ila_data[63:36]=28'b0;

always@(posedge usb_buffed_ifclk_in) begin
	fifo1_ila_data_reg<=fifo1_ila_data;
end

fifo_ila u_fifo1_ila (
    .CONTROL(control1), // INOUT BUS [35:0]
    .CLK(usb_buffed_ifclk_in), // IN
    .TRIG0(fifo1_ila_data_reg) // IN BUS [63:0]
);

//internal fifo 2 interface capture

wire [63:0] fifo2_ila_data;
reg  [63:0] fifo2_ila_data_reg;

assign fifo2_ila_data[15:0]=wr_cs_fifo_data;
assign fifo2_ila_data[31:16]=rd_cs_fifo_data;
assign fifo2_ila_data[32]=wr_cs_fifo_we;
assign fifo2_ila_data[33]=wr_cs_fifo_full;
assign fifo2_ila_data[34]=rd_cs_fifo_re;
assign fifo2_ila_data[35]=rd_cs_fifo_empty;
assign fifo2_ila_data[63:36]=28'b0;

always@(posedge usb_buffed_ifclk_in) begin
	fifo2_ila_data_reg<=fifo2_ila_data;
end

fifo_ila u_fifo2_ila (
    .CONTROL(control2), // INOUT BUS [35:0]
    .CLK(usb_buffed_ifclk_in), // IN
    .TRIG0(fifo2_ila_data_reg) // IN BUS [63:0]
);

endmodule

