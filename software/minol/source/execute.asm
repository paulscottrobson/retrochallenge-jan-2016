; ****************************************************************************************************************
; ****************************************************************************************************************
;
;										Instruction Execution
;	
; ****************************************************************************************************************
; ****************************************************************************************************************

; ****************************************************************************************************************
;							Source codes for execution, with skip-over go here
; ****************************************************************************************************************

	include source\commands\os.asm 								; OS
	include source\commands\list.asm 							; LIST
	include source\commands\new_end.asm 						; NEW and END
	include source\commands\input.asm 							; IN<put>
	include source\commands\clear.asm							; CLEAR
	include source\commands\print.asm 							; PR<int>
	include source\commands\call.asm 							; CALL
	include source\commands\let.asm 							; LET (optional, but slower if not present)
	include source\commands\if.asm								; IF
	include source\commands\goto_run.asm						; GOTO and RUN (has to be last, probably !)

; ****************************************************************************************************************
;								Command execution complete, check for error
; ****************************************************************************************************************

EndOfCommandExecution:
	csa 														; check CY/L error flag
	jp 		GotoCommandLine 									; if CY/L = 0 error so go to command line.

; ****************************************************************************************************************
;	Come here to execute the instruction P1 points to, after having executed, e.g. skips forward to : or NULL
; ****************************************************************************************************************

ExecuteNextInstruction:
	ld 		@1(p1) 												; get next and skip
	jz 		CheckLastCommandThenExecute							; if NULL, check if running mode and continue if so.
	xri 	':'
	jnz 	ExecuteNextInstruction 								; keep going until colon read.
	jmp 	ExecuteFromAddressDirect 							; run code from the address given.
;
;	Test to see if the line is not the last one (e.g. offset is +ve) and if so, execute its code.
;
CheckLastCommandThenExecute:
	ld 		(p1) 												; look at the offset to next.
	jp 		ExecuteFromCommandStart 							; if +ve value, execute the line here.
;
;	Have reached the end of the program. The buffer with typed commands has $FF on the end to 'fake' this.
; 	e.g. when it reaches the end of that command it thinks it's dropped off the top of the program
;
	scl 														; there is no error.
	ldi 	ERRC_End 											; set the error code to "End"
	xae
GotoCommandLine: 												; return to Command Line with CY/L = error and E = code
	lpi 	p3,ConsoleStart-1
	xppc 	p3
;
;	Syntax error comes here.
;
SyntaxError:
	ldi 	ERRC_Syntax
	xae
	ccl
	jmp 	GotoCommandLine

; ****************************************************************************************************************
;	  Execute from the instruction at P1 (preceded by offset, line number), which is known to be a valid line.
; ****************************************************************************************************************

ExecuteFromCommandStart:
	lpi 	p3,CurrentLine 										; point P3 to the current line
	ld 		1(p1) 												; read the line number 
	st 		(p3)												; and save it - current line # updated.
	ld 		@2(p1) 												; skip over offset (+0) line number (+1)

; ****************************************************************************************************************
;				Run command where the instruction is at P1 (e.g. it is an ASCIIZ string)
; ****************************************************************************************************************

ExecuteFromAddressDirect:
	ld 		@1(p1) 												; read next character
	jz 		CheckLastCommandThenExecute 						; if \0 then check for the next line.
	xri	 	' '
	jz 		ExecuteFromAddressDirect 							; skip over spaces.
	xri 	' '!':'												
	jz 		ExecuteFromAddressDirect 							; skip over colons.
	xri 	':'!'"'					
	jz 		ExecuteNextInstruction 								; if double quote (comment) found go to next instruction.
;
;	Now look the command up in the command list.
;
	ld 		-1(p1) 												; read first character of command again
	xae 														; put in E.
	lpi 	p3,CommandList
EAFD_Search:
	ld 		@5(p3) 												; read first character and bump to next.
	jz 		EAFD_LETCode 										; if zero then give up.
	xre 														; same as first character ?
	jnz		EAFD_Search 										; no, keep looking.

	ld 		-4(p3) 												; read 2nd character
	xor 	(p1) 												; compare against actual second character
	jnz 	EAFD_Search
;
;	Skip over characters in the command, checking for NULL and : which would be syntax errors.
;
	ld 		-3(p3) 												; number of characters to skip (one less than total as one skipped)
	st 		-1(p2) 												; temporary count.
EAFD_Skip:
	ld 		@1(p1) 												; read a character and skip
	jz 		SyntaxError 										; if zero, then syntax error
	xri 	':'
	jz 		SyntaxError 										; if colon, then syntax error.
	dld 	-1(p2) 												; do it the requisite number of times.
	jnz 	EAFD_Skip
;
;	Skip over any subsequent spaces
;
EAFD_SkipSpaces:
	ld 		@1(p1) 												; check for spaces
	xri 	' '													; space found
	jz 		EAFD_SkipSpaces
	ld 		@-1(p1) 											; undo last fetch so first character of next bit.
;
;	P1 is set up so execute the handler.
;
	ld 		-2(p3)												; get execute LSB
	xae 														; save in E
	ld 		-1(p3) 												; get execute MSB
	xpah 	p3 													; put in P3.H
	lde 														; copy E to P3.L
	xpal 	p3
	xppc 	p3
	jmp 	EvaluateExpression 									; is set up to have immediate evaluate call.
;
;	Couldn't find a command, so point P1 to first character, then call the LET code.
;
EAFD_LETCode:
	ld 		@-1(p1) 											; point P1 to first character of command.
	lpi 	p3,CMD_Let-1 										; go execute LET with evaluate re-entrancy
	xppc 	p3
	jmp 	EvaluateExpression

	include source\expression.asm 								; expression evaluator.

; ****************************************************************************************************************
;		Command look up table - should be ordered by degree of usage, and OS things (e.g. LIST) at the end
; ****************************************************************************************************************

CommandList:
	cmd 	'L','E',3,CMD_Let 									; LET var|(h,l) = <expr>
	cmd 	'I','F',2,CMD_If 									; If [expr][=|#|<][expr]; [statement]
	cmd 	'G','O',4,CMD_Goto									; GOTO [line number]
	cmd 	'C','A',4,CMD_Call									; CALL (high,low)
	cmd 	'P','R',2,CMD_Print 								; PRINT ["<text>"|<expr>|$(h,l)][,....][;]
	cmd 	'C','L',5,CMD_Clear									; CLEAR
	cmd 	'I','N',2,CMD_In 									; IN [l-expr],$(H,L)
	cmd 	'E','N',3,CMD_End 									; END
	cmd 	'N','E',3,CMD_New 									; NEW
	cmd 	'R','U',3,CMD_Run									; RUN
	cmd 	'L','I',4,CMD_List 									; LIST
	cmd 	'O','S',2,CMD_OS 									; OS
	db 		0

; Done:	GOTO, RUN, CLEAR, NEW, END, OS, CALL, LET (and optional version),IF, LIST., PR
; Not Done: IN