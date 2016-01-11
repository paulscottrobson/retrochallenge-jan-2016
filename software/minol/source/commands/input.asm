; ****************************************************************************************************************
; ****************************************************************************************************************
;
;												IN command
;	
; ****************************************************************************************************************
; ****************************************************************************************************************

	jmp		CIN_Over2

CMD_In:
	lpi 	p3,EvaluateAddressPair-1 							; set P3 to call evaluate pair (H,L)
	scl 														; indicates no error
	ld	 	(p1) 												; look at first character
	jz 		CIN_Over2 											; if zero or ':' then end of IN
	xri 	':'
	jz 		CIN_Over2
	ld 		@1(p1) 												; fetch and bump
	xri 	','													; ignora commas
	jz 		CMD_In
	xri 	' '!','												; ignore spaces.
	jz 		CMD_In
	xri 	'('!' '												; open bracket is Input to (H,L)
	jz 		CIN_Memory 
	xri 	'$'!'('												; $(H,L) is input to memory.
	jz 		CIN_String

; ****************************************************************************************************************
;											Check for A-Z input.
; ****************************************************************************************************************

	ld 		-1(p1)												; get letter of variable
	ccl
	adi 	255-'Z'												; check if > 'Z'
	jp 		CIN_Syntax 				
	adi 	26 													; will be +ve if A..Z now
	jp 		CIN_Variable

; ****************************************************************************************************************
;									Syntax error - not (x,x) $(x,x) or A..Z
; ****************************************************************************************************************

CIN_Syntax:
	ldi 	ERRC_Syntax
	xae
	ccl
CIN_Over2:
	jmp 	CIN_Over

; ****************************************************************************************************************
;										Input to variable in A (0-25)
; ****************************************************************************************************************

CIN_Variable:
	ccl 														; add variable number 0-25 to Variables to get an address
	adi 	Variables & 255
	st 		-2(p2)
	ldi 	Variables / 256
	adi 	0
	st 		-1(p2)
	jmp 	CIN_InputVariableOrMemory

; ****************************************************************************************************************
;											Input to (<expr>,<expr>)
; ****************************************************************************************************************

CIN_Memory:
	ld 		@-1(p1)												; point to the bracket.
	xppc 	p3 													; push the H,L on the stack, without the stack being changed
	jp 		CIN_Over 											; exit on error.

; ****************************************************************************************************************
;								Input to variable or memory address is hidden on TOS.
; ****************************************************************************************************************

CIN_InputVariableOrMemory:
	ld 		@-2(p2) 											; save the storage address as TOS "Make it visible"
	pushp 	p1 													; save P1 on stack
	lpi 	p3,GetString-1 										; read keyboard
	lpi 	p1,KeyboardBuffer 									; point P1 to keyboard buffer.
	ldi 	KeyboardBufferSize 									; buffer size
	xppc 	p3 													; read it in.

	lpi 	p3,GetConstant-1 									; extract constant to E if any
	xppc 	p3
	ani 	0x80 												; if CY/L set, e.g. is it legal 
	jnz 	CIN_StoreValue										; if so, store E at the address.
	ld 		(p1) 												; get the character code of the first letter
	xae 														; into E
CIN_StoreValue:
	pullp 	p1 													; restore P1
	ld 		@1(p2) 												; get low byte to P3.L
	xpal 	p3 												
	ld 		@1(p2)												; get high byte to P3.H
	xpah 	p3
	lde 														; get E, value to store
	st 		(p3)												; and write it.
CMD_In2:
	jmp 	CMD_In 												; and see if there is more to input

; ****************************************************************************************************************
;												Input String to Memory
; ****************************************************************************************************************

CIN_String:
	xppc 	p3 													; evaluate (H,L)
	jp 		CIN_Over 											; exit on error.
	ld 		-1(p2) 												; read High
	xpah 	p1 													; put into P1.H
	st 		-1(p2)
	ld 		-2(p2)												; read Low
	xpal 	p1 													; put into P1.L
	st 		@-2(p2) 											; save on stack
	lpi 	p3,GetString-1 										; read keyboard
	ldi 	KeyboardBufferSize 									; max size of input
	xppc 	p3 													; read keyboard into address

CIN_FindEnd:													; look for EOS (NULL)
	ld 		@1(p1)
	jnz 	CIN_FindEnd
	dld 	-1(p1) 												; convert $00 to $FF

	ld 		@1(p2) 												; pop P1
	xpal 	p1
	ld 		@1(p2)
	xpah 	p1
	jmp 	CMD_In2												; see if more input 

CIN_Over:


