; ****************************************************************************************************************
; ****************************************************************************************************************
;
;												VTL-2 ROM Image
;
; ****************************************************************************************************************
; ****************************************************************************************************************

	cpu 	sc/mp

	include source\memorymacros.asm 							; Memory allocation and Macro definition.	

; ****************************************************************************************************************
;													Main Program
; ****************************************************************************************************************

	org 	0x9000 												; the ROM starts here

	db 		0x68												; this makes it boot straight into this ROM.

	lpi 	p3,Variables
	setv 	'C',1023
	setv 	'D',15
	setv 	'&',0x2F0

	lpi 	p2,0xFF8											; set up stack
	lpi 	p1,StartProgram
Next:
	lpi 	p3,ExecuteStatement-1
	xppc 	p3
	xae
	csa
	jp 		stop
	jmp		Next

stop:jmp 	stop

	include source\screen.asm 									; screen I/O stuff.
	include source\special_terms.asm 							; special terms (things like ?, $, ! a)
	include source\expression.asm 								; expression evaluator.
	include source\statement.asm 								; statement

StartProgram:
	vtl 	100,"C=30*9"
	vtl 	110,"B=22*5+3"
	vtl 	120,"A=C+B"
	vtl 	130,"G=2173/1000"
	vtl 	140,"H=%"
	vtl 	150,"I='"
	vtl 	160,"J='"
	vtl 	170,"K='"
	vtl 	180,"L='"
	db 	0
FreeMemory: