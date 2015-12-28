; ****************************************************************************************************************
; ****************************************************************************************************************
;
;									# : Goto line number, optional return.
;
; ****************************************************************************************************************
; ****************************************************************************************************************

	jmp 	__STGOTO_End

__ST_Goto:
	xppc 	p3 													; check for '='
	jp 		__STGOTO_End 										; if error, end.
	xppc 	p3 													; evaluate rhs and push result
	ld 		@2(p2) 												; unstack the result and saved space
	csa 														; end if there was an error.
	jp 		__STGOTO_End
	ld 		-1(p2) 												; if the result is zero
	or 		-2(p2) 												; then exit, CY/L is set from the expression evaluator
	jz 		__STGOTO_End

	lpi 	p3,Variables 										; copy current line number + 1 to ! (return address)
	ccl
	ld 		('#' & 0x3F)*2(p3) 
	adi 	1
	st 		('!' & 0x3F)*2(p3) 
	ld 		('#' & 0x3F)*2+1(p3) 
	adi 	0
	st 		('!' & 0x3F)*2+1(p3) 

	ld 		ProgramBase-Variables(p3) 							; put program base address into P1.
	xpal 	p1
	ld 		ProgramBase-Variables+1(p3)
	xpah 	p1

__STGOTO_Search:												; look for line #
	ld 		(p1) 												; read offset.
	jz 		__STGOTO_Found 										; if offset is zero goto end of program (P1)
	xae 														; save offset in E

	scl
	ld 		1(p1) 												; calculate current# - required but not worried about
	cad 	-2(p2) 												; the actual answer.
	ld 		2(p1)
	cad 	-1(p2)

	csa 														; look at carry flag
	ani 	0x80
	jnz 	__STGOTO_Found 										; if set then current# >= required#
	ld 		@-0x80(p1)											; use auto index to go to next one
	jmp 	__STGOTO_Search

__STGOTO_Found:
	scl
	jmp 	ExecuteNextStatement 								

__STGOTO_End: