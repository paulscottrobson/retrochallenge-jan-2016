; ****************************************************************************************************************
; ****************************************************************************************************************
;
;										Special Term Evaluation
;	
; ****************************************************************************************************************
; ****************************************************************************************************************

; ****************************************************************************************************************
; ****************************************************************************************************************
;
;			Handle Special Non-Standard Terms. Standard terms are numeric constants and variables. 
;
;	Non standard terms are more complex than simple variable access or have side effects.
;
;	Accept pointer to term 2nd char in P1, first char in A.  Returns CY/L = 0 if processed, CY/L = 1 if ignored.
;
;										if processed correctly, value is on stack and E = 0.
;										if error occurred when processing, E != 0, no value on stack.
;	Non re-entrant:
;
;	Supported Terms are (at present) :
;
;		$ 			Read a single keystroke from keyboard, return ASCII value		(Not implemented)
;		?			Read a string from the keyboard, evaluate as expression			(Not implemented)
;		:<exp>)		Array access.													(Not implemented)
;		(<exp>)		Parenthesised expression.										(Not implemented)
;
; ****************************************************************************************************************
; ****************************************************************************************************************

SpecialTermEvaluate:
	st 		@-2(p2) 											; save A allocating space for result.
	pushp 	p3													; save P3
	ld 		2(p2) 												; get original A
	xri 	'$'													; check for $ (get a key stroke.)
	jnz 	__STE_NotKeyStroke

; ****************************************************************************************************************
;										$ Read Character from keyboard
; ****************************************************************************************************************
	lpi 	p3,GetChar-1 										; read a keystroke.
	xppc 	p3 													; call it
	st 		2(p2) 												; save result in LSB
	ldi 	0
	st 		3(p2) 												; save zero in MSB
	xae 														; E = 0
	ccl 														; CY/L = 1 => processed
	jmp 	__STEExit

__STE_NotKeyStroke:
	xri 	'$'!'?'												; check for ? (read an expression)
	jnz 	__STENotExpression

; ****************************************************************************************************************
;										? Read Expression from Keyboard
; ****************************************************************************************************************

	lpi 	p3,GetString-1 										; read a string
	lpi 	p1,KeyboardBuffer 									; into keyboard buffer
	ldi 	KeyboardBufferSize 									; max length.
	xppc 	p3
	lpi 	p3,EvaluateExpression-1 							; evaluate it
	xppc 	p3
	ld 		@1(p2)												; copy result
	st 		3(p2)
	ld 		@1(p2)
	st 		3(p2)
	ldi 	0 													; and exit ignoring errors.
	xae 	
	ccl 	
	jmp 	__STEExit

__STENotExpression:
	xri 	'?'!':'												; check if it is array or parenthesis
	jz 		__STEArrayOrBracket
	xri 	':'!'('
	jz 		__STEArrayOrBracket

__STEIgnore:
	scl 														; A = 0, CY/L = 1 => last option.
__STEExit:
	pullp 	p3
	csa 														; if CY/L = 0,
	jp 		__STEWasProcessed 									; then maybe keep result
__STEThrow:
	ld 		@2(p2) 												; remove result off stack.
	xppc 	p3

__STEWasProcessed:
	lde 														; if E != 0, throw result.
	jnz 	__STEThrow
	xppc 	p3 													; return with result still on stack.

__STEArrayOrBracket
wait5:
	jmp 	wait5
	