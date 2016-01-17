; ****************************************************************************************************************
; ****************************************************************************************************************
;
;												PR command
;	
; ****************************************************************************************************************
; ****************************************************************************************************************

	jmp 	CPR_Over2

; ****************************************************************************************************************
;												Main printing loop
; ****************************************************************************************************************

CMD_Print:
	ldi 	0x8 												; read keyboard
	xpah 	p3
	ld 		(p3) 
	xri 	0x80+3
	jz		CPR_Break

	lpi 	p3,Print-1 											; set up P3 for printing.
	ld 		(p1)												; reached end of command, print RETURN and exit.
	jz 		CPR_EndReturn
	xri 	':'
	jz 		CPR_EndReturn
	ld 		@1(p1)												; re-read with a bump
	xri 	' '													; if space, skip it
	jz 		CMD_Print
	xri 	','!' '												; if comma, skip it.
	jz 		CMD_Print
	xri 	';'!','												; if semicolon exit without a return
	jz 		CPR_EndOk 
	xri 	'"'!';'												; if quote mark print as quoted string
	jz 		CPR_QuotedString
	xri 	'$'!'"'												; if $ print string at address.
	jz 		CPR_StringAtAddress

; ****************************************************************************************************************
;												numerical expression
; ****************************************************************************************************************

	ldi 	' '													; preceding space
	xppc 	p3
	ld 		@-1(p1)												; unpick the get, first character of expression.
	lpi 	p3,EvaluateExpression-1 							; evaluate expression
	xppc 	p3
	jp 		CPR_Over 											; exit on error.
	lpi 	p3,PrintInteger-1 									; and print it
	xppc 	p3
	lpi 	p3,Print-1
	ldi 	' '													; trailing space
	xppc 	p3
CMD_Print2:
	jmp 	CMD_Print

; ****************************************************************************************************************
;													Break 
; ****************************************************************************************************************

CPR_Break:
	ldi 	ERRC_BREAK
	xae
	ccl
CPR_Over2:
	jmp 	CPR_Over

; ****************************************************************************************************************
;												"<quoted string>"
; ****************************************************************************************************************

CPR_QuotedString:
	ld 		@1(p1) 												; get character
	jz 		CPR_Syntax 											; if NULL, syntax error.
	xri 	'"'													; if closing quote
	jz 		CMD_Print
	ld 		-1(p1)												; re-get it
	xppc 	p3 													; print it
	jmp 	CPR_QuotedString

; ****************************************************************************************************************
;									$(H,L) print string at address, ended by -ve or 0.
; ****************************************************************************************************************

CPR_StringAtAddress:
	lpi 	p3,EvaluateAddressPair-1 							; evaluate (H,L)
	xppc 	p3	
	jp 		CPR_Over											; exit on error

	ld 		@-1(p2) 											; retrieve H to P1.H
	xpah 	p1
	st 		(p2)												; and save P1.H there
	ld 		@-1(p2) 											; retrieve L to P1.L
	xpal 	p1
	st 		(p2)
	lpi 	p3,Print-1 											; set up P3 to print.
CPR_StringLoop:
	ld 		@1(p1) 												; fetch and bump character
	jz 		CPR_StringExit 										; if zero end of string
	jp 		CPR_StringPrint 									; if +ve printable character
;
CPR_StringExit:
	ld 		@1(p2)												; restore P1.
	xpal 	p1
	ld 		@1(p2)
	xpah 	p1
	jmp 	CMD_Print2 											; and print the next thing.
;
CPR_StringPrint:
	ld 		-1(p1) 												; retrieve, print and loop
	xppc 	p3
	jmp 	CPR_StringLoop

; ****************************************************************************************************************
;												Syntax Error
; ****************************************************************************************************************

CPR_Syntax:
	ldi 	ERRC_Syntax 										; set up for syntax error and exit
	xae
	ccl
	jmp 	CPR_Over

; ****************************************************************************************************************
;										Print return and end okay.
; ****************************************************************************************************************

CPR_EndReturn:
	ldi 	13													; print a carriage return.
	xppc 	p3
CPR_EndOk:														; end successfully.
	scl 														; set carry flag (no error)

CPR_Over:
	