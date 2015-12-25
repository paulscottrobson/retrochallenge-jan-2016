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
	lpi 	p3,Variables
	setv 	'C',0x1382

	lpi 	p3,EvaluateExpression-1
	lpi 	p1,test
	xppc 	p3
	jp 		Wait1
	lpi 	p1,0xE00
	lpi 	p3,2
	ldi 	'$'
	xppc 	p3
	lpi 	p3,Print-1
	ldi 	0
	xppc 	p3
Wait1:
	jmp 	Wait1

test:
	db 		"200/7*0+%",0

; ****************************************************************************************************************
;													Source Files
; ****************************************************************************************************************

	include source\screen.asm 									; screen I/O stuff.
	include source\expression.asm 								; expression 
