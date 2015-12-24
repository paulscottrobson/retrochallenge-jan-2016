; ****************************************************************************************************************
; ****************************************************************************************************************
;
;													LET Command
;	
; ****************************************************************************************************************
; ****************************************************************************************************************

CMD_LET:
	ld 		(p1) 												; look at first character
	xri 	'('													; is it a ( (e.g. (H,L))
	jz		__CLE_HLIndirect 	
;
;	Look for A-Z
;	
	ld		(p1)
	ccl
	adi 	128-'A' 											; will be +ve if (p1) < 'A'
	jp 		__CLE_SyntaxError1
	adi 	128-26 												; will be +ve if (p1) >= 26
	jp 		__CLE_SyntaxError1

	ld 		@1(p1) 												; put address of variable on TOS, fetching.
	adi 	(Variables-'A') & 255 								; don't allocate it, yet, that's done
	st 		-2(p2) 												; in target_acquired
	ldi 	0
	adi 	(Variables-'A') / 256
	st 		-1(p2)
	jmp 	__CLE_TargetAcquired
;
;	Errors
;
__CLE_SyntaxError2:
	ld 		@2(p2) 												; syntax error with pop.
__CLE_SyntaxError1:
	ldi 	ERROR_Statement 									; set error to statement
	xae
	ccl 														; indicate error
	jmp 	CMD_LET-2 											; and jump back.
;
;	Handle (H,L) on LHS
;
__CLE_HLIndirect:
	lpi 	p3, EvaluateHL-1 									; evaluate (H,L) as a LHS
	xppc 	p3
	jp 		CMD_LET-2 											; error occurred
;
;	Save address on TOS (not allocated), check for = expression.
;
__CLE_TargetAcquired:
	ld 		@-2(p2) 											; store address is on top of stack.
__CLE_FindEquals:
	ld 		(p1) 												; check EOS
	jz 		__CLE_SyntaxError2
	ld 		@1(p1) 												; refetch and bump
	xri 	' ' 												; skip spaces
	jz 		__CLE_FindEquals
	xri 	' '!'=' 											; if not equals, syntax error
	jnz 	__CLE_SyntaxError2

	lpi 	p3,EvaluateExpression-1 							; evaluate the RHS.
	xppc 	p3
	ld 		@2(p2) 												; pop save address storage, data still there.
	csa 														; check CY/L
	jp 		CMD_LET-2 											; if CY/L = 0 the RHS caused an error.

	ld 		-2(p2) 												; copy save address to P3.
	xpal 	p3
	ld 		-1(p2)
	xpah 	p3
	lde 														; get expression result
	st 		(p3) 												; save where it should go.
	scl 														; executed successfully.
	jmp 	CMD_LET-2
