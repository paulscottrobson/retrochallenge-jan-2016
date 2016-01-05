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
; ****************************************************************************************************************
;
;	This function does special terms for the Right Hand Side. Returns CY/L = 0 Error, S -> A
;	If No Error is reported, E != 0 if processed, E = 0 if variable. If Error reported E is the Error Number.
;	Always returns a value on the stack.
;
; ****************************************************************************************************************
; ****************************************************************************************************************

CheckSpecialTerms:
	ldi 	0
	st 		@-1(p2) 											; allocate space for result and clear it
	st 		@-1(p2)
	pushp 	p3 													; save P3.

	ld 		@1(p1) 												; get character and skip over it
	xri 	'$'													; is it character in ?
	jnz 	__CST_NotCharacter

; ****************************************************************************************************************
;												$ Get Keystroke
; ****************************************************************************************************************

	lpi 	p3,GetChar-1 										; get character subroutine
	xppc 	p3 													; call it
	st 		2(p2) 												; save in return slot
__CST_ReturnDone:
	ldi 	1 													; set E to nonzero
	xae
	jmp 	__CST_SCLAndExit 									; set carry and exit.
;
__CST_NotCharacter:
	xri 	'?'!'$'												; is it expression in ?
	jnz 	__CST_NotInput 

; ****************************************************************************************************************
;											? Get Line and evaluate it.
; ****************************************************************************************************************

	pushp 	p1 													; save P1
	lpi 	p3,GetString-1 										; read string from keyboard
	lpi 	p1,KeyboardBuffer 								
	ldi 	KeyboardBufferSize 
	xppc 	p3 
	lpi 	p3,EvaluateExpression-1 							; evaluate this
	xppc 	p3
	jp 		__CST_EvaluateCont 									; if error, don't copy result.
	ld 		0(p2) 												; copy result
	st 		6(p2)
	ld 		1(p2)
	st 		7(p2)
__CST_EvaluateCont:
	ld 		@2(p2) 												; drop the return result.
	pullp 	p1 													; restore P1
	jmp 	__CST_ReturnDone									; exit successfully.
;
;	Check for : or (
;
__CST_NotInput:
	xri 	':'!'?'												; is it the array marker
	jz 		__CST_ArrayOrParenthesis
	xri 	':'!'('												; or the parenthesis (open bracket)
	jz 		__CST_ArrayOrParenthesis
	ld 		@-1(p1) 											; undo the bump.
	ldi 	0 													; E = 0 not processed
	xae
__CST_SCLAndExit:
	scl 														; CY/L = 1 no error.
__CST_Exit:
	pullp 	p3 													; restore P3
	csa 														; copy error flag to A.
	xppc 	p3

; ****************************************************************************************************************
;	:<expr> or (<expr>) - both evaluate and check the parenthesis value, then array does the array access
; ****************************************************************************************************************

__CST_ArrayOrParenthesis:
	ld 		-1(p1) 												; get the type (array or parenthesis)
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

; ****************************************************************************************************************
;	Now we know we had :<expr>) - so calculate & + <expr> * 2 and read what is there.
; ****************************************************************************************************************

	ccl 	
	ld 		2(p2) 												; double the offset
	add 	2(p2)
	st 		2(p2)
	ld 		3(p2)
	add 	3(p2)
	st 		3(p2)

	lpi 	p3,Variables+('&' & 0x3F) * 2 						; point P3 to '&'
	ccl
	ld 		2(p2) 												; add &.Low to offset.low -> E
	add 	0(p3)
	xae
	ld 		3(p2) 												; add &.High to offset.high -> P3.H
	add 	1(p3)
	xpah 	p3
	lde 														; E->P3.L ; P3 is now & + (offset * 2)
	xpal 	p3
	ld 		0(p3) 												; access array, store in return 
	st 		2(p2)
	ld 		1(p3)
	st 		3(p2)
	ldi 	0xFF 												; set E to non-zero and exit.
	xae
	jmp 	__CST_SCLAndExit
