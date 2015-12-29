; ****************************************************************************************************************
; ****************************************************************************************************************
;
;										Manages Program Space
;	
; ****************************************************************************************************************
; ****************************************************************************************************************


; ****************************************************************************************************************
; ****************************************************************************************************************
;
;			Update the value of '&' with the first free byte of memory, which is also returned in P1.
;
; ****************************************************************************************************************
; ****************************************************************************************************************

UpdateCodeTop:
	pushp 	p3 													; save return address.
	lpi 	p3,Variables 										; point P3 to the variables.
	ld 		ProgramBase-Variables(p3) 							; load P1 with program base
	xpal 	p1
	ld 		ProgramBase-Variables+1(p3)
	xpah 	p1
__UCT_Loop:
	ld 		(p1) 												; look at length byte.
	jz 		__UCT_End 											; if zero found end.
	xae 														; put in E
	ld 		@-0x80(p1) 											; go to next line.
	jmp 	__UCT_Loop 											; keep trying.
;
__UCT_End:
	ld 		@1(p1) 												; skip over the final NULL end of program byte.
	xpal 	p1 													; save P1 in & but preserve it
	st 		('&' & 0x3F) * 2(p3) 								
	xpal 	p1
	xpah 	p1
	st 		('&' & 0x3F) * 2+1(p3) 								
	xpah 	p1
	pullp 	p3 													; restore return
	xppc 	p3 