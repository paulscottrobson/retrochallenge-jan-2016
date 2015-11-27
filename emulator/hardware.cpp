// *******************************************************************************************************************************
// *******************************************************************************************************************************
//
//		Name:		hardware.c
//		Purpose:	Hardware handling routines (WP1)
//		Created:	1st January 2016
//		Author:		Paul Robson (paul@robsons.org.uk)
//
// *******************************************************************************************************************************
// *******************************************************************************************************************************

#ifdef WINDOWS 																		// Windows Includes
#include <stdio.h>
#include <ctype.h>
#include "gfx.h"
#endif

#ifdef ARDUINO 																		// Arduino Includes
#include <Arduino.h>
#include <PS2Keyboard.h>
#include "ST7920LCDDriver.h"
#endif

#include "sys_processor.h" 															// Everyone includes
#include <stdlib.h>

static BYTE8 needsRepaint = 0;														// Non-zero when needs repainting.
static BYTE8 pendingKey = 0;														// Key ready ?
static BYTE8 currentKey;															// Current key pressed.
static BYTE8 videoMemory[128];														// 16 x 8 VRAM
static BYTE8 dirtyFlags[8];															// 8 x 8 bit dirty flags
static BYTE8 ledDisplay; 															// LED Display
static BYTE8 toggleSwitches; 														// Toggle switch status.

#ifdef ARDUINO
// Wiring to SPI ST7920 GLCD
//
//  Pin 1 (Vss)     GND
//  Pin 2 (Vdd)     5V
//  Pin 3 (VO)      N/C
//  Pin 4 (RS)      A0 (SS Pin)
//  Pin 5 (R/W)     A1 (MOSI Pin)
//  Pin 6 (E)       A2 (SClk Pin)
//  Pin 7-14 (DBx)  N/C
//  Pin 15 (RSB)    GND
//  Pin 16 (NC)     N/C
//  Pin 17 (RST)    N/C
//  Pin 18 (VOUT)   N/C
//  Pin 19 (BLA)    5V
//  Pin 20 (BLK)    0V

#define SPI_MOSI   		A1															// Connection to ST7920
#define SPI_CLK   		A2
#define SPI_ENABLE     	A0 

static ST7920LCDDriver lcd(SPI_CLK, SPI_MOSI, 0);

#define DATA_PIN 		(2)															// Connection to PS2 keyboard
#define CLOCK_PIN 		(3)													
static PS2Keyboard keyboard;														// Keyboard object

#define BUZZER_PIN 		(12)														// Piezo Buzzer.

#endif


// *******************************************************************************************************************************
//													Reset all hardware
// *******************************************************************************************************************************

void HWIReset(void) {
	#ifdef ARDUINO
	pinMode(SPI_ENABLE, OUTPUT);   													// Enable SPI connection
  	digitalWrite(SPI_ENABLE, HIGH);
  	lcd.begin(true);          														// Start the driver
  	lcd.clear();																	// Clear screen
	keyboard.begin(DATA_PIN,CLOCK_PIN);												// Set up PS2 keyboard
	for (BYTE8 i = 0;i < 8;i++)  dirtyFlags[i] = 0xFF;								// WHole screen needs repainting.
	needsRepaint = 1;																// Set repaint flag.
	#endif
	for (BYTE8 i = 0;i < 128;i++) videoMemory[i] = rand();							// Fill VRAM with junk.
}

// *******************************************************************************************************************************
//													Handle on end of frame.
// *******************************************************************************************************************************

void HWIEndFrame(void) {
	if (needsRepaint) {																// Needs repainting.
		needsRepaint = 0;															// Clear flag
		#ifdef ARDUINO
		for (BYTE8 y = 0;y < 8;y++) { 												// Check each line
			if (dirtyFlags[y] != 0) {												// Line needs redoing
				for (BYTE8 x = 0;x < 8;x++) {										// Check each character-pair.
					lcd.drawText(x,y*8,videoMemory+x*2+y*16);
				}
				dirtyFlags[y] = 0;													// Clear dirty flag
			}
		}
		#endif
	}
	#ifdef ARDUINO
	if (keyboard.available()) {														// Key available ?
		pendingKey = keyboard.read();												// Read it.
		if (pendingKey >= 0x80) pendingKey = 0;										// Remove high characters
		if (pendingKey == PS2_BACKSPACE) pendingKey = 8;							// Backspace returns chr(8)
	}
	#endif
	currentKey = pendingKey;
	pendingKey = 0;																	// Comment out to run test code kbd.
}

// *******************************************************************************************************************************
//									Debugger key intercept handler
// *******************************************************************************************************************************

#ifdef WINDOWS
int HWIProcessKey(int key,int isRunTime) {
	if (key != 0 && isRunTime != 0) {												// Running and key press
		BYTE8 newKey = GFXToASCII(key,1);											// Convert to ASCII
		if (newKey != 0) pendingKey = newKey;										// Put pending key in buffer
		if (isxdigit(newKey)) {
			BYTE8 hex = toupper(newKey);
			toggleSwitches = (toggleSwitches << 4) | (hex >= 'A' ? hex-'A'+10:hex-'0');			
		}
	}
	return key;
}
#endif

// *******************************************************************************************************************************
//											Read keyboard
// *******************************************************************************************************************************

BYTE8 HWIReadKeyboard(void) {
	BYTE8 rv = currentKey;															// Only reads key on first read near enough :)
	currentKey = 0;
	if (rv != 0) rv |= 0x80;														// Set strobe bit DB7
	return rv;
}

// *******************************************************************************************************************************
//												Return pointer to video memory
// *******************************************************************************************************************************

BYTE8 *HWIGetVideoMemory(void) {
	return videoMemory;
}

// *******************************************************************************************************************************
//													Write to video memory
// *******************************************************************************************************************************

void HWIWriteVideoMemory(BYTE8 addr,BYTE8 data) {
	addr &= 0x7F;																	// 128 byte VRAM
	if (videoMemory[addr] != data) {												// If changed ?
		videoMemory[addr] = data;													// Update the VRAM
		dirtyFlags[addr >> 4] |= (0x80 >> ((addr >> 1) & 7));						// Mark that 2-character dirty
		needsRepaint = 1;															// Set overall repaint flag
	}
	ledDisplay = data;																// LED displays last write.
}

// *******************************************************************************************************************************
//														Get LED Display
// *******************************************************************************************************************************

BYTE8 HWIGetLEDDisplay(void) {
	return ledDisplay;

}

// *******************************************************************************************************************************
//													  Read toggle switches
// *******************************************************************************************************************************

BYTE8 HWIGetToggleSwitches(void) {
	return toggleSwitches;
}


// *******************************************************************************************************************************
//													External Buttons
// *******************************************************************************************************************************

BYTE8 HWIIsKeyPressed(BYTE8 key) {
	BYTE8 rv = 0;
	#ifdef WINDOWS
	switch(key) {																	// A,B,RESET for Base machine
		case HWIBUTTON_A:		rv = GFXIsKeyPressed(GFXKEY_F2);break;				// Don't bother on replica.
		case HWIBUTTON_B:		rv = GFXIsKeyPressed(GFXKEY_F3);break;
		case HWIBUTTON_RESET:	rv = GFXIsKeyPressed(GFXKEY_F1);break;
	}
	#endif
	return rv;
}

// *******************************************************************************************************************************
//										Set the frequency from the 3 bit value
// *******************************************************************************************************************************

static WORD16 const _freqTable[8] = { 0,280,390,520,650,780,730,447 };				// Pitches for 8 F2F1F0 Values

void HWISetSoundFrequency(BYTE8 f210) {
	WORD16 freq = _freqTable[f210];													// What pitch ?
	#ifdef WINDOWS
	GFXSetFrequency(freq);															// Framework code
	#endif
	#ifdef ARDUINO
	if (freq == 0) {																// Arduino code
		noTone(BUZZER_PIN);
	} else {
		tone(BUZZER_PIN,freq);
	}
	#endif
}
