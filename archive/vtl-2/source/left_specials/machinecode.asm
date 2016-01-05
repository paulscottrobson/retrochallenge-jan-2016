; ****************************************************************************************************************
; ****************************************************************************************************************
;
;												> : Call Machine Code
;
; ****************************************************************************************************************
; ****************************************************************************************************************

	jmp 	__STMAC_End

__ST_MachineCode:
	xppc 	p3 													; check for '='
	jp 		__STMAC_End 										; if error, end.
	xppc 	p3 													; evaluate rhs
	ld 		@2(p2) 												; unstack the result.
	csa 														; end if there was an error.
	jp 		__STMAC_End
	
	ld 		-2(p2) 												; LSB -> E
	xae
	ld 		-1(p2) 												; MSB -> P3.H
	xpah 	p3
	lde 														; E -> P3.L	
	xpal 	p3
	ld 		@-1(p3) 											; adjust for pre increment
	pushp 	p1 													; point P1 to variables
	lpi 	p1,Variables
	xppc 	p3 													; call routine
	pullp 	p1 													; restore P1
	scl 														; result ok.
	
__STMAC_End: