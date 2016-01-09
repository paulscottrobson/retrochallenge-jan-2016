; ****************************************************************************************************************
; ****************************************************************************************************************
;
;												GOTO and RUN
;	
; ****************************************************************************************************************
; ****************************************************************************************************************

	jmp 	CRG_Over											; Skip over this command.

; ****************************************************************************************************************
;												GOTO command
; ****************************************************************************************************************

CMD_Goto:	
	xppc 	p3 													; evaluate the line number to GOTO, in E
	jp 		CRG_Over 											; exit if error occurred
	lde 														; get line number
	st 		-1(p2) 												; save below TOS.
	lpi 	p1,ProgramBase 										; point P1 to program Base.
CRG_Find:
	ld 		0(p1) 												; look at offset
	jp 		CRG_NotEnd											; if -ve then end of program.
	ldi 	ERRC_Label 											; return label error
	xae
	ccl 														; set error flag
	jmp 	CRG_Over
;
CRG_NotEnd:
	xae 														; offset in E
	ld 		1(p1) 												; get line number
	xor 	-1(p2) 												; go back if not required one.
	jz 		CRG_ExecuteFromP1									; if found, run from P1.
	ld 		@-0x80(p1) 											; go to next line
	jmp 	CRG_Find 											; keep trying.
;
; ****************************************************************************************************************
;												RUN command
; ****************************************************************************************************************

CMD_Run:	
	lpi 	p1,ProgramBase 										; start from first line of program
CRG_ExecuteFromP1:
	jmp 	CheckLastCommandThenExecute 						; check if the last command and if not execute.

CRG_Over:
