; ****************************************************************************************************************
; ****************************************************************************************************************
;
;													OS Command
;	
; ****************************************************************************************************************
; ****************************************************************************************************************

CMD_OS:
	lpi 	p3,BootOS-1
	xppc 	p3
	jmp 	CMD_OS-2