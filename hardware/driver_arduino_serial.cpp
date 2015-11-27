// *******************************************************************************************************************************
// *******************************************************************************************************************************
//
//		Name:		driver_arduino_serial.cpp
//		Purpose:	I/O Driver, Arduino Serial port.
//		Created:	20th October 2015
//		Author:		Paul Robson (paul@robsons.org.uk)
//
// *******************************************************************************************************************************
// *******************************************************************************************************************************

#include <Arduino.h>
#include "driver_common.h"

static BYTE8 isInitialised = 0;

BYTE8 DRVGFXHandler(BYTE8 key,BYTE8 isRunMode) {
	if (key != 0 && isRunMode) {
		keyAvailable = 0;
	}
	return key;
}

// *******************************************************************************************************************************
//												Ultra simple STDOUT Driver
// *******************************************************************************************************************************

void DRVWrite(BYTE8 command,DRVPARAM data) {
	if (isInitialised == 0) {
		Serial.begin(9600);
		isInitialised = 1;
	}
	switch(command) {
		case DWA1_WRITE:	Serial.print("%c",data);break;
		case DWA1_BACKSPACE:Serial.print("[<-]");break;
		case DWA1_NEWLINE:	Serial.print("[CR]\n");break;
	}
}

