/************************************************************************/
/*																								*/
/*	linear_filter_header.h	--	Digilent Image Linear Filter					*/
/*																								*/
/************************************************************************/
/*	Author:	HE, Cong; WANG, Tinghui (steve)										*/
/*	Copyright 2011 Digilent CN															*/
/************************************************************************/
/*  File Description:																	*/
/*																								*/
/*																								*/
/************************************************************************/
/*  Revision History:																	*/
/*			1.0 Initial Release			WANG, Tinghui		19May2011			*/
/*																								*/
/************************************************************************/
#ifndef LINEAR_FILTER_HEADER_H		/* prevent circular inclusions */
#define LINEAR_FILTER_HEADER_H		/* by using protection macros */

#include <stdio.h>
#include <xil_io.h>

#include "xparameters.h"

/* ------------------------------------------------------------ */
/*					Miscellaneous Declarations								 */
/* ------------------------------------------------------------ */
#define blLinearFilterCR		0x00000000 // Control Reg Offset
#define blLinearFilterMat11	0x00000004 // Parameter <1,1>
#define blLinearFilterMat12	0x00000008 // Parameter <1,2>
#define blLinearFilterMat13	0x0000000c // Parameter <1,3>
#define blLinearFilterMat21	0x00000010 // Parameter <2,1>
#define blLinearFilterMat22	0x00000014 // Parameter <2,2>
#define blLinearFilterMat23	0x00000018 // Parameter <2,3>
#define blLinearFilterMat31	0x0000001c // Parameter <3,1>
#define blLinearFilterMat32	0x00000020 // Parameter <3,2>
#define blLinearFilterMat33	0x00000024 // Parameter <3,3>
#define blLinearFilterDIV		0x00000028 // Divider <0,1,2> => (4, 8, 16)
#define blLinearFilterHSR		0x0000002c // H Sync Reg Offset
#define blLinearFilterHBPR		0x00000030 // H Back Porch Reg Offset
#define blLinearFilterHFPR		0x00000034 // H Front Porch Reg Offset
#define blLinearFilterHTR		0x00000038 // H Total Reg Offset
#define blLinearFilterVSR		0x0000003c // V Sync Reg Offset
#define blLinearFilterVBPR		0x00000040 // V Back Porch Reg Offset
#define blLinearFilterVFPR		0x00000044 // V Front Porch Reg Offset
#define blLinearFilterVTR		0x00000048 // V Total Reg Offset

#define LinearFilter_Bilinear 0x00000001 // Bilinear Filter [1, 2, 1] * [1, 2, 1]
#define LinearFilter_Sobel    0x00000002 // Sobel Filter [1 2 1] * [-1 0 1]
#define LinearFilter_Enhanced 0x00000003 // Enhancement Filter [-1, -1, -1; -1, 9, -1; -1, -1, -1]
#define LinearFilter_Corner   0x00000004 // Corner Filter []
#define LinearFilter_Box      0x00000005 // Box Filter
#define LinearFilter_Bypass   0x0000000F // bypass

/* ------------------------------------------------------------ */
/*					General Type Declarations								 */
/* ------------------------------------------------------------ */

/* ------------------------------------------------------------ */
/*					Variable Declarations									 */
/* ------------------------------------------------------------ */

/* ------------------------------------------------------------ */
/*					Procedure Declarations									 */
/* ------------------------------------------------------------ */
int LinearFilterInit(u32 lLinearFilterBaseAddress, u32 fOptions);

/* ------------------------------------------------------------ */
#endif
/************************************************************************/
