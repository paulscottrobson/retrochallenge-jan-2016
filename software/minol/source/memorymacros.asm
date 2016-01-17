; ****************************************************************************************************************
; ****************************************************************************************************************
;
;										Memory and Macro Allocation.
;	
; ****************************************************************************************************************
; ****************************************************************************************************************

OSMathLibrary = 0x0003 											; the Maths library is here.
BootMonitor = 0x168 											; address to boot monitor

Print = 0x0003
GetChar = 0x0005
GetString = 0x0007

; ****************************************************************************************************************
;												 Memory Allocation
; ****************************************************************************************************************

ScreenMirror = 0xC00 											; Screen mirror, 128 bytes, 256 byte page boundary.
ScreenCursor = ScreenMirror+0x80  								; Position on that screen (00..7F)

SystemMemory = 0xC90 											; System Memory

RandomSeed = SystemMemory-2										; Random Seed Value (2 bytes)
CurrentLine = SystemMemory-3 									; Current Line Number (1 byte)
Variables = SystemMemory 										; Variables (26 bytes)

KeyboardBuffer = SystemMemory+32 								; Keyboard input buffer
KeyboardBufferSize = 72 										; Number of characters allowed to be typed in.

ProgramBase = 0x1004 											; Program memory here.

Marker1 = 	0xFD 												; Markers indicating "Code here"
Marker2 = 	0xB5
Marker3 = 	0xAE
Marker4 = 	0x76

; ****************************************************************************************************************
;														Macros
; ****************************************************************************************************************

lpi	macro	ptr,addr											; load pointer register with constant
	ldi 	(addr) / 256
	xpah 	ptr
	ldi 	(addr) & 255
	xpal 	ptr
	endm

pushp macro ptr 												; push pointer register on stack
	xpah 	ptr
	st 		@-1(p2)
	xpal 	ptr
	st 		@-1(p2)
	endm

pullp macro ptr 												; pull pointer register off stack
	ld 		@1(p2)
	xpal 	ptr
	ld 		@1(p2)
	xpah 	ptr
	endm

pushe macro 													; push E on stack
	lde
	st 		@-1(p2)
	endm

pulle macro 													; pull E off stack
	ld 		@1(p2)
	xae
	endm

pusha macro 													; push A on stack
	st 		@-1(p2)
	endm

pulla macro
	ld 		@1(p2)
	endm

setv macro ch,value 											; sets a variable to a value, assumes P3 = Variables.
	ldi 	(value) & 255
	st 		((ch) - 'A')(p3)
	endm

code macro lineNo,code 											; a debugging macro, which fakes up a line of code.
	db 		strlen(code)+3 										; one byte offset to next (255 = End of code)
	db 		lineNo 												; one byte line number 
	db 		code,0 												; ASCIIZ string
	endm

cmd macro 	c1,c2,length,code
	db 		c1,c2 												; first and second characters
	db 		(length)-1											; length -1 (first char already skipped)
	dw 		(code)-1 											; execution point for prefetch.
	endm