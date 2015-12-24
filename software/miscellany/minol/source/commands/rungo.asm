; ****************************************************************************************************************
; ****************************************************************************************************************
;
;											RUN and GOTO Command
;	
; ****************************************************************************************************************
; ****************************************************************************************************************

CMD_GOTO:
	lpi 	p3,EvaluateExpression-1 							; evaluate where to GOTO.
	xppc 	p3
	jp 		CMD_GOTO-2 											; error in evaluating GOTO.
	lpi 	p3,ProgramBase 										; point P1 to program base.
	ld 		(p3)
	xpal 	p1
	ld 		1(p3)
	xpah 	p1
	lde 														; save line number below stack
	st 		-1(p2)	
__CGO_Search:
	ld 		(p1) 												; get length.
	jz 		__CGO_Fail 											; if zero,  goto has failed.
	xae 														; save in E.
	ld 		1(p1) 												; read line number
	xor 	-1(p2) 												; does it match.
	jz 		__CRU_GotoP1 										; if so, jump there.
	ld 		@-0x80(p1) 											; go to next line
	jmp 	__CGO_Search

__CGO_Fail:
	ldi 	ERROR_NoLabel 										; cause a label error
	xae
	ccl 
	jmp 	CMD_GOTO-2

CMD_RUN:
	lpi 	p3,ProgramBase 										; point P1 to program base and "GOTO" there
	ld 		(p3)
	xpal 	p1
	ld 		1(p3)
	xpah 	p1
;
;	GOTO address P1. (P3 = ProgramBase at this point)
;
__CRU_GotoP1:
	ldi 	0xFF 												; set IsRunning flag as now running.
	st 		IsRunning-ProgramBase(p3)
	ld 		1(p1) 												; get line number and save it.
	st 		CurrentLine-ProgramBase(p3)
	ld 		@2(p1) 												; point to first command.
	scl 														; set ok as legal.
	jmp 	CMD_GOTO-2
