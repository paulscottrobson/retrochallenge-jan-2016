; ****************************************************************************************************************
; ****************************************************************************************************************
;
;													VTL-2 SC/MP
;
; ****************************************************************************************************************
; ****************************************************************************************************************

; ****************************************************************************************************************
;												 Memory Allocation
; ****************************************************************************************************************

	cpu 	sc/mp
	
ScreenMirror = 0xC00 											; Screen mirror, 128 bytes, 256 byte page boundary.
ScreenCursor = ScreenMirror+0x80  								; Position on that screen (00..7F)

KeyboardBuffer = ScreenMirror + 0xBE 							; 64 character keyboard buffer
KeyboardBufferSize = 64 										; max characters, excluding terminating NULL.

VariableBase = 0xD00 											; Base of variables. Variables start from here, 2 bytes
																; each, 6 bit ASCII (e.g. @,A,B,C)
																; VTL-2 other variables work backwards from here.

ProgramSpace = 0x1000 											; Page with program memory.

StackSearch = 0xFFF 											; Search for stack space back from here.

lpi	macro	ptr,addr
	ldi 	(addr) / 256
	xpah 	ptr
	ldi 	(addr) & 255
	xpal 	ptr
	endm

	org 	0x9000 												; the ROM starts here
	db 		0x68												; this makes it boot straight into this ROM.

	lpi 	p2,0xFFF

Loop:
	lpi 	p3,GetChar-1
	xppc 	p3
	xae
	lpi 	p3,Print-1
	lde
	xppc 	p3
	jmp 	Loop

message:
	db 		12,"HELLO WORLD",13,"ABCE",8,"DE",13,"X",13,"Y",13,"Z",13
	db 		"ABC",13,"DEF",13
	db 		"SCROLLNOW",13,"X",0

	include Source\screen.asm 									; screen I/O stuff.