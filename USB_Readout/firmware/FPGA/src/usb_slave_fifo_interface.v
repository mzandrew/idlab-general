
`timescale 1ns/1ps

//the implementation in this file simply realizes the slave fifo operations in the EZ-USB FX2 specification
//However, in the specification each transfer of a single word takes 2 clock cycles;
//No documentent is provided about whether and how bursting is supported by the EZ-USB FX2 chip
//So, those who are interested may have to do some experiments to check that.

//values for optimizing the throughputs and delays of the two directions 
//the user can try different values for their specific requirements

//Four channels have been implemented, all of which use the fifo interface
//Among them, two channels are for the transfer from FPGA->USB, one for Control&Status(CS) and the other for data;
//The other two are for the transfer from USB->FPGA, one for Control&Status(CS) and the other for data;
//The service priority is: USB2FPGA.CS>FPGA2USB.CS>USB2FPGA.DATA>FPGA2USB.DATA.

//note that the minimum value of X_TIME_OUT is 1, NOT 0;
//Also, the minimum value of X_MAX_LENGTH is 2, NOT (1 or 0);
`define USB2FPGA_CS_MAX_LENGTH 513 //=real+1. In this case, real is 512. max 255
`define USB2FPGA_CS_TIME_OUT 5 //max 255

`define USB2FPGA_DATA_MAX_LENGTH 513 //=real+1. In this case, real is 512. max 255
`define USB2FPGA_DATA_TIME_OUT 5 //max 255

`define FPGA2USB_CS_MAX_LENGTH 512 //max 255
`define FPGA2USB_CS_TIME_OUT 5 // max 255

`define FPGA2USB_DATA_MAX_LENGTH 512 //max 1023
`define FPGA2USB_DATA_TIME_OUT 5 //max 255

//EP point configuration
`define USB2FPGA_DATA_EP 2'b00 //EP2
`define USB2FPGA_CS_EP 2'b01 //EP4
`define FPGA2USB_DATA_EP 2'b10 //EP6
`define FPGA2USB_CS_EP 2'b11 //EP8

//the internal write fifo interfaces can be pipelined, as long as enough margin in the fifo is reserved
module usb_slave_fifo_interface
	(
	 input clk,
	 input rst,
	 //request
	 input fpga2usb_data_req,
	 input fpga2usb_cs_req,
	 //----------USB SLAVE FIFO--------------------
	 //read interface
	 input sl_data_fifo_empty, //USB2FPGA DATA FIFO (i.e., OUT EP for data) 
	 input sl_cs_fifo_empty, //USB2FPGA CS FIFO (i.e., OUT EP for Control&Status)
	 output sl_rd, //slave fifo read
	 input [15:0] sl_rd_data, //slave fifo rd data
	 //write interface
	 input sl_data_fifo_full, //FPGA2USB DATA FIFO(i.e., IN EP for data)
	 input sl_cs_fifo_full, //FPGA2USB CS FIFO(i.e., IN EP for CS)
	 output reg sl_wr, //slave fifo write
	 output [15:0] sl_wr_data,
	 output reg sl_pktend,
	 //read and write shared
	 output reg[1:0] sl_fifo_adr,
	 output reg sl_oe, //slave fifo output enable
	 //-----------Internal WR FIFO -------------------
	 //write cs fifo interface
	 output [15:0] wr_cs_fifo_data,
	 input wr_cs_fifo_full,
	 output wr_cs_fifo_we, //write enable
	 //write data fifo interface
	 output [15:0] wr_data_fifo_data,
	 input wr_data_fifo_full,
	 output wr_data_fifo_we, //write enable
	 //-----------Internal RD FIFO --------------
	 //read data fifo interface
	 input rd_data_fifo_empty,
	 input [15:0] rd_data_fifo_data,
	 output rd_data_fifo_re,//read enable
	 //read cs fifo interface
	 input rd_cs_fifo_empty,
	 input [15:0] rd_cs_fifo_data,
	 output rd_cs_fifo_re//read enable
	);

parameter SIZE=4;
reg [SIZE-1:0] state;
parameter IDLE=0,

	  U2F_CS_ADR=1,
	  U2F_CS_SLOE=2,
	  U2F_CS_DATA=3,
	  U2F_CS_WAIT=4,

	  U2F_DATA_ADR=5,
	  U2F_DATA_SLOE=6,
	  U2F_DATA_DATA=7,
	  U2F_DATA_WAIT=8,

	  F2U_CS_ADR=9,		
	  F2U_CS_CHECK=10,
	  F2U_CS_DATA=11,

	  F2U_DATA_ADR=12,
	  F2U_DATA_CHECK=13,
	  F2U_DATA_DATA=14,
	  F2U_PKTEND=15;	

//---------------------------------
reg [7:0] u2f_cs_timeout_cnt;
reg [7:0] u2f_cs_transferred_length;
wire u2f_cs_timeout;
wire u2f_cs_overpass_length;
wire last_u2f_cs_transfer;
wire next_u2f_cs_transfer;

reg wr_cs_fifo_we_reg;
reg[15:0] wr_cs_fifo_data_reg;

wire sl_rden_cs;
//---------------------------------
reg [7:0] u2f_data_timeout_cnt;
reg [9:0] u2f_data_transferred_length;
wire u2f_data_timeout;
wire u2f_data_overpass_length;
wire last_u2f_data_transfer;
wire next_u2f_data_transfer;

reg wr_data_fifo_we_reg;
reg[15:0] wr_data_fifo_data_reg;

wire sl_rden_data;
//---------------------------------
reg [7:0] f2u_cs_timeout_cnt;
wire f2u_cs_timeout;
reg [7:0] f2u_cs_transferred_length;
wire f2u_cs_overpass_length;
wire last_f2u_cs_transfer;
wire next_f2u_cs_transfer;

//--------------------------------
reg [7:0] f2u_data_timeout_cnt;
wire f2u_data_timeout;
reg [9:0] f2u_data_transferred_length;
wire f2u_data_overpass_length;
wire last_f2u_data_transfer;
wire next_f2u_data_transfer;
//--------------------------------
wire usb2fpga_cs_req;
wire usb2fpga_data_req;
wire fpga2usb_cs_req_in;
wire fpga2usb_data_req_in;

reg sl_cs_fifo_empty_in;
reg sl_data_fifo_empty_in;

always@(posedge clk or posedge rst) begin
	if(rst)
		sl_cs_fifo_empty_in<=1'b1;
	else
		sl_cs_fifo_empty_in<=sl_cs_fifo_empty;
end

always@(posedge clk or posedge rst) begin
	if(rst)
		sl_data_fifo_empty_in<=1'b1;
	else
		sl_data_fifo_empty_in<=sl_data_fifo_empty;
end

assign usb2fpga_cs_req=(~sl_cs_fifo_empty_in);
assign usb2fpga_data_req=(~sl_data_fifo_empty_in);

assign fpga2usb_cs_req_in=(fpga2usb_cs_req)&(~sl_cs_fifo_full);
assign fpga2usb_data_req_in=(fpga2usb_data_req)&(~sl_data_fifo_full);

reg f2u_switch;

always@(posedge clk) begin
	if(rst)
		f2u_switch<=1'b0;	
	else if(state==F2U_CS_ADR)
		f2u_switch<=1'b1;
	else if(state==F2U_DATA_ADR)
		f2u_switch<=1'b0;
	else
		f2u_switch<=f2u_switch;
end

always@(posedge clk or posedge rst) begin
	if(rst) begin
		state<=IDLE;

		sl_fifo_adr<=2'b00;
		sl_oe<=1'b0;

		sl_wr<=1'b0;
		sl_pktend<=1'b0;
	end else begin
		case(state)
			IDLE: 	begin 
					if(usb2fpga_cs_req & (!wr_cs_fifo_full)) begin//priority circuit
						state<=U2F_CS_ADR;
						
						sl_fifo_adr<=`USB2FPGA_CS_EP;
						sl_oe<=1'b0;

						sl_wr<=1'b0;
						sl_pktend<=1'b0;
					end else if(fpga2usb_cs_req_in & (!rd_cs_fifo_empty)) begin
						state<=F2U_CS_ADR;

						sl_fifo_adr<=`FPGA2USB_CS_EP;
						sl_oe<=1'b0;

						sl_wr<=1'b0;
						sl_pktend<=1'b0;
					end else if(usb2fpga_data_req & (!wr_data_fifo_full)) begin
						state<=U2F_DATA_ADR;

						sl_fifo_adr<=`USB2FPGA_DATA_EP;
						sl_oe<=1'b0;

						sl_wr<=1'b0;
						sl_pktend<=1'b0;
					end else if(fpga2usb_data_req_in & (!rd_data_fifo_empty)) begin
						state<=F2U_DATA_ADR;

						sl_fifo_adr<=`FPGA2USB_DATA_EP;
						sl_oe<=1'b0;

						sl_wr<=1'b0;
						sl_pktend<=1'b0;
					end else begin
						state<=IDLE;

						sl_fifo_adr<=2'b00;
						sl_oe<=1'b0;

						sl_wr<=1'b0;
						sl_pktend<=1'b0;
					end
				end		
			//-----------------------------------------------------------
			U2F_CS_ADR:	begin
						state<=U2F_CS_SLOE;	

						sl_fifo_adr<=`USB2FPGA_CS_EP;
						sl_oe<=1'b1;

						sl_wr<=1'b0;
						sl_pktend<=1'b0;
					end
			U2F_CS_SLOE:	begin
						state<=U2F_CS_DATA;

						sl_fifo_adr<=`USB2FPGA_CS_EP;
						sl_oe<=1'b1;

						sl_wr<=1'b0;
						sl_pktend<=1'b0;
					end
			U2F_CS_DATA:	begin
						state<=U2F_CS_WAIT;

						sl_fifo_adr<=`USB2FPGA_CS_EP;
						sl_oe<=1'b1;

						sl_wr<=1'b0;
						sl_pktend<=1'b0;
					end
			U2F_CS_WAIT:	begin
						sl_wr<=1'b0;
						sl_pktend<=1'b0;
						if(last_u2f_cs_transfer) begin//finished
							state<=IDLE;

							sl_fifo_adr<=2'b00;
							sl_oe<=1'b0;
						end else if(next_u2f_cs_transfer)begin
							state<=U2F_CS_DATA;

							sl_fifo_adr<=`USB2FPGA_CS_EP;
							sl_oe<=1'b1;
						end else begin
							state<=state;

							sl_fifo_adr<=`USB2FPGA_CS_EP;
							sl_oe<=1'b1;
						end
					end
			//-----------------------------------------------------------
			U2F_DATA_ADR:	begin
						state<=U2F_DATA_SLOE;	

						sl_fifo_adr<=`USB2FPGA_DATA_EP;
						sl_oe<=1'b1;

						sl_wr<=1'b0;
						sl_pktend<=1'b0;
					end
			U2F_DATA_SLOE:	begin
						state<=U2F_DATA_DATA;

						sl_fifo_adr<=`USB2FPGA_DATA_EP;
						sl_oe<=1'b1;

						sl_wr<=1'b0;
						sl_pktend<=1'b0;
					end
			U2F_DATA_DATA:	begin
						state<=U2F_DATA_WAIT;

						sl_fifo_adr<=`USB2FPGA_DATA_EP;
						sl_oe<=1'b1;

						sl_wr<=1'b0;
						sl_pktend<=1'b0;
					end
			U2F_DATA_WAIT:	begin
						sl_wr<=1'b0;
						sl_pktend<=1'b0;
						if(last_u2f_data_transfer) begin//finished
							state<=IDLE;

							sl_fifo_adr<=2'b00;
							sl_oe<=1'b0;
						end else if(next_u2f_data_transfer)begin
							state<=U2F_DATA_DATA;

							sl_fifo_adr<=`USB2FPGA_DATA_EP;
							sl_oe<=1'b1;
						end else begin
							state<=state;

							sl_fifo_adr<=`USB2FPGA_DATA_EP;
							sl_oe<=1'b1;
						end
					end
			//-----------------------------------------------------------
			F2U_CS_ADR:	begin	
						state<=F2U_CS_CHECK;						
						
						sl_fifo_adr<=`FPGA2USB_CS_EP;
						sl_oe<=1'b0;

						sl_wr<=1'b0;
						sl_pktend<=1'b0;
					end
			F2U_CS_CHECK: begin
					 	sl_oe<=1'b0;
						if(last_f2u_cs_transfer) begin
							state<=F2U_PKTEND;
							sl_fifo_adr<=`FPGA2USB_CS_EP;

							sl_wr<=1'b0;
							if(f2u_cs_transferred_length>0)
								sl_pktend<=1'b1;
							else
								sl_pktend<=1'b0;
						end else if(next_f2u_cs_transfer) begin
							state<=F2U_CS_DATA;
							sl_fifo_adr<=`FPGA2USB_CS_EP;

							sl_wr<=1'b1;
							sl_pktend<=1'b0;
						end else begin
							state<=state;
							sl_fifo_adr<=`FPGA2USB_CS_EP;

							sl_wr<=1'b0;
							sl_pktend<=1'b0;
						end
					end
			F2U_CS_DATA:	begin
						state<=F2U_CS_CHECK;

						sl_fifo_adr<=`FPGA2USB_CS_EP;
						sl_oe<=1'b0;

						sl_wr<=1'b0;
						sl_pktend<=1'b0;
					end
			//-----------------------------------------------------------
			F2U_DATA_ADR:	begin	
						state<=F2U_DATA_CHECK;						
						
						sl_fifo_adr<=`FPGA2USB_DATA_EP;
						sl_oe<=1'b0;

						sl_wr<=1'b0;
						sl_pktend<=1'b0;
					end
			F2U_DATA_CHECK: begin
					 	sl_oe<=1'b0;
						if(last_f2u_data_transfer) begin
							state<=F2U_PKTEND;
							sl_fifo_adr<=`FPGA2USB_DATA_EP;

							sl_wr<=1'b0;
							if(f2u_data_transferred_length>0)
								sl_pktend<=1'b1;
							else
								sl_pktend<=1'b0;
						end else if(next_f2u_data_transfer) begin
							state<=F2U_DATA_DATA;
							sl_fifo_adr<=`FPGA2USB_DATA_EP;

							sl_wr<=1'b1;
							sl_pktend<=1'b0;
						end else begin
							state<=state;
							sl_fifo_adr<=`FPGA2USB_DATA_EP;

							sl_wr<=1'b0;
							sl_pktend<=1'b0;
						end
					end
			F2U_DATA_DATA:	begin
						state<=F2U_DATA_CHECK;

						sl_fifo_adr<=`FPGA2USB_DATA_EP;
						sl_oe<=1'b0;

						sl_wr<=1'b0;
						sl_pktend<=1'b0;
					end
			 F2U_PKTEND: begin
						state<=IDLE;
						sl_fifo_adr<=2'b00;
						sl_oe<=1'b0;
						sl_wr<=1'b0;
						sl_pktend<=1'b0;
					end
			//-----------------------------------------------------------
			default: begin 	
					state<=IDLE;
						
					sl_fifo_adr<=2'b00;
					sl_oe<=1'b0;

					sl_wr<=1'b0;
					sl_pktend<=1'b0;
				 end
		endcase
	end
end

//-------------------------------------------------------------------------------------------

always@(posedge clk or posedge rst) begin
	if(rst)
		u2f_cs_timeout_cnt<=8'b0;
	else begin
		if(state==U2F_CS_DATA)
			u2f_cs_timeout_cnt<=8'b0;
		else if(state==U2F_CS_WAIT)
			u2f_cs_timeout_cnt<=u2f_cs_timeout_cnt+1'b1;
		else
			u2f_cs_timeout_cnt<=u2f_cs_timeout_cnt;
	end
end

assign u2f_cs_timeout=(u2f_cs_timeout_cnt==`USB2FPGA_CS_TIME_OUT);

always@(posedge clk or posedge rst) begin
	if(rst)
		u2f_cs_transferred_length<=8'b0;
	else begin
		if(state==IDLE)
			u2f_cs_transferred_length<=8'b0;
		else if(state==U2F_CS_DATA)
			u2f_cs_transferred_length<=u2f_cs_transferred_length+1'b1;
		else
			u2f_cs_transferred_length<=u2f_cs_transferred_length;
	end
end

assign u2f_cs_overpass_length=(u2f_cs_transferred_length==`USB2FPGA_CS_MAX_LENGTH);

assign last_u2f_cs_transfer=u2f_cs_timeout|u2f_cs_overpass_length;

assign next_u2f_cs_transfer=(!sl_cs_fifo_empty_in)&(!wr_cs_fifo_full);

always@(posedge clk or posedge rst) begin
	if(rst) begin
		wr_cs_fifo_we_reg<=1'b0;
		wr_cs_fifo_data_reg<=16'b0;
	end else begin
		wr_cs_fifo_data_reg<=sl_rd_data;
		if(state==U2F_CS_WAIT && last_u2f_cs_transfer==1'b0 && next_u2f_cs_transfer==1'b1)
			wr_cs_fifo_we_reg<=1'b1;
		else
			wr_cs_fifo_we_reg<=1'b0;
	end
end

assign wr_cs_fifo_we = wr_cs_fifo_we_reg;

assign wr_cs_fifo_data = wr_cs_fifo_data_reg;

assign sl_rden_cs=(state==U2F_CS_WAIT && last_u2f_cs_transfer==1'b0 && next_u2f_cs_transfer==1'b1);

//-------------------------------------------------------------------------------------------
always@(posedge clk or posedge rst) begin
	if(rst)
		u2f_data_timeout_cnt<=8'b0;
	else begin
		if(state==U2F_DATA_DATA)
			u2f_data_timeout_cnt<=8'b0;
		else if(state==U2F_DATA_WAIT)
			u2f_data_timeout_cnt<=u2f_data_timeout_cnt+1'b1;
		else
			u2f_data_timeout_cnt<=u2f_data_timeout_cnt;
	end
end

assign u2f_data_timeout=(u2f_data_timeout_cnt==`USB2FPGA_DATA_TIME_OUT);

always@(posedge clk or posedge rst) begin
	if(rst)
		u2f_data_transferred_length<=10'b0;
	else begin
		if(state==IDLE)
			u2f_data_transferred_length<=10'b0;
		else if(state==U2F_DATA_DATA)
			u2f_data_transferred_length<=u2f_data_transferred_length+1'b1;
		else
			u2f_data_transferred_length<=u2f_data_transferred_length;
	end
end

assign u2f_data_overpass_length=(u2f_data_transferred_length==`USB2FPGA_DATA_MAX_LENGTH);

assign last_u2f_data_transfer=u2f_data_timeout|u2f_data_overpass_length;

assign next_u2f_data_transfer=(!sl_data_fifo_empty_in)&(!wr_data_fifo_full);

always@(posedge clk or posedge rst) begin
	if(rst) begin
		wr_data_fifo_we_reg<=1'b0;
		wr_data_fifo_data_reg<=16'b0;
	end else begin
		wr_data_fifo_data_reg<=sl_rd_data;
		if(state==U2F_DATA_WAIT && last_u2f_data_transfer==1'b0 && next_u2f_data_transfer==1'b1)
			wr_data_fifo_we_reg<=1'b1;
		else
			wr_data_fifo_we_reg<=1'b0;
	end
end

assign wr_data_fifo_we = wr_data_fifo_we_reg;

assign wr_data_fifo_data = wr_data_fifo_data_reg;

assign sl_rden_data=(state==U2F_DATA_WAIT && last_u2f_data_transfer==1'b0 && next_u2f_data_transfer==1'b1);

//----------------------------------------------------------------------------------------------------

assign sl_rd=sl_rden_cs|sl_rden_data;

//----------------------------------------------------------------------------------------------------


always@(posedge clk or posedge rst) begin
	if(rst)
		f2u_cs_timeout_cnt<=8'b0;
	else begin
		if(state==F2U_CS_ADR || state==F2U_CS_DATA)
			f2u_cs_timeout_cnt<=8'b0;
		else if(state==F2U_CS_CHECK)
			f2u_cs_timeout_cnt<=f2u_cs_timeout_cnt+1'b1;
		else
			f2u_cs_timeout_cnt<=f2u_cs_timeout_cnt;
	end
end

assign f2u_cs_timeout=(f2u_cs_timeout_cnt==`FPGA2USB_CS_TIME_OUT);

always@(posedge clk or posedge rst) begin
	if(rst)
		f2u_cs_transferred_length<=8'b0;
	else begin
		if(state==IDLE)
			f2u_cs_transferred_length<=8'b0;
		else if(state==F2U_CS_DATA)
			f2u_cs_transferred_length<=f2u_cs_transferred_length+1'b1;
		else
			f2u_cs_transferred_length<=f2u_cs_transferred_length;
	end
end

assign f2u_cs_overpass_length=(f2u_cs_transferred_length==`FPGA2USB_CS_MAX_LENGTH);

assign last_f2u_cs_transfer=f2u_cs_timeout|f2u_cs_overpass_length;

assign next_f2u_cs_transfer=(!sl_cs_fifo_full) & (!rd_cs_fifo_empty);

assign rd_cs_fifo_re=(state==F2U_CS_CHECK && last_f2u_cs_transfer==1'b0 && next_f2u_cs_transfer==1'b1);

//---------------------------------------------------------------------------------------------------------

always@(posedge clk or posedge rst) begin
	if(rst)
		f2u_data_timeout_cnt<=10'b0;
	else begin
		if(state==F2U_DATA_ADR || state==F2U_DATA_DATA)
			f2u_data_timeout_cnt<=10'b0;
		else if(state==F2U_DATA_CHECK)
			f2u_data_timeout_cnt<=f2u_data_timeout_cnt+1'b1;
		else
			f2u_data_timeout_cnt<=f2u_data_timeout_cnt;
	end
end

assign f2u_data_timeout=(f2u_data_timeout_cnt==`FPGA2USB_DATA_TIME_OUT);

always@(posedge clk or posedge rst) begin
	if(rst)
		f2u_data_transferred_length<=8'b0;
	else begin
		if(state==IDLE)
			f2u_data_transferred_length<=8'b0;
		else if(state==F2U_DATA_DATA)
			f2u_data_transferred_length<=f2u_data_transferred_length+1'b1;
		else
			f2u_data_transferred_length<=f2u_data_transferred_length;
	end
end

assign f2u_data_overpass_length=(f2u_data_transferred_length==`FPGA2USB_DATA_MAX_LENGTH);

assign last_f2u_data_transfer=f2u_data_timeout|f2u_data_overpass_length;

assign next_f2u_data_transfer=(!sl_data_fifo_full) & (!rd_data_fifo_empty);

assign rd_data_fifo_re=(state==F2U_DATA_CHECK && last_f2u_data_transfer==1'b0 && next_f2u_data_transfer==1'b1);

//------------------------------------------------------------------------------------------------------

assign sl_wr_data=(f2u_switch==1'b1)? rd_cs_fifo_data:rd_data_fifo_data;

endmodule


