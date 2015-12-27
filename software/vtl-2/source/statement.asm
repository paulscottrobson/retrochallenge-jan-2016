; ****************************************************************************************************************
; ****************************************************************************************************************
;
;													Statement
;
; ****************************************************************************************************************
; ****************************************************************************************************************

; ****************************************************************************************************************
; ****************************************************************************************************************
;
;													Handlers
;
;	Special L-Expr handlers go here. Each is preceded with a jump to the end before the execution label, so
;	code automatically falls through to execute next statement.
;
; ****************************************************************************************************************
; ****************************************************************************************************************

	include source\left_specials\readonly.asm
	include source\left_specials\machinecode.asm
	include source\left_specials\charout.asm

; ****************************************************************************************************************
;							Handler end. Test for error and skip rest of line if comment
; ****************************************************************************************************************

	csa 														; read Status Register
	ani 	0x80 												; check if CY/L bit set, if so go to next statement
	jnz 	SkipEndLineNextStatement
__ENS_Stop:														; error has occurred in a handler.
	lpi 	p3,Variables 										; clear the is running flag
	ldi 	0
	st 		IsRunning-Variables(p3)	
	;
	; TODO: Go to input from keyboard handler.
	;
wait2:
	jmp 	wait2

SkipEndLineNextStatement: 										; find end of line if comment etc.
	ld 		@1(p1)
	jnz 	SkipEndLineNextStatement

; ****************************************************************************************************************
; ****************************************************************************************************************
;
;					Execute the next statement. P1 points to the offset byte to next
;
; ****************************************************************************************************************
; ****************************************************************************************************************

RandomVariable = 0x27 											; Assembler does not like single quote.

ExecuteNextStatement:

; ****************************************************************************************************************
;									Check to see if reached end of program
; ****************************************************************************************************************

	ld 		@1(p1) 												; look at length byte
	scl 														; set CY/L so stops without error if zero.
	jz 		__ENS_Stop 											; if zero, stop the program from running as at top of program.

; ****************************************************************************************************************
;				Check running flag and update # variable which contains current line number
; ****************************************************************************************************************

	lpi 	p3,Variables 										; look at variables.
	ld 		IsRunning-Variables(p3) 							; check is running flag
	jz 		__ENS_Stop 											; if zero, stop, still with CY/L set.

	ld 		@1(p1) 												; copy current line number to #
	st 		('#' & 0x3F)*2(p3)
	ld 		@1(p1)
	st 		('#' & 0x3F)*2+1(p3)

; ****************************************************************************************************************
;										Update the random number variable '
; ****************************************************************************************************************

	ld 		(RandomVariable*2)(p3) 								; check random seed initialised
	or 		(RandomVariable*2+1)(p3) 										
	jnz 	__ENS_RandomInitialised

	ldi 	0xE1  												; if it is $0000, set it to $ACE1
	st 		(RandomVariable*2)(p3)
	ldi 	0xAC
	st 		(RandomVariable*2+1)(p3)
__ENS_RandomInitialised:

	ld 		(RandomVariable*2+1)(p3) 							; shift LFSR right
	ccl
	rrl
	st 		(RandomVariable*2+1)(p3)
	ld 		(RandomVariable*2)(p3)
	rrl
	st 		(RandomVariable*2)(p3)
	csa
	jp 		__ENS_NoToggleMask 									; if output bit is 1 appl the toggle mask.
	ld 		(RandomVariable*2+1)(p3)
	xri 	0xB4
	st 		(RandomVariable*2+1)(p3)
__ENS_NoToggleMask:

; ****************************************************************************************************************
;									Look at the first non space character
; ****************************************************************************************************************

__ENS_GetFirstCharacter:
	ld 		@1(p1) 												; get first character of line.
	jz 		ExecuteNextStatement 								; if it is NULL the line is blank, so go to next one.
	xri 	' '													; keep going till space not found
	jz 		__ENS_GetFirstCharacter
	ld 		@-1(p1) 											; go back and reload first non space character
	ani 	0x40 												; same optimisation trick as RHS. If this bit set it is
	jz 		__ENS_CheckSpecials 								; a standard variable @A-Z[/]^_ (e.g. 64-91) so don't check specials.

; ****************************************************************************************************************
;									A standard assignment of the A=<expr> type
; ****************************************************************************************************************

__ENS_StandardAssignment:
	ld 		@1(p1)												; get the variable and skip over it
	st 		@-1(p2) 											; save on stack for later usage.
	lpi		p3,CheckEquals-1 									; check equals and spacing function
	xppc 	p3 													; call it.
	ld 		@1(p2) 												; drop variable, temporarily
	csa
	jp 		__ENS_Stop 											; error trap
	ld 		@-1(p2) 											; restore variable on stack. data still there.
	xppc 	p3 													; call it again to evaluate expression
	ld 		@3(p2) 												; drop result and variable, though values still present
	csa
	jp 		__ENS_Stop 											; error trap

	ld 		-1(p2) 												; variable name
	ccl 														; double it, 2 bytes each
	add 	-1(p2) 
	ani 	0x3F * 2 											; same as anding with 3F and doubling.
	xae 														; put in E as an offset into variables
	lpi 	p3,Variables 										; point P3 to variables.
	ld 		-3(p2) 												; get LSB of result
	st 		-0x80(p3) 											; save it
	ld 		@1(p3) 												; bump P3
	ld 		-2(p2) 												; get MSB of result
	st 		-0x80(p3) 											; save it.
	jmp 	SkipEndLineNextStatement 							; skip to end of line, if not there, and do next statement.

; ****************************************************************************************************************
;	P1 points to a character in the 32-63 range, which *might* be a special so we look it up in the specials table
; ****************************************************************************************************************

__ENS_CheckSpecials:
	lpi 	p3,SpecialsTable 									; point P3 to the specials table.
__ENS_SearchSpecials:
	ld 		@3(p3) 												; fetch, and point to next.
	jz 		__ENS_StandardAssignment 							; if end of table, then do as standard assignment
	xor 	(p1) 												; found the character
	jnz 	__ENS_SearchSpecials 								; no, keep looking for it.

	ld 		@1(p1) 												; skip over specials character
	ld 		-2(p3) 												; read LSB of jump address to E
	xae 
	ld 		-1(p3) 												; read MSB of jump address to P3.H
	xpah 	p3
	lde 														; copy E to P3.L Predecrement is done by the macro
	xpal 	p3 

	xppc 	p3 													; and go to the handler. By doing this here we have 
																; and XPPC P3 for check equals and an XPPC P3 for 
																; expression with no P3 setup.

; ****************************************************************************************************************
; ****************************************************************************************************************
;
;						Check for = <expression>, skip following and trailing spaces
;
; ****************************************************************************************************************
; ****************************************************************************************************************

CheckEquals:
	ld 		@1(p1) 												; fetch and bump
	jz 		__CEQ_Fail
	xri 	' ' 
	jz 		CheckEquals 										; keep going if space found.
	xri 	' ' ! '=' 											; if not found equals
	jnz 	__CEQ_Fail  										; then fail with Syntax error.

__CEQ_SkipSpaces:
	ld 		@1(p1) 												; look at next after =
	jz 		__CEQ_Fail 											; if NULL syntax error.
	xri 	' ' 												; loop back if space.
	jz 		__CEQ_SkipSpaces
	scl 														; set CY/L flag as okay
	jmp 	__CEQ_Exit
__CEQ_Fail:	
	ldi 	ERROR_Syntax
	xae
	ccl 														; clear CY/L as error and return.
__CEQ_Exit:
	ld 		@-1(p1) 											; undo last fetch.
	csa 														; copy result to A
	xppc 	p3 													; return and fall through to evaluate expression

; ****************************************************************************************************************
;	Expression follows directly as this and the CheckEquals function can be executed using XPPC P3 with no set up
; ****************************************************************************************************************

	include source\expression.asm 								; expression 
	include source\right_special.asm 							; r-expr specials (parenthesis,array,key,line)

; TODO List
;	:<expr>)					Array access (relative to '&')
;	?							Write number and/or literal to screen
;	#							Jump to new line

SpecialsTable:
	special '$',__ST_CharacterOut 								; $ is write direct to output.
	special '>',__ST_MachineCode 								; > is call machine code.
	special ')',SkipEndLineNextStatement 						; ) is a comment.
	special '&',__ST_ReadOnlyVariable-1							; & is read only, cannot be changed.
	db 		0 													; end marker.
