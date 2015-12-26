; ****************************************************************************************************************
; ****************************************************************************************************************
;
;												VTL-2 Expression Test
;
; ****************************************************************************************************************
; ****************************************************************************************************************

	cpu 	sc/mp

	include ..\vtl-2\source\memorymacros.asm 							; Memory allocation and Macro definition.	
	include ..\vtl-2\source\errors.asm 									; Error Codes

; ****************************************************************************************************************
;													Main Program
; ****************************************************************************************************************

	org 	0x9000 												; the ROM starts here

	db 		0x68												; this makes it boot straight into this ROM.
	lpi 	p1,testData
	lpi 	p3,Variables										; set up variables.
	setv 	'C',1029
	setv 	'E',42
	setv 	'A',13
	setv 	'Z',69
	setv 	'&',0x2F0 											; array starts here, sort of.
	
TestLoop:
	lpi 	p2,0xFF8											; set up stack default value
	ld 		(p1) 												; reached end ?
	jz 		Report
	lpi 	p3,EvaluateExpression-1 							; evaluate expression.
	xppc 	p3
	jp 		Error
FindEnd: 														; find answer.
	ld 		@1(p1)
	jnz 	FindEnd
	ld 		(p2)
	xor 	@1(p1)
	jnz 	Error
	ld 		1(p2)
	xor 	@1(p1)
	jz 		TestLoop
Error:
	ldi 	0xFF
Report:
	xae
	lde
	jmp 	Report

; ****************************************************************************************************************
;													Source Files
; ****************************************************************************************************************

	include ..\vtl-2\source\expression.asm 								; expression 
	include ..\vtl-2\source\right_special.asm 							; r-expr specials
	
testData:
	include tests.inc
	db 		0

	