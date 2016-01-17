; ****************************************************************************************************************
; ****************************************************************************************************************
;	
;								Include in DemoCode.Asm to load default program in
;
; ****************************************************************************************************************
; ****************************************************************************************************************

	lpi 	p3,ProgramCode 										; copy program default code to memory.
	lpi 	p1,ProgramBase-4
Copy1:
	ld 		@1(p3)
	st 		@1(p1)
	xri 	0xFF
	jnz 	Copy1
	jmp 	StartUp
ProgramCode:
	db 		Marker1,Marker2,Marker3,Marker4
	code 	10,"\"TEST PROGRAM\""
	code 	15,"PR A;:GOTO 15"
	code 	20,"IN A"
	code 	30,"PR A*2"
	code 	40,"PR A*A"
	code 	50,"END"
	db 		255


