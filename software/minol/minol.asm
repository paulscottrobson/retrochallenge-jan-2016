; ****************************************************************************************************************
; ****************************************************************************************************************
;
;												MINOL Intepreter
;
; ****************************************************************************************************************
; ****************************************************************************************************************

; ****************************************************************************************************************
;												 Memory Allocation
; ****************************************************************************************************************

	cpu 	sc/mp
	
ScreenMirror = 0xC00 											; Screen mirror, 128 bytes, 256 byte page boundary.
ScreenCursor = ScreenMirror+0x80  								; Position on that screen (00..7F)

Variables = ScreenCursor+2 										; uses 32 bytes for expression evaluation

MinolVars = Variables + 32 										; MINOL variables start here.

CurrentLine = MinolVars + 0 									; current line number (0 = not running)
CurrentAddr = MinolVars + 1 									; position in current line (Low,High)

MonitorBoot = 0x210 											; go here to boot monitor

ERROR_Label = 1 												; Undefined GOTO.

; ****************************************************************************************************************
;														Macros
; ****************************************************************************************************************

lpi	macro	ptr,addr
	ldi 	(addr) / 256
	xpah 	ptr
	ldi 	(addr) & 255
	xpal 	ptr
	endm

; ****************************************************************************************************************
;													Main Program
; ****************************************************************************************************************

	org 	0x9000 												; the ROM starts here

	db 		0x68												; this makes it boot straight into this ROM.
	lpi 	p2,0xFFF											; set up stack

	lpi 	p3,Print-1 											; clear screen
	ldi 	12
	xppc 	p3
	ldi 	']'													; Prompt
	xppc 	p3
	lpi 	p1,test
	lpi 	p3,ExecuteCommand-1
	xppc 	p3

stop:
	jmp 	stop

; ****************************************************************************************************************
;										Routines in source subdirectory
; ****************************************************************************************************************
	
	include source\execute.asm									; command execution
	include source\program.asm 									; program space management.
	include source\console.asm 									; PR and IN command execution.

; ****************************************************************************************************************
;						Routines developed and tested seperately in other subdirectories.
; ****************************************************************************************************************

	include ..\screen\screen.asm 								; screen I/O stuff.
	include ..\expression\expression.asm 						; expression stuff.


