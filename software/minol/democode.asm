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
	code 	10,"PR\"NAME\";:IN$(14,1)"
	code 	20,"IF(14,1)='J';IF(14,2)='I';IF(14,3)='M';PR \"ITS JIM\""
	code 	30,"IF(14,1)#'J';PR\"ITS NOT JIM.\":GOTO10"
	db 		255


