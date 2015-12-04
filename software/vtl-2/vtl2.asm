; ****************************************************************************************************************
; ****************************************************************************************************************
;
;													VTL-2 SC/MP
;
; ****************************************************************************************************************
; ****************************************************************************************************************

; ****************************************************************************************************************
;												 Memory Allocation
; ****************************************************************************************************************

ScreenMirror = 0xC00 											; Screen mirror, 128 bytes, 256 byte page boundary.
ScreenCursor = ScreenMirror+0x80  								; Position on that screen (00..7F)

VariableBase = 0xCC0 											; Base of variables. Variables start from here, 2 bytes
																; each, 6 bit ASCII (e.g. @,A,B,C)
																; VTL-2 other variables work backwards from here.

ProgramSpace = 0x1000 											; Page with program memory.

StackSearch = 0xFFF 											; Search for stack space back from here.



	db 		0x68
wait:
	jmp 	wait
