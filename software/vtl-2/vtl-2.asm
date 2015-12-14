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
	setv 	'&',0x2F0
	ldi 	0xFF
	st 		-1(p3)
	lpi 	p2,0xFF8											; set up stack
	lpi 	p1,StartProgram
Next:
	lpi 	p3,ExecuteStatement-1
	xppc 	p3
	xae
	csa
	jp 		stop
	lpi 	p3,IsRunningProgram
	ld 		(p3)
	jnz		Next

stop:jmp 	stop

	include source\screen.asm 									; screen I/O stuff.
	include source\special_terms.asm 							; special terms (things like ?, $, ! a)
	include source\expression.asm 								; expression evaluator.
	include source\statement.asm 								; statement

StartProgram:
	vtl 	100,"$=12"
	vtl 	110,"A=?"
	vtl 	120,"B=A*A"
	vtl 	130,"C='"
	db 	0
FreeMemory: