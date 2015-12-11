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
	scl 														; A = 0, CY/L = 1 => last option.
	xppc 	p3