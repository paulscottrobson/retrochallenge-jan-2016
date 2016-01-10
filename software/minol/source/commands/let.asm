; ****************************************************************************************************************
; ****************************************************************************************************************
;
;												LET command
;	
; ****************************************************************************************************************
; ****************************************************************************************************************

	jmp 	CLE_Over

CMD_Let:
	ld 		(p1) 												; look at character
	xri 	'('													; is it let (h,l) ?
	jz 		CLE_IsHL 											; if so, go to the (H,L) code
	ld 		(p1) 												; re-read it.
	ccl
	adi 	255-'Z' 											; will be +ve on error
	jp 		CLE_Syntax 											; e.g. > Z
	adi 	26 													; will be 0-25 if A..Z
	jp 		CLE_SingleVariable
;
;	Syntax Error
;
CLE_Syntax:
	ldi 	ERRC_Syntax 										; set E to error code.
	xae
	ccl 														; CY/L = 0 = Error
	jmp 	CLE_Over 											; and exit
;
;	A-Z. AC contains 0-25
;
CLE_SingleVariable:
	ccl  														; work out variable address, and put on stack.
	adi 	Variables & 255
	st 		@-2(p2) 
	ldi 	Variables / 256
	adi 	0
	st 		1(p2)
	ld 		@1(p1) 												; skip over the variable.
	jmp 	CLE_EvaluateAndWrite
;
;	LET is (H,L) = <expr>
;
CLE_IsHL:
	lpi 	p3,EvaluateAddressPair-1 							; evaluate the (H,L)
	xppc 	p3
	jp 		CLE_Over 											; exit on error
	ld 		@-2(p2) 											; the address to write to is now on TOS.
;
;	Evaluate and write.
;
CLE_EvaluateAndWrite:
	ld 		@1(p1) 												; skip over spaces
	xri 	' '
	jz 		CLE_EvaluateAndWrite
	xri 	' '!'='												; check first non space character is =
	jnz 	CLE_Syntax 											; if not, a syntax error.

	lpi 	p3,EvaluateExpression-1 							; set up to evaluate the RHS
	xppc 	p3													; do it
	ld 		@2(p2) 												; remove target from TOS but leave data there
	csa 														; did that evaluate cause an error ?
	jp 		CLE_Over 											; if so, exit with that error.

	ld 		-2(p2) 												; load address into P3
	xpal 	p3
	ld 		-1(p2)
	xpah 	p3
	lde 														; get value
	st 		(p3) 												; store there
	scl 														; no error and exit.

CLE_Over: