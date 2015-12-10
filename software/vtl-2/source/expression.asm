; ****************************************************************************************************************
; ****************************************************************************************************************
;
;						Expression Evaluation. Returns CY/L = 0 on Error, A = Error Code
;	
; ****************************************************************************************************************
; ****************************************************************************************************************

; TODO: Write test program using +,-,*,/ and numeric constants, and test that part.
; TODO: Add variable support (not special) and test that
; TODO: Add special terms.

test:db 	"22/7-9",0

operation = 3													; pending operation
resultLo = 5
resultHi = 6

;
;	Come here when the binary operator (+,-,*,/,>,=,<) fails. There are the two values still on the stack
;	so drop one and exit.
;
__EE_TermErrorAndDrop:
	ld 		@2(p2) 												; reduce back to one number on the stack.
;
;	Return with a Term Error.
;
__EE_TermError:
	ccl
	ldi 	'*'
	st 		6(p2) 												; return the term error in A register
__EE_Exit:
	ld 		@1(p2)												; copy result to final target
	st 		6(p2)
	ld 		@1(p2)
	st 		6(p2)
	pullp 	p3													; restore registers
	pulle 	
	pulla 	 													; this is pending operation
	pulla 	
	xppc 	p3

EvaluateExpression:
	st 		@-2(p2)												; 2 byte final result
	pusha 														; save A
	ldi 	'+' 												; save pending operation.
	st 		@-1(p2)
	pushe 														; save E and P3.
	pushp 	p3
	ldi 	0 													; clear current value, push 0 on the stack.
	st 		@-1(p2)
	st		@-1(p2)
;
;	Get a new term to complete pending operation.
;
__EE_NextTerm:
	ld 		(p1) 												; read P1
	jz 		__EE_TermError 										; term not found error.
	ld 		@1(p1)												; fetch and skip over any spaces.
	xri 	' '
	jz 		__EE_NextTerm
;
;	Check if it is a numeric constant
;
	ld 		@-1(p1) 											; re-read first non space character.
	ccl
	adi 	128-'0'												; will be +ve if < '0'
	jp 		__EE_Variable
	adi 	255-0x89 											; will be +ve if > '9'
	jp 		__EE_Variable
;
;	Using the pending operation, the old value, and the new value, do the operation. Choice of either the
;	OS built in routines or a seperate function for < = and >.
;
	lpi 	p3,OSMathLibrary-1 									; use the maths library to convert to an integer
	ldi	 	'?' 												; this is that function.
	xppc 	p3
__EE_RunPendingOperation:										; now two values on the stack that we operate on.
	lpi 	p3,OSMathLibrary-1									; use the library routine.
	ld 		operation+4(p2)										; get the operation
	ani 	0xFC 												; is it 3C-3F which are < = > ?
	xri 	0x3C
	jnz 	__EE_IsLibraryOperator 								; use the library routine which supports those.
	lpi 	p3,ExpressionComparison-1  							; instead.
__EE_IsLibraryOperator:
	ld 		operation+4(p2)										; get the operation
	xppc 	p3 													; execute the operation.
	csa 														; this has Carry Set = Error.
	ani 	0x80
	jnz 	__EE_TermErrorAndDrop 								; so fail on error.
;
;	If we have done division, copy the remainder to the % variable.
;
	ld 		operation+2(p2) 									; re-read the operation just done.
	xri 	'\\'												; is it unsigned integer divide ?
	jz 		__EE_ProcessRemainder 								; if so, then go copy remainder.
;
;	Get the next operator, ending if we find the end of the string or a closing bracket. At the outer parenthesis
;	level, this is a comment.
;
__EE_Next:
	scl 														; successful exit.
	ld 		@1(p1) 												; look for next operator and bump.
	jz 		__EE_Exit 											; exit okay when found \0 or ), leave P1 on it.
	xri 	')'
	jz 		__EE_Exit 										
	xri 	')'!' '												; space, try next.
	jz 		__EE_Next
	ld 		-1(p1) 												; read it
__EE_WriteAndLoop:
	st 		operation+2(p2) 									; the new pending operator.
	xri 	'/' 												; is it divide
	jnz 	__EE_NextTerm 										; then go round again.
	ldi 	'\\' 												; use unsigned divide, not signed divide.
	jmp 	__EE_WriteAndLoop
;
;	Copy the remainder from the division into the '%' variable.
;	
__EE_ProcessRemainder:
	lpi 	p3,Variables+('%' & 0x3F) * 2 						; point P3 to remainder variable
	ld 		-2(p2)												; copy remainder value into remainder variable.
	st 		0(p3)
	ld 		-1(p2)
	st 		1(p3)
	jmp 	__EE_Next 											; get next operator.
;
;	Found a non-numeric term.
;
__EE_Variable:	

wait4:
	jmp 	wait4




; op is <=>?
ExpressionComparison:
	scl
	xppc 	p3