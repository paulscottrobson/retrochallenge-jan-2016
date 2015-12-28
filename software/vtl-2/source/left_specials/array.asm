; ****************************************************************************************************************
; ****************************************************************************************************************
;
;												: : Array Access
;
; ****************************************************************************************************************
; ****************************************************************************************************************

	jmp 	__STARR_End

__ST_ArrayWrite:
	lpi 	p3,EvaluateExpression-1 							; evaluate the array index
	xppc 	p3
	jp 		__STARR_Drop2_End 									; exit if error.
	ld 		(p1) 												; look at last character
	xri 	')'
	jnz 	__STARR_NoCloseBracket 								; if not ) then error
	ld 		@1(p1) 												; skip the )
	lpi 	p3,CheckEquals-1 									; do check-equals test
	xppc 	p3
	jp 		__STARR_Drop2_End
	xppc 	p3 													; do right expression.
	ld 		@4(p2) 												; drop result and array index.
	csa
	jp 		__STARR_End 										; exit if error.

	ld 		-2(p2) 												; double array index
	ccl 
	add 	-2(p2)
	st 		-2(p2)
	ld 		-1(p2)
	add 	-1(p2)
	st 		-1(p2)

	lpi 	p3,Variables+('&' & 0x3F) * 2 						; point P3 to array base.
	ccl
	ld 		(p3) 												; calculate LSB -> E
	add 	-2(p2)
	xae
	ld 		1(p3) 												; calculate MSB -> P3.H
	add 	-1(p2)
	xpah 	p3
	lde 														; E -> P3.L
	xpal 	p3
	ld 		-4(p2) 												; copy r-expression to memory
	st 		@1(p3)
	ld 		-3(p2)
	st 		(p3)
	scl 														; is okay
	jmp 	__STARR_End 										; and exit out.


__STARR_NoCloseBracket:											; return bracket error (missing ) off array)
	ldi		ERROR_Bracket
	xae
	ccl
__STARR_Drop2_End:
	ld 		@2(p2) 												; drop two bytes off the stack.

__STARR_End: