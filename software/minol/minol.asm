; ****************************************************************************************************************
; ****************************************************************************************************************
;
;												Minol ROM Image
;
; ****************************************************************************************************************
; ****************************************************************************************************************

	cpu 	sc/mp

	include source\memorymacros.asm 							; Memory allocation and Macro definition.	
	include source\errors.asm 									; Error Codes

; ****************************************************************************************************************
; ****************************************************************************************************************
; 	NOTE: When executing line follow the line with $FF so it thinks it has reached the program end.
; ****************************************************************************************************************
; ****************************************************************************************************************


; ****************************************************************************************************************
;													Main Program
; ****************************************************************************************************************

	org 	0x9000 												; the ROM starts here

	db 		0x68												; this makes it boot straight into this ROM.
	lpi 	p2,0xFF8											; set up stack default value
	lpi 	p3,SystemMemory

	lpi 	p3,CMD_Run-1
	xppc	p3
wait1:	
	jmp 	wait1


ProgramBase:
	code 	1,"\"START\":CLEAR:GOTO 30"
	code 	10,"HELLO WORLD"
	code 	20,"GOTO 20"
	code 	30,"LET B = 69:LET A = 42:C = A + B:END"
	code 	120,"CALL   (2,144)"
	db 		255


; ****************************************************************************************************************
;													Source Files
; ****************************************************************************************************************

	include source\screen.asm 									; screen I/O stuff.
	include source\execute.asm 									; statement exec main loop