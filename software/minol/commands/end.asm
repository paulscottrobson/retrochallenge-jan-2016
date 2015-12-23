; ****************************************************************************************************************
; ****************************************************************************************************************
;
;													END Command
;	
; ****************************************************************************************************************
; ****************************************************************************************************************

CMD_NEW:
	lpi 	p3,ProgramBase 										; read in program base to P1.
	ld 		0(p3)
	xpal 	p1
	ld 		1(p3)
	xpah 	p1
	ldi 	0 													; set first length byte to $00
	st 		(p1)

CMD_END:
	ld 		@1(p1) 												; look for terminating 0, end of line
	jnz 	CMD_END
	ld 		@-1(p1) 											; unpick bump so P1 pointing to terminating NULL
	lpi 	p3,Variables 
	ldi 	0
	st		IsRunning-Variables(p3) 							; zero running flag and current line.
	st 		CurrentLine-Variables(p3)
	scl 														; result is okay.
	jmp 	CMD_NEW-2
