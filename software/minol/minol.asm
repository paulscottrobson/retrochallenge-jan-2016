; ****************************************************************************************************************
; ****************************************************************************************************************
;
;												Minol ROM Image
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
	setv 	'C',10
	setv 	'D',20
	setv 	'Z',33
	lpi 	p2,0xFF8											; set up stack default value
	lpi 	p1,TestExpr
	lpi 	p3,EvaluateExpression-1
	xppc 	p3
stop:jmp 	stop

	include source\screen.asm 									; screen I/O stuff.
	include source\errors.asm 									; errors
	include source\expression.asm 								; expression evaluator (e.g. RHS)


