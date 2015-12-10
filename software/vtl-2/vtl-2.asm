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
	lpi 	p2,0xFFF											; set up stack

	lpi 	p3,Print-1 											; clear screen
	ldi 	12
	xppc 	p3

loop:
	ldi 	']'													; Prompt
	xppc 	p3
	lpi 	p3,GetString-1 										; Input a string
	lpi 	p1,0xD00
	ldi 	15
	xppc 	p3
	lpi 	p3,Print-1 											; Echo it
	ldi 	0
	xppc 	p3
	ldi 	13
	xppc 	p3
	jmp 	loop

	include source\screen.asm 									; screen I/O stuff.
