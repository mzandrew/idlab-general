//-----------------------------------------------------------------------------
//   File:      periph.c
//   Contents:  Hooks required to implement USB peripheral function.
//
// $Archive: /USB/Target/Fw/lp/periph.c $
// $Date: 3/23/05 3:03p $
// $Revision: 3 $
//
//
//-----------------------------------------------------------------------------
// Copyright 2003, Cypress Semiconductor Corporation
//
// This software is owned by Cypress Semiconductor Corporation (Cypress) and is
// protected by United States copyright laws and international treaty provisions. Cypress
// hereby grants to Licensee a personal, non-exclusive, non-transferable license to copy,
// use, modify, create derivative works of, and compile the Cypress Source Code and
// derivative works for the sole purpose of creating custom software in support of Licensee
// product ("Licensee Product") to be used only in conjunction with a Cypress integrated
// circuit. Any reproduction, modification, translation, compilation, or representation of this
// software except as specified above is prohibited without the express written permission of
// Cypress.
//
// Disclaimer: Cypress makes no warranty of any kind, express or implied, with regard to
// this material, including, but not limited to, the implied warranties of merchantability and
// fitness for a particular purpose. Cypress reserves the right to make changes without
// further notice to the materials described herein. Cypress does not assume any liability
// arising out of the application or use of any product or circuit described herein. Cypress�
// products described herein are not authorized for use as components in life-support
// devices.
//
// This software is protected by and subject to worldwide patent coverage, including U.S.
// and foreign patents. Use may be limited by and subject to the Cypress Software License
// Agreement.
//-----------------------------------------------------------------------------
#pragma NOIV               // Do not generate interrupt vectors

#include "fx2.h"
#include "fx2regs.h"
#include "syncdly.h"            // SYNCDELAY macro

extern BOOL   GotSUD;         // Received setup data flag
extern BOOL   Sleep;
extern BOOL   Rwuen;
extern BOOL   Selfpwr;

BYTE   Configuration;      // Current configuration
BYTE   AlternateSetting;   // Alternate settings

//-----------------------------------------------------------------------------
// Task Dispatcher hooks
//   The following hooks are called by the task dispatcher.
//-----------------------------------------------------------------------------

void TD_Init(void)             // Called once at startup
{
 // set the CPU clock to 48MHz
   //CPUCS = ((CPUCS & ~bmCLKSPD) | bmCLKSPD1) ;

  //EP1OUTCFG,EP1INCFG,EP2CFG, EP4CFG, EP6CFG and EP8CFG
  EP1OUTCFG = 0xA0; //VALID,BULK
  EP1INCFG = 0xA0;//VALID,BULK
  SYNCDELAY;                    
  EP2CFG = 0xA2; //VALID,OUT,512 byte, BULK,DOUBLE BUFFERING
  SYNCDELAY;                    
  EP4CFG = 0xA0;//VALID,OUT,512 byte, BULK,
  SYNCDELAY;                    
  EP6CFG = 0xE2;//VALID,IN,512 byte, BULK,DOUBLE BUFFERING
  SYNCDELAY;                    
  EP8CFG = 0xE0;//VALID,IN,512 byte, BULK,
  SYNCDELAY;

   // set the slave FIFO interface to 48MHz, enable clock output, internal clock is used, inverted polarity, select slave fifo interface
   IFCONFIG = 0xE3;

   //REVCTL
   REVCTL=0x03;
   SYNCDELAY;   

   //FIFORESET  
   FIFORESET=0x80;//NAK
   SYNCDELAY;
   FIFORESET=0x02;//RESET the EP2 fifo
   SYNCDELAY;
   FIFORESET=0x04;//RESET the EP4 fifo
   SYNCDELAY;  
   FIFORESET=0x06;//RESET the EP6 fifo
   SYNCDELAY;
   FIFORESET=0x08;//RESET the EP8 fifo
   SYNCDELAY; 
   FIFORESET=0x00;//restore the normal operation
   SYNCDELAY;

   //OUTPKTEND to arm output EPs
   OUTPKTEND=0x82;
   SYNCDELAY;
   OUTPKTEND=0x82;
   SYNCDELAY;
   OUTPKTEND=0x84;
   SYNCDELAY;
   OUTPKTEND=0x84;
   SYNCDELAY;	
     
  //EP2FIFOCFG,EP4FIFOCFG,EP6FIFOCFG,EP8FIFOCFG 

  EP2FIFOCFG=0x19;//autoout,autoin,no zero length pkt, 16bit
  SYNCDELAY;
  EP4FIFOCFG=0x19;//autoout,autoin,no zero length pkt,16bit
  SYNCDELAY;
  EP6FIFOCFG=0x19;//autoout,autoin,no zero length pkt,16bit
  SYNCDELAY;
  EP8FIFOCFG=0x19;//autoout,autoin,no zero length pkt,16bit
  SYNCDELAY;
  

   // PINFLAGSAB and PINFLAGSCD use the default value 
   // FLAGA-> indexed programmable full 
   // FLAGB-> indexed full
   // FLAGC-> indexed empty
   // FLAGD-> NOT USED
  
   PINFLAGSAB=0x89; //FLAGB->EP2EF FLAGA->EP4EF
   SYNCDELAY;
   PINFLAGSCD=0xEF;//FLAGD->EP6FF FLAGC->EP8FF
   SYNCDELAY;
 

  //PORTACFG control FLAGD, SLCS, INT0 and INT1,
  //use PA7 as FLAGD 
  PORTACFG|=0x80;
 

  //FIFOPINPOLAR 
  
  FIFOPINPOLAR=0x3F; //all fifo interface signals are set to be active high
  SYNCDELAY;
  

  //EP2AUTOINLENH,EP6AUTOINLENH,EP4AUTOINLENH,EP8AUTOINLENH
  //EP2AUTOINLENL,EP6AUTOINLENL,EP4AUTOINLENL,EP8AUTOINLENL
  //512 bytes
 
  EP2AUTOINLENH=0x02;
  SYNCDELAY;
  EP4AUTOINLENH=0x02;
  SYNCDELAY;
 
  EP6AUTOINLENH=0x02;
  SYNCDELAY;
  EP8AUTOINLENH=0x02;
  SYNCDELAY;

 
  EP2AUTOINLENL=0x00;
  SYNCDELAY;
  EP4AUTOINLENL=0x00;
  SYNCDELAY;
  
  EP6AUTOINLENL=0x00;
  SYNCDELAY;
  EP8AUTOINLENL=0x00;
  SYNCDELAY;
  
  //EP2FIFOPFH/L,EP6FIFOPFH/L,EP4FIFOPFH/L and EP8FIFOPFH/L control the PF flags which are not used by our FPGA firmware, 
 
  EP2FIFOPFH=0xC2;//512 bytes
  SYNCDELAY;
  EP2FIFOPFL=0x00;
  SYNCDELAY;
  EP4FIFOPFH=0xC1;//256 bytes
  SYNCDELAY;
  EP4FIFOPFL=0x00;
  SYNCDELAY;
 
  EP6FIFOPFH=0x42;//512 bytes
  SYNCDELAY;
  EP6FIFOPFL=0x00;
  SYNCDELAY;
  EP8FIFOPFH=0x41;//256 bytes
  SYNCDELAY;
  EP8FIFOPFL=0x00;
  SYNCDELAY;
 

  //EP2FIFOBCH,EP4FIFOBCH,EP6FIFOBCH, and EP8FIFOBCH
  //EP2FIFOBCL,EP4FIFOBCL,EP6FIFOBCL, and EP8FIFOBCL
  //are for read

  //INPKTEND
  /*
  INPKTEND=0x00; 
  */


  //EP2FIFOIE,EP4FIFOIE,EP6FIFOIE, and EP8FIFOIE are not important for our case.

  //EP2FIFOIRQ,EP4FIFOIRQ,EP6FIFOIRQ and EP8FIFOIRQ are only for read, so not set here
  
  //EP2FIFOFLGS,EP4FIFOFLGS,EP6FIFOFLGS, and EP8FIFOFLGS are for read, so not set here
  
  //EP2FIFOBUF,EP4FIFOBUF,EP6FIFOBUF and EP8FIFOBUF are used by the 8051 CPU. Not important here

  // Registers which require a synchronization delay, see section 15.14
  // FIFORESET        FIFOPINPOLAR
  // INPKTEND         OUTPKTEND
  // EPxBCH:L         REVCTL
  // GPIFTCB3         GPIFTCB2
  // GPIFTCB1         GPIFTCB0
  // EPxFIFOPFH:L     EPxAUTOINLENH:L
  // EPxFIFOCFG       EPxGPIFFLGSEL
  // PINFLAGSxx       EPxFIFOIRQ
  // EPxFIFOIE        GPIFIRQ
  // GPIFIE           GPIFADRH:L
  // UDMACRCH:L       EPxGPIFTRIG
  // GPIFTRIG
  
  // Note: The pre-REVE EPxGPIFTCH/L register are affected, as well...
  //      ...these have been replaced by GPIFTC[B3:B0] registers

  // default: all endpoints have their VALID bit set
  // default: TYPE1 = 1 and TYPE0 = 0 --> BULK  
  // default: EP2 and EP4 DIR bits are 0 (OUT direction)
  // default: EP6 and EP8 DIR bits are 1 (IN direction)
  // default: EP2, EP4, EP6, and EP8 are double buffered

  // we are just using the default values, yes this is not necessary...
  

  // out endpoints do not come up armed

  /*
  // since the defaults are double buffered we must write dummy byte counts twice
  EP2BCL = 0x80;                // arm EP2OUT by writing byte count wo/skip.
  SYNCDELAY;                    
  EP2BCL = 0x80;
  SYNCDELAY;                    
  EP4BCL = 0x80;                // arm EP4OUT by writing byte count wo/skip.
  SYNCDELAY;                    
  EP4BCL = 0x80;    
  SYNCDELAY;                    
  */
  

/*
  EP6BCL = 0x00; //arm EP6IN by writing byte count wo/skip
  SYNCDELAY;                    
  EP6BCL = 0x00; //arm EP6IN by writing byte count wo/skip
  SYNCDELAY;                    
  EP8BCL = 0x00; //arm EP8IN by writing byte count wo/skip
  SYNCDELAY;                    
  EP8BCL = 0x00; //arm EP8IN by writing byte count wo/skip
  SYNCDELAY;  
*/

  //set the auto mode configuration
  
  // enable dual autopointer feature
  //AUTOPTRSETUP |= 0x01;
}

void TD_Poll(void)             // Called repeatedly while the device is idle
{
}

BOOL TD_Suspend(void)          // Called before the device goes into suspend mode
{
   return(TRUE);
}

BOOL TD_Resume(void)          // Called after the device resumes
{
   return(TRUE);
}

//-----------------------------------------------------------------------------
// Device Request hooks
//   The following hooks are called by the end point 0 device request parser.
//-----------------------------------------------------------------------------

BOOL DR_GetDescriptor(void)
{
   return(TRUE);
}

BOOL DR_SetConfiguration(void)   // Called when a Set Configuration command is received
{
   Configuration = SETUPDAT[2];
   return(TRUE);            // Handled by user code
}

BOOL DR_GetConfiguration(void)   // Called when a Get Configuration command is received
{
   EP0BUF[0] = Configuration;
   EP0BCH = 0;
   EP0BCL = 1;
   return(TRUE);            // Handled by user code
}

BOOL DR_SetInterface(void)       // Called when a Set Interface command is received
{
   AlternateSetting = SETUPDAT[2];
   return(TRUE);            // Handled by user code
}

BOOL DR_GetInterface(void)       // Called when a Set Interface command is received
{
   EP0BUF[0] = AlternateSetting;
   EP0BCH = 0;
   EP0BCL = 1;
   return(TRUE);            // Handled by user code
}

BOOL DR_GetStatus(void)
{
   return(TRUE);
}

BOOL DR_ClearFeature(void)
{
   return(TRUE);
}

BOOL DR_SetFeature(void)
{
   return(TRUE);
}

BOOL DR_VendorCmnd(void)
{
   return(TRUE);
}

//-----------------------------------------------------------------------------
// USB Interrupt Handlers
//   The following functions are called by the USB interrupt jump table.
//-----------------------------------------------------------------------------

// Setup Data Available Interrupt Handler
void ISR_Sudav(void) interrupt 0
{
   GotSUD = TRUE;            // Set flag
   EZUSB_IRQ_CLEAR();
   USBIRQ = bmSUDAV;         // Clear SUDAV IRQ
}

// Setup Token Interrupt Handler
void ISR_Sutok(void) interrupt 0
{
   EZUSB_IRQ_CLEAR();
   USBIRQ = bmSUTOK;         // Clear SUTOK IRQ
}

void ISR_Sof(void) interrupt 0
{
   EZUSB_IRQ_CLEAR();
   USBIRQ = bmSOF;            // Clear SOF IRQ
}

void ISR_Ures(void) interrupt 0
{
   // whenever we get a USB reset, we should revert to full speed mode
   pConfigDscr = pFullSpeedConfigDscr;
   ((CONFIGDSCR xdata *) pConfigDscr)->type = CONFIG_DSCR;
   pOtherConfigDscr = pHighSpeedConfigDscr;
   ((CONFIGDSCR xdata *) pOtherConfigDscr)->type = OTHERSPEED_DSCR;
   
   EZUSB_IRQ_CLEAR();
   USBIRQ = bmURES;         // Clear URES IRQ
}

void ISR_Susp(void) interrupt 0
{
   Sleep = TRUE;
   EZUSB_IRQ_CLEAR();
   USBIRQ = bmSUSP;
}

void ISR_Highspeed(void) interrupt 0
{
   if (EZUSB_HIGHSPEED())
   {
      pConfigDscr = pHighSpeedConfigDscr;
      ((CONFIGDSCR xdata *) pConfigDscr)->type = CONFIG_DSCR;
      pOtherConfigDscr = pFullSpeedConfigDscr;
      ((CONFIGDSCR xdata *) pOtherConfigDscr)->type = OTHERSPEED_DSCR;
   }

   EZUSB_IRQ_CLEAR();
   USBIRQ = bmHSGRANT;
}
void ISR_Ep0ack(void) interrupt 0
{
}
void ISR_Stub(void) interrupt 0
{
}
void ISR_Ep0in(void) interrupt 0
{
}
void ISR_Ep0out(void) interrupt 0
{
}
void ISR_Ep1in(void) interrupt 0
{
}
void ISR_Ep1out(void) interrupt 0
{
}
void ISR_Ep2inout(void) interrupt 0
{
}
void ISR_Ep4inout(void) interrupt 0
{
}
void ISR_Ep6inout(void) interrupt 0
{
}
void ISR_Ep8inout(void) interrupt 0
{
}
void ISR_Ibn(void) interrupt 0
{
}
void ISR_Ep0pingnak(void) interrupt 0
{
}
void ISR_Ep1pingnak(void) interrupt 0
{
}
void ISR_Ep2pingnak(void) interrupt 0
{
}
void ISR_Ep4pingnak(void) interrupt 0
{
}
void ISR_Ep6pingnak(void) interrupt 0
{
}
void ISR_Ep8pingnak(void) interrupt 0
{
}
void ISR_Errorlimit(void) interrupt 0
{
}
void ISR_Ep2piderror(void) interrupt 0
{
}
void ISR_Ep4piderror(void) interrupt 0
{
}
void ISR_Ep6piderror(void) interrupt 0
{
}
void ISR_Ep8piderror(void) interrupt 0
{
}
void ISR_Ep2pflag(void) interrupt 0
{
}
void ISR_Ep4pflag(void) interrupt 0
{
}
void ISR_Ep6pflag(void) interrupt 0
{
}
void ISR_Ep8pflag(void) interrupt 0
{
}
void ISR_Ep2eflag(void) interrupt 0
{
}
void ISR_Ep4eflag(void) interrupt 0
{
}
void ISR_Ep6eflag(void) interrupt 0
{
}
void ISR_Ep8eflag(void) interrupt 0
{
}
void ISR_Ep2fflag(void) interrupt 0
{
}
void ISR_Ep4fflag(void) interrupt 0
{
}
void ISR_Ep6fflag(void) interrupt 0
{
}
void ISR_Ep8fflag(void) interrupt 0
{
}
void ISR_GpifComplete(void) interrupt 0
{
}
void ISR_GpifWaveform(void) interrupt 0
{
}
