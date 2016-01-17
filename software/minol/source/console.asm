; ****************************************************************************************************************
; ****************************************************************************************************************
;
;												Console Handler
;
; ****************************************************************************************************************
; ****************************************************************************************************************

; ****************************************************************************************************************
;
;							Come here when a program stops running, or at the start.
;
; ****************************************************************************************************************

ConsoleStart:
	lpi 	p3,Print-1 
	csa 														; see if CY/L is set
	ani	 	0x80								
	jz 		CONError 											; if so, there is an error.

; ****************************************************************************************************************
;													Print OK
; ****************************************************************************************************************

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
CONMsgErr2:														; Error Message
	db 		"BREAK",0 
	db 		"AT ",0


; ****************************************************************************************************************
;											   Print Error Message
; ****************************************************************************************************************

CONError:
	lpi 	p1,CONMsgErr1
	lde 														; check if faux error
	xri 	ERRC_End
	jz 		CONOk
	lde
	xri 	ERRC_Break			 								; check if BREAK
	jnz 	CONError2
	lpi 	p1,CONMsgErr2
	ldi 	' '													; makes it print space rather than code.
	xae
CONError2:
	ldi 	0
	xppc 	p3
	lde 														; get error code
	xppc 	p3
	ldi 	0 													; print _AT_
	xppc 	p3
	lpi 	p3,CurrentLine 										; get current line number into E.
	ld 		(p3)
	xae
	lpi 	p3,PrintInteger-1 									; print it.
	xppc 	p3
	lpi 	p3,Print-1
	ldi 	13 													; print new line
	xppc 	p3

; ****************************************************************************************************************
;												Get next command.
; ****************************************************************************************************************

CONEnter:
	lpi 	p3,GetString-1 										; get input from keyboard.
	lpi 	p1,KeyboardBuffer
	ldi 	0 													; clear current line # using value.
	st 		CurrentLine-KeyboardBuffer(p1)
	ldi 	KeyboardBufferSize									; input length
	xppc 	p3

	lpi 	p3,GetConstant-1 									; extract a constant if there is one.
	xppc 	p3
	ani 	0x80
	jnz 	CONHasLineNumber 									; if okay, has line number.

	ld 		(p1)												; if no text, enter again.
	jz 		CONEnter

; ****************************************************************************************************************
;									Execute a command from the keyboard.
; ****************************************************************************************************************

CONEndOfLine:
	ld 		@1(p1) 												; find end of line
	jnz 	CONEndOfLine
	ldi 	0xFF												; put end of code marker at end of string.
	st 		(p1)
	lpi 	p1,KeyboardBuffer 	
	lpi 	p3,ExecuteFromAddressDirect-1
	xppc 	p3

; ****************************************************************************************************************
;						Command has a Line Number - text is at P1, line number in E.
; ****************************************************************************************************************

CONHasLineNumber:
	lpi 	p3,DeleteLine-1 									; delete the line whose number is in E
	xppc 	p3

	ld 		(p1) 												; any text in this line ?
	jz 		CONEnter											; if not, then just do the delete (possible)

	ldi 	0													; temporarily set the line number to zero.
	st 		-1(p1)
	ldi 	2
	st 		-1(p2) 												; and reset the counter to 2 to get size right.
CONGetLength:
	ild 	-1(p2) 												; bump count
	ld 		@1(p1) 												; keep going forward till 0 read.
	jnz 	CONGetLength
	ld 		@-1(p1) 											; undo the last bump over zero

CONBackToStart:
	ld 		@-1(p1) 											; keep going back until zero.
	jnz 	CONBackToStart										; this is the line number we set to zero

	lde 														; copy line number
	st 		(p1)
	ld 		-1(p2) 												; get measured length
	st 		@-1(p1) 											; and store in the length slot.

	xppc 	p3 													; put line in using fall through insert routine.
	jmp 	CONEnter 											; and get another line.
