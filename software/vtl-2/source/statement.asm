; ****************************************************************************************************************
; ****************************************************************************************************************
;
;												Statement Processing
;
; ****************************************************************************************************************
; ****************************************************************************************************************

; ****************************************************************************************************************
;
;	Execute current line. P1 points to <Total Length>,<Line# Low>,<Line# High> <Text> ....,0
;
;	Returns CY/L = 1 okay, CY/L = 0 Error, code in 'A'. On exit P1 points to the next line, if this is
;	at the top of memory the program is automatically stopped.
;
;	# [35]	if non zero, save current line number + 1 in ! and find line, stopping if too high, in run mode otherwise.
; 	? [63]	Print string constants, numbers
;	$ [36]	Print single characters
;	& [38]	First free program byte, when set does a "NEW", stop always.
;	: [58]	Array update :<expr>) =
;	> [62]	Execute program at RHS (machine code)
;
;	Handle NULL/Comment lines seperately.
;	
;	Random Number processing is done on every execution.
;
; ****************************************************************************************************************

;
;	Find the next line and then exit.
;
__EX_EndLineAndExit:
	ld 		@1(p1) 												; read and bump
	jnz 	__EX_EndLineAndExit
;
;	Come here if P1 already pointing to the next instruction ()
;
__EX_ExecuteExit:
	scl 														; Set carry Flag
	ld 		(p1) 												; look at the instruction length byte, 0 if end.
	jnz 	__EX_LeaveExecution 		
__EX_StopOnError:			
	lpi 	p3,IsRunningProgram 								; clear the 'is running program' flag.
	ldi 	0
	st 		(p3)
;
;	Leave anyway
;
__EX_LeaveExecution:
	pullp 	p3 													; restore A,E,P3
	pulle
	pulla
	xppc 	p3
;
;	Execute an A = B statement type (which is all of them !)
;
ExecuteStatement:
	pusha 	 													; save A,E,P3
	pushe
	pushp 	p3
	ld 		(p1) 												; check if already at end.
	jz 		__EX_ExecuteExit 									; if length was zero already at last line of memory, stop
	lpi 	p3,('#' & 0x3F)*2+Variables 						; update # variable with current line number
	ld 		1(p1)
	st 		0(p3)
	ld 		2(p1)
	st 		1(p3)
	ld 		@3(p1) 												; skip over length and line number.
	lpi 	p3,RandomProcess-1 									; change the Random Number done every program line.
	xppc 	p3
__ES_SkipSpaces:
	ld 		@1(p1) 												; read next character in line and skip it
	jz 		__EX_ExecuteExit 									; if it is zero, it will now point to the next line, exit.
	xri 	')'													; is it a comment ?
	jz 		__EX_EndLineAndExit 								; skip the rest of the line and exit.	
	xri 	')'!' ' 											; is it space ? if so, go back.
	jz 		__ES_SkipSpaces 									; first line of character now at -1(p1)

	ld 		@-1(p1) 											; point P1 to first character and read it.
	scl  														; valid values are 32-95.
	cai 	32 													; valid values are 0-63 now.
	ani 	0xC0 												; which means this must be zero
	jz 		__ES_LegalAssignment  									
	ldi 	'A'													; illegal assignment
	xpal 	p3
__ES_ReturnErrorP3Low:
	xpal 	p3
__ES_ReturnErrorA:
	st 		3(p2) 												; this overrides stacked value with the returned A value.
	ccl 														; return with error flag 
	jmp 	__EX_StopOnError

__ES_LegalAssignment:
	ld 		(p1) 												; get ASCII character code.
	ani 	0x40 												; look at bit $40. 
	jnz 	__ES_NotSpecial 									; if set, it is @A-Z range so can't be "special"
	lpi 	p3,SpecialAssignment-1 								; check for "special assignments" (see above list)
	ld 		(p1) 												; get the character code
	xppc 	p3					 								; check
	xae 														; error code in E now (if any)
	csa 														; check return flag.
	ani 	0x80
	jnz 	__ES_NotSpecial 									; if returned CY/L = 1 didn't process it so normal var.

	lde 														; processed it, check error flag.
	jnz 	__ES_ReturnErrorA 									; if non zero return with that error code.
__EX_EndLineAndExit2:
	jmp 	__EX_EndLineAndExit 								; otherwise just find EOL and exit as it was okay.
;
;	"Non Special" variables - e.g. straight copy expression value into memory stuff.
;
__ES_NotSpecial:
	ld 		@1(p1) 												; it is a normal assignment.
	ani 	0x3F 												; variable number
	xae 														; double it as two byte variables.
	ccl
	lde
	ade
	xae 														; save in E
	lpi 	p3,CheckEqualsAndEvaluate-1 						; check '=' and evaluate RHS.
	xppc 	p3
	xpal 	p3 													; save error code in P3.L, if there was one :)
	ld 		@2(p2) 												; drop the result.
	csa
	jp 		__ES_ReturnErrorP3Low 								; if +ve (CY/L = 0) then error (in P3.L) occurred

	lpi 	p3,Variables 										; E(p3) points to correct variable.
	ld 		-2(p2) 												; unstack LSB
	st 		-0x80(p3)
	ld 		@1(p3) 												; bump P3 easier than bumping E :)
	ld 		-1(p2) 												; unstack MSB
	st 		-0x80(p3)
	jmp 	__EX_EndLineAndExit2 								; and done :)

; ****************************************************************************************************************
;
;	Test to see if the following character is '=' and evaluate the expression following it. Returns CY/L = 0 and
;	A = error code on error, if CY/L = 1 . Value is always returned on stack whatever.
;
; ****************************************************************************************************************

CheckEqualsAndEvaluate:
	st 		@-2(p2) 											; save result for answer, if any.
__CEE_FindEquals:
	ld 		(p1) 												; check if EOS
	jz 		__CEEFailEquals
	ld 		@1(p1) 												; fetch and bump.
	xri 	' '													; keep trying if space.
	jz 		__CEE_FindEquals
	xri 	' ' ! '='											; okay, if equals.
	jz 		__CEE_FoundEqual
__CEEFailEquals:
	ldi 	'E'													; E Error
	ccl
	xppc 	p3

__CEE_FoundEqual:
	pusha 														; save A and P3
	pushp 	p3
	lpi 	p3,EvaluateExpression-1 							; evaluate the expression.
	xppc 	p3
	st  	4(p2) 												; save error code overwriting A.
	ld 		@1(p2) 												; copy result over.
	st 		4(p2)
	ld 		@1(p2)
	st 		4(p2)
	pullp 	p3 													; restore P3
	pulla 														; restore A
	xppc 	p3

; ****************************************************************************************************************
;
;		Special assignment tests, e.g. those with a side effect. On entrance (p1) points to the assignment.
;		On exit CY/L = 0 means processed and the value is on the TOS. CY/L = 1 means did not process, so should
;		be processed as variable assignment. If processed then A contains the error code, which is zero if successful.
;
; ****************************************************************************************************************

SpecialAssignment:
	pusha
	pushp 	p3
	lpi 	p3,__SA_Table 										; point P3 to the table of special assignments
__SA_Find:
	ld 		@3(p3) 												; get next table entry
	jz 		__SA_NotFound
	xor 	(p1) 												; is it the one we've found.
	jnz 	__SA_Find 											; no, try again.

	ld 		@1(p1) 												; skip P1 over the assignment charactr.
	ld 		-2(p3) 												; get LSB of vector
	xae
	ld 		-1(p3) 												; get MSB of vector to P3.H
	xpah 	p3
	lde 														; copy LSB from E to P3.L
	xpal 	p3
	xppc 	p3 													; and go there.
	jmp 	CheckEqualsAndEvaluate 								; set up so a further xppc p3 goes here immediately.
;
;	Nothing found in the specials table.
;
__SA_NotFound:
	scl 														; set CY/L as nothing processed.
__SA_Exit:
	pullp 	p3
	pulla
	xppc 	p3 												
;
;	Error occurred on expression evaluation, E contains error code.
;
__SA_ExpressionError:
	ccl
	lde 														; get error code
	st 		2(p2) 												; save error code on stack.
	jmp 	__SA_Exit

; ****************************************************************************************************************
;								$ = nn Prints the low byte of nn as a character
; ****************************************************************************************************************

__SA_CO_Enter:													; $ right hand side.
	xppc 	p3 													; evaluate RHS
	xae															; save error code if any
	ld 		@2(p2) 												; drop the return value
	csa 														; error check
	jp 		__SA_ExpressionError 								; go here if failed.
	lpi 	p3,Print-1											; print character
	ld 		-2(p2) 												; get LSB of value
	jz 		__SA_CO_NoPrint 									; don't print if $00
	xppc 	p3 													; print character
__SA_CO_NoPrint:
;
;	Come here when special case has been completed successfully.
;
__SA_Completed:	
	ldi 	0 													; clear A return value
	st 		2(p2)
	ccl 														; clear carry flag, processed successfully.
	jmp 	__SA_Exit

; ****************************************************************************************************************
; 							> = nn Call routine at nn with P1 pointing to variables.
; ****************************************************************************************************************

__SA_CO_Call:
	xppc 	p3 													; evaluate RHS
	xae															; save error code if any
	ld 		@2(p2) 												; drop the return value
	csa 														; error check
	jp 		__SA_ExpressionError 								; go here if failed.
	ld 		-2(p2) 												; put value into P3.L
	xpal 	p3
	ld 		-1(p2)
	xpah 	p3
	ld 		@-1(p3) 											; adjust call address for preincrement
	pushp 	p1 													; save P1 on stack
	lpi 	p1,Variables 										; point P1 to system variables
	xppc 	p3 													; call routine
	pullp 	p1 													; restore P1
	jmp 	__SA_Completed

; ****************************************************************************************************************
; 							  & = nn Set end of program pointer (actually start !)
; ****************************************************************************************************************

__SA_CO_New:
	xppc 	p3 													; evaluate RHS
	xae															; save error code if any
	ld 		@2(p2) 												; drop the return value
	csa 														; error check
	jp 		__SA_ExpressionError 								; go here if failed.
	lpi 	p3,Variables+('&' & 0x3F) * 2 						; point P3 to & variable.
	ld 		-2(p2) 												; copy value into &
	st 		0(p3)
	ld 		-1(p2)
	st 		1(p3)
	lpi 	p3,NewProgram-1 									; New program routine
	xppc 	p3

__SA_Completed2:
	jmp 	__SA_Completed
__SA_ExpressionError2:
	jmp 	__SA_ExpressionError

; ****************************************************************************************************************
;												:<expr>) Array Access
; ****************************************************************************************************************

__SA_CO_Array:
	lpi 	p3,EvaluateExpression-1 							; get expression value (array index)
	xppc 	p3 													; evaluate RHS
	xae															; save error code if any
	ld 		@2(p2) 												; drop the return value
	csa 														; error check
	jp 		__SA_ExpressionError 								; go here if failed.
	ld 		(p1) 												; if next character not ) that's an error.
	xri 	')'
	jnz 	__SA_ExpressionError
	ccl
	ld 		@-2(p2) 											; double array index as words, and keep on stack.
	add 	0(p2)
	st 		0(p2)
	ld 		1(p2)
	add 	1(p2)
	st 		1(p2)
	lpi 	p3,Variables+('&' & 0x3F) * 2 						; point P3 to & variable.
	ccl 	
	ld 		0(p3) 												; add that variable's value to the index
	add 	0(p2)												; this will make this stack value where the 
	st 		0(p2)												; expression is going to be written to.
	ld 		1(p3)
	add 	1(p2)
	st 		1(p2)
	ld 		@1(p1) 												; skip over the closing bracket, already tested.
	lpi 	p3,CheckEqualsAndEvaluate-1 						; check = nnnn and evaluate.
	xppc	p3 													; call it
	xae 														; save error
	ld 		@4(p2) 												; drop address and data
	csa 														; check CY/L
	jp 		__SA_ExpressionError2 								; error exit.
	ld 		-2(p2)												; load address into P3.
	xae
	ld 		-1(p2)
	xpah 	p3
	lde
	xpal 	p3
	ld 		-4(p2)												; write out to array memory
	st 		0(p3)
	ld 		-3(p2)
	st 		1(p3)
__SA_Completed3:
	jmp 	__SA_Completed2	

; ****************************************************************************************************************
;									? Print either ?=<expr> or ?="<text>"[;]
; ****************************************************************************************************************

__SA_CO_Print:
	ld 		(p1)												; look for =
	jz 		__SA_PR_Error
	ld 		@1(p1) 												; fetch and bump
	xri 	' '
	jz 		__SA_CO_Print
	xri 	' '!'=' 											; if found equals, go to that code.
	jz 		__SA_PR_FoundEquals
__SA_PR_Error:													; report a P error
	ldi 	'P'
	xae
__SA_ExpressionError3:
	jmp 	__SA_ExpressionError2

__SA_PR_FoundEquals:											; now look for a non-space character
	ld 		(p1)
	jz 		__SA_PR_Error
	ld 		@1(p1)
	xri 	' '
	jz 		__SA_PR_FoundEquals
	xri 	' '!'"'												; have we found a quote mark. 
	jnz 	__SA_PR_Expression
;
;	?="<literal>"[;]
;
	lpi 	p3,Print-1 											; print character routine
__SA_PR_Literal:
	ld 		(p1) 												; check end of string
	jz 		__SA_Completed3 
	ld 		@1(p1) 												; fetch and bump.
	xri 	'"'													; found quote mark.
	jz 		__SA_CheckSemicolon	 								; if found check for semicolon following.
	ld 		-1(p1) 												; fetch previous character
	xppc 	p3 													; print the character
	jmp 	__SA_PR_Literal										; and go back.
;
;	Found ending quote mark, check for semicolon and print CR if absent
;
__SA_CheckSemicolon:
	ld 		(p1) 												; check EOS
	jz 		__SA_PrintReturn
	ld 		@1(p1) 												; fetch and bump
	xri 	' ' 												; loop back if space
	jz 		__SA_CheckSemicolon
	xri 	' '!';'												; exit if semicolon
	jz 		__SA_Completed3 
__SA_PrintReturn:
	ldi 	13 													; print CR 													
	xppc 	p3
__SA_Completed4:
	jmp 	__SA_Completed3
;
;	Expression not literal
;
__SA_PR_Expression:
	ld 		@-1(p1) 											; point to start of literal
	lpi 	p3,EvaluateExpression-1 							; evaluate expression.
	xppc 	p3 													; do it
	xae
	ld 		@2(p2) 												; drop value off stack
	csa 	
	jp 		__SA_ExpressionError3
	ld 		-2(p2) 												; copy dropped value one level down.
	st 		-4(p2)
	ld 		-1(p2)
	st 		-3(p2)
	pushp 	p1 													; save P1 on stack.
	ld 		@-2(p2) 											; pushes the dropped value on the stack.
	lpi 	p1,KeyboardBuffer+8 								; temporary space for string to decode
	lpi 	p3,OSMathLibrary-1 									; Maths library.
	ldi 	'$'													; convert to ASCII.
	xppc 	p3 													; go do it.
	lpi 	p3,Print-1 											; print the string
	ldi 	0													; at P1
	xppc 	p3 	
	pullp 	p1 													; restore P1.
	jmp 	__SA_Completed4

; ****************************************************************************************************************
;												# = <expr> GOTO
; ****************************************************************************************************************

__SA_CO_Goto:
	xppc 	p3 													; evaluate RHS
	xae															; save error code if any
	ld 		@2(p2) 												; drop the return value
	csa 														; error check
	jp 		__SA_ExpressionError3 								; go here if failed.
	ld 		-2(p2) 												; check if expression was zero
	or 		-1(p2)
	jz 		__SA_Completed4 									; if so, don't do anything at all.
	lpi 	p3,Variables 										; access variables.
	ld 		('#' & 0x3F)*2(p3)									; get old line number, add one, store in '!'
	ccl 														; this is the return address.
	adi 	1
	st 		('!' & 0x3F)*2(p3)
	ld 		('#' & 0x3F)*2+1(p3)								; do the MSB
	adi 	0
	st 		('!' & 0x3F)*2+1(p3)
	ld 		-2(p2) 												; copy evaluated expression to '#' variable.
	st 		('#' & 0x3F)*2(p3)
	ld 		-1(p2)
	st 		('#' & 0x3F)*2+1(p3)
	ldi 	0  													; stop running - start again if we find the line.
	st 		IsRunningProgram-Variables(p3) 					

	ld 		ProgramBase-Variables(p3) 							; now load the program base into P1 to line search
	xpal 	p1
	ld 		ProgramBase-Variables+1(p3)
	xpah 	p1
__SA_GO_FindLine:
	ld 		(p1) 												; if length byte = 0 then didn't find line.
	jz 		__SA_Completed4 									; so the command ends with the program stopped.
	ld 		1(p1) 												; calculate current line# - search line #
	scl 														; (result doesn't matter.)
	cad 	-2(p2)
	ld 		2(p1)
	cad 	-1(p2)
	csa
	jp 		__SA_GO_NextLine 									; if CY/L = 0 then < search line, go to next.

	ldi 	1 													; set the running flag.
	st 		IsRunningProgram-Variables(p3) 					
	ld 		@3(p2) 												; we have to jump out here rather than return because
																; the normal exit does EOL scan. Drop stack values
	lpi 	p3,__EX_ExecuteExit-1 								; and jump out.
	xppc 	p3

__SA_GO_NextLine:
	ld 		(p1) 												; length byte in E
	xae
	ld 		@-0x80(p1) 											; add that length byte to go to next instruction.
	jmp 	__SA_GO_FindLine 									; and keep searching.
	
wait4:
	jmp 	wait4

; ****************************************************************************************************************
;											Special Assignment Jump Table.
; ****************************************************************************************************************

__SA_Entry macro ch,code
	db 		ch
	dw 		code-1
	endm

__SA_Table:
	__SA_Entry	'#',__SA_CO_Goto
	__SA_Entry	'$',__SA_CO_Enter
	__SA_Entry  '>',__SA_CO_Call
	__SA_Entry 	'&',__SA_CO_New
	__SA_Entry 	':',__SA_CO_Array
	__SA_Entry  '?',__SA_CO_Print
	db 			0												; marks end of table.

; ****************************************************************************************************************
;
;						Update the random seed, initialising if required. Galois LFSR
;
; ****************************************************************************************************************

RandomProcess:
	pushp 	p3 													; save P3
	lpi 	p3,Variables+(0x27 & 0x3F) * 2 						; point P3 to random variable (' mark)
	ld 		0(p3) 												; check to see if seed is zero.
	or 		1(p3)
	jnz 	__RPNoInitialise
	ldi 	0xE1 												; initialise to $ACE1
	st 		0(p3)
	ldi 	0xAC
	st 		1(p3)
__RPNoInitialise:
	ccl 														; rotate seed right.
	ld 		1(p3)
	rrl
	st 		1(p3)
	ld 		0(p3)
	rrl
	st 		0(p3)
	csa  														; this is the dropped bit
	jp 		__RPNoToggle 	
	ld 		1(p3) 												; if it is set xor ms byte with $B4
	xri 	0xB4
	st 		1(p3)
__RPNoToggle:
	pullp 	p3 													; restore P3 and exit
	xppc 	p3

; ****************************************************************************************************************
;
;							Set the bottom program address to the value in variable '&'
;
; ****************************************************************************************************************

NewProgram:
	pushp 	p3
	lpi 	p3,Variables 										; point P3 to & variable.
	ldi 	0 													; reset is program running flag
	st 		IsRunningProgram-Variables(p3)
	ld  	('&' & 0x3F)*2(p3) 									; read low value of P3
	st 		ProgramBase-Variables(p3) 							; copy into program base
	xae 														; save in E
	ld  	('&' & 0x3F)*2+1(p3) 								; read high value of P3
	st 		ProgramBase+1-Variables(p3) 						; copy into program base
	xpah 	p3 													; put into P3.H
	lde 														; put low address into P3.L
	xpal 	p3
	ldi 	0
	st 		(p3) 												; put a $00 there, indicating line length = 0 final line.
	pullp 	p3
	xppc 	p3 													; return
