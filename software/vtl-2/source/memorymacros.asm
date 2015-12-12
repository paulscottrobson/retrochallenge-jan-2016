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

SystemVariables = 0xC90 										; System variables start here.

Variables = SystemVariables 									; 64 x 2 byte system variables, 6 bit ASCII (@,A,B,C...)

KeyboardBuffer = SystemVariables+128							; Keyboard buffer.
KeyboardBufferSize = 80

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

setv macro var,value											; a debugging macro, to set a variable value.
	ldi 	value & 255											; P3 points to variables
	st 		((var & 0x3F)*2)(p3)
	ldi 	value/256
	st 		((var & 0x3F)*2+1)(p3)
	endm
