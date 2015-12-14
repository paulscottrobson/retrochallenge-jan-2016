; ****************************************************************************************************************
; ****************************************************************************************************************
;
;						Expression Evaluation. Returns CY/L = 0 on Error, A = Error Code
;	
; ****************************************************************************************************************
; ****************************************************************************************************************

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
	ldi 	'T'													; 'T' is Term Error.
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
	ld 		(p1) 												; look for next operator and bump.
	jz 		__EE_Exit 											; exit okay when found \0 or ), leave P1 on it.
	xri 	')'
	jz 		__EE_Exit 										
	ld 		@1(p1) 												; read, but advance pointer
	xri 	' '													; space, try next.
	jz 		__EE_Next
	ld 		-1(p1) 												; read it again.
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
	ld 		@1(p1) 												; check it is in the range 32-95
	scl
	cai 	32
	ani 	0xC0 												; this will be zero for 00-63
	jnz 	__EE_GoTermError 
	lpi 	p3,SpecialTermEvaluate-1 							; check for "specials"
	ld 		-1(p1)												; read character
	xppc 	p3
	csa 														; if CY/L = 0 we have processed this
	jp 		__EE_SpecialProcess
	ld 		-1(p1)												; read it again
	ccl 														; double it
	add 	-1(p1)
	ani 	0x7E 												; and with $3F << 1, this is an offset
	xae 														; put in E
	lpi 	p3,Variables+1 										; offset from variables, read high byte first
	ld 		-0x80(p3) 											; read high byte
	st 		@-1(p2) 											; push on stack
	ld 		@-1(p3) 											; point to low byte
	ld 		-0x80(p3) 											; read it
	st 		@-1(p2) 											; push on stack.
	jmp 	__EE_RunPendingOperation

;
;	Get here. If E = 0 then okay and value on stack as normal. E != 0 then error, no value pushed.
;
__EE_SpecialProcess:
	lde 														; check E
	jz 		__EE_RunPendingOperation 							; if zero, carry on as normal.											
;
;	Jumping back to TERM error.
;	
__EE_GoTermError:												; too far to jump.
	lpi 	p3,__EE_TermError-1
	xppc 	p3

; ****************************************************************************************************************
;	Perform operation A on the top 2 values on the stack.  NOTE: this returns CY/L = 1 = error unlike
; 	the functions here but like the functions in the maths library. Only receives < = > ? as binary operators.
; ****************************************************************************************************************

ExpressionComparison:
	xae															; save in E and reload.
	lde
	xri 	'='													; check for equals.
	jz 		__EC_Equals
	xri 	'='!'?'												; if it wasn't ? it must've been < or >
	jnz 	__EC_GLCompare
	scl 														; return with an error, as we sent in '?'
	xppc 	p3
;
;	Equality test.
;
__EC_Equals:
	ld 		0(p2)
	xor 	2(p2)
	jnz 	__EC_Fail
	ld 		1(p2)
	xor 	3(p2)
	jnz 	__EC_Fail
__EC_Succeed:
	ldi 	1 													; return value 1
__EC_ReturnA:
	st 		@2(p2) 												; drop TOS (save is irrelevant)
	st 		0(p2) 												; save in LSB
	ldi 	0
	st 		1(p2) 												; zero LSB
	ccl 														; it's okay
	xppc 	p3
;
__EC_Fail:
	ldi 	0 													; same as succeed, return 0.
	jmp 	__EC_ReturnA
;
;	>= or < test
;
__EC_GLCompare:
	scl 														; subtract, don't care about the result.
	ld 		2(p2)
	cad 	0(p2)
	ld 		3(p2)
	cad 	1(p2)
	lde 														; get original operator
	xri 	'<'													; will be 0 if <, #0 if >(=)
	jz 		__EC_IsLessThan
	ldi 	0x80 												; now will be 0 if <, 0x80 if >(=) 	
__EC_IsLessThan:
	xae 														; put in E
	csa 														; get CY/L
	xre 														; invert CY/L if it was >(=)
	jp 		__EC_Succeed 										; true
	jmp 	__EC_Fail 											; false