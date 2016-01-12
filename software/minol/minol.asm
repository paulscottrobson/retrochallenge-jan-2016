; ****************************************************************************************************************
; ****************************************************************************************************************
;
;												Minol ROM Image
;
; ****************************************************************************************************************
; ****************************************************************************************************************

	cpu 	sc/mp

	include source\memorymacros.asm 							; Memory allocation and Macro definition.	
	include source\errors.asm 									; Error codes

; TODO: Find real TOS
; TODO: Memory check ? 
; TODO: Break option ?
; TODO: New if not preloaded ....

; ****************************************************************************************************************
;													Main Program
; ****************************************************************************************************************

	org 	0x9000 												; the ROM starts here

	db 		0x68												; this makes it boot straight into this ROM.
	lpi 	p2,0xFF8											; set up stack default value
	lpi 	p3,Print-1
	ldi 	12
	xppc	p3

	lpi 	p3,ProgramCode 										; copy program default code to memory.
	lpi 	p1,ProgramBase
Copy1:
	ld 		@1(p3)
	st 		@1(p1)
	xri 	0xFF
	jnz 	Copy1

	lpi 	p3,Print-1											; Print Boot Message
	lpi 	p1,BootMessage
	ldi 	0
	xppc 	p3

	lpi 	p3,ConsoleStart-1 									; run the console
	scl 														; non-error (so it prints ok)
	xppc	p3

BootMessage:
	db 		"** MINOL **",13,"V0.91 PSR 2016",13,0

ProgramCode:
	code 	10,"\"TEST PROGRAM\""
	code 	20,"PR 4/2"
	code 	30,"PR 5"
	code 	40,"PR 6"
	code 	50,"PR 7:END"
	db 		255

; ****************************************************************************************************************
;													Source Files
; ****************************************************************************************************************

	include source\itoa.asm 									; print integer routine.
	include source\atoi.asm 									; decode integer routine.
	include source\screen.asm 									; screen I/O stuff.
	include source\execute.asm 									; statement exec main loop
	include source\manager.asm 									; manage program lines.
	include source\console.asm 									; console type in etc.
