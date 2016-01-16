; ****************************************************************************************************************
; ****************************************************************************************************************
;
;												NEW and END
;	
; ****************************************************************************************************************
; ****************************************************************************************************************

	jmp 	CNE_Over

; ****************************************************************************************************************
;						NEW (Erase program) also executes END in case in running program
; ****************************************************************************************************************

CMD_New:
	lpi 	p3,ProgramBase 										; write $FF at program base
	ldi 	0xFF
	st 		0(p3) 												; this erases the program
	ldi 	Marker1 											; write the program-code-marker out.
	st 		-4(p3)
	ldi 	Marker2
	st 		-3(p3)
	ldi 	Marker3
	st 		-2(p3)
	ldi 	Marker4
	st 		-1(p3)

; ****************************************************************************************************************
;													END program
; ****************************************************************************************************************

CMD_End:
	ccl 														; we cause an error, but it is ERRC_End which is 
	ldi 	ERRC_End 											; not an error and not reported as such.
	xae

CNE_Over: