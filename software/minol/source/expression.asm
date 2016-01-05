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
	csa 														; put CY/L in A bit 7
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
	xri 	'+'
	jnz 	EEX_NotAdd

; ****************************************************************************************************************
;												Add Right Term to Value
; ****************************************************************************************************************
	ccl
	ld 		EEX_Value(p2)										; get value
	ade 														; add right
	jmp 	EEX_SaveAndExit 									; save and exit

EEX_NotAdd:
	xri 	'+'!'-'
	jnz		EEX_NotSubtract

; ****************************************************************************************************************
;											 Subtract Right Term from Value
; ****************************************************************************************************************
	scl
	ld 		EEX_Value(p2)										; get value
	cae 														; subtract right
EEX_SaveAndExit:
	st 		EEX_Value(p2) 										; save value back
	jmp 	EEX_CheckNextOperation 								; and exit, look for next operator.

EEX_Divide_Zero:												; handle divide by zero error.
	ldi 	ERRC_DivZero
	jmp 	EEX_Error

EEX_EndExpression:
	ld 		EEX_Value(p2) 										; get current value
	xae 														; put in E
	scl 														; set CY/L indicating expression okay.
	jmp 	EEX_Exit 											; and exit.

EEX_NotSubtract:
	xri 	'-'!'*'
	jnz 	EEX_Divide

; ****************************************************************************************************************
;											 Multiply Right Term into Value
; ****************************************************************************************************************

	ld 		EEX_Value(p2) 										; a = left value
	st 		1(p2)
	ldi 	0													; res = 0(p2)
	st 		0(p2) 												; clear it.
EEX_MultiplyLoop:
	lde  														; if B == 0 then we are done.
	jz 		EEX_CheckNextOperation
	ani 	1 													; if B LSB is non zero.
	jz 		EEX_Multiply_B0IsZero
	ld 		0(p2) 												; add A to Result
	ccl
	add 	1(p2)
	st 		0(p2)
EEX_Multiply_B0IsZero:
	lde 														; shift B right
	sr
	xae
	ld 		1(p2) 												; shift A left
	ccl
	add 	1(p2)
	st 		1(p2)
	jmp 	EEX_MultiplyLoop

; ****************************************************************************************************************
;											Check next operation
; ****************************************************************************************************************

EEX_CheckNextOperation:
	ld 		@1(p1)												; skip over spaces
	xri 	' '
	jz 		EEX_CheckNextOperation
	ld 		@-1(p1)												; get operator
	xri 	'+'													; check if + - * /
	jz 		EEX_FoundOperator
	xri 	'+'!'-'
	jz 		EEX_FoundOperator
	xri 	'-'!'*'
	jz 		EEX_FoundOperator
	xri 	'*'!'/'
	jnz 	EEX_EndExpression

EEX_FoundOperator:
	ld  	@1(p1) 												; get and skip operator
	st 		EEX_PendingOp(p2)									; save then pending operator
	lpi 	p3,EEX_Term-1
	xppc 	p3

; ****************************************************************************************************************
;											 Divide Right Term into Value
; ****************************************************************************************************************

EEX_Divide:
	lde 														; if denominator zero, error 2.
	jz 		EEX_Divide_Zero
	ld 		0(p2) 												; numerator into 1(p2)
	st 		1(p2) 												; denominator is in E
	ldi 	0
	st 		0(p2)												; quotient in 0(p2)
	st 		-1(p2) 												; remainder in -1(p2)
	ldi 	0x80 									
	st 		-2(p2) 												; bit in -2(p2)

EEX_Divide_Loop:
	ld 		-2(p2) 												; exit if bit = 0,we've finished.
	jz 		EEX_CheckNextOperation

	ccl 	 													; shift remainder left.
	ld 		-1(p2)
	add 	-1(p2)
	st 		-1(p2)

	ld 		1(p2)												; get numerator.
	jp 		EEX_Divide_Numerator_Positive
	ild 	-1(p2)  											; if numerator -ve, increment remainder.
EEX_Divide_Numerator_Positive:

	ld 		-1(p2) 												; calculate remainder - denominator
	scl
	cae 
	st 		-3(p2) 												; save in temp -3(p2)
	csa 														; if temp >= 0, CY/L is set
	jp 		EEX_Divide_Temp_Positive

	ld 		-3(p2) 												; copy temp to remainder
	st 		-1(p2)
	ld 		-2(p2) 												; or bit into quotient
	or 		0(p2)
	st 		0(p2)
EEX_Divide_Temp_Positive:
	ld 		-2(p2) 												; shift bit right
	sr
	st 		-2(p2)

	ld 		1(p2)												; shift numerator positive
	ccl
	add 	1(p2)
	st 		1(p2)
	jmp 	EEX_Divide_Loop

EvaluateAddressPair:
	ldi 	0xFF
	xae
	ccl
	xppc 	p3
