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
;									 Delete the line at TOS. Does not change TOS.
;
; ****************************************************************************************************************
; ****************************************************************************************************************

DeleteCodeLine:
	pushp 	p3 													; save P3 on stack.

	lpi 	p3,Variables 										; point P3 to the variables.
	ld 		ProgramBase-Variables(p3) 							; load P1 with program base
	xpal 	p1
	ld 		ProgramBase-Variables+1(p3)
	xpah 	p1
__DCL_Search:
	ld 		(p1) 												; read offset to next
	jz 		__DCL_Exit 											; if zero, line not found, drop through
	xae 														; save offset in E
	ld 		1(p1) 												; check if line found (LSB first)
	xor 	2(p2)
	jnz 	__DCL_Next
	ld 		2(p1) 												; then MSB
	xor 	3(p2)
	jz 		__DCL_Copy 											; if found, then start deletion process
__DCL_Next:
	ld 		@-0x80(p1) 											; add E to P1
	jmp 	__DCL_Search 										; try next.
;
;	Found the line to delete, address in P1, offset to next in E
;
__DCL_Copy:
	ld 		-0x80(p1) 											; get E up
	st 		0x00(p1) 											; save in current slot
	ld 		@1(p1) 												; bump P1
	ld   	-1(p1) 												; keep going till copied a pair of zeros.
	or 		-2(p1)												; which marks the end of the program.
	jnz 	__DCL_Copy

__DCL_Exit:														
	jmp 	__UCT_NoPush 										; avoids PULLP P3/PUSHP P3

; ****************************************************************************************************************
; ****************************************************************************************************************
;
;			Update the value of '&' with the first free byte of memory, which is also returned in P1.
;
; ****************************************************************************************************************
; ****************************************************************************************************************

UpdateCodeTop:
	pushp 	p3 													; save return address.
__UCT_NoPush:
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
	