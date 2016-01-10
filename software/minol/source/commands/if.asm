; ****************************************************************************************************************
; ****************************************************************************************************************
;
;												IF command
;	
; ****************************************************************************************************************
; ****************************************************************************************************************

	jmp		CIF_Over

CMD_If:
	xppc 	p3 													; calculate LHS of expr.
	jp 		CIF_Over											; exit on error.
	ld 		(p1)												; get the relative operator.
	xri 	'='													; check it is =, < or #
	jz 		CIF_Continue
	xri 	'='!'#'
	jz 		CIF_Continue
	xri 	'#'!'<'
	jz 		CIF_Continue
;
;	Syntax error - bad relative operation.
;
CIF_Syntax:
	ldi	 	ERRC_Syntax											; report syntax error
	xae
	ccl
	jmp 	CIF_Over
;
;	Continue IF - have LHS in E.
;
CIF_Continue:
	ld 		@1(p1) 												; reget operator, and save on stack
	st 		@-1(p2)
	lde 														; save LHS on stack.
	st 		@-1(p2)
	xppc 	p3 													; evaluate the RHS of the expression
	ld 		@2(p2) 												; drop operator and LHS but the values still there.
	csa 														; check for RHS error
	jp 		CIF_Over 											; and exit on error
	ld 		-1(p2) 												; get operator
	xri 	'<'
	jnz 	CIF_Equality 										; if not less than it's an equality test e.g. # or =

; ****************************************************************************************************************
;												Less than test.
; ****************************************************************************************************************

	ld 		-2(p2) 												; get LHS
	scl
	cae 														; subtract RHS.
	csa 														; get CY/L flag
	ani 	0x80 												; now it is AC = 0 if < true.
	jmp 	CIF_TestIfZero

; ****************************************************************************************************************
;											Equal/Not Equal Test.
; ****************************************************************************************************************
	
CIF_Equality:
	ld 		-2(p2) 												; get LHS
	xre 														; compare to RHS. AC = 0 if *equal*
	jz 		CIF_Equality2
	ldi 	2 													; AC = 0 if *equal* 2 if *different*
CIF_Equality2:
	xae 														; save in E
	ld 		-1(p2) 												; get operator.
	ani 	2 													; is now 0 if '=' ($3D) 2 if '#' ($23)
	xre 														; XOR with the result. Now 0 if passes test.

; ****************************************************************************************************************
;							Pass Test (e.g. execute statement following ;) if AC = 0
; ****************************************************************************************************************

CIF_TestIfZero:
	scl 														; set CY/L = No Error.
	jnz 	CIF_Over 											; if non-zero then do next command as normal.
	
	ld 		(p1) 												; get next character
	xri 	';'													; should be a semicolon
	jnz 	CIF_Syntax 											; if not error
	ld 		@1(p1) 												; step over it.
	jmp 	ExecuteFromAddressDirect 							; and run from here.

CIF_Over:

