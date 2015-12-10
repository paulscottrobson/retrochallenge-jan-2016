; ****************************************************************************************************************
; ****************************************************************************************************************
;
;										Special Term Evaluation
;	
; ****************************************************************************************************************
; ****************************************************************************************************************

; ****************************************************************************************************************
;
;			Handle Special Non-Standard Terms. Standard terms are numeric constants and variables. 
;
;	Non standard terms are more complex than simple variable access or have side effects.
;
;	Accept pointer to term in P1. Returns value on stack, : with CY/L = 0 and A != 0 	Error has occurred
;																 CY/L = 1 and A != 0 	Successfully processed
;																 CY/L = 1 and A == 0 	Unknown, treat as variable.
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

SpecialTermEvaluate:
	ld 		@-2(p2) 											; make space for 2 byte return value on the stack.
	ldi 	0  													; this dummy code means "I don't know any special terms"	
	scl 														; A = 0, CY/L = 1 => last option.
	xppc 	p3