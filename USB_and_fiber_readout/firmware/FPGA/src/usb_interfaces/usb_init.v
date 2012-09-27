`timescale 1ns/1ps

module usb_init
	(
	 input clk,

	 input usb_clk_lock,
	 output reg usb_clk_rst,

	 input rst,
	 input wakeup,

	 output reg n_ready
	);

wire rst_in;
reg [31:0] counter;
reg [31:0] usb_clk_rst_cnt;

//----------------------------------------

initial begin
	usb_clk_rst_cnt<=32'b0;
end

always@(posedge clk) begin
	if(wakeup==1'b0)
		usb_clk_rst_cnt<=32'b0;
	if(usb_clk_rst_cnt[16]==1'b0)
		usb_clk_rst_cnt<=usb_clk_rst_cnt+1'b1;	
	else
		usb_clk_rst_cnt<=usb_clk_rst_cnt;
end

always@(posedge clk) begin
	usb_clk_rst=(~usb_clk_rst_cnt[16]);
end

//----------------------------------------

assign rst_in=rst|(!usb_clk_lock);

always@(posedge clk or posedge rst_in) begin
	if(rst_in)
		counter<=32'b0;
	else if(counter[25]==1'b0)
		counter<=counter+1'b1;
	else
		counter<=counter;
end

always@(posedge clk) begin
	n_ready<=(~counter[25]);
end

//----------------------------------------

endmodule

