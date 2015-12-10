; ****************************************************************************************************************
; ****************************************************************************************************************
;
;											Execute MINOL ommand
;
;		Command at P1, Stack at P2. Preserves A,E except in Error (CY/L = 0 where A is error code).
;
; ****************************************************************************************************************
; ****************************************************************************************************************

test:db 	"GOTO 42",0

__EXExit:
	scl 														; is okay.
__EXExitNoSC:
	ld 		@1(p2) 												; restore P3
	xpal 	p3
	ld 		@1(p2)
	xpah 	p3
	ld 		@1(p2)												; restore E
	xae
	ld 		@1(p2) 												; restore A
	xppc 	p3

ExecuteCommand:
	st 		@-1(p2) 											; push A
	lde 														; push E
	st 		@-1(p2)
	xpah 	p3 													; push P3.
	st 		@-1(p2)
	xpal 	p3
	st 		@-1(p2)

__EXFirst:
	ld 		0(p1) 												; found EOS 
	jz 		__EXExit 											; exit, empty string.
	ld 		@1(p1) 												; fetch and skip over
	xri 	' ' 												; is it space ?
	jz 		__EXFirst 											; keep going.
	xri 	' '!':'												; if it is colon, then exit.
	jz 		__EXExit
	xri 	':'!'"'												; if it is quote (comment )
	jnz 	__EXCode 											; try it as a command.
;
;	Go to next command, skip forward to ':' (skip over) or End of String (\0)
;
__EXNextCommand:
	ld 		(p1)												; if 0 then end of command
	jz 		__EXExit
	ld 		@1(p1) 												; fetch and bump
	xri 	':'
	jnz 	__EXNextCommand 									; until found a colon.
__EXExit2:
	jmp 	__EXExit
;
;	Report Error in E.
;
__EX_ReportError:
	lde 														; get error code
	st 		3(p2) 												; save so returned as A
	ccl 														; clear carry
	jmp 	__EXExitNoSC 										; exit without setting CY/L

; ****************************************************************************************************************
;
;	Instructions: (in alphabetical order except LET/LIST because of default assignment statement)
;
;		CALL 	(h,l)
;		CLEAR
;		END
;		GOTO	<expr>												[TODO: FindProgramLine()]
;		NEW 	(stops running program as well)						[TODO: NewProgram()]
;		IN 		string|var,... (no spaces ???? check source)		[TODO: InCommand()]
;		IF 		<expr> [#<=] <expr> ; instruction
;		OS 		Boots to Monitor (JMP $210)
;		PR 		string|number|string const,....[;]					[TODO: OutCommand()]
;		RUN 														[TODO: RunProgram()]
;		LIST
;		[LET]	var|(h,l) = <expr>
;
;	Unimplemented:
;
;
; ****************************************************************************************************************

__EXDefaultLET:
	ld 		@-1(p1) 											; point back to start of command
	lpi 	p3,__EX_Command_LET_Optional-1						; and go to the LET code.
	xppc 	p3

__EXCode:
	ld 		0(p1) 												; check 2nd character is alphabetic
	ani 	64 													; if it 
	jz 		__EXDefaultLET 										; if it isn't try for a default LET.

	lpi 	p3,__EXSkipCharacters-1 							; character/space skipping routine
	ld 		-1(p1) 												; reload character for decoding.
	xri 	'C'
	jnz 	__EX_Decode_NotC									; check if it is C(A)LL or C(L)ear
	ld 		0(p1) 												; get next character
	xri 	'A'
	jz 		__EX_Command_CALL

; ****************************************************************************************************************
;									CLEAR command. Clear all variables.
; ****************************************************************************************************************

__EX_Command_CLEAR:
	lpi 	p3,Variables 										; point P3 to variables
	ldi 	26 													; clear 26 (28 to clear RNG Seed ????)
	st 		-1(p2)
__EX_CLEAR_Loop:
	ldi 	0 													; clear and bump pointer
	st 		@1(p3)
	dld 	-1(p2) 												; do it 26 times.
	jnz 	__EX_CLEAR_Loop
	jmp 	__EXNextCommand 									; next command.

; ****************************************************************************************************************
;				CALL (h,l) Calls machine code routine at (H,L) where h,l are any two expressions.
; ****************************************************************************************************************

__EX_Command_CALL:
	ldi 	3 													; skip 'A' 'L' 'L' and spaces.
	xppc 	p3
	lpi 	p3,ReadHLMemoryFull-1 								; read the (h,l)
	xppc 	p3 
	xae
	csa 
__EX_ReportErrorIfPositive:
	jp 		__EX_ReportError 									; if CY/L = 0 then error.
	ld 		-2(p2) 												; read L
	xpal 	p3
	ld 		-1(p2) 												; read H
	xpah 	p3
	ld 		@-1(p3) 											; fix up for pre-increment
	xppc 	p3
	jmp 	__EXNextCommand										; next command.

__EXExit3:
	jmp 	__EXExit2

__EX_Decode_NotC:
	xri 	'C'!'E'												; check for E(ND)
	jnz 	__EX_Decode_NotE

; ****************************************************************************************************************
;											END end running program
; ****************************************************************************************************************

__EX_Command_END:
	lpi 	p3,CurrentLine 										; set current line to zero.
	ldi 	0
	st 		(p3)
__EX_END_EndOfLine:
	ld 		@1(p1) 												; keep going till find NULL EOL marker
	jnz 	__EX_END_EndOfLine
	ld 		@-1(p1) 											; point back to the EOS
__EXNextCommand2:
	jmp 	__EXNextCommand 									; and do next command, in this case will be input :)


__EX_Decode_NotE:
	xri 	'E'!'G'												; check for G(OTO)
	jnz 	__EX_Decode_NotG

; ****************************************************************************************************************
;										 GOTO <expr> transfer control
; ****************************************************************************************************************

__EX_Command_GOTO:
	ldi 	3 													; skip O T O
	xppc 	p3
	lpi 	p3,EvaluateExpression-1 							; get line number to GOTO ... to :)
	xppc 	p3
	xae 														; save in E
	csa
	jp 		__EX_ReportErrorIfPositive							; error in expression.

	lpi 	p3,FindProgramLine-1 								; Find program line.
	lde 														; with that number.		
	xppc 	p3 												
	csa 
	jp 		__EX_GOTO_NotFound 									; if CY/L = 0 then not found.

	lpi 	p3,CurrentLine
	lde  														; save current line number
	st 		(p3)
	xpah 	p1 													; save P1 returned from line find in Current address
	st 		CurrentAddr-CurrentLine(p3)
	xpah 	p1
	xpal 	p1
	st 		CurrentAddr-CurrentLine(p3)
	xpal 	p1
__EXExit4:
	jmp 	__EXExit3 											; exit, don't skip over.

__EX_GOTO_NotFound:
	ldi 	ERROR_Label 
__EX_ReportErrorA:
	xae
__EX_ReportErrorE:
	ldi 	0 													; makes P for jump tests which are JP.
	jmp 	__EX_ReportErrorIfPositive

__EX_Decode_NotG:
	xri 	'G'!'N'												; check if N(EW)
	jnz 	__EX_Decode_NotN

; ****************************************************************************************************************
;								NEW Erase current program, and stop if running
; ****************************************************************************************************************

__EX_Command_NEW:
	ld 		0(p1) 												; check actually NEW as this is important !
	xri 	'E' 												; check E
	jnz 	__EX_NEW_Syntax
	ld 		1(p1)	
	xri 	'W'													; check W
	jnz 	__EX_NEW_Syntax
	lpi 	p3,NewProgram-1 									; call the NEW routine.
	xppc 	p3
	jmp 	__EX_Command_END 									; END program.

__EX_NEW_Syntax:												; come here if test for NEW fails, report syntax
	ldi 	ERROR_Syntax										; error - only this command is fully decoded.
	jmp 	__EX_ReportErrorA

__EXNextCommand3:
	jmp 	__EXNextCommand2

__EX_Decode_NotN:
	xri 	'N'!'I' 											; check for IF and IN.
	jnz 	__EX_Decode_NotI
	ld 		0(p1)												; look at next.
	xri 	'F'
	jz 		__EX_Command_IF

; ****************************************************************************************************************
;										IN <variable>.... ; input
; ****************************************************************************************************************

__EX_Command_IN:
	ldi 	1 													; skip over 1 character (N) and spaces
	xppc 	p3
	lpi 	p3,InCommand-1 										; handled via another source file.
	xppc 	p3
	xae 														; save error code.
	csa 														; check for error.
	jp 		__EX_ReportErrorE 									; if occurred, report it.
	jmp 	__EXNextCommand3

__EXExit5:
	jmp 	__EXExit4

; ****************************************************************************************************************
;									IF <expr> [#<=] <expr> ; conditional
; ****************************************************************************************************************

__EX_Command_IF:
	ldi 	1 													; skip over 1 character (F) and spaces
	xppc 	p3
	lpi 	p3,EvaluateExpression-1 							; get LHS of expression
	xppc	p3
	xae 														; save in E
	csa 														; if error occured, report it.
	jp 		__EX_ReportErrorE
	ld 		(p1) 												; get the condition
	xri 	'#'
	jz 		__EX_IF_LegalTest
	xri 	'#'!'<'
	jz 		__EX_IF_LegalTest
	xri 	'<'!'='
__EX_NEW_Syntax_NZ2:
	jnz 	__EX_NEW_Syntax 									; this reports a syntax error
;
;	Now we have a legal left side, and a valid comparison =,#,or <
;
__EX_IF_LegalTest:
	ld 		@1(p1) 												; re-read condition and bump pointer
	st 		@-1(p2) 											; save on stack
	lde 														; save left hand side of comparison on stack
	st 		@-1(p2) 	
	lpi 	p3,EvaluateExpression-1 							; and evaluate the RHS.
	xppc 	p3
	xae 														; result in E
	ld 		@2(p2) 												; fix the stack back up.
	csa 														; check for error
__EX_ReportErrorE_P:
	jp 		__EX_ReportErrorE 									; we have got Left -2(p2) and operator -1(p2) and right (E)
	ld 		-1(p2) 												; check if operator is <
	xri 	'<'
	jz 		__EX_IF_LessThan
	ld 		-2(p2) 												; XOR the two values together
	xre 			
	jz 		__EX_IsEqual
	ldi 	0x08
__EX_IsEqual:													; at this point, A = 8 (different) A = 0 (equal)
	xae 														; put in E (8 different, 0 same)
	ld 		-1(p2) 												; get operator.
	ani 	0x08 												; # => $23 : = => $3D so A = 0 (for #) 8 (for =)
	xre 														; if A = 0, E = 8 equal and = test and vice versa
	jz 		__EXNextCommand3 									; so the XOR will be non zero, so this is pass
__EX_IF_Succeed:
	ld 		0(p1)												; look at next character
	xri 	';'													; error if not semicolon.
	jnz 	__EX_NEW_Syntax
	ld 		@1(p1)												; skip over it.
__EXExit6:
	jmp 	__EXExit5 											; just exit , ready to do the 'success' code.

__EX_IF_LessThan:
	ld 		-2(p2) 												; get left
	scl 														; subtract right
	cae
	csa 														; CY/L = 0 if succeeded.
	jp 		__EX_IF_Succeed
__EXNextCommand4:
	jmp 	__EXNextCommand3 									; failed.

__EX_NEW_Syntax2:
	jmp 	__EX_NEW_Syntax

__EX_Decode_NotI:
	xri 	'I'!'O'												; check for O
	jnz 	__EX_Decode_NotO

; ****************************************************************************************************************
;											OS Boot Monitor
; ****************************************************************************************************************

__EX_Command_OS:
	ld 		0(p1) 												; check it is OS
	xri 	'S'
	jnz		__EX_NEW_Syntax_NZ2
	lpi 	p3,MonitorBoot-1 									; boot to monitor
	xppc 	p3

__EX_Decode_NotO:
	xri 	'O'!'P' 											; check for P
	jnz 	__EX_Decode_NotP

; ****************************************************************************************************************
;										PR items .... [;] Print
; ****************************************************************************************************************

__EX_Command_PR:
	ldi 	1 													; skip R
	xppc 	p3
	lpi 	p3,OutCommand-1 									; handled via another source file.
	xppc 	p3
	xae 														; save error code.
	csa 														; check for error.
	jp 		__EX_ReportErrorE_P 								; if occurred, report it.
	jmp 	__EXNextCommand4									; otherwise, try again.

__EX_Decode_NotP:
	xri 	'P'!'R'
	jnz 	__EX_Decode_NotR

; ****************************************************************************************************************
;											RUN Run Program
; ****************************************************************************************************************

__EX_Command_RUN:
	lpi 	p3,RunProgram-1 									; run program, set everything up
	xppc 	p3
	jmp 	__EXExit6

__EX_Decode_NotR:												; finally check for L.
	xri 	'R'!'L'
	jnz 	__EX_Command_LET_Optional
	ld 		0(p1)												; look at next
	xri 	'E'													; is it LE
	jz 		__EX_Command_LET

; ****************************************************************************************************************
;											LIST List Program
; ****************************************************************************************************************

__EX_Command_LIST:
	lpi 	p3,ListProgram-1
	xppc 	p3
	jmp 	__EXNextCommand4

; ****************************************************************************************************************
;								LET var = expr assignment, LET optional
; ****************************************************************************************************************

__EX_Command_LET:
	ldi 	2													; skip over E and T
	xppc 	p3
__EX_Command_LET_Optional:										; analyse to look for a LET.
	ld 		0(p1)
	jz 		__EX_NEW_Syntax

wait2:	jmp 	wait2


; ****************************************************************************************************************
;							Skip A characters from P1, and any subsequent spaces.
; ****************************************************************************************************************

__EXSkipCharacters:
	st 		-1(p2)												; save number to skip
__EXSkipOne:
	ld 		(p1) 												; end skip if ASCIIZ end of string
	jz 		__EXSkipExit
	ld 		@1(p1)												; advance by one.
	dld 	-1(p2)												; done all of them
	jnz 	__EXSkipOne											; no, keep going
__EXSkipSpace:
	ld 		(p1)												; now skip over any spaces, 
	jz 		__EXSkipExit										; check if end of string
	ld 		@1(p1)												; get next char
	xri 	' '													; and loop back if space
	jz 		__EXSkipSpace
	ld 		@-1(p1)												; unpick final non-space bump.
__EXSkipExit
	xppc 	p3

