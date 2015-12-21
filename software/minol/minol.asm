; ****************************************************************************************************************
; ****************************************************************************************************************
;
;												Minol ROM Image
;
; ****************************************************************************************************************
; ****************************************************************************************************************

	cpu 	sc/mp

	include source\memorymacros.asm 							; Memory allocation and Macro definition.	

; ****************************************************************************************************************
;													Main Program
; ****************************************************************************************************************

	org 	0x9000 												; the ROM starts here

	db 		0x68												; this makes it boot straight into this ROM.
	lpi 	p2,0xFF8											; set up stack default value

	lpi 	p3,Print-1 											; clear screen
	ldi 	12
	xppc 	p3
	lpi 	p3,Variables
	ldi 	codeStart & 255										; set where the program code is.
	st 		ProgramBase-Variables(p3)
	ldi 	codeStart / 256
	st 		ProgramBase+1-Variables(p3)
	ldi 	0 													; not running a program
	st 		IsRunning-Variables(p3)
		
	setv 	'C',10 												; give some variables default values.
	setv 	'D',20
	setv 	'Z',33

	lpi 	p1,CodeStart+2 										; first actual code.
	lpi 	p3,ExecuteStatement-1
	xppc 	p3

stop:jmp 	stop

	include source\screen.asm 									; screen I/O stuff.
	include source\errors.asm 									; errors
	include source\expression.asm 								; expression evaluator (e.g. RHS)

	include source\statement.asm 								; statement executor.



