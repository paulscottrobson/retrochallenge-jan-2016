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
	setv 	'&',0x9002
	lpi 	p2,0xFF8											; set up stack
	lpi 	p1,test
	lpi 	p3,EvaluateExpression-1
	xppc 	p3
stop:jmp 	stop

	include source\screen.asm 									; screen I/O stuff.
	include source\special_terms.asm 							; special terms (things like ?, $, ! a)
	include source\expression.asm 								; expression evaluator.

test:
	db 	"?",0