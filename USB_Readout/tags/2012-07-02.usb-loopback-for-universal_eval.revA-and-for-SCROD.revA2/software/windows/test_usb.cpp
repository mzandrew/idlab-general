// test_usb.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"
#include "test_usb.h"

int test_usb_device()
{
	long len;
	bool out_success;
	bool in_success;
	int success_no=0,failure_no=0;

	printf("Initializing the USB Device...\n");
	//open the driver
	CCyUSBDevice *USBDevice=new CCyUSBDevice(NULL);

	//open the attached devices
	int devices=USBDevice->DeviceCount();
	int d=0;
	for(d=0;d<devices;d++)
	{
		USBDevice->Open(d);
		printf("found device %d with VID 0x%x and PID 0x%x\n",d, USBDevice->VendorID,USBDevice->ProductID);
	}
	int c;
		do
		{
		printf("please select a device number:");
//		scanf_s("%d",&c,1);
		c=0;
		}while(c<0 || c>=devices);
	printf("Will use Device %d for test ...\n",(int)c);

	USBDevice->Open((int)c);

	//list the in and out bulk end points
	int epts=USBDevice->EndPointCount();
	CCyUSBEndPoint *endpt;
	int i;
	for(i=0;i<epts;i++)
	{
	 endpt=USBDevice->EndPoints[i];
	 if(endpt->Attributes==2) //Bulk
		{
		 if(endpt->Address & 0x80) //IN
			 printf("Found An In End Point %d with address 0x%x\n",i,endpt->Address);
		 else
			 printf("Found An Out End Point %d with address 0x%x\n",i,endpt->Address);
		}
	}

	//choose the end points
	printf("Preparing In and Out End Points...\n");
	printf("EP2 and EP4 are Out End Points...\n");
	printf("EP6 and EP8 are In End Points...\n");
	printf("MUST select EP2 and EP6 (or EP4 and EP8) simultaneously for the test!!!\n");

	//choose the end points
	do
	{
		do
		{
		printf("please input the number of the Out End Point:");
//		scanf_s("%d",&c,1);
		c = 1;
		}while(c<0 || c>=epts);
		endpt=USBDevice->EndPoints[(int)c];
	}while((endpt->Attributes!=2) || (endpt->Address & 0x80));
	printf("Will use End Point %d for out transfer ...\n",(int)c);
	CCyUSBEndPoint *OutEndpt;
	OutEndpt=USBDevice->EndPoints[(int)c];
	do
	{
		do
		{
		printf("please input the number of the In End Point:");
//		scanf_s("%d",&c,1);
		c = 3;
		}while(c<0 || c>=epts);
		endpt=USBDevice->EndPoints[(int)c];
	}while((endpt->Attributes!=2) || ((endpt->Address & 0x80)==0));
	printf("Will use End Point %d for in transfer ...\n",(int)c);
	CCyUSBEndPoint *InEndpt;
	InEndpt=USBDevice->EndPoints[(int)c];

	long size = 560;

	unsigned char* outbuf=new unsigned char[size];
	unsigned char* inbuf=new unsigned char[size];

	printf("Cleaning the In End Point, please wait ...\n");
	len=512;
	InEndpt->TimeOut=2000;
	InEndpt->XferData(inbuf,len);
	InEndpt->XferData(inbuf,len);//twice because double buffering
	printf("Cleaning done!\n");

	int loop=0;
	while(loop<1) //4G bytes
	{

////////////////////////////////////////////////////RX			
		//InEndpt->Abort();
		InEndpt->Reset();

		len=size;
		InEndpt->TimeOut=2000;
		in_success=InEndpt->XferData(inbuf,len);

		unsigned int chk_sum = 0;
		for(i=0;i<size/4;i++){
			printf("# %d:\t0x%0.2x%0.2x%0.2x%0.2x\n",i,inbuf[4*i+3],inbuf[4*i+2],inbuf[4*i+1],inbuf[4*i]);
			chk_sum += (inbuf[4*i+3]<<24)|(inbuf[4*i+2]<<16)|(inbuf[4*i+1]<<8)|inbuf[4*i];
		}

		chk_sum = chk_sum - ((inbuf[4*138+3]<<24)|(inbuf[4*138+2]<<16)|(inbuf[4*138+1]<<8)|inbuf[4*138]);
		printf("Check sum: 0x%0.8x\n",chk_sum);

		if(len!=size)
		{
			in_success=FALSE;
		}
////////////////////////////////////////////////////
////////////////////////////////////////////////////TX
		OutEndpt->Abort();
		OutEndpt->Reset();

		srand(rand());
		for(i=0;i<size;i++)
		{	 
			outbuf[i]=(unsigned char)rand();
		}

		len=size;
		OutEndpt->TimeOut=2000;
		out_success=OutEndpt->XferData(outbuf,len);

		//for(i=0;i<size/2;i++)
		//	printf("# %d:\t0x%0.2x%0.2x\n",i,outbuf[2*i+1],outbuf[2*i]);

		if(len!=size)
		{
			out_success=FALSE;
		}
////////////////////////////////////////////////////

		if(out_success==FALSE || in_success==FALSE)
		{
			failure_no++;
		}
		else
		{
			if(chk_sum == ((inbuf[4*138+3]<<24)|(inbuf[4*138+2]<<16)|(inbuf[4*138+1]<<8)|inbuf[4*138]))
				success_no++;
			else
				failure_no++;
		}

printf("len: %d\tout_success: %d\tin_success: %d\n",len,out_success,in_success);

		printf("\rloop %12d success_no: %12d failure_no: %12d",loop,success_no,failure_no);
		loop++;
	}
	printf("\n");
	delete inbuf;
	delete outbuf;
	USBDevice->Close();
	delete USBDevice;
	printf("success no is %d, failure no is %d\n",success_no,failure_no);
	return 0;
}

int _tmain(int argc, _TCHAR* argv[])
{
	test_usb_device();
	getchar();
	getchar();
	getchar();
	getchar();
	return 0;
}

