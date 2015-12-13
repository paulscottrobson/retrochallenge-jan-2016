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
	ld 		@3(p1) 												; skip over length and line number.
	jz 		__EX_ExecuteExit 									; if length was zero already at top.
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
	jmp 	__EX_LeaveExecution

__ES_LegalAssignment:
	ld 		(p1) 												; get ASCII character code.
	ani 	0x40 												; look at bit $40. 
	jnz 	__ES_NotSpecial 									; if set, it is @A-Z range so can't be "special"
	lpi 	p3,SpecialAssignment-1 								; check for "special assignments" (see above list)
	ld 		(p1)
	xppc 	p3					
	xae 														; error code in E now (if any)
	csa 														; check return flag.
	ani 	0x80
	jnz 	__ES_NotSpecial 									; if returned CY/L = 1 didn't process it.

	lde 														; processed it, check error flag.
	jnz 	__ES_ReturnErrorA 									; if non zero return with that error code.
__EX_EndLineAndExit2:
	jmp 	__EX_EndLineAndExit 								; otherwise just find EOL and exit.
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
	csa
	jp 		__ES_ReturnErrorP3Low 								; if +ve (CY/L = 0) then error (in P3.L) occurred

	lpi 	p3,Variables 										; E(p3) points to correct variable.
	ld 		@1(p2) 												; unstack LSB
	st 		-0x80(p3)
	ld 		@1(p3) 												; bump P3 easier than bumping E :)
	ld 		@1(p2) 												; unstack MSB
	st 		-0x80(p3)
	jmp 	__EX_EndLineAndExit2 								; and done :)
;
;
;
SpecialAssignment:
	scl 														; dummy "don't process anything"
	ldi 	0 													; CY/L = 0 A = Error
	xppc 	p3

;
;
;
CheckEqualsAndEvaluate:											; check presence of '=' then call expression evaluate
	scl 														; result ok
	ldi 	1 													; fake evaluated as '57'
	st 		@-1(p2)
	ldi 	10
	st 		@-1(p2)
	xppc 	p3

;
;
;
RandomProcess:
	xppc 	p3