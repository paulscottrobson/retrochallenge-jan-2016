

; ****************************************************************************************************************
;							Find Program Line A, P1 points to it CY/L = 0 = not found
; ****************************************************************************************************************

FindProgramLine:	
	ccl 														; A Line # -> P1 start of line. CY/L = 0 = error.		
	xppc 	p3

; ****************************************************************************************************************
;											Erase the Program Completely
; ****************************************************************************************************************

NewProgram:
	xppc 	p3
