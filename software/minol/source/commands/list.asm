; ****************************************************************************************************************
; ****************************************************************************************************************
;
;												LIST command
;	
; ****************************************************************************************************************
; ****************************************************************************************************************

	jmp		CLI_Over

CMD_List:
	lpi 	p1,ProgramBase 										; point P1 to first line.
	ldi 	0 													; clear counter. used for Speccy style list.
	st 		@-1(p2)
CLI_Loop:
	ld 		@1(p1) 												; check if finished
	ani 	0x80
	jnz 	CLI_End
	ld 		@1(p1) 												; get line number into E
	xae 
	lpi 	p3,PrintInteger-1 									; and print it.
	xppc 	p3
	ldi 	' '													; print space
	xppc 	p3
;
CLI_Line:
	ld 		@1(p1) 												; get character
	jz 		CLI_EndLine											; if zero, do next line.
	xppc 	p3 													; print it
	jmp 	CLI_Line
;
CLI_EndLine:
	ldi 	13													; new line
	xppc 	p3
	ild 	(p2) 												; bump counter
	ani 	0x03 												; stop every 3 lines
	jnz 	CLI_Loop 											; keep going.
	lpi 	p3,GetChar-1 										; get a keystroke
	xppc 	p3
	xri 	' '													; if space pressed
	jz 		CLI_Loop 											; and do next line.

CLI_End:
	ld 		@1(p2) 												; drop counter
	ldi 	ERRC_End											; fake error to end after LIST as destroys P1.
	xae
	ccl

CLI_Over:

