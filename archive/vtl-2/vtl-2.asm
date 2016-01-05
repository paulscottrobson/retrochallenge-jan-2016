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
	ldi		0x10												; set program base address.
	st 		ProgramBase-Variables+1(p3)
	xpah 	p1
	ldi		0x00
	st 		ProgramBase-Variables(p3)
	xpal 	p1 													; P1 = target address
	lpi 	p3,test												; P3 = test code
	xpal 	p1
__Copy:															; copy sample code to RAM.
	xpal 	p1
	ld 		@1(p3) 												; copy byte
	st 		@1(p1)
	xpal 	p1 													; copy one whole page.
	jnz 	__Copy 	

	lpi 	p3,UpdateCodeTop-1 									; update & with correct value
	xppc 	p3

	ldi 	300/256												; push 300 on the stack.
	st 		@-1(p2)
	ldi 	300&255
	st 		@-1(p2)

	lpi 	p3,DeleteCodeLine-1 								; delete line at TOS.
	xppc 	p3
	ld 		@2(p2) 												; throw line.

	lpi 	p3,ExecuteCodeLine-1								; direct execute # = 1
	lpi 	p1,start
	xppc 	p3

	lpi 	p3,ListProgram-1
	xppc 	p3
wait0:jmp 	wait0

test:
	code 	100,"?=\"1\""
	code 	200,"?=\"2\""
	code 	300,"?=\"3\""
	code 	400,"?=\"4\""
	code 	500,"?=\"DONE\""
	db 		0

start:
	db 		"# = 111",0

; ****************************************************************************************************************
;													Source Files
; ****************************************************************************************************************

	include source\screen.asm 									; screen I/O stuff.
	include source\statement.asm 								; statement interpreter.
	include source\listing.asm 									; program listing.
	include source\manager.asm 									; program memory management