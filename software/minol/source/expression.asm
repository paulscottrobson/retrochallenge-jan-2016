; ****************************************************************************************************************
; ****************************************************************************************************************
;
;												Expression Evaluation
;
; ****************************************************************************************************************
; ****************************************************************************************************************


; ****************************************************************************************************************
; ****************************************************************************************************************
;
;		Evaluate expression at P1. Return 	CY/L = 0 : Error 	E = Error Code
;											CY/L = 1 : Okay 	E = Result
;
;		Terms are : 	A-Z 			Variables
;						[0-9]+			Constants
;						! 				Random byte
;						'?'				Character constant
;						(<expr>,<expr>)	Read Memory location
;
; ****************************************************************************************************************
; ****************************************************************************************************************

EEX_PendingOp = 1 												; offset to pending operation
EEX_Value = 0 													; offset to value

EvaluateExpression:
	pushp 	p3 													; save P3 on stack
	ldi 	'+'													; push pending operation on stack
	st 		@-1(p2)
	ldi 	0 													; push current value on stack
	st 		@-1(p2)												; effectively this puts 0+ on the front of the expression.

; ****************************************************************************************************************
;													Get Next Term
; ****************************************************************************************************************

EEX_Term:
	lpi 	p3,Variables 										; point P3 to variables
EEX_NextChar:
	ld 		(p1) 												; look at character
	jz 		EEX_TermError
	ld 		@1(p1) 												; fetch and skip over.
	xri 	' '													; is it space ?
	jz 		EEX_NextChar
	xri 	' '!'('												; is it memory access ?
	jz 		EEX_MemoryAccess
	xri 	'('!'!'												; is it a random value ?
	jnz 	EEX_NotRandom

; ****************************************************************************************************************
;												Term is ! (random byte)
; ****************************************************************************************************************

EEX_Random:
	ccl 	
	ld 		RandomSeed+1-Variables(p3) 							; shift the seed right
	rrl
	st 		RandomSeed+1-Variables(p3)
	xae 														; put MSB in E
	ld 		RandomSeed-Variables(p3)
	rrl
	st 		RandomSeed-Variables(p3)
	xre 														; XOR E into LSB
	xae
	csa 														; if CY/L is zero
	ani 	0x80
	jnz 	EEX_NoTap 
	ld 		RandomSeed+1-Variables(p3) 							; XOR MSB with $B4
	xri 	0xB4
	st 		RandomSeed+1-Variables(p3)
EEX_NoTap:
	jmp 	EEX_HaveTerm

EEX_NotRandom:
	xri 	'!'!0x27											; is it a quote ?
	jnz 	EEX_NotQuote

; ****************************************************************************************************************
;													Term is '<char>'
; ****************************************************************************************************************

	ld 		(p1) 												; get character that is quoted
	jz 		EEX_TermError 										; if zero, error.
	xae 														; save in E if okay character.
	ld 		1(p1) 												; get character after that
	xri 	0x27 												; is it a quote ?
	jnz 	EEX_TermError
	ld 		@2(p1) 												; skip over character and quote
	jmp 	EEX_HaveTerm 										; and execute as if a legal term

; ****************************************************************************************************************
;									Not 'x' or !, so test for 0-9 and A-Z
; ****************************************************************************************************************

EEX_NotQuote:
	ld 		-1(p1)												; get old character.
	ccl
	adi 	255-'Z'												; if >= 'Z' then error.										
	jp 		EEX_TermError
	adi 	26 													; will be 0..25 if A..Z
	jp 		EEX_Variable 										; so do as a variable.
	adi 	'A'-1-'9'											; check if > 9
	jp 		EEX_TermError
	adi 	10 													; if 0-9
	jp 		EEX_Constant

; ****************************************************************************************************************
;													 Error Exit.
; ****************************************************************************************************************

EEX_TermError:
	ldi 	ERRC_Term 											; put term error in A
EEX_Error:
	xae 														; put error code in E
	ccl 														; clear CY/L indicating error
EEX_Exit:
	ld 		@2(p2) 												; throw the pending operation and value
	pullp 	p3 													; restore P3
	xppc 	p3 													; and exit
	jmp 	EvaluateExpression 									; make re-entrant

; ****************************************************************************************************************
;										Handle (<expr>,<expr>)
; ****************************************************************************************************************

EEX_MemoryAccess:
	ld 		@-1(p1) 											; point to the (
	lpi 	p3,EvaluateAddressPair-1 							; call the evaluate/read of (h,l)
	xppc 	p3
	jp 		EEX_Exit 											; error occurred, so exit with it.
	jmp 	EEX_HaveTerm

; ****************************************************************************************************************
;								Handle constant, first digit value is in A
; ****************************************************************************************************************

EEX_Constant:
	xae 														; put first digit value in E
EEX_ConstantLoop:
	ld 		(p1) 												; get next character.
	ccl
	adi 	255-'9' 											; if >= 9 term is too large.
	jp 		EEX_HaveTerm
	adi 	10+128
	jp 		EEX_HaveTerm
	ccl
	lde 														; A = n
	ade 														; A = n * 2
	ade 														; A = n * 3
	ade 														; A = n * 4
	ade 														; A = n * 5
	xae 														; E = n * 5
	lde 														; A = n * 5
	ade 														; A = n * 10
	xae
	ld 		@1(p1) 												; read character convert to number
	ani 	0x0F
	ade
	xae
	jmp 	EEX_ConstantLoop


; ****************************************************************************************************************
;									Access variable, variable id (0-25) in A
; ****************************************************************************************************************

EEX_Variable:
	xae 														; put value 0-25 in E
	ld 		-0x80(p3) 											; load using E as index
	xae 														; put in E

; ****************************************************************************************************************
;										Have the right term in E, process it
; ****************************************************************************************************************

EEX_HaveTerm:
	ld 		EEX_PendingOp(p2) 									; get pending operation.
	jmp 	EEX_HaveTerm





EvaluateAddressPair:
	ldi 	0xFF
	xae
	ccl
	xppc 	p3
