/*
 * Copyright (c) 2009-2012 Xilinx, Inc.  All rights reserved.
 *
 * Xilinx, Inc.
 * XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS" AS A
 * COURTESY TO YOU.  BY PROVIDING THIS DESIGN, CODE, OR INFORMATION AS
 * ONE POSSIBLE   IMPLEMENTATION OF THIS FEATURE, APPLICATION OR
 * STANDARD, XILINX IS MAKING NO REPRESENTATION THAT THIS IMPLEMENTATION
 * IS FREE FROM ANY CLAIMS OF INFRINGEMENT, AND YOU ARE RESPONSIBLE
 * FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE FOR YOUR IMPLEMENTATION.
 * XILINX EXPRESSLY DISCLAIMS ANY WARRANTY WHATSOEVER WITH RESPECT TO
 * THE ADEQUACY OF THE IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO
 * ANY WARRANTIES OR REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE
 * FROM CLAIMS OF INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.
 *
 */

/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include "platform.h"
#include <xil_io.h>
#include "linear_filter_header.h"
#include "color_space_header.h"
#include <xparameters.h>

//void print(char *str);

#define SW_BASEADDR XPAR_SWS_4BITS_BASEADDR
#define BTN_BASEADDR XPAR_BTNS_4BITS_BASEADDR
#define COLORSPACE_BASEADDR XPAR_AXI_COLOR_SPACE_0_BASEADDR
#define LINEAR_BASEADDR XPAR_AXI_LINEARFILTER_0_BASEADDR

int main()
{
    u32 btnState = 0;
    u32 swState = 0;
    u32 linearState = 0;
    u32 colorState = 0;
    u32 ctrlState = 0;

    u32 temp;

	init_platform();



    xil_printf("Hello World\n\r");

    ColorSpaceInit(COLORSPACE_BASEADDR, 0);
    LinearFilterInit(LINEAR_BASEADDR, 0);

    xil_printf("Entering While Loop\n\r");

    while (1)
    {
    	btnState = Xil_In32(BTN_BASEADDR);
    	swState = Xil_In32(SW_BASEADDR);

    	if ((btnState & 0b001) && swState != linearState)
    	{
    		linearState = swState;
    		LinearFilterInit(LINEAR_BASEADDR, linearState);
    	    xil_printf("Linear Filter state changed!\n\r");
    	}
    	if ((btnState & 0b010) && swState != colorState)
    	{
    		colorState = swState;
    		ColorSpaceInit(COLORSPACE_BASEADDR, colorState);
    	    xil_printf("Color Space state changed!\n\r");
    	}
//    	if ((btnState & 0b100) && swState != ctrlState)
//		{
//			ctrlState = swState;
//			temp = Xil_In32(LINEAR_BASEADDR);
//			if (ctrlState == 0b0001)
//				temp = temp | 0b1;
//			else if (ctrlState == 0)
//				temp = temp & ~0b1;
//			Xil_Out32(LINEAR_BASEADDR, temp);
//
//			xil_printf("ctrl state changed!\n\r");
//
//			ctrlState = swState;
//			temp = Xil_In32(COLORSPACE_BASEADDR);
//			if (ctrlState == 0b0001)
//				temp = temp | 0x80000000;
//			else if (ctrlState == 0)
//				temp = temp & ~0x80000000;
//			Xil_Out32(COLORSPACE_BASEADDR, temp);
//
//			xil_printf("ctrl state changed!\n\r");
//		}
    }
    return 0;
}
