; ****************************************************************************************************************
; ****************************************************************************************************************
;
;								Try to extract integer into E. CY/L = 0 Error, P1 data
;	
; ****************************************************************************************************************
; ****************************************************************************************************************

GetConstant:
	ldi 	0 													; number of characters read, push on stack.
	st 		@-1(p2)
	xae 														; reset initial value.
GCO_Loop:
	ld 		@1(p1) 												; get and bump
	xri 	' '													; skipping over spaces
	jz 		GCO_Loop
	ld 		@-1(p1) 											; get character undoing bump.
	ccl
	adi 	255-'9'												; check range 0-9.
	jp 		GCO_Exit
	adi 	128+10
	jp 		GCO_Exit

	ccl
	lde 														; A = E 														
	ade 														; A = E * 2
	ade 														; A = E * 3
	ade 														; A = E * 4
	ade 														; A = E * 5
	xae 														; E = E * 5
	ld 		@1(p1) 												; get character and bump over.
	ani 	0x0F 												; make number
	ccl
	ade 														; add E * 5 twice.
	ade
	xae 														; back in E
	ild 	(p2)												; bump count.
	jmp 	GCO_Loop											; try next.
;
GCO_Exit:
	ld 		@1(p2)												; get count.
	ccl
	adi 	255 												; CY/L will be set if one or more characters read in
	csa 														; A contains CY/L flag now
	xppc 	p3 													; return.
	