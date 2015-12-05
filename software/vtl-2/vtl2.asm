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


Error = VariableBase-1 											; Error Flag (single character if not $00)
ExpressionLevel = VariableBase-2 								; Expression Level (e.g. how many open parenthesis)

MathLibrary = 3 												; Monitor Mathematics Routine Address

ProgramSpace = 0x1000 											; Page with program memory.

StackSearch = 0xFFF 											; Search for stack space back from here.

; ****************************************************************************************************************
;														Macros
; ****************************************************************************************************************

lpi	macro	ptr,addr
	ldi 	(addr) / 256
	xpah 	ptr
	ldi 	(addr) & 255
	xpal 	ptr
	endm

; ****************************************************************************************************************
;													Main Program
; ****************************************************************************************************************

	org 	0x9000 												; the ROM starts here

	db 		0x68												; this makes it boot straight into this ROM.
VTL2Boot:
	lpi 	p2,StackSearch 										; possible top of stack, we check by working down.
	ld 		@64(p2) 											; get round the 4:12 wrapping non emulation.
FindStackTop:
	ldi 	0x75 												; write this at potential TOS
	st 		@-64(p2)
	xor 	(p2) 												; did the write work
	jnz 	FindStackTop


	lpi 	p3,Evaluate-1
	lpi 	p1,Test
	xppc 	p3
wait:
	jmp 	wait


	include Source\screen.asm 									; screen I/O stuff.
	include Source\evaluate.asm 								; evaluate an expression.
