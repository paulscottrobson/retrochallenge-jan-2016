; ****************************************************************************************************************
; ****************************************************************************************************************
;
;												VTL-2 Expression test
;
; ****************************************************************************************************************
; ****************************************************************************************************************

	cpu 	sc/mp

	include ..\vtl-2\source\memorymacros.asm 					; Memory allocation and Macro definition.	

; ****************************************************************************************************************
;													Main Program
; ****************************************************************************************************************

	org 	0x9000 												; the ROM starts here

	db 		0x68												; this makes it boot straight into this ROM.
	lpi 	p2,0xFF8											; set up stack
	ldi 	testexpr/256 										; set pointer to testexpr
	st 		1(p2)
	ldi 	testexpr&255
	st 		0(p2)
testLoop:
	lpi 	p2,0xFF8 											; load pointer into P1.
	ld 		0(p2)
	xpal 	p1
	ld 		1(p2)
	xpah 	p1
	ld 		0(p1)												; check if done.
	jz 		ExprDone
	lpi 	p3,EvaluateExpression-1 							; evaluate expression.
	xppc 	p3
	csa 														; check if failed.
	jp 		ExprFail
	xpal 	p2
	xri 	0xF6 												; check stack position correct.
	jnz 	ExprFail
	lpi 	p2,0xFF8 											; fix stack back up.
	ld 		0(p2)												; load string position
	xpal 	p1
	ld 		1(p2)
	xpah 	p1
testEOS:														; find end of string
	ld 		@1(p1)
	jnz 	testEOS
	ld 		-2(p2)												; check result
	xor 	@1(p1)
	jnz 	ExprFail
	ld 		-1(p2)
	xor 	@1(p1)
	jnz 	ExprFail
	xpal 	p1 													; write it back
	st 		0(p2)
	xpah 	p1
	st 		1(p2)
	jmp 	testloop
stop:jmp 	stop

ExprDone:
	ldi 	0
	xae
	jmp 	ExprDone
ExprFail:
	ldi 	0xFF
	xae
	jmp 	ExprFail

	include ..\vtl-2\source\special_terms.asm 					; special terms (things like ?, $, ! a)
	include ..\vtl-2\source\expression.asm 						; expression evaluator.

testexpr:
	include 	tests.inc	
	db 		0