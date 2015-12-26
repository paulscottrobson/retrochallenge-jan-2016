; ****************************************************************************************************************
; ****************************************************************************************************************
;
;										Expression Evaluation
;										=====================
;
;	On entry, P1 points to the expression, on exit it points to ) or NULL if okay. Error in E. CY/L flag = 0
;	indicates error, and this is already copied into A (e.g. CSA ; XPPC P3). A two byte result is stored on 
;	the stack whatever happens but this is not a valid value unless CY/L = 1.
;
;	This code has the monitor maths library as a dependency.
;	
; ****************************************************************************************************************
; ****************************************************************************************************************


EvaluateExpression:
	pushp 	p3 													; save P3 on stack.
	ldi 	'+'													; push + on stack as pending operator
	st 		@-1(p2)
	ldi 	0 													; push 0 (16 bit) on stack as current term.
	st 		@-1(p2)
	st 		@-1(p2)

; ****************************************************************************************************************
;					Get the next term. This is the main loop. We pretend we have already done 0+
; ****************************************************************************************************************

__EE_NextTerm:	
	ld 		@1(p1) 												; get next character and bump.
	jz 		__EE_ExitSyntax 									; fail with syntax error if nothing found
	xri 	' ' 												; keep going, skipping over spaces.
	jz 		__EE_NextTerm
	ld 		@-1(p1) 											; get character, unpicking bump
	ccl 														; add 128-'0' ; if +ve it is less than '0'
	adi 	128-'0'
	jp 		__EE_NotInteger
	adi 	128-10 												; add 128-10 ; if +ve it is greater than '9'
	jp 		__EE_NotInteger

; ****************************************************************************************************************
;					Found an integer term, use the math library to extract the integer.
; ****************************************************************************************************************

	lpi 	p3,OSMathLibrary-1 									; use math library function '?'
	ldi 	'?'
	xppc 	p3 													; convert to an integer (cannot return an error)
	jmp 	__EE_ProcessOperator 								; process the pending operator
;
;	Syntax errors, come here
;
__EE_ExitSyntax:
	ldi 	ERROR_SyntaxTerm 									; E = Syntax Error in term.
	xae
	ccl
;
;	Any other error, or successful completion, come here.
;
__EE_Exit:
	ld 		@3(p2) 												; drop result and pending operator space on stack
	pullp 	p3 													; restore P3

	ld 		-5(p2) 												; copy result to correct slot
	st 		-2(p2)
	ld 		-4(p2)
	st 		-1(p2)
	ld 		@-2(p2)												; make space for result, result always returned.
	csa 														; get CY/L bit into A bit 7
	xppc 	p3 													; return
	jmp 	EvaluateExpression 									; re-entrant.

; ****************************************************************************************************************
;	We know it is not a numeric constant, so check for special terms. First though we optimise it by 
;	checking bit 5 - if zero the code is @A-Z[\]^_ none of which are 'special' terms.
; ****************************************************************************************************************

__EE_NotInteger:
	ld 		(p1) 												; look at character bit 5 (32)
	ani 	32 													; if this is zero it cannot be a special term 
	jz 		__EE_IsVariable 									; as they are 32-63.

	lpi 	p3,CheckSpecialTerms-1 								; call the special terms routine.
	xppc 	p3
	ld 		@2(p2) 												; drop the result
	csa
	jp 		__EE_Exit  											; if CY/L = 0 then an error has occurred, return it.
	ld 		@-2(p2) 											; restore result to TOS.
	lde  														; if E != 0 then the value has been processed and is on 
	jnz 	__EE_ProcessOperator 								; the stack, so go process it
	ld 		@2(p2) 												; drop the TOS as it is not valid.

; ****************************************************************************************************************
;										We now know this is a variable.
; ****************************************************************************************************************

__EE_IsVariable:
	ld 		(p1) 												; calculate twice the character
	ccl 
	add 	@1(p1) 												; add with bump of variable.
	ani 	(0x3F * 2)											; same as (n & 0x3F) * 2
	xae 														; put in E, use this as an index.
	lpi 	p3,Variables 										; point P3 to variables
	ld 		-0x80(p3) 											; get low byte
	st 		@-2(p2) 											; push on stack, allow space for high byte
	ld 		@1(p3) 												; increment P3 to get high byte
	ld 		-0x80(p3) 											; get high byte
	st 		1(p2) 												; save on allocated stack space.
	jmp 	__EE_ProcessOperator

__EE_NextTerm2: 												; the jump is too large.
	jmp 	__EE_NextTerm

; ****************************************************************************************************************
;		We now have two values on the stack and an operator, so apply the operator to the two values.
; ****************************************************************************************************************

__EE_ProcessOperator:
	lpi 	p3,OSMathLibrary-1 									; point P3 to the OS Math Library.
	ld 		4(p2) 												; get operator
	ani 	0xFC 												; clear bits 0,1
	xri 	0x3C 												; now will be zero for 3C..3F which is < = > ?
	jnz 	__EE_NotComparison
	lpi 	p3,CompareLibrary-1 								; if it is, we use this library instead
__EE_NotComparison:
	ld 		4(p2) 												; get operator
	xri 	'/'													; is it divide ?
	jnz 	__EE_NotDivide
	xri 	'/'!'\\'											; if so, this will change it to \ unsigned divide for Math lib.
__EE_NotDivide:
	xri 	'/'													; unpick the test, but / will have changed to \ (backslash)
	xppc 	p3 													; do the operation.
	csa 														; check for error.
	jp 		__EE_GetNextOperator 								; CY/L = 1, error
	ld 		@2(p2) 												; drop TOS - if divide by zero then stack unchanged.
	ldi 	ERROR_DivideZero 									; prepare for division by zero error.
	xae 														; the only error the Math Library can return from + - * /
	ccl 														; return error flag.
__EE_Exit2:
	jmp 	__EE_Exit 											; return if error.

; ****************************************************************************************************************
;	Have successfully performed operation. First check if we have done division, and if so, save the remainder.
; ****************************************************************************************************************

__EE_GetNextOperator:
	ld 		2(p2) 												; was it divide ?
	xri 	'/'
	jnz 	__EE_FindNextOperator
	lpi 	p3,Variables+('%' & 0x3F)*2 						; point P3 to remainder variable
	ld 		-2(p2)												; copy remainder there.
	st 		(p3)
	ld 		-1(p2)
	st 		1(p3)

; ****************************************************************************************************************
;							Now find the next operator. NULL or ) ends an expression.
; ****************************************************************************************************************

__EE_FindNextOperator:
	scl 														; prepare for successful exit.
	ld 		(p1) 												; get next operator
	jz 		__EE_Exit2 											; if end of line, exit
	xri 	')' 												; if close parenthesis, exit.
	jz 		__EE_Exit2
	ld 		@1(p1) 												; refetch and bump
	xri 	' ' 												; loop back if spaces
	jz 		__EE_FindNextOperator

	ld 		-1(p1) 												; reload old character.
	st 		2(p2) 												; save as pending operation.

	xri 	'+'
	jz 		__EE_NextTerm2 										; go to next term if a valid operator.
	xri 	'-'!'+'
	jz 		__EE_NextTerm2
	xri 	'*'!'-'
	jz 		__EE_NextTerm2
	xri 	'/'!'*'
	jz 		__EE_NextTerm2
	xri 	'<'!'/'
	jz 		__EE_NextTerm2
	xri 	'='!'<'
	jz 		__EE_NextTerm2
	xri 	'>'!'='
	jz 		__EE_NextTerm2

	ldi 	ERROR_Operator 										; bad operator error
	xae
	ccl
	jmp 	__EE_Exit2

; ****************************************************************************************************************
;	
;							This library provides functionality for >, = and <.
;
; ****************************************************************************************************************

CompareLibrary:
	scl 														; calculate Stack2 - Stack1
	ld 		2(p2) 												; lower byte
	cad 	0(p2)
	xae 														; save in E
	ld 		3(p2) 												; upper byte
	cad 	1(p2)
	ore 														; or into E, now zero if equal.
	jz 		__CL_ResultZero 
	ldi 	1  													
__CL_ResultZero:												; A = 0 if result same, A = 1 if result different
	xri 	1 													; A = 1 if result same, A = 1 if result different
	xae 														; put in E
	ld 		4(p2) 												; get comparator
	xri 	'=' 												; if it is '=', exit with E
	jz 		__CL_ExitE

	csa 														; get not borrow from subtraction
	ani 	0x80 												; isolate carry
	jz 		__CL_CarryClear
	ldi 	1
__CL_CarryClear:												; now A = 1 : Carry set, A = 0 : Carry Clear
 	xae 														; in E
 	ld 		4(p2) 												; if it is '>', exit with this value
 	xri 	'>'
 	jz 		__CL_ExitE
 	lde 														; toggle E bit 0, e.g. reversing result.
 	xri 	1
 	xae
__CL_ExitE:
	ld 		@2(p2) 												; pop a value off
	lde 														; save E as LSB
	st 		0(p2)
	ldi 	0 													; MSB is zero, result is 0 or 1.
	st 		1(p2)
	ccl 														; clear carry because we must to be okay, matches behaviour
	xppc 	p3 													; of Maths library.

