; ****************************************************************************************************************
; ****************************************************************************************************************
;
;												Minol ROM Image
;
; ****************************************************************************************************************
; ****************************************************************************************************************

	cpu 	sc/mp

	include source\memorymacros.asm 							; Memory allocation and Macro definition.	
	include source\errors.asm 									; Error codes

; ****************************************************************************************************************
;													Main Program
; ****************************************************************************************************************

	org 	0x9000 												; the ROM starts here

	db 		0x68												; this makes it boot straight into this ROM.
	lpi 	p2,0xFFF											; set up top stack value
FindTOS:
	ldi 	0x75												; can we write there, if so, found TOS.
	st 		(p2)
	xor 	(p2)
	jz 		StackFound
	ld 		-64(p2) 											; wind backwards 64 bytes
	jmp 	FindTOS	
StackFound:

 	; 		include democode.asm

StartUp:
	lpi 	p3,Print-1											; Print Boot Message
	lpi 	p1,BootMessage
	ldi 	0
	xppc 	p3

	lpi 	p3,ProgramBase 										; check to see if MINOL code resident.
	ld 		-4(p3) 												; which requires the 4 byte markers to be loaded.
	xri 	Marker1
	jnz 	RunNew
	ld 		-3(p3) 			
	xri 	Marker2
	jnz 	RunNew
	ld 		-2(p3) 			
	xri 	Marker3
	jnz 	RunNew
	ld 		-1(p3) 			
	xri 	Marker4
	jnz 	RunNew

	lpi 	p3,ConsoleStart-1 									; run the console if code present
	scl 														; non-error (so it prints ok)
	xppc	p3

RunNew:															; otherwise execute NEW.
	lpi 	p3,CMD_New-1
	xppc 	p3



BootMessage:
	db 		12,"** MINOL **",13,"V0.94 PSR 2016",13,0

; ****************************************************************************************************************
;													Source Files
; ****************************************************************************************************************

	include source\itoa.asm 									; print integer routine.
	include source\atoi.asm 									; decode integer routine.
	include source\execute.asm 									; statement exec main loop
	include source\manager.asm 									; manage program lines.
	include source\console.asm 									; console type in etc.
