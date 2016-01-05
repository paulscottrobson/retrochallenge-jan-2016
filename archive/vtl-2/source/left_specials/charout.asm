; ****************************************************************************************************************
; ****************************************************************************************************************
;
;												$ : Character Output
;
; ****************************************************************************************************************
; ****************************************************************************************************************

	jmp 	__STCHO_End

__ST_CharacterOut:
	xppc 	p3 													; check for '='
	jp 		__STCHO_End 										; if error, end.
	xppc 	p3 													; evaluate rhs
	ld 		@2(p2) 												; unstack the result.
	csa 														; end if there was an error.
	jp 		__STCHO_End
	lpi 	p3,Print-1 											; get print routine ptr
	ld 		-2(p2) 												; read the byte
	xppc 	p3 													; and print it.
	scl 														; no error occurred.
	
__STCHO_End: