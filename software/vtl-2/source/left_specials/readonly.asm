; ****************************************************************************************************************
; ****************************************************************************************************************
;
;												Read-Only Variable
;
; ****************************************************************************************************************
; ****************************************************************************************************************

	jmp 	__STROV_End

__ST_ReadOnlyVariable:
	xppc 	p3 													; check for '='
	jp 		__STROV_End 										; if error, end.
	xppc 	p3 													; evaluate rhs
	ld 		@2(p2) 												; unstack the result.
	csa 														; end if there was an error.
	jp 		__STROV_End
	ld 		-1(p2) 												; if the returned result was non zero
	or 		-2(p2)
	jnz 	__STROV_Error 										; report as error

	lpi 	p3,BootMonitor-1 									; else crash back to monitor
	xppc 	p3

__STROV_Error:
	ldi 	ERROR_ReadOnly										; set error to E
	xae 
	ccl 														; return with carry clear indicating error

__STROV_End: