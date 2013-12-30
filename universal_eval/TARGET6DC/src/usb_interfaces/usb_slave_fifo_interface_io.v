`timescale 1ns/1ps

module usb_slave_fifo_interface_io
	(
	 input rst,

	 input IFCLK,
	 output usb_buffed_ifclk_in,
	 output usb_locked_ifclk_in,
	 output usb_ifclk_in_locked,

	 input CTL0,
	 input CTL1,
	 input CTL2,
	 output usb_flagA_in,
	 output usb_flagB_in,
	 output usb_flagC_in,

	 inout[15:0] FDD,
	 input[15:0] usb_fd_out,
	 output[15:0] usb_fd_in,

	 output PA2,
	 input usb_sloe,

	 output PA4,
	 output PA5,
	 input[1:0] usb_fifo_adr, 

	 output PA6,
	 input usb_pktend,

	 output RDY0,
	 input usb_slrd,

	 output RDY1,
	 input usb_slwr,

	 input WAKEUP,
	 output usb_wakeup_in,
	 
	 //PA0,1 are not used, tied to high
	 output PA0,
	 output PA1,

	 //PA3 is not used, tied to low
	 output PA3,

	 //PA7 is not used, tied to low
	 input PA7, //used as FLAGD
	 output usb_flagD_in,
	 
	 //CLKOUT is not used, floating
	 input CLKOUT
	);

//lock the input clock

 USB_IFCLK_XC3S400 u_USB_IFCLK (
    .CLKIN_IN(IFCLK), 
    .RST_IN(rst), 
    .CLKIN_IBUFG_OUT(usb_buffed_ifclk_in), 
    .CLK0_OUT(usb_locked_ifclk_in), 
    .LOCKED_OUT(usb_ifclk_in_locked)
    );	 
//
IBUF FLAGA_BUF(.I(CTL0),.O(usb_flagA_in));
IBUF FLAGB_BUF(.I(CTL1),.O(usb_flagB_in));
IBUF FLAGC_BUF(.I(CTL2),.O(usb_flagC_in));

//
OBUF SLOE_BUF(.I(usb_sloe),.O(PA2));
OBUF FIFO_ADR0_BUF(.I(usb_fifo_adr[0]),.O(PA4));
OBUF FIFO_ADR1_BUF(.I(usb_fifo_adr[1]),.O(PA5));
OBUF PKTEND_BUF(.I(usb_pktend),.O(PA6));

//
OBUF SLRD_BUF(.I(usb_slrd),.O(RDY0));
OBUF SLWR_BUF(.I(usb_slwr),.O(RDY1));

//
IBUF WAKEUP_BUF(.I(WAKEUP),.O(usb_wakeup_in));

//
OBUF PA0_BUF(.I(1'b1),.O(PA0));
OBUF PA1_BUF(.I(1'b1),.O(PA1));
OBUF PA3_BUF(.I(1'b0),.O(PA3));

IBUF PA7_BUF(.I(PA7),.O(usb_flagD_in));

IBUF CLKOUT_BUF(.I(CLKOUT),.O()); //floating

//
generate
genvar i;
for(i=0;i<16;i=i+1) begin: USB_DATA_BUF

	IBUF FDD_IN_BUF(.I(FDD[i]),.O(usb_fd_in[i]));
	OBUFT FDD_OUT_BUF(.T(usb_sloe),.I(usb_fd_out[i]),.O(FDD[i]));

end
endgenerate

endmodule

