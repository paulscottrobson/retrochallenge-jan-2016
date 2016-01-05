; ****************************************************************************************************************
; ****************************************************************************************************************
;
;											* : Set RAMTOP
;
; ****************************************************************************************************************
; ****************************************************************************************************************

	jmp 	__STTOP_End

__ST_RamTop:
	xppc 	p3 													; check for '='
	jp 		__STTOP_End 										; if error, end.
	xppc 	p3 													; evaluate rhs
	ld 		@2(p2) 												; unstack the result.
	csa 														; end if there was an error.
	jp 		__STTOP_End
	ld 		-1(p2) 												; if the returned result was non zero
	or 		-2(p2)
	jnz 	__STTOP_Error 										; report as error

	lpi 	p3,BootMonitor-1 									; else crash back to monitor
	xppc 	p3

__STTOP_Error:
	ldi 	ERROR_ReadOnly										; set error to E
	xae 
	ccl 														; return with carry clear indicating error

__STTOP_End: