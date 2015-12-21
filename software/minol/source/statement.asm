; ****************************************************************************************************************
; ****************************************************************************************************************
;
;										Statement Execution
;	
; ****************************************************************************************************************
; ****************************************************************************************************************

codeStart:
	code 	10,"CLEAR"
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
	jmp 	__ES_LookUpCommand 									; and go figure out what to do.
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
	lpi 	p3,__ES_GoCommandLine-1								; and go to the command line input routine.
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

	ldi 	'X'
	xae
	jmp 	__ES_Error




	jmp 	__ES_CheckResult 									; come back here, check what happened, last in chain.

; ****************************************************************************************************************
;
;	include statements. All these end by having CY/L = 0 = error (code E) or CY/L = 1 (ok) and jumping back
;	to two before their own start.  This automatically chains the jumps back.
;
; ****************************************************************************************************************

;
;	lookup table.
;

__ES_Msg1: 														; messages
	db 		"!ERR ",0
	db 		" AT ",0