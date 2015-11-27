; ******************************************************************************************************************
; ******************************************************************************************************************
; ******************************************************************************************************************
;
;												Machine Language Monitor
;
; ******************************************************************************************************************
; ******************************************************************************************************************
; ******************************************************************************************************************

		cpu	sc/mp

cursor 		= 0xC00 											; cursor position
current 	= 0xC01 											; current address hi,lo
parPosn		= 0xC03 											; current param offset in buffer (low addr)

kbdBuffer 	= 0xC04 											; 12 character keyboard buffer
kbdBufferLn = 12 										

codeStart 	= kbdBuffer+kbdBufferLn								; code starts here.

		org 	0x0000
		nop

; ******************************************************************************************************************
;
;												Clear the screen
;
; ******************************************************************************************************************
ClearScreen:
		xpal 	p1												; clear screen
		ldi 	' '
		st 		@1(p1)
		xpal 	p1
		jp 		ClearScreen

; ******************************************************************************************************************
;
;									Find Top of Memory to initialise the stack.
;
; ******************************************************************************************************************
		ldi 	0x80 											; point P2 to theoretical top of RAM + 64
		xpah 	p2 												; e.g. $803F
		ldi 	0x3F
		xpal 	p2
FindTopMemory:
		ldi 	0xA5 											; try to write this to memory
		st 		@-64(p2) 										; predecrementing by 64.
		xor 	(p2) 											; did it write correctly.
		jnz 	FindTopMemory 									; now P2 points to top of memory.

; ******************************************************************************************************************
;
;									Reset cursor position and current address.
;
; ******************************************************************************************************************
		ldi 	Cursor/256 										; reset the cursor position to TOS
		xpah 	p1
		ldi 	Cursor&255
		xpal 	p1 
		ldi 	0
		st 		@1(p1)											
		ldi 	codeStart/256 									; reset current address to code start
		st 		@1(p1)
		ldi 	codeStart&255
		st 		@1(p1)

; ****************************************************************************************************************
;
;													Main Loop
;
; ****************************************************************************************************************

CommandMainLoop:
		ldi 	(PrintAddressData-1)/256						; print Address and Data there
		xpah 	p3
		ldi 	(PrintAddressData-1)&255
		xpal 	p3
		ldi 	1
		xppc 	p3

		ldi 	(PrintCharacter-1)/256 							; set P3 = print character.
		xpah 	p3
		ldi 	(PrintCharacter-1)&255
		xpal 	p3
		ldi 	'.'
		xppc 	p3

; ****************************************************************************************************************
;
;											Keyboard Line Input
;
; ****************************************************************************************************************

		ldi 	0 												; set E = character position.
		xae 
KeyboardLoop:
		ldi 	0x8 											; set P1 to point to keyboard latch
		xpah 	p1
_KBDWaitRelease:
		ld 		0(p1) 											; wait for strobe to clear
		jp 		_KBDWaitKey
		jmp 	_KBDWaitRelease
_KBDWaitKey:
		ld 		0(p1) 											; wait for strobe, i.e. new key
		jp 		_KBDWaitKey
		ani 	0x7F 											; throw away bit 7
		st 		-1(p2) 											; save key.

		ldi 	kbdBuffer/256 									; set P1 = keyboard buffer
		xpah 	p1
		ldi 	kbdBuffer&255
		xpal 	p1		

		ld 		-1(p2) 											; read key
		xri 	8 												; is it backspace
		jz 		__KBDBackSpace
		xri 	8!13 											; is it CR, then exit
		jz 		__KBDExit

		lde 													; have we a full buffer.
		xri 	kbdBufferLn 									; if so, ignore the key.
		jz 		KeyboardLoop

		ld 		-1(p2) 											; restore the key.
		ccl
		adi 	0x20											; will make lower case -ve
		jp 		__KBDNotLower
		cai 	0x20 											; capitalise
__KBDNotLower:
		adi 	0xE0 											; fix up.
		st 		-0x80(p1) 										; save in the buffer using E as index.
		xppc 	p3 												; print the character
		xae 													; increment E
		ccl
		adi 	1
		xae
		jmp 	KeyboardLoop 									; and get the next key.

__KBDBackSpace:
		lde 													; get position
		jz 		KeyboardLoop 									; can't go back if at beginning
		scl 													; go back 1 from E
		cai 	1
		xae 
		ldi 	8 												; print a backspace
		xppc 	p3
		jmp 	KeyboardLoop 									; and go round again.

__KBDExit:
		st 		-0x80(p1) 										; add the ASCIIZ terminator.
		ldi 	13												; print a new line.
		xppc 	p3

; ****************************************************************************************************************
;
;						Extract the 5 bit 3 letter (max command value). P1 points to buffer
;
; ****************************************************************************************************************

		ldi 	0
		xae 													; E contains the LSB of the 5 bit shift
		lde 	
		st 		-1(p2) 											; -1(P2) contains the MSB
Extract5Bit:
		ld 		(p1) 											; look at character
		ccl 													; add 128-65, will be +ve if < 64
		adi 	128-65
		jp 		__ExtractEnd
		ldi 	5 												; shift current value left 5 times using -2(p2)
		st 		-2(p2)
__Ex5Shift:
		lde 													; shift E left into CY/L
		ccl
		ade 
		xae
		ld 		-1(p2) 											; shift CY/L into -1(p2) and carry/link
		add 	-1(p2)
		st 		-1(p2)
		dld 	-2(p2) 											; done it 5 times ?
		jnz 	__Ex5Shift
		ld 		@1(p1) 											; re-read character.
		ani 	0x1F 											; lower 5 bits only.
		ore 													; OR into E
		xae
		jmp 	Extract5Bit 									; go and get the next one.

__ExtractEnd:
		ldi 	parPosn & 255 									; P1.L = Parameter Position, A = first non cmd char
		xpal	p1
		st 		(p1) 											; write to parameter position.


wait:	jmp 	wait

		;jmp 	CommandMainLoop

; ****************************************************************************************************************
; ****************************************************************************************************************
;
;						Print A as a hexadecimal 2 digit value. If CY/L set precede with space
;
; ****************************************************************************************************************
; ****************************************************************************************************************

PrintHexByte:
		st 		@-1(p2) 										; push A and P3, set P3 up to print character
		ldi 	(PrintCharacter-1)/256
		xpah 	p3
		st 		@-1(p2)
		ldi 	(PrintCharacter-1)&255
		xpal 	p3
		st 		@-1(p2)
		csa 													; check carry
		jp 		__PHBNoSpace									; if clear, no space.
		ldi 	' '												; print leading space
		xppc 	p3 
__PHBNoSpace:
		ld 		2(p2) 											; read digit
		sr 														; convert MSB
		sr
		sr
		sr
		ccl
		dai 	0x90
		dai 	0x40
		xppc 	p3 												; print
		ld 		2(p2) 											; read digit
		ani 	0x0F 											; convert LSB
		ccl
		dai 	0x90
		dai 	0x40
		xppc 	p3 												; print

		ld 		@1(p2) 											; restore P3 & A and Return
		xpal 	p3
		ld 		@1(p2)
		xpah 	p3
		ld 		@1(p2)
		xppc 	p3
		jmp 	PrintHexByte

; ****************************************************************************************************************
; ****************************************************************************************************************
;
;		Print Character in A, preserves all registers, re-entrant. Handles 13 (New Line), 8 (Backspace)
;		Characters 32 - 95 only.
;	
;		Rolls to screen top rather than scrolling.
;
; ****************************************************************************************************************
; ****************************************************************************************************************

PrintCharacter:
		st 		@-1(p2) 										; save A
		ldi 	Cursor/256 										; save P1, setting up P1 -> Cursor at same time.
		xpah 	p1
		st 		@-1(p2)
		ldi 	Cursor&255
		xpal 	p1
		st 		@-1(p2)
		ldi 	0 												; save P3, setting up P3 -> Page 0 (Video RAM Write)
		xpah 	p3
		st 		@-1(p2)
		xpal 	p3
		st 		@-1(p2)

		ld 		(p1) 											; read cursor position
		xpal 	p3 												; put in P3.Low

		ldi 	' ' 											; erase the cursor.
		st 		0(p3)

		ld 		4(p2) 											; read character to print.
		xri 	13 												; is it CR ?
		jz 		__PCNewLine 									; if so, go to new line.
		xri 	13!8 											; is it Backspace ?
		jz 		__PCBackSpace

		ld 		4(p2) 											; get character to print
		ani 	0x3F 											; make 6 bit ASCII
		st 		@1(p3) 											; write into P3, e.g. the screen and bump it.
		ild 	(p1) 											; increment cursor position and load
		ani 	15 												; are we at line start ?
		jnz 	__PCExit 										; if so, erase the current line.

__PCBlankNewLine:
		ldi 	16 												; count to 16, the number of spaces to write out.
		st 		-1(p2) 
__PCBlankNewLineLoop:
		ldi 	' '
		st 		@1(p3)
		dld 	-1(p2)
		jnz 	__PCBlankNewLineLoop

__PCExit:
		ld 		(p1) 											; read cursor
		xpal 	p3 												; put in P3.L
		ldi 	0x9B 											; shaded block cursor on screen
		st 		(p3)
		ld 		@1(p2)											; restore P3
		xpal 	p3
		ld 		@1(p2)
		xpah 	p3
		ld 		@1(p2)											; restore P1
		xpal 	p1
		ld 		@1(p2)
		xpah 	p1
		ld 		@1(p2) 											; restore A and Return.	
		xppc 	p3
		jmp 	PrintCharacter 									; and it is re-entrant.

__PCBackSpace:
		xpal 	p3 												; get current cursor position
		jz 		__PCExit 										; if top of screen then exit.
		dld 	(p1) 											; backspace and load cursor
		xpal 	p3 												; put in P3
		ldi 	' '												; erase character there
		st 		(p3)
		jmp 	__PCExit 										; and exit.

__PCNewLine:
		ld 		(p1) 											; read cursor position
		ani 	0x70 											; line
		ccl 													; next line
		adi 	0x10
		st 		(p1) 											; write back
		xpal 	p3 												; put in P3.L
		jmp 	__PCBlankNewLine

; ****************************************************************************************************************
; ****************************************************************************************************************
;
;					Print current address followed by A data bytes. Doesn't update current address
;
; ****************************************************************************************************************
; ****************************************************************************************************************

PrintAddressData:
		st 		@-1(p2) 										; save count, we don't restore this.
		ldi 	(PrintHexByte-1)/256 							; save and set up P3
		xpah 	p3
		st 		@-1(p2)
		ldi 	(PrintHexByte-1)&255
		xpal 	p3
		st 		@-1(p2)
		ldi 	current / 256 									; point P1 to current address
		xpah 	p1
		ldi 	current & 255
		xpal 	p1
		ld 		0(p1) 											; read high byte of address
		ccl
		xppc 	p3												; print w/o leading space
		ld 		1(p1)											; read low byte of address
		ccl 	
		xppc 	p3 												; print w/o leading space.
		xae 													; put in E
		ld 		0(p1) 											; high byte to P1.H
		xpah 	p1
		lde 													; low byte to P1.H
		xpal 	p1
_PADLoop:
		dld 	2(p2) 											; decrement counter
		jp 		_PADPrint 										; if +ve print another byte

		ld 		@1(p2) 											; restore P3, skipping A hence @2
		xpal 	p3
		ld 		@2(p2)
		xpah 	p3
		xppc 	p3
		jmp 	PrintAddressData

_PADPrint:
		ld 		@1(p1) 											; read byte advance pointer
		scl
		xppc 	p3 												; print with space.
		jmp 	_PADLoop