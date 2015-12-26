; ****************************************************************************************************************
; ****************************************************************************************************************
;
;										Special Terms (Right Hand Side)
;
; ****************************************************************************************************************
; ****************************************************************************************************************
;
;	(<expr>)					Parenthesised expression
;	:<expr>)					Array access (relative to '&')
;	$ 							Read character from keyboard
;	?							Read line and evaluate expression.
;
; ****************************************************************************************************************
;
;	This function does special terms for the Right Hand Side. Returns CY/L = 0 Error, S -> A
;	If No Error is reported, E != 0 if processed, E = 0 if variable. If Error reported E is the Error Number.
;	Always returns a value on the stack.
;
; ****************************************************************************************************************

CheckSpecialTerms:
	ld 		@-2(p2) 											; allocate space for result.
	pushp 	p3 													; save P3.

	ld 		(p1) 												; get character
	xri 	':'													; is it the array marker
	jz 		__CST_ArrayOrParenthesis
	xri 	':'!'('												; or the parenthesis (open bracket)
	jz 		__CST_ArrayOrParenthesis

	ldi 	0 													; E = 0 not processed
	xae
__CST_SCLAndExit:
	scl 														; CY/L = 1 no error.
__CST_Exit:
	pullp 	p3 													; restore P3
	csa 														; copy error flag to A.
	xppc 	p3

;
;	:<expr> or (<expr>)
;
__CST_ArrayOrParenthesis:
	ld 		@1(p1) 												; get the type (array or parenthesis) and skip over it
	st 		@-1(p2) 											; push on the stack so we know what type it was for later.
	lpi 	p3,EvaluateExpression-1								; call the expression evaluator recursively.
	xppc 	p3
	ld 		@3(p2) 												; drop the type and result, but they are still physically there.
	csa 														; check for error
	jp 		__CST_Exit 											; if error occurred, then exit 
	ldi 	ERROR_Bracket 										; set E for missing close bracket error.
	xae
	ccl 														; clear carry , this means error.

	ld 		(p1) 												; get terminating character
	xri 	')'													; which should be a close bracket
	jnz 	__CST_Exit 											; if not, exit with a missing close bracket error.
	ld 		@1(p1) 												; skip over the closing bracket.

	ld 		-1(p2) 												; get the operator ( or :
	xae 														; save in E
	ld 		-3(p2) 												; move value to correct position.
	st 		2(p2)
	ld 		-2(p2)
	st 		3(p2)
	lde 														; get E
	xri 	'(' 												; is it parenthesised expression
	jz 		__CST_SCLAndExit 									; if so, exit with E != 0 and CY/L = 1

wait4:
	jmp 	wait4
