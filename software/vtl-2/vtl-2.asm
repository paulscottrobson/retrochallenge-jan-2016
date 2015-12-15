; ****************************************************************************************************************
; ****************************************************************************************************************
;
;												VTL-2 ROM Image
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

	lpi 	p3,Variables
	setv 	'&',0xE03 											; set array pointer/top of memory fudge.
	ldi 	0xFF 												; sets the running flag .
	st 		-1(p3)
	ldi 	StartProgram/256
	st 		-2(p3) 												; set start program address.
	ldi 	StartProgram&255
	st 		-3(p3)
	lpi 	p2,0xFF8											; set up stack

	; TODO: Proper stack detection.
	; TODO: Proper program initialisation.

	lpi 	p1,StartProgram 									; internal code for testing
Next:
	lpi 	p3,ExecuteStatement-1 								; execute a statement
	xppc 	p3
	xae
	csa
	jp 		stop
	lpi 	p3,IsRunningProgram
	ld 		(p3)
	jnz		Next
stop:jmp 	stop

	include source\screen.asm 									; screen I/O stuff.
	include source\statement.asm 								; assignment statement (e.g. LHS)
	include source\expression.asm 								; expression evaluator (e.g. RHS)
	include source\special_terms.asm 							; RHS special terms (things like ?, $, ! a)

StartProgram:
	vtl 	5,"$=12"
	vtl 	10,"A=0"
	vtl 	20,"B=1"
	vtl 	30,"?=A"
	vtl 	40,"?=\"! \";"
	vtl 	50,"?=B"
	vtl 	60,"?=\"\""
	vtl 	70,"A=A+1"
	vtl 	80,"B=B*A"
	vtl 	90,"#=A<9*30"
EndProgram:
	db 		0
