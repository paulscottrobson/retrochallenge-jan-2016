; ****************************************************************************************************************
; ****************************************************************************************************************
;
;										Insert / Delete Program Lines
;
; ****************************************************************************************************************
; ****************************************************************************************************************

; ****************************************************************************************************************
; ****************************************************************************************************************
;
;						Delete program line 'E'. If program line does not exist, has no effect.
;
;	Sets up P3 to call insert program line next.
; ****************************************************************************************************************
; ****************************************************************************************************************

DeleteLine:
	pushp	p3 													; save P3
	lde 														; push E on stack
	st 		@-1(p2)
;
;	First find the line in question.
;
	lpi 	p3,ProgramBase 										; first, look for the line.
DLN_Search:
	ld 		(p3)												; look at offset
	ani 	0x80
	jnz 	DLN_Exit 											; if -ve then end of program so exit.

	ld 		(p3) 												; reload offset to next.
	xae 														; put offset in E
	ld 		1(p3) 												; read line number
	xor 	(p2)												; is it the required line number
	jz 		DLN_Delete  										; if so, delete line.
	ld 		@-0x80(p3) 											; use E as offset to next.
	jmp 	DLN_Search 											; and try next one.
;
DLN_Delete:
	ld 		-0x80(p3) 											; read ahead
	st 		@1(p3) 												; save here and bump
	xri 	0xFF 												; until 0xFF is copied, which is end of program.
	jnz 	DLN_Delete
;
DLN_Exit:
	ld 		@1(p2)												; pop E
	xae
	pullp	p3													; pop P3
	xppc 	p3 													; and return.

; ****************************************************************************************************************
; ****************************************************************************************************************
;
;									Insert line at line E, text at P1
;
;	Jams if line already present.
; ****************************************************************************************************************
; ****************************************************************************************************************

InsertLine:
	pushp 	p3 													; save P3
	pushe 														; save E , line number.

	xpah 	p1													; save P1 on stack without changing it.
	st 		@-1(p2)
	xpah 	p1
	xpal 	p1
	st 		@-1(p2)
	xpal 	p1
	ldi 	0 													; this is the length of the string
	st 		@-1(p2) 											; including the terminating zero.

ILI_FindLength:
	ild 	(p2)												; increment length
	ld 		@1(p1) 												; fetch and bump
	jnz 	ILI_FindLength

	lpi 	p3,ProgramBase 
ILI_FindPosition:
	ld 		(p3) 												; read offset
	ani 	0x80 												; if negative, insert here.
	jnz 	ILI_InsertHere
	ld 		(p3)												; put offset to next in E.
	xae
	ld 		3(p2) 												; calculate line# - this#
	scl
	cad 	1(p3)
ILI_Failed: 													; error here. If line# found, we haven't deleted it !
	jz 		ILI_Failed
	csa 														; if CY/L = 0 then insert here
	jp 		ILI_InsertHere
	ld 		@-0x80(p3)											; go to next line.
	jmp 	ILI_FindPosition

ILI_InsertHere:
	ldi 	0 													; these are used to count how many bytes from here to the end.
	st 		-1(p2)
	st 		-2(p2)
ILI_CountBytes:
	ild 	-2(p2)
	jnz 	ILI_NoCarry
	ild 	-1(p2)
ILI_NoCarry:
	ld 		@1(p3)												; fetch and bump
	xri 	0xFF 												; until $FF found.
	jnz 	ILI_CountBytes
	ld 		0(p2) 												; get length of string into E
	xae

ILI_Move:
	ld 		(p3)												; move byte
	st 		-0x80(p3)
	ld 		@-1(p3) 											; point to previous byte

	ld 		-2(p2) 												; decrement the counter
	jnz 	ILI_NoBorrow
	dld 	-1(p2) 
	ani 	0x80
	jnz 	ILI_GotSpace 										; if counter out, then got the space.
ILI_NoBorrow:
	dld 	-2(p2)
	jmp 	ILI_Move

ILI_GotSpace:
	ld 		@1(p3) 												; this is where the new data goes
	ld 		1(p2)												; restore the original P1.
	xpal 	p1
	ld 		2(p2)
	xpah 	p1

ILI_Copy:														; copy the new line in.
	ld 		@1(p1)
	st 		@1(p3)
	jnz 	ILI_Copy

	ld 		@1(p2) 												; dump string length
	pullp 	p1													; restore registers
	pulle
	pullp 	p3
	xppc 	p3
