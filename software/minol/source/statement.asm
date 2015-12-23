; ****************************************************************************************************************
; ****************************************************************************************************************
;
;										Statement Execution
;	
; ****************************************************************************************************************
; ****************************************************************************************************************

codeStart:
	code 	1,"GOTO 10"
	code 	2,"OS"
	code 	4,"NEW"
	code 	10,"END:CALL (2,144):CLEAR"
	db 		0 													; 0 length means end of program.	

; ****************************************************************************************************************
;
;											Execute statement at P1.
;
; ****************************************************************************************************************

ExecuteStatement:
	ld 		@1(p1) 												; look at character at P1 and bump
	jz 		__ES_EndOfLine 										; end of line.
	xri 	':'													; skip over ':'
	jz 		ExecuteStatement
	xri 	':'!' '												; skip over space.
	jz 		ExecuteStatement
	xri 	' '!'"'												; is it a comment ?
	jnz 	__ES_LookUpCommand 									; no, go figure out what to do.
;
;	Comment
;
__ES_Comment:
;
;	We have reached the end of the line - if running, go to next line, stopping if we have reached the 
; 	end of the code.
;
__ES_EndOfLine:
	lpi 	p3,IsRunning 										; reached end of line
	ld 		(p3)												; read the "is running" flag
	jz 		__ES_GoCommandLine 									; if not running, go to the command line.
	ld 		(p1) 												; look at next byte
	jz 		__ES_GoCommandLine 									; if zero, end of program code, so stop.
	ld 		1(p1) 												; read the line number
	st 		CurrentLine-IsRunning(p3) 							; save it in current line variable
	ld 		@2(p1) 												; skip over length and current line
	jmp 	ExecuteStatement 									; and execute the statement.
;
;	Program has stopped, so go to the command line.
;
__ES_GoCommandLine:
	lpi 	p3,IsRunning
	ldi 	0 													; clear the "Is Running" flag to zero.
	st 		(p3)
	st 		CurrentLine-IsRunning(p3) 							; clear the current line to zero.
	lpi 	p3,CommandInput-1									; and go to the command line input routine.
	xppc 	p3
;
;	Error E has occurred.
;
__ES_Error:
	lpi 	p3,Print-1 											; print "!ERR "
	lpi 	p1,__ES_Msg1
	ldi 	0
	xppc 	p3
	lde 														; print Error Code
	xppc	p3
	ldi 	0 													; print " AT "
	xppc 	p3
	st 		@-1(p2) 											; push line number on the stack.
	lpi 	p3,CurrentLine
	ld 		(p3)
	st 		@-1(p2)
	lpi 	p3,OSMathLibrary-1 									; convert to ASCII
	lpi 	p1,KeyboardBuffer+8
	ldi 	'$'
	xppc 	p3 
	lpi 	p3,Print-1 											; print it 
	ldi 	0
	xppc 	p3
	jmp 	__ES_GoCommandLine
;
;	Come here after executing statement to decide what to do next, depending on CY/L value.
;	
__ES_CheckResult:
	csa 														; get status
	jp 		__ES_Error 											; if CY/L = 0 then error E occurred
	jmp 	ExecuteStatement 									
;
;	P1+1 is the current command, figure out what it is and do it.
;
__ES_LookUpCommand:
	ld 		@-1(p1) 											; put first character in 'E' register
	xae 														; speeds look up slightly.
	lpi 	p3,__ES_Lookup 										; P3 is lookup table.
__ES_Search:
	ld 		@5(p3) 												; read first letter and skip forward 5
	jz 		wait7 												; end of table
	xre 														; is the first character ?
	jnz 	__ES_Search 										; no, do next character.
	ld 		-4(p3) 												; get second character
	xor 	1(p1) 												; compare against 2nd char of command
	jnz 	__ES_Search 										; different, try the next one.
	ld 		@2(p1) 												; skip over first two characters
	ld 		-3(p3) 												; get the number to skip
	jz 		__ES_SkipSpace 										; if zero, already done it.
	st 		-1(p2) 												; characters to skip after first two
__ES_Skip:
	ld 		@1(p1) 												; read character
	jz 		__ES_SkipSpace 										; if \0 reached end of command which is allowed.
	dld 	-1(p2) 												; skip over requisite number of characters
	jnz 	__ES_Skip
__ES_SkipSpace:
	ld 		@1(p1) 												; skip over spaces
	xri 	' '
	jz 		__ES_SkipSpace
	ld 		@-1(p1)												; undo the fetch.
	ld 		-2(p3) 												; get low jump address to E
	xae 
	ld 		-1(p3) 												; get high jump address to P3.H
	xpah 	p3
	lde 														; E -> P3.L
	xpal 	p3
	xppc 	p3 													; and go there.

wait7:
	jmp 	wait7

; ****************************************************************************************************************
;
;	include statements. All these end by having CY/L = 0 = error (code E) or CY/L = 1 (ok) and jumping back
;	to two before their own start.  This automatically chains the jumps back.
;
; ****************************************************************************************************************

	jmp 	__ES_CheckResult 									; come back here, check what happened, last in chain.

	include commands\clear.asm									; CLEAR
	include commands\call.asm 									; CALL
	include commands\end.asm 									; END and NEW
	include commands\os.asm 									; OS
	include commands\rungo.asm 									; RUN and GOTO 

; TODO: LIST, LET, IF, PR, IN 

; ****************************************************************************************************************
;
;	lookup table. This is the lookup and dispatch table for commands, which are differentiated by the first two
; 	letters only, though the full entry is expected, e.g. for CLEAR you can have CLxxx where xxx is anything.
;
;	This table should be roughly sorted by use.
;
; ****************************************************************************************************************

command macro twoChar,length,address
	db 		twoChar,length-2
	dw 		address-1
	endm

__ES_Lookup:
	command 	"GO",4,CMD_GOTO 								; GOTO command.
	command 	"CA",4,CMD_CALL 								; CALL command.
	command 	"CL",5,CMD_CLEAR 								; CLEAR command.
	command 	"RU",3,CMD_RUN									; RUN command.
	command 	"EN",3,CMD_END 									; END command.
	command 	"NE",3,CMD_NEW 									; NEW command
	command 	"OS",2,CMD_OS 									; OS command.
	db 			0

__ES_Msg1: 														; messages
	db 		"!ERR ",0
	db 		" AT ",0