; ****************************************************************************************************************
; ****************************************************************************************************************
;
;												VTL-2 ROM Image
;
; ****************************************************************************************************************
; ****************************************************************************************************************

	cpu 	sc/mp

	include source\memorymacros.asm 							; Memory allocation and Macro definition.	
	include source\errors.asm 									; Error Codes

; ****************************************************************************************************************
;													Main Program
; ****************************************************************************************************************

	org 	0x9000 												; the ROM starts here

	db 		0x68												; this makes it boot straight into this ROM.
	lpi 	p2,0xFF8											; set up stack default value
	lpi 	p3,Print-1 											; clear screen
	ldi 	12
	xppc 	p3

	lpi 	p3,Variables 										; set some variables
	setv 	'C',0x1382
	setv	'&',0x2F0
	ldi 	1
	st 		IsRunning-Variables(p3)	

	ldi		test/256											; set program base address.
	st 		ProgramBase-Variables+1(p3)
	ldi		test&255
	st 		ProgramBase-Variables(p3)

	lpi 	p3,ExecuteNextStatement-1							; execute statement
	lpi 	p1,test
	xppc 	p3

test:
	code 	90,"?= \"STARTED\""
	code 	100,"A = 0"
	code 	110,"A = A + 1"
	code 	200,"# = (A < 1000) * 110"
	code 	90,"?=\"FINISHED\""
	db 		0

; ****************************************************************************************************************
;													Source Files
; ****************************************************************************************************************

	include source\screen.asm 									; screen I/O stuff.
	include source\statement.asm 								; statement interpreter.
