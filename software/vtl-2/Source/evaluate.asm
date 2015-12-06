; ****************************************************************************************************************
; ****************************************************************************************************************
;
;											Evaluate, VTL-2 ROM
;											===================
;
;	R-Expression and Term Evaluators
;
; ****************************************************************************************************************
; ****************************************************************************************************************

Test:db 	":2)",0

; ****************************************************************************************************************
; ****************************************************************************************************************
;
;					Evaluate a single term from P1 and push it on the stack. CY/L set on error
;
;	Terms can be:
;
;		A numeric constant (e.g. "46")
;		A parenthesised expression ( (5+2) )
;		An array expression :42)
;		A system variable (?)
;		A variable (all other values 32-95)
;
;	Registers are unchanged except P1, which points to the erroneous character, or the next character.
;
; ****************************************************************************************************************
; ****************************************************************************************************************

EvaluateTerm:
EvaluateExpression:

	section EvaluateTerm

EVTermResult = 4 												; offset in stack to result.

	st 		@-3(p2) 											; save A, reserving room for the result.
	lde 														; save E
	st 		@-1(p2) 	
	xpah 	p3 													; save P3
	st 		@-1(p2)
	xpal	p3
	st 		@-1(p2)

	ldi 	0 													; blank the result on the stack
	st 		EVTermResult(p2) 									; not strictly necessary :)
	st 		EVTermResult+1(p2)
	jmp 	__ETFindTerm

__ETSkipSpace:
	ld 		@1(p1) 												; bump P1
__ETFindTerm:
	ld 		(p1) 												; read the first term character
	scl
	cai 	32													; if space, skip over it and try again.
	jz 		__ETSkipSpace
	ani 	0xC0												; should be in range 00-3F to be 32-95 (legal chars)
	scl
	jnz 	__ETExit 											; if not, exit with error.

	ld 		(p1) 												; read term first character again
	scl
	cai 	'9'+1 												; if >= '9' will be +ve
	jp 		__ETTermNotConstant
	adi 	128+10 												; if < '0' will be +ve
	jp 		__ETTermNotConstant
;
;	Term is an ASCII Constant
;
	lpi 	p3,MathLibrary-1 									; use Math library to convert to integer.
	ldi 	'?'													; function ASCII->Int, cannot fail as first digit numeric
	xppc 	p3
;
;	Result on TOS - have to reposition past the stacked SC/MP registers.
;
__ETSucceed:
	ld 		@1(p2)												; put result in its proper place
	st 		EVTermResult+1(p2) 									; unstacking TOS.
	ld 		@1(p2)
	st 		EVTermResult+1(p2)
__ETCCLAndExit:
	ccl 														; clear carry indicating success
__ETExit:
	ld 		@1(p2) 												; restore P3
	xpal 	p3
	ld 		@1(p2)
	xpah 	p3
	ld 		@1(p2) 												; restore E
	xae
	ld 		@1(p2) 												; restore A, leaving the result on the tack
	xppc 	p3 													; return
	jmp 	EvaluateTerm 										; make re-entrant
;
;	P1 still points to first non space, which is in range 33-95. It is not a numeric character.
;
__ETTermNotConstant:

	ld 		(p1) 												; read character
	xri 	':'													; array check ?
	jz 		__ETIsParenType 					
	xri 	':'!'('												; parenthesis check ?
	jz 		__ETIsParenType
;
;	System variable checks.
;
	lpi 	p3,TermSystemVariableCheck-1 						; this routine checks for system variables.
	ld 		@1(p1)												; read the variable name and bump, finally.
	xppc 	p3 													; call it
	csa 														; if CY/L is clear, this has done the work.
	jp 		__ETSucceed 										; and the result is on the stack, so process it.
;
;	Okay, finally we think it's just a normal variable. We copy it in, don't bother shoving it on the stack.
;
	ld 		-1(p1) 												; read the variable name and skip over it
	ccl
	add 	-1(p1) 												; double it.
	ani 	0x7E 												; arrangement is 6 bit ASCII, this is 3F x 2
	xpal 	p3
	ldi 	VariableBase/256 									; point P3 to the variables
	xpah 	p3
	ld 		@1(p3) 												; read low 
	st 		EVTermResult(p2) 									; copy to stack space
	ld 		(p3) 												; same for high
	st 		EVTermResult+1(p2)
	jmp 	__ETCCLAndExit 										; clear carry and exit.

__ETSucceed2:													; allows extended jump from end of array code.
	jmp 	__ETSucceed

;
;	Parenthesis (expr) or Array :expr)
;
__ETIsParenType:
	ld 		@1(p1) 												; read the type and save in E so we know what it was.
	xae
	lpi 	p3,EvaluateExpression-1 							; evaluate the sub-expression.
	xppc 	p3 
	csa 														; if carry set, error occurred
	ani 	0x80
	jnz 	__ETExit
;
;	Look for )
;
__ETFindClosure:
	scl
	ld 		(p1) 												; what's next ?
	jz 		__ETExit 											; if nothing, exit with fail (end of string)
	ld 		@1(p1) 												; read it with bumping
	xri 	' ' 												; is it a space character ?
	jz 		__ETFindClosure 									; if so, try the next one.
	xri 	' '!')'												; check it was close brackets ?
	jnz 	__ETExit 											; if not, exit with fail as both end in close bracket.

	lde 														; was it :nnn) or (nnn)
	xri 	'('
	jz 		__ETSucceed 										; if '(' exit with value on TOS.
;
;	Now it is array type e.g. :expr) so we have to do the array lookup.
;
	ccl 														; otherwise, it's an array reference.
	ld 		0(p2)  												; double TOS as it is word orientated
	add 	0(p2)
	st 		0(p2)
	ld 		1(p2)
	add 	1(p2)
	st 		1(p2) 												; p2 is now double the index.
	ldi 	VariableBase/256 									; point P3 to the program last byte variable (&)
	xpah 	p3
	ldi 	('&' & 0x3F) * 2
	xpal 	p3 
	ccl
	ld 		0(p2)												; get offset
	add 	0(p3) 												; add top of program memory
	xae 														; put in E temporarily
	ld 		1(p2) 												; repeat for MSB
	add 	1(p3)
	xpah 	p3 													; put in P3.H
	lde 														; get E temporary
	xpal 	p3 													; put in P3.L - P3 now the address to access
	ld 		0(p3) 												; so access it
	st 		0(p2)												; and override the array index
	ld 		1(p3)
	st 		1(p2) 
	jmp 	__ETSucceed2 										; and we are done.

	endsection EvaluateTerm

TermSystemVariableCheck:
	; for var in A, if it is a non-standard variable, read it and push on stack and return CY/L = 0
	; if normal variable, return CY/L = 1
	scl
	xppc	p3



