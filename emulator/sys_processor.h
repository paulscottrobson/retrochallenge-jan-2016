// *******************************************************************************************************************************
// *******************************************************************************************************************************
//
//		Name:		sys_processor.h
//		Purpose:	Processor Emulation (header)
//		Created:	1st January 2016
//		Author:		Paul Robson (paul@robsons.org.uk)
//
// *******************************************************************************************************************************
// *******************************************************************************************************************************

#ifndef _SYS_PROCESSOR_H
#define _SYS_PROCESSOR_H

typedef unsigned short WORD16;														// 8 and 16 bit types.
typedef unsigned int   LONG32;
typedef unsigned char  BYTE8;

#define DEFAULT_BUS_VALUE (0xFF)													// What's on the bus if it's not memory.

#define RAMSIZE		(1024+4096)														// Ram available from 0xC00 upwards.

void CPUReset(void);																// CPU methods
void CPURequestInterrupt(void);														// Request Interrupt
BYTE8 CPUExecuteInstruction(void);													// Execute one instruction (multi phases)

void HWIReset(void);																
void HWIEndFrame(void);																
int HWIProcessKey(int key,int isRunTime);
BYTE8 HWIReadKeyboard(void);
BYTE8 *HWIGetVideoMemory(void);
void HWIWriteVideoMemory(BYTE8 addr,BYTE8 data);
BYTE8 HWIIsKeyPressed(BYTE8 key);
BYTE8 HWIGetLEDDisplay(void);
BYTE8 HWIGetToggleSwitches(void);
void HWISetSoundFrequency(BYTE8 f210);

#define HWIBUTTON_A		(0)
#define HWIBUTTON_B		(1)
#define HWIBUTTON_RESET	(2)

#ifdef INCLUDE_DEBUGGING_SUPPORT													// Only required for debugging

typedef struct _CPUSTATUS {
	int a,e,s;
	int p0,p1,p2,p3;
	int cycles;
} CPUSTATUS;

CPUSTATUS *CPUGetStatus(void);														// Access CPU State
void CPULoadBinary(const char *fileName);											// Load Binary in.
BYTE8 CPUExecute(WORD16 break1,WORD16 break2);										// Run to break point(s)
WORD16 CPUGetStepOverBreakpoint(void);												// Get step over breakpoint
BYTE8 CPUReadMemory(WORD16 address);												// Access RAM and ROM.
void CPUWriteMemory(WORD16 address,BYTE8 data);

#endif
#endif
