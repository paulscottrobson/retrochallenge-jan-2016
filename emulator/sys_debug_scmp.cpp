// *******************************************************************************************************************************
// *******************************************************************************************************************************
//
//		Name:		debug_scmp.c
//		Purpose:	Debugger Code (System Dependent)
//		Created:	1st January 2016
//		Author:		Paul Robson (paul@robsons->org.uk)
//
// *******************************************************************************************************************************
// *******************************************************************************************************************************

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "gfx.h"
#include "sys_processor.h"
#include "debugger.h"

#define DBGC_ADDRESS 	(0x0F0)														// Colour scheme.
#define DBGC_DATA 		(0x0FF)														// (Background is in main.c)
#define DBGC_HIGHLIGHT 	(0xFF0)

static const char *__mnemonics[] = {
	#include "scmp/__scmp_mnemonics.h"
};

static const BYTE8 __bitmapFont[] = {
	#include "binaries/__font8x8.h"
};

static void _DBGBinary(int x,int y,int n,int cOn,int onColour,int cOff,int offColour) {
	for (int i = 0;i < 8;i++) {
		if (n & 0x80) {
			GFXCharacter(GRID(x,y),cOn,GRIDSIZE,onColour,-1);
		} else {
			GFXCharacter(GRID(x,y),cOff,GRIDSIZE,offColour,-1);
		}
		n = n << 1;
		x++;
		if (i == 3) x++;
	}
};

// *******************************************************************************************************************************
//											This renders the debug screen
// *******************************************************************************************************************************

static const char *labels[] = { "A","E","S","P0","P1","P2","P3","CL","LD","TS","BP","CY", NULL };

void DBGXRender(int *address,int showDisplay) {
	int n = 0;
	char buffer[32],buffer2[4];
	CPUSTATUS *s = CPUGetStatus();
	GFXSetCharacterSize(32,23);
	DBGVerticalLabel(19,0,labels,DBGC_ADDRESS,-1);									// Draw the labels for the register
	GFXDefineCharacter(127,0x3E,0x7F,0x7F,0x7F,0x3E);
	GFXDefineCharacter(126,0x3E,0x4F,0x4F,0x4F,0x3E);
	GFXDefineCharacter(125,0x3E,0x79,0x79,0x79,0x3E);
	#define DN(v,w) GFXNumber(GRID(22,n++),v,16,w,GRIDSIZE,DBGC_DATA,-1)			// Helper macro

	//s->a = HWIReadKeyboard();

	n = 0;
	DN(s->a,2);DN(s->e,2);DN(s->s,2);												// Dump Registers etc.
	DN(s->p0,4);DN(s->p1,4);DN(s->p2,4);DN(s->p3,4);		
	DN((s->s >> 7) & 1,1);
	_DBGBinary(22,n++,HWIGetLEDDisplay(),127,0xF00,127,0x400);
	_DBGBinary(22,n++,HWIGetToggleSwitches(),125,0x0F0,126,0x00F);
	DN(address[3],4);DN(s->cycles,4);

	int a = address[1];																// Dump Memory.
	for (int row = 13;row < 22;row++) {
		GFXNumber(GRID(2,row),a,16,4,GRIDSIZE,DBGC_ADDRESS,-1);
		GFXCharacter(GRID(6,row),':',GRIDSIZE,DBGC_HIGHLIGHT,-1);
		for (int col = 0;col < 8;col++) {
			GFXNumber(GRID(7+col*3,row),CPUReadMemory(a),16,2,GRIDSIZE,DBGC_DATA,-1);
			a = (a + 1) & 0xFFFF;
		}		
	}
	int p = address[0];																// Dump program code. 
	int opc,opr;
	for (int row = 0;row < 12;row++) {
		int isPC = (p == ((s->p0+1) & 0xFFFF));										// Tests.
		int isBrk = (p == address[3]);
		GFXNumber(GRID(2,row),p,16,4,GRIDSIZE,isPC ? DBGC_HIGHLIGHT:DBGC_ADDRESS,	// Display address / highlight / breakpoint
																	isBrk ? 0xF00 : -1);
		opc = CPUReadMemory(p);p = (p + 1) & 0xFFFF;								// Read opcode.
		if ((opc & 0x80) != 0) {
			opr = CPUReadMemory(p);p = (p + 1) & 0xFFFF;							// Read operand.
		}
		strcpy(buffer,__mnemonics[opc]);												// Set the mnemonic.
		if (buffer[0] == '\0') sprintf(buffer,"db %02x",opc);						// Make up one if required.

		char *ph = strchr(buffer,'#');												// Insert operand
		if (ph != NULL) {
			sprintf(buffer2,"%02x",opr);
			*ph++ = buffer2[0];
			*ph++ = buffer2[1];
		}
					
		GFXString(GRID(7,row),buffer,GRIDSIZE,isPC ? DBGC_HIGHLIGHT:DBGC_DATA,-1);	// Print the mnemonic
	}

	if (showDisplay == 0) return;

	int xSize = 5;
	int ySize = 5;

	SDL_Rect rc;
	rc.w = 8 * 16 * xSize;															// 8 x 8 font, 16 x 8 text
	rc.h = 8 * 8 * ySize;			
	rc.x = WIN_WIDTH/2-rc.w/2;rc.y = WIN_HEIGHT-64-rc.h;
	SDL_Rect rc2 = rc;
	rc2.x -= 10;rc2.y -= 10;rc2.w += 20;rc2.h += 20;
	GFXRectangle(&rc2,0xFFF);
	rc2.x += 2;rc2.y += 2;rc2.w -= 4;rc2.h -= 4;
	SDL_Rect rcPixel;rcPixel.w = xSize;rcPixel.h = ySize;
	GFXRectangle(&rc2,0x13F);
	for (int x = 0;x < 16;x++) {
		for (int y = 0;y < 8;y++) {
			BYTE8 ch = HWIGetVideoMemory()[x + y * 16];
			for (int y1 = 0;y1 < 8;y1++) {
				BYTE8 b = __bitmapFont[ch * 8 + y1];
				rcPixel.x = (x * 8 * xSize)+rc.x;
				rcPixel.y = (y * 8 + y1) * ySize + rc.y;
				while (b != 0) {
					if (b & 0x80) GFXRectangle(&rcPixel,0xFFF);
					b = (b << 1) & 0xFF;
					rcPixel.x += xSize;
				}
			}
		}
	}
}	