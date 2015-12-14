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
	vtl 	100,":3)=11*11"
	vtl 	102,":2)=:3)+256"
	vtl 	105,"$=12"
	vtl 	108,"$=63"
	vtl 	110,"A=?"
	vtl 	120,"B=A*A"
	vtl 	130,"C='"
	vtl 	140,"D=(A<10)*20"
EndProgram:
	db 		0
