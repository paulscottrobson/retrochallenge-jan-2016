; ****************************************************************************************************************
; ****************************************************************************************************************
;
;												CALL command
;	
; ****************************************************************************************************************
; ****************************************************************************************************************

	jmp		CCA_Over

CMD_Call:
	lpi 	p3,EvaluateAddressPair-1 							; evaluate the address pair (e.g. (H,L))
	xppc 	p3
	jp 		CCA_Over 											; exit on error.
	ld 		-2(p2) 												; retrieve the L value to E
	xae 	
	ld 		-1(p2)												; retrieve the H value to P3.H
	xpah 	p3
	lde	 														; copy L value to P3.L
	xpal 	p3
	ld 		@-1(p3) 											; fix up for pre-increment
	pushp 	p1 													; save P1
	lpi 	p1,Variables 										; and point P1 to the variables
	scl 														; set CY/L flag, so the call can return an error.
	xppc 	p3 													; call the routine
	pullp	p1 													; restore P1
	
CCA_Over: