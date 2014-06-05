/******************************************************************************
*
* (c) Copyright 2012-2013 Xilinx, Inc. All rights reserved.
*
* This file contains confidential and proprietary information of Xilinx, Inc.
* and is protected under U.S. and international copyright and other
* intellectual property laws.
*
* DISCLAIMER
* This disclaimer is not a license and does not grant any rights to the
* materials distributed herewith. Except as otherwise provided in a valid
* license issued to you by Xilinx, and to the maximum extent permitted by
* applicable law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND WITH ALL
* FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES AND CONDITIONS, EXPRESS,
* IMPLIED, OR STATUTORY, INCLUDING BUT NOT LIMITED TO WARRANTIES OF
* MERCHANTABILITY, NON-INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE;
* and (2) Xilinx shall not be liable (whether in contract or tort, including
* negligence, or under any other theory of liability) for any loss or damage
* of any kind or nature related to, arising under or in connection with these
* materials, including for any direct, or any indirect, special, incidental,
* or consequential loss or damage (including loss of data, profits, goodwill,
* or any type of loss or damage suffered as a result of any action brought by
* a third party) even if such damage or loss was reasonably foreseeable or
* Xilinx had been advised of the possibility of the same.
*
* CRITICAL APPLICATIONS
* Xilinx products are not designed or intended to be fail-safe, or for use in
* any application requiring fail-safe performance, such as life-support or
* safety devices or systems, Class III medical devices, nuclear facilities,
* applications related to the deployment of airbags, or any other applications
* that could lead to death, personal injury, or severe property or
* environmental damage (individually and collectively, "Critical
* Applications"). Customer assumes the sole risk and liability of any use of
* Xilinx products in Critical Applications, subject only to applicable laws
* and regulations governing limitations on product liability.
*
* THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS PART OF THIS FILE
* AT ALL TIMES.
*
*******************************************************************************/
/*****************************************************************************/
/**
*
* @file pcap.c
*
* Contains code for enabling and accessing the PCAP
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver	Who	Date		Changes
* ----- ---- -------- -------------------------------------------------------
* 1.00a ecm	02/10/10	Initial release
* 2.00a jz	05/28/11	Add SD support
* 2.00a mb	25/05/12	using the EDK provided devcfg driver
* 						Nand/SD encryption and review comments
* 3.00a mb  16/08/12	Added the poll function
*						Removed the FPGA_RST_CTRL define
*						Added the flag for NON PS instantiated bitstream
* 4.00a sgd 02/28/13	Fix for CR#681014
* 						Fix for CR#689026
* 						Fix for CR#699475
*						Removed check for Fabric is already initialized
*						Fix for CR#705664
* </pre>
*
* @note
*
******************************************************************************/

/***************************** Include Files *********************************/

#include "pcap.h"
#include "nand.h"		/* For NAND geometry information */
#include "fsbl.h"
#include "image_mover.h"	/* For MoveImage */
#include "xparameters.h"
#include "xil_exception.h"
#include "xdevcfg.h"
#include "sleep.h"

#ifdef XPAR_XWDTPS_0_BASEADDR
#include "xwdtps.h"
#endif
/************************** Constant Definitions *****************************/
/*
 * The following constants map to the XPAR parameters created in the
 * xparameters.h file. They are only defined here such that a user can easily
 * change all the needed parameters in one place.
 */

#define DCFG_DEVICE_ID		XPAR_XDCFG_0_DEVICE_ID

/**************************** Type Definitions *******************************/

/***************** Macros (Inline Functions) Definitions *********************/

/************************** Function Prototypes ******************************/
extern int XDcfgPollDone(u32 MaskValue, u32 MaxCount);

/************************** Variable Definitions *****************************/
/* Devcfg driver instance */
static XDcfg DcfgInstance;
XDcfg *DcfgInstPtr;

#ifdef XPAR_XWDTPS_0_BASEADDR
extern XWdtPs Watchdog;	/* Instance of WatchDog Timer	*/
#endif

/******************************************************************************/
/**
*
* This function transfer data using PCAP
*
* @param 	SourceDataPtr is a pointer to where the data is read from
* @param 	DestinationDataPtr is a pointer to where the data is written to
* @param 	SourceLength is the length of the data to be moved in words
* @param 	DestinationLength is the length of the data to be moved in words
* @param 	SecureTransfer indicated the encryption key location, 0 for
* 			non-encrypted
*
* @return
*		- XST_SUCCESS if the transfer is successful
*		- XST_FAILURE if the transfer fails
*
* @note		 None
*
****************************************************************************/
u32 PcapDataTransfer(u32 *SourceDataPtr, u32 *DestinationDataPtr,
				u32 SourceLength, u32 DestinationLength, u32 SecureTransfer)
{
	u32 Status;
	u32 PcapTransferType = XDCFG_CONCURRENT_NONSEC_READ_WRITE;

	/*
	 * Check for secure transfer
	 */
	if (SecureTransfer) {
		PcapTransferType = XDCFG_CONCURRENT_SECURE_READ_WRITE;
	}

#ifdef FSBL_PERF
	XTime tXferCur = 0;
	FsblGetGlobalTime(tXferCur);
#endif

	/*
	 * Clear the PCAP status registers
	 */
	Status = ClearPcapStatus();
	if (Status != XST_SUCCESS) {
		fsbl_printf(DEBUG_INFO,"PCAP_CLEAR_STATUS_FAIL \r\n");
		return XST_FAILURE;
	}

#ifdef	XPAR_XWDTPS_0_BASEADDR
	/*
	 * Prevent WDT reset
	 */
	XWdtPs_RestartWdt(&Watchdog);
#endif

	/*
	 * PCAP single DMA transfer setup
	 */
	SourceDataPtr = (u32*)((u32)SourceDataPtr | PCAP_LAST_TRANSFER);
	DestinationDataPtr = (u32*)((u32)DestinationDataPtr | PCAP_LAST_TRANSFER);

	/*
	 * Transfer using Device Configuration
	 */
	Status = XDcfg_Transfer(DcfgInstPtr, (u8 *)SourceDataPtr,
					SourceLength,
					(u8 *)DestinationDataPtr,
					DestinationLength, PcapTransferType);
	if (Status != XST_SUCCESS) {
		fsbl_printf(DEBUG_INFO,"Status of XDcfg_Transfer = %d \r \n",Status);
		return XST_FAILURE;
	}

	/*
	 * Dump the PCAP registers
	 */
	PcapDumpRegisters();

	/*
	 * Poll for the DMA done
	 */
	Status = XDcfgPollDone(XDCFG_IXR_DMA_DONE_MASK, MAX_COUNT);
	if (Status != XST_SUCCESS) {
		fsbl_printf(DEBUG_INFO,"PCAP_DMA_DONE_FAIL \r\n");
		return XST_FAILURE;
	}

	fsbl_printf(DEBUG_INFO,"DMA Done ! \n\r");

	/*
	 * For Performance measurement
	 */
#ifdef FSBL_PERF
	XTime tXferEnd = 0;
	fsbl_printf(DEBUG_GENERAL,"Time taken is ");
	FsblMeasurePerfTime(tXferCur,tXferEnd);
#endif

	return XST_SUCCESS;
}


/******************************************************************************/
/**
*
* This function loads PL partition using PCAP
*
* @param 	SourceDataPtr is a pointer to where the data is read from
* @param 	DestinationDataPtr is a pointer to where the data is written to
* @param 	SourceLength is the length of the data to be moved in words
* @param 	DestinationLength is the length of the data to be moved in words
* @param 	SecureTransfer indicated the encryption key location, 0 for
* 			non-encrypted
*
* @return
*		- XST_SUCCESS if the transfer is successful
*		- XST_FAILURE if the transfer fails
*
* @note		 None
*
****************************************************************************/
u32 PcapLoadPartition(u32 *SourceDataPtr, u32 *DestinationDataPtr,
		u32 SourceLength, u32 DestinationLength, u32 SecureTransfer)
{
	u32 Status;
	u32 PcapTransferType = XDCFG_NON_SECURE_PCAP_WRITE;

	/*
	 * Check for secure transfer
	 */
	if (SecureTransfer) {
		PcapTransferType = XDCFG_SECURE_PCAP_WRITE;
	}

#ifdef FSBL_PERF
	XTime tXferCur = 0;
	FsblGetGlobalTime(tXferCur);
#endif

	/*
	 * Clear the PCAP status registers
	 */
	Status = ClearPcapStatus();
	if (Status != XST_SUCCESS) {
		fsbl_printf(DEBUG_INFO,"PCAP_CLEAR_STATUS_FAIL \r\n");
		return XST_FAILURE;
	}

	/*
	 * For Bitstream case destination address will be 0xFFFFFFFF
	 */
	DestinationDataPtr = (u32*)XDCFG_DMA_INVALID_ADDRESS;

	/*
	 * New Bitstream download initialization sequence
	 */
	FabricInit();


#ifdef	XPAR_XWDTPS_0_BASEADDR
	/*
	 * Prevent WDT reset
	 */
	XWdtPs_RestartWdt(&Watchdog);
#endif

	/*
	 * PCAP single DMA transfer setup
	 */
	SourceDataPtr = (u32*)((u32)SourceDataPtr | PCAP_LAST_TRANSFER);
	DestinationDataPtr = (u32*)((u32)DestinationDataPtr | PCAP_LAST_TRANSFER);

	/*
	 * Transfer using Device Configuration
	 */
	Status = XDcfg_Transfer(DcfgInstPtr, (u8 *)SourceDataPtr,
					SourceLength,
					(u8 *)DestinationDataPtr,
					DestinationLength, PcapTransferType);
	if (Status != XST_SUCCESS) {
		fsbl_printf(DEBUG_INFO,"Status of XDcfg_Transfer = %d \r \n",Status);
		return XST_FAILURE;
	}


	/*
	 * Dump the PCAP registers
	 */
	PcapDumpRegisters();


	/*
	 * Poll for the DMA done
	 */
	Status = XDcfgPollDone(XDCFG_IXR_DMA_DONE_MASK, MAX_COUNT);
	if (Status != XST_SUCCESS) {
		fsbl_printf(DEBUG_INFO,"PCAP_DMA_DONE_FAIL \r\n");
		return XST_FAILURE;
	}

	fsbl_printf(DEBUG_INFO,"DMA Done ! \n\r");

	/*
	 * Poll for FPGA Done
	 */
	Status = XDcfgPollDone(XDCFG_IXR_PCFG_DONE_MASK, MAX_COUNT);
	if (Status != XST_SUCCESS) {
		fsbl_printf(DEBUG_INFO,"PCAP_FPGA_DONE_FAIL\r\n");
		return XST_FAILURE;
	}

	fsbl_printf(DEBUG_INFO,"FPGA Done ! \n\r");

	/*
	 * For Performance measurement
	 */
#ifdef FSBL_PERF
	XTime tXferEnd = 0;
	fsbl_printf(DEBUG_GENERAL,"Time taken is ");
	FsblMeasurePerfTime(tXferCur,tXferEnd);
#endif

	return XST_SUCCESS;
}

/******************************************************************************/
/**
*
* This function Initializes the PCAP driver.
*
* @param	none
*
* @return
*		- XST_SUCCESS if the pcap driver initialization is successful
*		- XST_FAILURE if the pcap driver initialization fails
*
* @note	 none
*
****************************************************************************/
int InitPcap(void)
{
	XDcfg_Config *ConfigPtr;
	int Status = XST_SUCCESS;
	DcfgInstPtr = &DcfgInstance;

	/*
	 * Initialize the Device Configuration Interface driver.
	 */
	ConfigPtr = XDcfg_LookupConfig(DCFG_DEVICE_ID);

	Status = XDcfg_CfgInitialize(DcfgInstPtr, ConfigPtr,
					ConfigPtr->BaseAddr);
	if (Status != XST_SUCCESS) {
		fsbl_printf(DEBUG_INFO, "XDcfg_CfgInitialize failed \n\r");
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}

/******************************************************************************/
/**
*
* This function programs the Fabric for use.
*
* @param	None
*
* @return	None
*		- XST_SUCCESS if the Fabric  initialization is successful
*		- XST_FAILURE if the Fabric  initialization fails
* @note		None
*
****************************************************************************/
void FabricInit(void)
{
	u32 PcapReg;
	u32 StatusReg;

	/*
	 * Set Level Shifters DT618760 - PS to PL enabling
	 */
	Xil_Out32(PS_LVL_SHFTR_EN, LVL_PS_PL);
	fsbl_printf(DEBUG_INFO,"Level Shifter Value = 0x%x \r\n",
				Xil_In32(PS_LVL_SHFTR_EN));

	/*
	 * Get DEVCFG controller settings
	 */
	PcapReg = XDcfg_ReadReg(DcfgInstPtr->Config.BaseAddr,
				XDCFG_CTRL_OFFSET);

	/*
	 * Setting PCFG_PROG_B signal to high
	 */
	XDcfg_WriteReg(DcfgInstPtr->Config.BaseAddr, XDCFG_CTRL_OFFSET,
				(PcapReg | XDCFG_CTRL_PCFG_PROG_B_MASK));

	/*
	 * 5msec delay
	 */
	usleep(5000);
	/*
	 * Setting PCFG_PROG_B signal to low
	 */
	XDcfg_WriteReg(DcfgInstPtr->Config.BaseAddr, XDCFG_CTRL_OFFSET,
				(PcapReg & ~XDCFG_CTRL_PCFG_PROG_B_MASK));

	/*
	 * 5msec delay
	 */
	usleep(5000);
	/*
	 * Polling the PCAP_INIT status for Reset
	 */
	while(XDcfg_GetStatusRegister(DcfgInstPtr) &
				XDCFG_STATUS_PCFG_INIT_MASK);

	/*
	 * Setting PCFG_PROG_B signal to high
	 */
	XDcfg_WriteReg(DcfgInstPtr->Config.BaseAddr, XDCFG_CTRL_OFFSET,
			(PcapReg | XDCFG_CTRL_PCFG_PROG_B_MASK));

	/*
	 * Polling the PCAP_INIT status for Set
	 */
	while(!(XDcfg_GetStatusRegister(DcfgInstPtr) &
			XDCFG_STATUS_PCFG_INIT_MASK));

	/*
	 * Get Device configuration status
	 */
	StatusReg = XDcfg_GetStatusRegister(DcfgInstPtr);
	fsbl_printf(DEBUG_INFO,"Devcfg Status register = 0x%x \r\n",StatusReg);

	fsbl_printf(DEBUG_INFO,"PCAP:Fabric is Initialized done\r\n");
}

/******************************************************************************/
/**
*
* This function Clears the PCAP status registers.
*
* @param	None
*
* @return
*		- XST_SUCCESS if the pcap status registers are cleared
*		- XST_FAILURE if errors are there
*		- XST_DEVICE_BUSY if Pcap device is busy
* @note		None
*
****************************************************************************/
u32 ClearPcapStatus(void)
{

	u32 StatusReg;
	u32 IntStatusReg;

	/*
	 * Clear it all, so if Boot ROM comes back, it can proceed
	 */
	XDcfg_IntrClear(DcfgInstPtr, 0xFFFFFFFF);

	/*
	 * Get PCAP Interrupt Status Register
	 */
	IntStatusReg = XDcfg_IntrGetStatus(DcfgInstPtr);
	if (IntStatusReg & FSBL_XDCFG_IXR_ERROR_FLAGS_MASK) {
		fsbl_printf(DEBUG_INFO,"FATAL errors in PCAP %x\r\n",
				IntStatusReg);
		return XST_FAILURE;
	}

	/*
	 * Read the PCAP status register for DMA status
	 */
	StatusReg = XDcfg_GetStatusRegister(DcfgInstPtr);

	fsbl_printf(DEBUG_INFO,"PCAP:StatusReg = 0x%.8x\r\n", StatusReg);

	/*
	 * If the queue is full, return w/ XST_DEVICE_BUSY
	 */
	if ((StatusReg & XDCFG_STATUS_DMA_CMD_Q_F_MASK) ==
			XDCFG_STATUS_DMA_CMD_Q_F_MASK) {

		fsbl_printf(DEBUG_INFO,"PCAP_DEVICE_BUSY\r\n");
		return XST_DEVICE_BUSY;
	}

	fsbl_printf(DEBUG_INFO,"PCAP:device ready\r\n");

	/*
	 * There are unacknowledged DMA commands outstanding
	 */
	if ((StatusReg & XDCFG_STATUS_DMA_CMD_Q_E_MASK) !=
			XDCFG_STATUS_DMA_CMD_Q_E_MASK) {

		IntStatusReg = XDcfg_IntrGetStatus(DcfgInstPtr);

		if ((IntStatusReg & XDCFG_IXR_DMA_DONE_MASK) !=
				XDCFG_IXR_DMA_DONE_MASK){
			/*
			 * Error state, transfer cannot occur
			 */
			fsbl_printf(DEBUG_INFO,"PCAP:IntStatus indicates error\r\n");
			return XST_FAILURE;
		}
		else {
			/*
			 * clear out the status
			 */
			XDcfg_IntrClear(DcfgInstPtr, XDCFG_IXR_DMA_DONE_MASK);
		}
	}

	if ((StatusReg & XDCFG_STATUS_DMA_DONE_CNT_MASK) != 0) {
		XDcfg_IntrClear(DcfgInstPtr, StatusReg &
				XDCFG_STATUS_DMA_DONE_CNT_MASK);
	}

	fsbl_printf(DEBUG_INFO,"PCAP:Clear done\r\n");

	return XST_SUCCESS;
}

/******************************************************************************/
/**
*
* This function prints PCAP register status.
*
* @param	none
*
* @return	none
*
* @note		none
*
****************************************************************************/
void PcapDumpRegisters (void) {

	fsbl_printf(DEBUG_INFO,"PCAP register dump:\r\n");

	fsbl_printf(DEBUG_INFO,"PCAP CTRL 0x%x: 0x%08x\r\n",
		XPS_DEV_CFG_APB_BASEADDR + XDCFG_CTRL_OFFSET,
		Xil_In32(XPS_DEV_CFG_APB_BASEADDR + XDCFG_CTRL_OFFSET));
	fsbl_printf(DEBUG_INFO,"PCAP LOCK 0x%x: 0x%08x\r\n",
		XPS_DEV_CFG_APB_BASEADDR + XDCFG_LOCK_OFFSET,
		Xil_In32(XPS_DEV_CFG_APB_BASEADDR + XDCFG_LOCK_OFFSET));
	fsbl_printf(DEBUG_INFO,"PCAP CONFIG 0x%x: 0x%08x\r\n",
		XPS_DEV_CFG_APB_BASEADDR + XDCFG_CFG_OFFSET,
		Xil_In32(XPS_DEV_CFG_APB_BASEADDR + XDCFG_CFG_OFFSET));
	fsbl_printf(DEBUG_INFO,"PCAP ISR 0x%x: 0x%08x\r\n",
		XPS_DEV_CFG_APB_BASEADDR + XDCFG_INT_STS_OFFSET,
		Xil_In32(XPS_DEV_CFG_APB_BASEADDR + XDCFG_INT_STS_OFFSET));
	fsbl_printf(DEBUG_INFO,"PCAP IMR 0x%x: 0x%08x\r\n",
		XPS_DEV_CFG_APB_BASEADDR + XDCFG_INT_MASK_OFFSET,
		Xil_In32(XPS_DEV_CFG_APB_BASEADDR + XDCFG_INT_MASK_OFFSET));
	fsbl_printf(DEBUG_INFO,"PCAP STATUS 0x%x: 0x%08x\r\n",
		XPS_DEV_CFG_APB_BASEADDR + XDCFG_STATUS_OFFSET,
		Xil_In32(XPS_DEV_CFG_APB_BASEADDR + XDCFG_STATUS_OFFSET));
	fsbl_printf(DEBUG_INFO,"PCAP DMA SRC ADDR 0x%x: 0x%08x\r\n",
		XPS_DEV_CFG_APB_BASEADDR + XDCFG_DMA_SRC_ADDR_OFFSET,
		Xil_In32(XPS_DEV_CFG_APB_BASEADDR + XDCFG_DMA_SRC_ADDR_OFFSET));
	fsbl_printf(DEBUG_INFO,"PCAP DMA DEST ADDR 0x%x: 0x%08x\r\n",
		XPS_DEV_CFG_APB_BASEADDR + XDCFG_DMA_DEST_ADDR_OFFSET,
		Xil_In32(XPS_DEV_CFG_APB_BASEADDR + XDCFG_DMA_DEST_ADDR_OFFSET));
	fsbl_printf(DEBUG_INFO,"PCAP DMA SRC LEN 0x%x: 0x%08x\r\n",
		XPS_DEV_CFG_APB_BASEADDR + XDCFG_DMA_SRC_LEN_OFFSET,
		Xil_In32(XPS_DEV_CFG_APB_BASEADDR + XDCFG_DMA_SRC_LEN_OFFSET));
	fsbl_printf(DEBUG_INFO,"PCAP DMA DEST LEN 0x%x: 0x%08x\r\n",
			XPS_DEV_CFG_APB_BASEADDR + XDCFG_DMA_DEST_LEN_OFFSET,
			Xil_In32(XPS_DEV_CFG_APB_BASEADDR + XDCFG_DMA_DEST_LEN_OFFSET));
	fsbl_printf(DEBUG_INFO,"PCAP ROM SHADOW CTRL 0x%x: 0x%08x\r\n",
		XPS_DEV_CFG_APB_BASEADDR + XDCFG_ROM_SHADOW_OFFSET,
		Xil_In32(XPS_DEV_CFG_APB_BASEADDR + XDCFG_ROM_SHADOW_OFFSET));
	fsbl_printf(DEBUG_INFO,"PCAP MBOOT 0x%x: 0x%08x\r\n",
		XPS_DEV_CFG_APB_BASEADDR + XDCFG_MULTIBOOT_ADDR_OFFSET,
		Xil_In32(XPS_DEV_CFG_APB_BASEADDR + XDCFG_MULTIBOOT_ADDR_OFFSET));
	fsbl_printf(DEBUG_INFO,"PCAP SW ID 0x%x: 0x%08x\r\n",
		XPS_DEV_CFG_APB_BASEADDR + XDCFG_SW_ID_OFFSET,
		Xil_In32(XPS_DEV_CFG_APB_BASEADDR + XDCFG_SW_ID_OFFSET));
	fsbl_printf(DEBUG_INFO,"PCAP UNLOCK 0x%x: 0x%08x\r\n",
		XPS_DEV_CFG_APB_BASEADDR + XDCFG_UNLOCK_OFFSET,
		Xil_In32(XPS_DEV_CFG_APB_BASEADDR + XDCFG_UNLOCK_OFFSET));
	fsbl_printf(DEBUG_INFO,"PCAP MCTRL 0x%x: 0x%08x\r\n",
		XPS_DEV_CFG_APB_BASEADDR + XDCFG_MCTRL_OFFSET,
		Xil_In32(XPS_DEV_CFG_APB_BASEADDR + XDCFG_MCTRL_OFFSET));
}

/******************************************************************************/
/**
*
* This function Polls for the DMA done or FPGA done.
*
* @param	none
*
* @return
*		- XST_SUCCESS if polling for DMA/FPGA done is successful
*		- XST_FAILURE if polling for DMA/FPGA done fails
*
* @note		none
*
****************************************************************************/
int XDcfgPollDone(u32 MaskValue, u32 MaxCount)
{
	int Count = MaxCount;
	u32 IntrStsReg = 0;

	/*
	 * poll for the DMA done
	 */
	IntrStsReg = XDcfg_IntrGetStatus(DcfgInstPtr);
	while ((IntrStsReg & MaskValue) !=
				MaskValue) {
		IntrStsReg = XDcfg_IntrGetStatus(DcfgInstPtr);
		Count -=1;

		if (IntrStsReg & FSBL_XDCFG_IXR_ERROR_FLAGS_MASK) {
				fsbl_printf(DEBUG_INFO,"FATAL errors in PCAP %x\r\n",
						IntrStsReg);
				PcapDumpRegisters();
				return XST_FAILURE;
		}

		if(!Count) {
			fsbl_printf(DEBUG_GENERAL,"PCAP transfer timed out \r\n");
			return XST_FAILURE;
		}
		if (Count > (MAX_COUNT-100)) {
			fsbl_printf(DEBUG_GENERAL,".");
		}
	}

	fsbl_printf(DEBUG_GENERAL,"\n\r");

	XDcfg_IntrClear(DcfgInstPtr, IntrStsReg & MaskValue);

	return XST_SUCCESS;
}

