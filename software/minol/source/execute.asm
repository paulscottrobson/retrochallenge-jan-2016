; ****************************************************************************************************************
; ****************************************************************************************************************
;
;											Execute MINOL ommand
;
;		Command at P1, Stack at P2. Preserves A,E except in Error (CY/L = 0 where A is error code).
;
; ****************************************************************************************************************
; ****************************************************************************************************************

test:db 	"NEW:X = 42:LIST",0

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
;		GOTO	<expr>
;		NEW 	(stops running program as well)
;
;	Unimplemented:
;
;		IF 		<expr> [#<=] <expr> ; instruction
;		IN 		string|var,... (no spaces ???? check source)
;		OS 		Boots to Monitor (JMP $210)
;		PR 		string|number|string const,....[;]
;		RUN
;		LIST
;		[LET]	var|(h,l) = <expr>
;
; ****************************************************************************************************************

__EXCode:
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
	ldi 	2 													; skip N and D
	xppc 	p3 
	lpi 	p3,CurrentLine 										; set current line to zero.
	ldi 	0
	st 		(p3)
__EX_END_EndOfLine:
	ld 		@1(p1) 												; keep going till find NULL EOL marker
	jnz 	__EX_END_EndOfLine
	ld 		@-1(p1) 											; point back to the EOS
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
	jp 		__EX_ReportError									; error in expression.
	lpi 	p3,FindProgramLine-1 								; Find program line.
	lde 														; with that number.		
	xppc 	p3 												
	csa 
	jp 		__EX_GOTO_NotFound 									; if CY/L = 0 then not found.
	lpi 	p3,CurrentLine
	lde  														; save current line
	st 		(p3)
	xpah 	p1 													; save P1 from line find in Current address
	st 		CurrentAddr-CurrentLine(p3)
	xpah 	p1
	xpal 	p1
	st 		CurrentAddr-CurrentLine(p3)
	xpal 	p1
	jmp 	__EXExit3 											; exit, don't skip over.

__EX_GOTO_NotFound:
	ldi 	ERROR_Label 
__EX_ReportErrorA
	xae
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
	jnz 	__EX_NEW_NoMatch
	ld 		1(p1)	
	xri 	'W'													; check W
	jnz 	__EX_NEW_NoMatch
	lpi 	p3,NewProgram-1 									; call the NEW routine.
	xppc 	p3
	jmp 	__EX_Command_END 									; END program.

__EX_NEW_NoMatch:												; come here if test for NEW fails, report syntax
	ldi 	ERROR_Syntax										; error - only this command is fully decoded.
	jmp 	__EX_ReportErrorA

__EX_Decode_NotN:
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

