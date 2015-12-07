; ****************************************************************************************************************
; ****************************************************************************************************************
;
;											Evaluate, VTL-2 ROM
;											===================
;
;	R-Expression and Term Evaluators, including specials.
;
; ****************************************************************************************************************
; ****************************************************************************************************************

; ****************************************************************************************************************
; ****************************************************************************************************************
;
;				Evaluate an expression from P1, and push it on the stack. CY/L set on error
;
; ****************************************************************************************************************
; ****************************************************************************************************************

EvaluateExpression:

	section EvaluateExpression

EXExprResult = 4

	st 		@-3(p2) 											; save A, allow space for answer 
	lde
	st 		@-1(p2) 											; save E
	xpah 	p3 												
	st 		@-1(p2) 											; save P3
	xpal 	p3
	st 		@-1(p2)
	ldi 	0 													; clear final result, not technically required
	st 		EXExprResult(p2)
	st 		EXExprResult+1(p2)
;
;	Evaluate the first term.
;
	lpi 	p3,EvaluateTerm-1 									; evaluate term and push on stack.
	xppc 	p3
	csa
	jp 		__EXTermOkay 										; term is okay if CY/L = 0

__EXError:
	scl 														; return with CY/L set and erroneous value.
	jmp 	__EXCopyAndExit

__EXClearCarryCopyAndExit 										; come here if finished successfully.
	ccl
__EXCopyAndExit:	
	ld 		@1(p2) 												; copy stack to result space
	st 		EXExprResult+1(p2)
	ld 		@1(p2)
	st 		EXExprResult+1(p2)

	ld 		@1(p2) 												; restore P3,E,A
	xpal 	p3
	ld 		@1(p2)
	xpah 	p3
	ld 		@1(p2)
	xae
	ld 		@1(p2)
	xppc 	p3 													; return and make re-entrant.
	jmp 	EvaluateExpression 
;
;	Successfully acquired first term / main loop.
;
__EXTermOkay:
	ld 		(p1) 												; look at next character to find operator.
	jz 		__EXClearCarryCopyAndExit							; if zero, then end of string.
	xri 	')'													; found a close bracket, ending paren expr
	jz 		__EXClearCarryCopyAndExit 							; keep P1 pointing to that close bracket though.

	ld 		@1(p1) 												; get character and bump
	xri 	' '													; if space, keep going
	jz 		__EXTermOkay
	xri 	'('!' '												; found an open bracket which would be comment
	jz 		__EXClearCarryCopyAndExit
	ld 		-1(p1) 												; get this, this is the operator.
	xae 														; save in E.
	lpi 	p3,EvaluateTerm-1 	
	xppc 	p3 													; get the second term
	csa 														; if CY/L = 0 do operator.
	jp 		__EXDoOperator
;
;	Drop an unwanted value and exit with error flag set
;
__EXDropValueAndExitWithError:
	ld 		@2(p2) 												; throw away the 2nd operand
	jmp 	__EXError 											; and exit.
;
;	Do the operator in E.
;
__EXDoOperator:
	lde
	xri 	'/'													; convert signed division to unsigned division
	jnz 	__EXNotDivision
	ldi 	'\\'
	xae
__EXNotDivision:
	lde
	xri 	'='													; check for comparisons. = > <
	jz 		__EXDoCompare
	xri		'>'!'='
	jz 		__EXDoCompare
	xri 	'<'!'>'
	jz 		__EXDoCompare

	lpi 	p3,MathLibrary-1 									; do the maths operations + - * /
	lde 	
	xppc 	p3 	
	csa 														; if CY/L = 0 then try and get another term.
	ani 	0x80
	jnz 	__EXDropValueAndExitWithError 						; if set drop the value and exit with error.
	lde 														; check if it was division
	xri 	'\\'
	jnz 	__EXTermOkay 										; if not it's fine, exit.
	lpi 	p3,VariableBase+('%' & 0x3F) * 2					; point to the '%' variable.
	ld 		-2(p2) 												; copy remainder to % variable
	st 		(p3)
	ld 		-1(p2)
	st 		1(p3)
__EXTermOkay2:
	jmp 	__EXTermOkay 										; loop round to get the next operator.
;
;	Do the comparison in E (yields 1 or 0)
;
__EXDoCompare:
	ld 		2(p2) 												; do the subtraction comparison
	scl
	cad 	0(p2)
	st 		0(p2)
	ld 		3(p2)
	cad 	1(p2)
	or 		0(p2)												; A = 0 if equal
	xpah 	p3 													; save temporarily in P3.H
	ldi 	0
	st 		2(p2)												; zero the result. 
	st 		3(p2)
	ld 		@2(p2) 												; drop the 2nd value off the stack.
	lde 														; check for < 
	xri 	'<'	
	jz 		__EXLessThan
	xri 	'<'!'='												; check for =
	jz 		__EXEquals

	xpah 	p3 													; greater than test
	jz 		__EXTermOkay2 										; if equal then it is false.
	csa 														; for >= requires carry set
	jp 		__EXTermOkay2 										; exit if clear.
__EXReturnTrue:
	ild 	0(p2) 												; return 1 rather than 0.
	jmp 	__EXTermOkay2

__EXEquals:														; equal test
	xpah 	p3 													; get zero test.
	jz 		__EXReturnTrue										; if zero, return 1.
	jmp 	__EXTermOkay2

__EXLessThan:													; < test
	csa 														; look at carry
	jp 		__EXReturnTrue										; if carry clear then <
	jmp 	__EXTermOkay2 										; pop and continue.


	endsection EvaluateExpression

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
;		A system variable (e.g. $ or ?)
;		A variable (all other values 32-95)
;
;	Registers are unchanged except P1, which points to the erroneous character, or the next character.
;
; ****************************************************************************************************************
; ****************************************************************************************************************

EvaluateTerm:

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
	ld 		@2(p2) 												; throw away the saved value
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

__ETFailParen:
	ld 		@2(p2) 												; throw away the index value as error
	scl
	jmp 	__ETExit 											; and exit with failure.
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
	ld 		(p1) 												; what's next ?
	jz 		__ETFailParen 										; if nothing, exit with fail (end of string)
	ld 		@1(p1) 												; read it with bumping
	xri 	' ' 												; is it a space character ?
	jz 		__ETFindClosure 									; if so, try the next one.
	xri 	' '!')'												; check it was close brackets ?
	jnz 	__ETFailParen 										; if not, exit with fail as both end in close bracket.

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

; ****************************************************************************************************************
; ****************************************************************************************************************
;
;		A is a variable whose value has been requested. Returns single value. This is used for non
;		standard variables, things like $ and ? which have side-effects.
;
;		If legitimate value return CY/L = 0, else return CY/L = 1
;
; ****************************************************************************************************************
; ****************************************************************************************************************

TermSystemVariableCheck:

	section ReadSystemVariables

	xpah 	p3													; save P3 preserving A, reserve space for result.
	st 		@-3(p2)
	xpal 	p3
	st 		@-1(p2)

	xpah 	p3 													; get system variable back.

	xri 	'$'													; $ as a term reads a keystroke.
	jz 		__TSVCGetCharacter
	xri 	'$'!'?'												; ? reads a keyboard line in and evaluates it.
	jz 		__TSVCGetNumber
	scl 														; fail - set CY/L and just restore P3 and exit
__TSVCExit:
	ld 		@1(p2)
	xpal 	p3
	ld 		@1(p2)
	xpah 	p3
	xppc	p3 													; doesn't need to be re-entrant
;
;	$ (read character ASCII code)
;
__TSVCGetCharacter:
	lpi 	p3,GetChar-1 										; get a character
	xppc 	p3 													; from the keyboard.
	st 		2(p2) 												; put on stack in return slot
	ldi 	0
	st 		3(p2) 												; clear MSB of answer.
	ccl 														; mark as done
	jmp 	__TSVCExit 											; and exit.
;
;	? (read keyboard line in and evaluate it)
;
__TSVCGetNumber:
	xpah 	p1 													; save P1 on the stack
	st 		@-1(p2)
	xpal 	p1
	st 		@-1(p2)
	lpi 	p1,KeyboardBuffer 									; P1 points to keyboard buffer
	lpi 	p3,GetString-1 										; P3 points to string read function
	ldi 	KeyboardBufferSize 									; max length
	xppc 	p3 													; read keyboard input.
	lpi 	p3,EvaluateExpression-1 							; evaluate and push on stack, ignore any errors.
	xppc 	p3
	ld 		0(p2) 												; copy result
	st 		6(p2)
	ld 		1(p2)
	st 		7(p2)
	ld 		@2(p2) 												; skip over result
	ld 		@1(p2)												; restore P1
	xpal 	p1
	ld 		@1(p2)
	xpah 	p1
	ccl 														; clear carry as done
	jmp 	__TSVCExit

	endsection ReadSystemVariables
