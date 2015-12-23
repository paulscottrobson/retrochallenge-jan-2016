; ****************************************************************************************************************
; ****************************************************************************************************************
;
;													LIST Command
;	
; ****************************************************************************************************************
; ****************************************************************************************************************

CMD_LIST:
	lpi 	p3,EvaluateExpression-1 							; evaluate expression.
	xppc 	p3
	pushp 	p1 													; save P1 post-evaluate.
	ldi 	0 													; zero minimum line and counter for displaying.
	st 		@-1(p2)
	st 		@-1(p2)
	csa 														; get result of expression evaluation.
	jp 		__CLI_FromStart
	lde  														; save start line.
	st 		1(p2)
__CLI_FromStart:
	lpi 	p3,ProgramBase 										; point P1 to program base.
	ld 		(p3)
	xpal 	p1
	ld 		1(p3)
	xpah 	p1
__CLI_Loop:
	ld 		(p1) 												; end of program
	jz 		__CLI_Exit 											; exit.
	ld 		1(p1) 												; get Line Number into E
	xae
	lde 														; calculate line# - lowest
	scl
	cad 	1(p2)
	csa
	ani 	0x80
	jnz 	__CLI_List
__CLI_SkipOver:
	ld 		@2(p1) 												; skip offset and line#
__CLI_FindEnd:
	ld 		@1(p1)
	jnz 	__CLI_FindEnd
	jmp 	__CLI_Loop

__CLI_Exit:
	scl 														; set carry link as okay.
	ld 		@2(p2) 												; pop counter,upwards off stack.
	pullp 	p1
__CLI_ToPrev:
	jmp 	CMD_LIST-2 											; back up the chain.

__CLI_List:
	pushp 	p1 													; save P1
	ldi 	0 													; push high byte number
	st 		@-1(p2)
	lde 														; push low byte line number
	st 		@-1(p2)
	lpi 	p1,KeyboardBuffer+8 								; convert to ASCII
	lpi 	p3,OSMathLibrary-1
	ldi 	'$'
	xppc 	p3  
	lpi 	p3,Print-1											; print converted string
	ldi 	0
	xppc 	p3
	ldi 	' '													; print space
	xppc 	p3
	pullp 	p1 													; restore P1
	ld 		@2(p1) 												; skip over offset and line #
	ldi 	0 													; print it.
	xppc 	p3 	
	ldi 	13 													; print CRLF
	xppc 	p3
	ild 	(p2) 												; bump counter
	ani 	3
	jnz 	__CLI_Loop 
	lpi 	p3,GetChar-1 										; read a character
	xppc 	p3
	xri 	' ' 												; if space, keep going.
	jz 		__CLI_Loop
	jmp 	__CLI_Exit

	jmp 	__CLI_ToPrev 										; step through to top, can't do it in one here.

