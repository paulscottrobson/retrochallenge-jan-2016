// *******************************************************************************************************************************
// *******************************************************************************************************************************
//
//		Name:		sys_processor.c
//		Purpose:	Processor Emulation.
//		Created:	1st January 2016
//		Author:		Paul Robson (paul@robsons.org.uk)
//
// *******************************************************************************************************************************
// *******************************************************************************************************************************

#include "sys_processor.h"
#include "sys_debug_system.h"

// *******************************************************************************************************************************
//														   Timing
// *******************************************************************************************************************************

#define CRYSTAL_CLOCK 	(1000000)													// Clock cycles (1Mhz)
#define CYCLE_RATE 		(CRYSTAL_CLOCK/2)											// Cycles per second (500khz)
#define FRAME_RATE		(50)														// Frames per second (50)
#define CYCLES_PER_FRAME (CYCLE_RATE / FRAME_RATE)									// Cycles per frame

// *******************************************************************************************************************************
//														ROM Memory
// *******************************************************************************************************************************

#ifdef WINDOWS
#define ROMTYPE static BYTE8 
#define ROM(image,offset)	image[offset]
#endif
#ifdef ARDUINO
#include <Arduino.h>
#include <avr/pgmspace.h>
#define ROMTYPE static uint8_t const PROGMEM 
#define ROM(image,offset) pgm_read_byte_far(image+offset)
#endif

ROMTYPE      romMemory[2048] = {													// 0x0000-0x07FF ROM Memory
	#include "binaries/__monitor_rom.h"
};

static BYTE8 ramMemory[RAMSIZE];													// 0x0C00-0x7FFF RAM Memory

ROMTYPE      extRomMemory[] = {														// 0x9000-0x9FFF ROM Memory
	#include "binaries/__rom_9000.h"
};

// *******************************************************************************************************************************
//														CPU / Memory
// *******************************************************************************************************************************

static BYTE8  AC,EX,SR;																// CPU Registers (Bits 0-3)
static WORD16 P0,P1,P2,P3,cycles;		
static WORD16 doubleCyclesToWaste; 													// Number of double cycles to waste.
static BYTE8  carryFlag,overflowFlag;												// More SR components.

static BYTE8 MB,opcode,operand,temp8;												// Working storage
static WORD16 MA,temp16,offset;

// *******************************************************************************************************************************
//													Memory read and write macros.
// *******************************************************************************************************************************

#define READ() 		_Read()
#define WRITE() 	_Write()

static void inline _Read(void) {
	if (MA < 0x800) {
		MB = ROM(romMemory,MA);
		return;
	}
	if (MA >= 0x9000) {
		MB = ROM(extRomMemory,MA-0x9000);
		return;
	}
	if (MA >= 0xC00 && MA < 0xC00+RAMSIZE) {
		MB = ramMemory[MA-0xC00];
		return;
	}
	if (MA >= 0x800 && MA < 0xC00) {
		if (MA == 0xAAA) {
			MB = HWIGetToggleSwitches();
		} else {
			MB = HWIReadKeyboard();
		}
		return;
	}
	MB = DEFAULT_BUS_VALUE;
}

static void inline _Write(void) {
	if (MA >= 0xC00 && MA < 0xC00+RAMSIZE) {
		ramMemory[MA-0xC00] = MB;
		return;
	}
	if (MA < 0x800) {
		HWIWriteVideoMemory(MA,MB);
	}
}

// *******************************************************************************************************************************
//															Other macros
// *******************************************************************************************************************************

#define CYCLES(n)		cycles += (n)												// Add to cycles

#define SENSEA()		(HWIIsKeyPressed(HWIBUTTON_A) == 0)							// Button inputs.
#define SENSEB()		(HWIIsKeyPressed(HWIBUTTON_B) == 0)

#define DELAYCPU(op,ac)	_StartDelay(op,ac)											// Instigate a CPU delay.

#define SEXT(c) 		((signed short)((signed char)(c)))							// Sign extend 8->16

#define UPDATEFLAGS(f) 	HWISetSoundFrequency(f)										// Update pitch

// *******************************************************************************************************************************
//													Complete status register
// *******************************************************************************************************************************

BYTE8 _GetStatusReg(void) {
	SR = SR & 0x0F;																	// Keep IE/F2/F1/F0
	if (SENSEA()) SR |= 0x10;														// Get other values.
	if (SENSEB()) SR |= 0x20;
	if (overflowFlag) SR |= 0x40;
	if (carryFlag != 0) SR |= 0x80;
	return SR;
}

// *******************************************************************************************************************************
//														  Arithmetic
// *******************************************************************************************************************************

static void inline _BinaryAdd(void) {
	temp16 = AC + MB + carryFlag;													// Calculate result into temp16
	carryFlag = (temp16 >> 8) & 1;													// Get new carry flag.	
	overflowFlag = 0;																// Clear Overflow
	if ((AC & 0x80) == (MB & 0x80)) {												// Sign of inputs the same
		if ((AC & 0x80) != (temp16 & 0x80)) overflowFlag = 1;						// If sign of result different set OV
	}
	AC = temp16 & 0xFF;																// Copy to AC
}

static void inline _DecimalAdd(void) {
	temp8 = (AC & 0xF) + (MB & 0xF) + carryFlag;									// Calculate Lower digit
	temp16 = (AC & 0xF0) + (MB & 0xF0);												// Calculate Upper digit
	carryFlag = 0;																	// Clear carry
	if (temp8 > 9) {																// Propagate from low to high (half carry)
		temp8 = temp8 - 10;															// Adjust lower digit	
		temp16 = temp16 + 0x10;														// Add to upper digit
	}
	if (temp16 > 0x90) {															// Carry out ?
		temp16 = temp16 - 0xA0;														// Adjust upper digit
		carryFlag = 1;																// Set carry flag.
	}
	AC = (temp8 | temp16) & 0xFF;													// Calculate result put in AC.
}

// *******************************************************************************************************************************
//														Reset the CPU
// *******************************************************************************************************************************

void CPUReset(void) {
	AC = EX = SR = 0;																// Reset 8 bit registers
	P0 = P1 = P2 = P3 = 0;															// Reset Ptr registers
	carryFlag = overflowFlag = 0;													// Reset other bits of status
	cycles = 0;																		// Reset cycle count.
	doubleCyclesToWaste = 0;														// Reset cycle waste counter.
	HWIReset();																		// Reset hardware
}

// *******************************************************************************************************************************
//												  Start a DLY instruction
// *******************************************************************************************************************************

static void _StartDelay(BYTE8 operand,BYTE8 acc) {
	doubleCyclesToWaste = operand * 256;											// We aren't that worried, near enough :)

	WORD16 doubleCyclesRemaining = (CYCLES_PER_FRAME-cycles)/2;						// How many 2-cycles are left.
	if (doubleCyclesRemaining > doubleCyclesToWaste) {								// Can we do it this frame ?
		cycles = cycles + doubleCyclesToWaste * 2; 									// If so, bump the cycle count.
		doubleCyclesToWaste = 0;													// and nothing left to throw.
	} else {
		doubleCyclesToWaste -= doubleCyclesRemaining;								// What we use this frame.
		cycles = CYCLES_PER_FRAME;													// End this frame.
	}
}

// *******************************************************************************************************************************
//												Execute a single instruction
// *******************************************************************************************************************************

BYTE8 CPUExecuteInstruction(void) {

	if (doubleCyclesToWaste > 0) {													// Time to waste due to DLY ?
		if (doubleCyclesToWaste > CYCLES_PER_FRAME/2) {								// Won't expire this time.
			doubleCyclesToWaste -= CYCLES_PER_FRAME / 2;
			HWIEndFrame();															// Call the end of frame code.
			return FRAME_RATE;
		}
		cycles = cycles + doubleCyclesToWaste * 2;									// Use up this many cycles
		doubleCyclesToWaste = 0;													// None left to waste.
	}

	// This read doesn't use READ/WRITE macros for speed.
	MA = P0 = (P0 + 1) & 0xFFFF;													// Bump P0.
	READ();opcode = MB;																// Read opcode
	if ((opcode & 0x80) != 0) {														// Two byte instruction, fetch operand.
		P0++;MA++;																	// Bump P0 and MA
		READ();operand = MB;														// Read the operand.
	}
	
	switch(opcode) {																// Execute it.
		#include "scmp/__scmp_opcodes.h"
	}

	if (cycles < CYCLES_PER_FRAME) return 0;										// Not completed a frame.
	cycles = cycles - CYCLES_PER_FRAME;												// Adjust this frame rate.
	HWIEndFrame();																	// Call the end of frame code.
	if (HWIIsKeyPressed(HWIBUTTON_RESET)) CPUReset();								// Reset Button.
	return FRAME_RATE;																// Return frame rate.
}

#ifdef INCLUDE_DEBUGGING_SUPPORT

// *******************************************************************************************************************************
//		Execute chunk of code, to either of two break points or frame-out, return non-zero frame rate on frame, breakpoint 0
// *******************************************************************************************************************************

BYTE8 CPUExecute(WORD16 breakPoint1,WORD16 breakPoint2) { 
	breakPoint1 = (breakPoint1-1) & 0xFFFF;											// Fix to work with SC/MP preincrement
	breakPoint2 = (breakPoint2-1) & 0xFFFF;
	do {
		BYTE8 r = CPUExecuteInstruction();											// Execute an instruction
		if (r != 0) return r; 														// Frame out.
	} while (P0 != breakPoint1 && P0 != breakPoint2);								// Stop on breakpoint.
	return 0; 
}

// *******************************************************************************************************************************
//									Return address of breakpoint for step-over, or 0 if N/A
// *******************************************************************************************************************************

WORD16 CPUGetStepOverBreakpoint(void) {
	BYTE8 opcode = CPUReadMemory((P0+1) & 0xFFFF);									// Read next opcode.
	if (opcode >= 0x3D && opcode <= 0x3F) {											// If XPPC P1,P2 or P3 (SC/MP function calls)
		return (P0+2) & 0xFFFF;														// Return the address after that.
	}
	return 0;																		// Do a normal single step
}

// *******************************************************************************************************************************
//												Read/Write Memory
// *******************************************************************************************************************************

BYTE8 CPUReadMemory(WORD16 address) {
	BYTE8 _return,_MB = MB;WORD16 _MA = MA;
	MA = address;READ();_return = MB;
	MA = _MA;MB = _MB;
	return _return;
}

void CPUWriteMemory(WORD16 address,BYTE8 data) {
	BYTE8 _MB = MB;WORD16 _MA = MA;
	MA = address;MB = data;WRITE();
	MA = _MA;MB = _MB;
}

// *******************************************************************************************************************************
//											Retrieve a snapshot of the processor
// *******************************************************************************************************************************

static CPUSTATUS s;																	// Status area

CPUSTATUS *CPUGetStatus(void) {
	s.a = AC;s.e = EX;s.s = _GetStatusReg();
	s.p0 = P0;s.p1 = P1;s.p2 = P2;s.p3 = P3;
	s.cycles = cycles;
	return &s;
}

#include <stdio.h>

// *******************************************************************************************************************************
//													Loading in Binary Code
// *******************************************************************************************************************************

void CPULoadBinary(const char *file) {
	BYTE8* target = romMemory;														// Default target ROM
	int n = 0;
	if (*file == '@') {																// @xxxxx loads into RAM
		file++; 																	// Skip the @
		target = ramMemory;															// New target
	}
	if (*file == '$') {																// $xxxxx loads into 9000 ROM
		file++;
		target = extRomMemory;
	}
	//printf("Reading file %s\n",file);
	FILE *f = fopen(file,"rb");														// And load in.
	while (!feof(f)) {
		target[n++] = fgetc(f);
	}
	fclose(f);	
	//printf("Read %d\n",n);
}

#endif
