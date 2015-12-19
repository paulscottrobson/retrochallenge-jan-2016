; ****************************************************************************************************************
; ****************************************************************************************************************
;
;	  Evaluate expression at P1. On exit either CY/L = 0, E = Error code, or CY/L = 1, E = Result ; A = S
;
;	Re-entrant
;	
; ****************************************************************************************************************
; ****************************************************************************************************************

; TODO: Write testing code in Python.
; TODO: Write (H,L)
; TODO: Expand Python Test to test (H,L)

TestExpr:
	db 	"(1,2)",0

EvaluateExpression:
	pushp 	p3 													; save P3 on stack
	ldi 	0 													; push 0 onto stack (current value) will be restored
	st 		@-1(p2) 											; to E on exit.
	ldi 	'+' 												; push pending operation onto stack - this means we
	st 		@-1(p2) 											; have 'faked' a 0+ to start the expression.

; ****************************************************************************************************************
;													Get a new term 
; ****************************************************************************************************************

__EE_NextTerm:
__EE_SkipSpace:
	ld 		(p1) 												; check end of string
	jz 		__EE_TermError
	ld 		@1(p1) 												; fetch and skip
	xri 	' ' 												; if space, keep going.
	jz 		__EE_SkipSpace

	ld 		@-1(p1) 											; backtrack and reload
	ccl
	adi 	255-'Z'												; will be +ve if >= 'Z'
	jp 		__EE_TermError 										; which is an error ($,!,',0-9,A-Z)
	adi 	26 													; will be +ve if >= 'A'
	jp 		__EE_IsVariable 									; will contain 0-25, conveniently the offset.
	adi 	7
	jp 		__EE_TermError 										; will be +ve if between 9 and A, error.
	adi 	10 				
	ani 	0x80
	jnz 	__EE_CheckPuncTerms 								; if -ve check for punctuation terms (! and 'x')

; ****************************************************************************************************************
;										Constant term. P1 points to first digit
; ****************************************************************************************************************

	xae 														; zero E, the result.
__EE_ConstantTerm:
	ccl
	lde
	ade 														; x 2
	ade															; x 3
	ade															; x 4
	ade															; x 5
	xae 														; put x 5 in E
	lde 														; double it
	ade
	xae 														; back in E
	ld 		@1(p1) 												; read digit, known okay, and bump
	ani 	0x0F 												; convert to decimal value
	ade 														; add to E 	
	xae 														; put back in E
	ld 		(p1) 												; get next.
	ccl
	adi 	255-'9'												; check out of range
	jp 		__EE_ConstantEnd
	adi 	10
	jp 		__EE_ConstantTerm
__EE_ConstantEnd:
	jmp 	__EE_HaveTerm 										; term is fetched.

; ****************************************************************************************************************
;							Have a variable, in A, value 0-25 representing A-Z.
; ****************************************************************************************************************

__EE_IsVariable:
	xae 														; variable number 0-25 in E
	lpi 	p3,Variables 										; point P3 to variables.
	ld 		-0x80(p3) 											; read variable into E offset E
	xae
	ld 		@1(p1)												; skip over variable.
	jmp 	__EE_HaveTerm

__EvaluateExpression2:
	jmp 	EvaluateExpression

; ****************************************************************************************************************
;			Check for punctuation terms, random number ! and character constant 'x' and $(H,L)
; ****************************************************************************************************************

__EE_CheckPuncTerms:
	ld 		@1(p1) 												; check for (
	xri 	'('
	jz 		__EE_MemoryRead
	xri 	'!'!'(' 											; check for random (!)
	jz 		__EE_Random
	xri 	'!'!0x27 											; check for 'x'
	jnz 	__EE_TermError
;
;	'<char>' constant
;
	ld 		(p1) 												; check second is not EOL
	jz 		__EE_TermError
	ld 		1(p1)
	xri 	0x27 												; check third is quote mark.
	jnz 	__EE_TermError
	ld 		@2(p1) 												; skip over character and quote
	ld 		-2(p1) 												; read character into E
	xae
	jmp 	__EE_HaveTerm 										; have a legitimate term.
;
;	! random number
;
__EE_Random:
	lpi 	p3,Random-1 
	jmp 	__EE_CallAndCheck
;
;	(H,L) read memory.
;
__EE_MemoryRead:
	ld 		@-1(p1) 											; point back to the first bracket
	lpi 	p3,EvaluateHL-1 									; evaluate (H,L) and read it.
__EE_CallAndCheck:
	xppc 	p3 													; call routine
	jp 		__EE_TermError 										; if CY/L = 0, error
	jmp 	__EE_HaveTerm 										; otherwise fine.

; ****************************************************************************************************************
;												TERM Error here.
; ****************************************************************************************************************
	
__EE_TermError:
	ldi 	ERROR_Term 											; put error-term in E
__EE_ErrorA:
	ccl 														; clear carry flag => error
	xae 														; value in E
	ld 		@2(p2) 												; drop pending operation and result
__EE_Exit:
	pullp 	p3 													; restore P3
	csa 														; S->A
	xppc 	p3 													; and exit.
	jmp 	__EvaluateExpression2

; ****************************************************************************************************************
;										 Have a new legitimate term in E
; ****************************************************************************************************************

__EE_HaveTerm:
	ld 		0(p2) 												; read pending value
	xri 	'+'
	jnz 	__EE_NotAdd

; ****************************************************************************************************************
;													  Add
; ****************************************************************************************************************

	ccl 														; add
	ld 		1(p2)
	ade
	st 		1(p2)
	jmp 	__EE_NextOperation

__EE_NotAdd:
	xri 	'+'!'-'
	jnz 	__EE_NotSubtract

; ****************************************************************************************************************
;	 											    Subtract
; ****************************************************************************************************************

	scl 														; subtract
	ld 		1(p2)
	cae 
	st 		1(p2)
	jmp 	__EE_NextOperation

__EE_Divide_Zero
	ldi 	ERROR_DivideZero
	jmp 	__EE_ErrorA

__EE_NotSubtract:	
	xri 	'-'!'*'
	jnz 	__EE_NotMultiply

; ****************************************************************************************************************
;													 Multiply
; ****************************************************************************************************************

	ld 		1(p2) 												; a = 0(p2)
	st 		0(p2)
	ldi 	0													; res = 1(p2)
	st 		1(p2) 												; clear it.
__EE_MultiplyLoop:
	lde  														; if B == 0 then we are done.
	jz 		__EE_NextOperation
	ani 	1 													; if B LSB is non zero.
	jz 		__EE_Multiply_B0IsZero
	ld 		0(p2) 												; add A to Result
	ccl
	add 	1(p2)
	st 		1(p2)
__EE_Multiply_B0IsZero:
	lde 														; shift B right
	sr
	xae
	ld 		0(p2) 												; shift A left
	ccl
	add 	0(p2)
	st 		0(p2)
	jmp 	__EE_MultiplyLoop

; ****************************************************************************************************************
;	     Come here when arithmetic finished, looking for the next operator, + - * / keep going else exit
; ****************************************************************************************************************

__EE_NextOperation:
	ld 		(p1) 												; get next character
	jz 		__EE_ExitOkay										; exit if EOS.
	ld 		@1(p1) 												; get and bump
	xri 	' ' 												; skip over space 
	jz 		__EE_NextOperation
	xri 	'+'!' ' 											; continue if +,-,*,/ found
	jz 		__EE_FoundOperator
	xri 	'+'!'-'
	jz 		__EE_FoundOperator
	xri 	'-'!'*'
	jz 		__EE_FoundOperator
	xri 	'*'!'/'
	jz 		__EE_FoundOperator
	ld 		@-1(p1) 											; undo the get so points to next char

__EE_ExitOkay:
	ld 		@1(p2) 												; drop pending operation
	ld 		@1(p2) 												; get result
	xae 														; put in E
	scl 														; set carry link
	jmp 	__EE_Exit

__EE_FoundOperator:
	ld 		-1(p1) 												; get the operator
	st 		0(p2)												; save in pending operator
	lpi 	p3,__EE_NextTerm-1									; long jump back to near the start.
	xppc 	p3	

; ****************************************************************************************************************
;													Divide
; ****************************************************************************************************************

__EE_NotMultiply:												; must be divide, as only + - * / allowed.
	lde 														; if denominator zero, error 2.
	jz 		__EE_Divide_Zero
	ld 		1(p2) 												; numerator into 0(p2)
	st 		0(p2) 												; denominator is in E
	ldi 	0
	st 		1(p2)												; quotient in 1(p2)
	st 		-1(p2) 												; remainder in -1(p2)
	ldi 	0x80 									
	st 		-2(p2) 												; bit in -2(p2)

__EE_Divide_Loop:
	ld 		-2(p2) 												; exit if bit = 0,we've finished.
	jz 		__EE_NextOperation

	ccl 	 													; shift remainder left.
	ld 		-1(p2)
	add 	-1(p2)
	st 		-1(p2)

	ld 		0(p2)												; get numerator.
	jp 		__EE_Divide_Numerator_Positive
	ild 	-1(p2)  											; if numerator -ve, increment remainder.
__EE_Divide_Numerator_Positive:

	ld 		-1(p2) 												; calculate remainder - denominator
	scl
	cae 
	st 		-3(p2) 												; save in temp -3(p2)
	csa 														; if temp >= 0, CY/L is set
	jp 		__EE_Divide_Temp_Positive

	ld 		-3(p2) 												; copy temp to remainder
	st 		-1(p2)
	ld 		-2(p2) 												; or bit into quotient
	or 		1(p2)
	st 		1(p2)
__EE_Divide_Temp_Positive:
	ld 		-2(p2) 												; shift bit right
	sr
	st 		-2(p2)

	ld 		0(p2)												; shift numerator positive
	ccl
	add 	0(p2)
	st 		0(p2)
	jmp 	__EE_Divide_Loop

; ****************************************************************************************************************
;					Get a random number from the seed, return in E, CY/L = 1 okay S=>A
; ****************************************************************************************************************

Random:
	pushp	p3
	lpi 	p3,RandomSeed 										; point P3 to random seed.
	ld 		0(p3)												; does it need initialising.
	or 		1(p3)
	jnz 	__RA_NoInitialise
	ldi 	0xE1 												; set to $E1AC
	st 		1(p3)
	ldi 	0xAC
	st 		0(p3)
__RA_NoInitialise:
	ccl 														; shift seed right
	ld 		1(p3)
	rrl
	st 		1(p3)
	ld 		0(p3)
	rrl
	st 		0(p3)
	csa 														; get status
	jp 		__RA_Exit
	ld 		1(p3)
	xri 	0xB4
	st 		1(p3)
__RA_Exit:
	ld 		0(p3) 												; get the number
	add 	1(p3)
	xae
	pullp 	p3 													; restore P3
	scl															; no error
	csa
	xppc	p3

; ****************************************************************************************************************
; ****************************************************************************************************************

; evaluate $(HL) leave address accessible, return same as expr
EvaluateHL:
	ldi 	0x74
	xae
	ldi 	0x80
	xppc 	p3

