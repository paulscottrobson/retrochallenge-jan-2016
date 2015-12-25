; ****************************************************************************************************************
; ****************************************************************************************************************
;
;										Memory and Macro Allocation.
;	
; ****************************************************************************************************************
; ****************************************************************************************************************

OSMathLibrary = 0x0003 											; the Maths library is here.

; ****************************************************************************************************************
;												 Memory Allocation
; ****************************************************************************************************************

ScreenMirror = 0xC00 											; Screen mirror, 128 bytes, 256 byte page boundary.
ScreenCursor = ScreenMirror+0x80  								; Position on that screen (00..7F)

SystemVariables = 0xD00 										; System variables start here.

Variables = SystemVariables 									; 128 16 bit variables start here.

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
	st 		((ch) & 0x3F)*2(p3)
	ldi 	(value) / 256
	st 		((ch) & 0x3F)*2+1(p3)
	endm

code macro lineNo,code 											; a debugging macro, which fakes up a line of code.
	db 		strlen(code)+4 										; one byte offset to next (0 = End of code)
	dw 		lineNo 												; two byte line number (low byte first)
	db 		code,0 												; ASCIIZ string
	endm
