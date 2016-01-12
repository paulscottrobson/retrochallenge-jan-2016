; ****************************************************************************************************************
; ****************************************************************************************************************
;
;												Console Handler
;
; ****************************************************************************************************************
; ****************************************************************************************************************

ConsoleStart:
	lpi 	p3,Print-1 
	csa 														; see if CY/L is set
	ani	 	0x80								
	jz 		CONError 											; if so, there is an error.
;
;	Print OK
;
CONOk:
	lpi 	p1,CONMsgOk 										; print OK.
	ldi 	0
	xppc 	p3
	jmp 	CONEnter

CONMsgOk:														; OK prompt.
	db 		"OK",13,0
CONMsgErr1:														; Error Message
	db 		"!ERR ",0 
	db 		" AT ",0
;
;	Print Error Message
;
CONError:
	lde 														; check if faux error
	xri 	ERRC_End
	jz 		CONOk
	lpi 	p1,CONMsgErr1										; print !ERR_ 
	ldi 	0
	xppc 	p3
	lde 														; get error code
	ori 	'0'													; make ASCII
	xppc 	p3
	ldi 	0 													; print _AT_
	xppc 	p3
	lpi 	p3,CurrentLine 										; get current line number into E.
	ld 		(p3)
	xae
	lpi 	p3,PrintInteger-1 									; print it.
	xppc 	p3
	ldi 	13 													; print new line
	xppc 	p3
;
;	Get next command.
;
CONEnter:
	lpi 	p3,GetString-1 										; get input from keyboard.
	lpi 	p1,KeyboardBuffer
	ldi 	KeyboardBufferSize
	xppc 	p3

	lpi 	p3,GetConstant-1 									; extract a constant if there is one.
	xppc 	p3
	ani 	0x80
	jnz 	CONHasLineNumber 									; if okay, has line number.
;
;	Execute a command from the keyboard.
;
CONEndOfLine:
	ld 		@1(p1) 												; find end of line
	jnz 	CONEndOfLine
	ldi 	0xFF												; put end of code marker at end of string.
	st 		(p1)
	lpi 	p1,KeyboardBuffer 	
	lpi 	p3,ExecuteFromAddressDirect-1
	xppc 	p3
;
;	Line Number - text is at P1, line number in E.
;
CONHasLineNumber:
wait8:
	jmp 	wait8
