; ****************************************************************************************************************
; ****************************************************************************************************************
;
;												VTL-2 ROM Image
;
; ****************************************************************************************************************
; ****************************************************************************************************************

	cpu 	sc/mp

	include source\memorymacros.asm 							; Memory allocation and Macro definition.	
	include source\errors.asm 									; Error Codes

; ****************************************************************************************************************
;													Main Program
; ****************************************************************************************************************

	org 	0x9000 												; the ROM starts here

	db 		0x68												; this makes it boot straight into this ROM.
	lpi 	p2,0xFF8											; set up stack default value
	lpi 	p3,Print-1 											; clear screen
	ldi 	12
	xppc 	p3

	lpi 	p3,Variables 										; set some variables
	setv 	'C',0x1382
	setv	'&',0x1000
	setv 	'*',0x1FFF 											; check RAM - up to 4k - not assume.

	ldi 	0 													; set direct mode
	st 		IsRunning-Variables(p3)	
	ldi		test/256											; set program base address.
	st 		ProgramBase-Variables+1(p3)
	ldi		test&255
	st 		ProgramBase-Variables(p3)

	lpi 	p3,UpdateCodeTop-1 									; update & with correct value
	xppc 	p3

	lpi 	p3,ExecuteCodeLine-1								; direct execute # = 1
	lpi 	p1,start
	xppc 	p3

	lpi 	p3,ListProgram-1
	xppc 	p3
wait0:jmp 	wait0

test:
	code 	10,"?=*-&"
	code 	15,"?=\"\""
	code 	20,"K = 32"
	code 	30,"K = K + 1"
	code 	40,"$=K"
	code 	50,"# = (K < 44) * 30"
	code 	60,"?=\"DONE\""
	db 		0

start:
	db 		"# = 1",0

; ****************************************************************************************************************
;													Source Files
; ****************************************************************************************************************

	include source\screen.asm 									; screen I/O stuff.
	include source\statement.asm 								; statement interpreter.
	include source\listing.asm 									; program listing.
	include source\manager.asm 									; program memory management