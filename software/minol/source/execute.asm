; ****************************************************************************************************************
; ****************************************************************************************************************
;
;											Execute Command
;
; ****************************************************************************************************************
; ****************************************************************************************************************

test:db 	"CALL (4,6)",0

__EXExit:
	scl 														; is okay.
__EXExitNoCC:
	ld 		@1(p2) 												; restore P3
	xpal 	p3
	ld 		@1(p2)
	xpah 	p3
	ld 		@1(p2)												; restore E
	xae
	ld 		@1(p2) 												; restore A
	xppc 	p3

ExecuteCommand:
	st 		@-1(p2) 											; push A
	lde 														; push E
	st 		@-1(p2)
	xpah 	p3 													; push P3.
	st 		@-1(p2)
	xpal 	p3
	st 		@-1(p2)

__EXFirst:
	ld 		0(p1) 												; found EOS 
	jz 		__EXExit 											; exit, empty string.
	ld 		@1(p1) 												; fetch and skip over
	xri 	' ' 												; is it space ?
	jz 		__EXFirst 											; keep going.
	xri 	' '!':'												; if it is colon, then exit.
	jz 		__EXExit
	xri 	':'!'"'												; if it is quote (comment )
	jnz 	__EXCode 											; try it as a command.
;
;	Go to next command, skip forward to ':' (skip over) or End of String (\0)
;
__EXNextCommand:
	ld 		(p1)												; if 0 then end of command
	jz 		__EXExit
	ld 		@1(p1) 												; fetch and bump
	xri 	':'
	jnz 	__EXNextCommand 									; until found a colon.
	jmp 	__EXExit

; ****************************************************************************************************************
;
;	Instructions:
;
;		CALL 	(h,l)
;		CLEAR
;		END
;		[LET]	var|(h,l) = <expr>
;		GOTO	<expr>
;		LIST
;		NEW 	(stops running program as well)
;		IF 		<expr> [#<=] <expr> ; instruction
;		IN 		string|var,...
;		OS 		Boots to Monitor (JMP $210)
;		PR 		string|number|string const,....[;]
;		RUN
;
; ****************************************************************************************************************

__EXCode:

	; TODO:Set P3 to skip w/o going off the end routine.

	ld 		-1(p1) 												; reload character for decoding.
	xri 	'C'
	jnz 	__EX_Decode_NotC									; check if it is C(A)LL or C(L)ear
	ld 		0(p1) 												; get next character
	xri 	'A'
	jz 		__EX_Command_CALL
;
;	CLEAR command. Clear all variables.
;
	lpi 	p3,Variables 										; point P3 to variables
	ldi 	26 													; clear 26
	st 		-1(p2)
__EX_CALL_Loop:
	ldi 	0 													; clear and bump pointer
	st 		@1(p3)
	dld 	-1(p2) 												; do it 26 times.
	jnz 	__EX_CALL_Loop
	jmp 	__EXNextCommand 									; next command.
;
;	CALL
;
__EX_Command_CALL:
	ldi 	3 													; skip 'A' 'L' 'L'
	xppc 	p3
	; TODO: Call routine and fail on error.
	; TODO: Load into P3, subtract 1, do XPPC P3.
	jmp 	__EXNextCommand										; next command.

__EX_Decode_NotC:

wait2:	jmp 	wait2
