; ****************************************************************************************************************
; ****************************************************************************************************************
;
;											Expression, MINOL
;											=================
;
;	Terms are :
;		0-9* 		Numeric constant
;		A-Z 		Variables
;		'c'			Character ASCII value
;		(h,l) 		Memory direct access
;		! 			Random number
;
;	Operators are:	+,-,*,/
;
; ****************************************************************************************************************
; ****************************************************************************************************************

; ****************************************************************************************************************
; ****************************************************************************************************************
;
;				Evaluate an expression at P1. Returns A = Result, CY/L = 1 or A = Error, CY/L = 0
;
;	Preserves registers except A and P1, which is advanced to the end of the expression - on exit it points to
;	NULL or the next character - so 2+3, will return A = 5, CY/L = 1,P1 pointing to the comma.
;
;	This isn't re-entrant.
;
; ****************************************************************************************************************
; ****************************************************************************************************************

EvaluateExpression:

__EEValue = 0 													; stack positions of current value & pending
__EEOperator = 1 												; operator.
__EERandomOffset = 26 											; offset to random seed from p3

ERROR_BadTerm = 4
ERROR_Syntax = 5
ERROR_DivZero = 7

	lde 														; save E on stack
	st 		@-1(p2)
	xpah 	p3 													; save P3 on stack
	st 		@-1(p2)
	xpal 	p3
	st 		@-1(p2)
	ldi 	'+'													; pending expression (+) at +1(p2)
	st 		@-1(p2)												; set up so done "0+" in theory :)
	ldi 	0 													; current value (0) at +0(p2)
	st 		@-1(p2)
	jmp 	__EELoop

; ****************************************************************************************************************
;											'c' term (character constant)
; ****************************************************************************************************************

__EECharacter:
	ld 		(p1) 												; read character following quote
	jz 		__EECharacterError 									; if EOS fail
	xae 														; save in E
	ld 		1(p1) 												; read the one after that
	xri 	0x27												; check if closing quote
	jnz 	__EECharacterError 									; should be a quote mark, fail if not.
	ld 		@2(p1) 												; skip over 2 characters
	jmp 	__EECalculate4 										; go and complete the calculation

__EECharacterError:
	ldi 	ERROR_BadTerm	 									; bad character
	jmp 	__EEError3	

; ****************************************************************************************************************
;											! term (random number)
; ****************************************************************************************************************

__EERandom:
	ld 		__EERandomOffset(p3) 								; does it need initialising
	or 		__EERandomOffset+1(p3)
	jnz		__EERandom_IsInitialised
	ldi 	0xE1												; if so, set to $ACE1
	st 		__EERandomOffset(p3)
	ldi 	0xAC
	st 		__EERandomOffset+1(p3)
__EERandom_IsInitialised:
	ld 		__EERandomOffset+1(p3) 								; shift seed right into carry
	ccl
	rrl
	st 		__EERandomOffset+1(p3)
	ld 		__EERandomOffset(p3)
	rrl
	st 		__EERandomOffset(p3)
	csa  														; if the LSB was 1
	jp 		__EERandomNoToggle
	ld 		__EERandomOffset+1(p3)
	xri 	0xB4
	st 		__EERandomOffset+1(p3)
__EERandomNoToggle:
	ld 		__EERandomOffset(p3) 								; XOR two values together into E.
	xor 	__EERandomOffset+1(p3)
	xae
__EECalculate4:
	jmp 	__EECalculate3

; ****************************************************************************************************************
;												  Read data (h,l)
; ****************************************************************************************************************

__EEDataAccess:
	lpi 	p3,ReadHLMemory-1 									; read HL memory into A
	xppc 	p3
	xae 														; save in E
	csa 														; if carry is set then calculate as normal.
	ani 	0x80
	jnz 	__EECalculate3
	lde 														; get error code
__EEError3:
	jmp 	__EEError2

; ****************************************************************************************************************
;
;											Main loop - get another term.
;
; ****************************************************************************************************************
__EELoop:
	lpi 	p3,Variables 										; point P3 to variables

	ld 		(p1) 												; check end of string.
	jz 		__EEBadTerm 				
	ld 		@1(p1) 												; get next character till non-space
	xri		' '
	jz 		__EELoop

	xri 	' ' ! '('											; if ( then (x,y) memory access.
	jz 		__EEDataAccess
	xri 	'(' ! '!' 											; if ! then random number.
	jz 		__EERandom
	xri 	'!' ! 0x27											; if ' then character constant
	jz 		__EECharacter

	ld 		-1(p1) 												; get character.
	ccl
	adi 	128-'0' 											; if < '0' then there is an error.
	jp 		__EEBadTerm
	adi 	0xFF-0x89 											; if > '9' then it is not a digit.
	jp 		__EENotDigit 										; so check for A-Z

; ****************************************************************************************************************
;
;								We have a constant value 0-255, extract it
;
; ****************************************************************************************************************

	ld 		-1(p1) 												; re-read digit
	ani 	0x0F 												; make number
	xae 														; put in E.
__EEConstantLoop:
	ld 		(p1) 												; keep going until non digit found
	ccl
	adi 	128-'0'												; exit if outside range 0-9.
	jp 		__EECalculate 										; calculate the result.
	adi 	0xFF-0x89 
	jp 		__EECalculate 
	lde 														; A = E
	ccl
	ade 														; A = E * 2
	ade 														; A = E * 3
	ade 														; A = E * 4
	ade 														; A = E * 5
	xae 														; E = E * 5
	ld 		@1(p1) 												; read digit and bump pointer.
	ani 	0x0F 												; make number
	ade 														; add E * 5 twice, e.g. E * 10
	ade
	xae 														; put into E
	jmp 	__EEConstantLoop

__EEError2:
	jmp 	__EEError
__EELoop2:
	jmp 	__EELoop

; ****************************************************************************************************************
;
;												Check for variable A-Z.
;
; ****************************************************************************************************************
__EENotDigit:
	ld 		-1(p1) 												; read character again.
	ccl
	adi 	128-'A' 											; check in range A-Z.
	jp 		__EEBadTerm 										; if not in that range, we failed.
	adi 	0x80-26 
	jp 		__EEBadTerm 
	adi 	26 													; make it 0-25 (A-Z)
	xae 														; E is variable number 0-25
	ld 		-0x80(p3) 											; read variable value.
	xae 														; put in E
__EECalculate3:
	jmp 	__EECalculate 										; calculate result of delayed operation.
;
;	Bump over spaces to find operator.
;
__EEGetNextOperator:
	scl 														; set Carry/Link indicating okay.
	ld 		0(p1) 												; skip spaces, checking for exit.
	jz 		__EEExit 											; exit on NULL.
	xri 	' ' 												
	jnz 	__EECheckOperator
	ld 		@1(p1)
	jmp 	__EEGetNextOperator
;
;	Found something not NULL or space - see if it is an operator + - * /, in which case go round again.
;
__EECheckOperator:
	ld 		(p1) 												; get operator
	xri 	'+' 												; check if it is +,-,*,/
	jz 		__EEDoOperator
	xri 	'+'!'-'
	jz 		__EEDoOperator
	xri 	'-'!'*'
	jz 		__EEDoOperator
	xri 	'*'!'/'
	jnz 	__EEExit 											; if not any of those, then exit.
__EEDoOperator:
	ld 		@1(p1) 												; get and save operator
	st 		1(p2)
	jmp		__EELoop2 											; go get another term. 			
;
;	Handle Errors (1) Bad Term (2) Divide by zero.
;
__EEBadTerm:
	ldi 	ERROR_BadTerm 										; syntax in expression
__EEError:
	st 		__EEValue(p2) 										; error code as result.
	ccl 														; CY/L clear indicating error
;
;	Exit with the value in __EEValue(p2) and CY/L set accordingly.
;
__EEExit:
	ld 		@2(p2) 												; skip over saved values
	ld 		@1(p2) 												; restore P3
	xpal 	p3
	ld 		@1(p2)
	xpah 	p3
	ld 		@1(p2) 												; restore E
	xae 
	ld 		-5(p2)												; get answer into A
	xppc 	p3 													; and exit.

__EE_Divide_Zero:
	ldi 	ERROR_DivZero 										; come here for divide by zero.	
	jmp 	__EEError

; ****************************************************************************************************************
;
;							Do 0(p2) op E where op is 1(p2) and is a valid operator.
;	
; ****************************************************************************************************************

__EECalculate:
	ld 		__EEOperator(p2) 									; get the operator.
	xri 	'-'
	jz 		__EE_Subtract
	xri 	'-'!'*'
	jz 		__EE_Multiply
	xri 	'*'!'/'
	jz 		__EE_Divide

; ****************************************************************************************************************
;														  Add.
; ****************************************************************************************************************

__EE_Add:
	ccl
	ld 		__EEValue(p2)
	ade
	st 		__EEValue(p2)
	jmp 	__EEGetNextOperator

; ****************************************************************************************************************
;														Subtract
; ****************************************************************************************************************

__EE_Subtract:
	scl
	ld 		__EEValue(p2)
	cae
	st 		__EEValue(p2)
__EEGetNextOperator2:
	jmp 	__EEGetNextOperator

; ****************************************************************************************************************
;														Multiply
; ****************************************************************************************************************

__EE_Multiply:										
	ld 		__EEValue(p2) 													; a = __EEOperator(p2)
	st 		__EEOperator(p2)
	ldi 	0																; res = __EEValue(p2)
	st 		__EEValue(p2) 													; clear it.
__EE_MultiplyLoop:
	lde  																	; if B == 0 then we are done.
	jz 		__EEGetNextOperator
	ani 	1 																; if B LSB is non zero.
	jz 		__EE_Multiply_B0IsZero
	ld 		__EEOperator(p2) 												; add A to Result
	ccl
	add 	__EEValue(p2)
	st 		__EEValue(p2)
__EE_Multiply_B0IsZero:
	lde 																	; shift B right
	sr
	xae
	ld 		__EEOperator(p2) 												; shift A left
	ccl
	add 	__EEOperator(p2)
	st 		__EEOperator(p2)
	jmp 	__EE_MultiplyLoop

;	res = 0
;	while (b != 0):
;		if (b & 1) != 0:
;		 	res = (res + a) & 0xFF
;		a = (a << 1) & 0xFF
;		b = (b >> 1) & 0xFF


; ****************************************************************************************************************
;														Divide
; ****************************************************************************************************************

__EE_Divide:
	lde 																	; if denominator zero, error 2.
	jz 		__EE_Divide_Zero
	ld 		__EEValue(p2) 													; numerator into __EEOperator(p2)
	st 		__EEOperator(p2) 												; denominator is in E
	ldi 	0
	st 		__EEValue(p2)													; quotient in __EEValue(p2)
	st 		-1(p2) 															; remainder in -1(p2)
	ldi 	0x80 									
	st 		-2(p2) 															; bit in -2(p2)

__EE_Divide_Loop:
	ld 		-2(p2) 															; exit if bit = 0,we've finished.
	jz 		__EEGetNextOperator2

	ccl 	 																; shift remainder left.
	ld 		-1(p2)
	add 	-1(p2)
	st 		-1(p2)

	ld 		__EEOperator(p2)												; get numerator.
	jp 		__EE_Divide_Numerator_Positive
	ild 	-1(p2)  														; if numerator -ve, increment remainder.
__EE_Divide_Numerator_Positive:

	ld 		-1(p2) 															; calculate remainder - denominator
	scl
	cae 
	st 		-3(p2) 															; save in temp -3(p2)
	csa 																	; if temp >= 0, CY/L is set
	jp 		__EE_Divide_Temp_Positive

	ld 		-3(p2) 															; copy temp to remainder
	st 		-1(p2)
	ld 		-2(p2) 															; or bit into quotient
	or 		__EEValue(p2)
	st 		__EEValue(p2)
__EE_Divide_Temp_Positive:

	ld 		-2(p2) 															; shift bit right
	sr
	st 		-2(p2)

	ld 		__EEOperator(p2)												; shift numerator positive
	ccl
	add 	__EEOperator(p2)
	st 		__EEOperator(p2)
	jmp 	__EE_Divide_Loop

;	quotient = 0			
;	remainder = 0 			
;	bit = 0x80
;
;	while (bit != 0):
;
;		remainder = remainder << 1
;		if numerator & 0x80 != 0:
;			remainder = (remainder + 1) & 0xFF
;		temp = remainder - denominator
;		if temp >= 0:
;			remainder = temp
;			quotient = quotient | bit
;		bit = (bit >> 1) & 0xFF
;		numerator = (numerator << 1) & 0xFF


; ****************************************************************************************************************
; ****************************************************************************************************************
;
;		P1 points to <expr>,<expr>) - parse out the values, read memory location and return in A, 
;		CY/L = 0 => error A. -2(p2) and -1(p2) should contain the address if we need to read it later.
;	
; ****************************************************************************************************************
; ****************************************************************************************************************

ReadHLMemoryFull:
	ld 		@1(p1) 												; look at next character and bump.
	xri 	' '													; skip over the spaces.
	jz 		ReadHLMemoryFull
	xri 	' ' ! '(' 											; if it is '(' then evaluate normally.
	jz 		ReadHLMemory
	ld 		@-1(p1) 											; undo the post increment.
	ccl 														; return with a syntax error.
	ldi 	ERROR_Syntax 
	xppc 	p3 

ReadHLMemory:

RHL_AddrLo = 3
RHL_AddrHi = 4
RHL_Result = -1

	lde 														; save E
	st 		@-3(p2) 											; save leaving room for addr.lo and addr.hi
	xpah 	p3 													; save P3
	st 		@-1(p2)
	xpal 	p3
	st 		@-1(p2)
	ldi 	',' 												; first seperator is a comma.
	xae
__RHLLoop:	
	ld 		RHL_AddrLo(p2) 										; copy addr lo to addr hi
	st 		RHL_AddrHi(p2)
	lpi 	p3,EvaluateExpression-1 							; evaluate the expression.
	xppc 	p3
	st 		RHL_AddrLo(p2) 										; save in addr.lo
	csa  														; if error
	jp 		__RHLError
__RHLSkip:
	ld 		0(p1) 												; check for end of line
	jz 		__RHLSyntax
	ld 		@1(p1) 												; fetch next character
	xri 	' ' 												; skip over spaces.
	jz 		__RHLSkip 
	ld 		-1(p1) 												; get fetched character
	xre 														; is it the one we wanted ?
	jnz 	__RHLSyntax 										; no, so fail.
	lde 														; get character
	xri 	','!')'												; switch from , to )
	xae 														; put back in E.
	lde 														; if it is ')' , go back.
	xri 	')'
	jz 		__RHLLoop 

	ld 		RHL_AddrLo(p2) 										; load address into P3
	xpal 	p3
	ld 		RHL_AddrHi(p2)
	xpah 	p3
	ld 		0(p3) 												; read byte there
	st 		-1(p2) 												; save in return value space.
	scl 														; set CY/L indicating no error
	jmp 	__RHLExit 											; and exit.

__RHLError:
	ld 		RHL_AddrLo(p2) 										; read error code
	jmp 	__RHLSaveErrorAndExit

__RHLSyntax:
	ldi 	ERROR_Syntax 										; syntax error
__RHLSaveErrorAndExit:
	st 		RHL_Result(p2)										; save as error code
	ccl 														; return error

__RHLExit:														; exit with result in RHL_AddrLo.
	ld 		@1(p2) 												; reload P3
	xpal 	p3
	ld 		@1(p2)
	xpah 	p3
	ld 		@3(p2)
	xae
	ld 		-6(p2) 												; get the return value
	xppc 	p3 													; and exit.
