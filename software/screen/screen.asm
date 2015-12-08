; ****************************************************************************************************************
; ****************************************************************************************************************
;
;											Screen I/O, MINOL ROM
;											=====================
;
;	Provides Character and String Input/Output functionality.
;
; ****************************************************************************************************************
; ****************************************************************************************************************

; ****************************************************************************************************************
; ****************************************************************************************************************
;
;	Print routine. Prints either character in A, or ASCIIZ string at P1 (if A is zero). Preserves all registers
;	except if printing string, P1 points to the character after the NULL terminator.
;
;	Scrolls automatically. Understands character codes 32-255, 8 (Backspace) 12 (Clear Screen) 13 (Carriage
;	Return). Others are currently ignored (except 0, see above). Note L/C values (97....) display those characters
;	in the ROM font *not* lower case :)
;
; ****************************************************************************************************************
; ****************************************************************************************************************

Print:
	section 	Print

	st 		@-1(p2) 											; save character on stack.
	xpah 	p1
	st 		@-1(p2) 											; save P1 on the stack.
	xpal 	p1
	st 		@-1(p2)
	xae 	
	st 		@-1(p2) 											; save E on the stack.

	ld 		3(p2) 												; read character 
	jnz 	__PRPrintCharacterA 								; if non zero print it on its own.

__PRPrintString:
	ld 		1(p2) 												; restore original P1
	xpal 	p1
	ld 		2(p2)
	xpah 	p1 													; read character at P1.
	ld 		@1(p1)
	xae 														; save in E.
	xpah 	p1 													; write P1 back.
	st 		2(p2)
	xpal 	p1
	st 		1(p2)
	lde 														; get character from E
	jz 		__PRExitNoCheck 									; exit without loop check.
;
;	Print character in A now ; throughout it is stored in E.
;
__PRPrintCharacterA:
	xae 														; save character in E.
;
;	Read cursor and set P1 to that address
;
	ldi 	ScreenCursor/256 									; set P1 to point to screen cursor
	xpah 	p1
	ldi 	ScreenCursor&255
	xpal 	p1
	ld 		0(p1) 												; put cursor position in P1.L
	xpal 	p1
;
;	Check for control
;
	lde 														; look at character
	ani 	0xE0 												; is it code 0-31
	jz 		__PRIsControlChar
;
;	Print non-control
;
	lde 														; read character
	scl 														; CY/L clear if < 96
	cai 	96 
	csa 	 	 												; skip if carry set
	xri 	0x80													
	jp 		__PRNotASCII
	lde 														; if ASCII make 6 bit.
	ani 	0x3F
	xae
__PRNotASCII:
	lde 														; get character.
	st 		(p1) 												; save in shadow memory
	xpah 	p1 													; switch to VRAM, preserving A.
	ldi 	0 													
	xpah 	p1
	st 		@1(p1) 												; save in screen memory, advance write position.
;
;	Write cursor position back from P1.L
;
__PRUpdateCursor:
	ldi		ScreenCursor / 256 									; set P1 to point to screen cursor, restore position to P1
	xpah 	p1
	ldi 	ScreenCursor & 255 
	xpal 	p1 													; after this, adjusted cursor position is in AC.
	st 		(p1) 												; write back in cursor position
	jp 		__PRExit 											; if position is off the bottom then scroll.
;
;	Scroll display
;
	ldi 	(ScreenMirror+16) / 256 							; point P1 to 2nd line.
	xpah 	p1
	ldi 	(ScreenMirror+16) & 255
__PRScrollLoop:
	xpal 	p1
	ld 		0(p1) 												; copy char to previous line
	st 		-16(p1)
	ld 		@1(p1) 												; bump pointer.
	xpal 	p1
	jp 		__PRScrollLoop
	ldi 	128-16 												; clear from and move to last line
	jmp 	__PRClearFromMoveTo
;
;	Exit screen drawing routine.
;
__PRExit:
	ld 		3(p2) 												; if character was zero, loop
	jz 		__PRPrintString 									; back as printing string at P1.
__PRExitNoCheck:
	ld 		@1(p2) 												; restore E
	xae
	ld 		@1(p2) 												; restore P1
	xpal 	p1
	ld 		@1(p2)
	xpah 	p1
	ld 		@1(p2)												; restore A
	xppc 	p3 													; return
	jmp 	Print 												; make re-entrant.
;
;	Check for supported control characters 8 (Backspace) 12 (Clear) 13 (Carriage Return)
;
__PRIsControlChar:
	lde 														; restore character.
	xri 	13 													; carriage return ? (13)
	jz 		__PRIsReturn
	xri 	13!12 												; form feed ? (12)
	jz 		__PRClearScreen
	xri 	12!8 												; backspace ? (8)
	jnz 	__PRExit 
;
;	Handle backspace (8)
;
	xpal 	p1 													; check cursor position is zero
	jz 		__PRExit 											; if it is, cannot backspace so exit.
	xpal 	p1  												; put it back
	ld 		@-1(p1)												; move it back one
	ldi 	' '	 												; erase in shadow
	st 		(p1)
	ldi 	0 													; point P1 to VRAM
	xpah 	p1
	ldi 	' '													; erase in VRAM
	st 		(p1)
	jmp 	__PRUpdateCursor 									; and exit
;
;	Handle carriage return (13)
;
__PRIsReturn:
	xpal 	p1 													; cursor position in A
	ani 	0xF0 												; start of current line
	ccl 														; down one line
	adi 	0x10 	
	xpal 	p1 													; put it back in P1.
	jmp 	__PRUpdateCursor
;
;	Handle clear screen (12)
;
__PRClearScreen:
	ldi 	0 													; clear shadow memory from here.
;
;	From position A, clear the memory in the shadow screen to the end, copy the shadow screen to VRAM
;	then use position A as the new cursor position.
;
__PRClearFromMoveTo:
	st 		@-1(p2) 											; save this position, the cursor goes here.
__PRClearLoop:
	xpal 	p1 													; save position in P1.
	ldi 	' '													; write space there.
	st 		@1(p1)
	xpal 	p1
	jp 		__PRClearLoop 										; until reached shadow memory start.
	ldi 	0 													; now copy shadow memory to screen memory.
__PRCopy:
	xpal 	p1 													; set up P1.L
	ldi 	ScreenMirror/256 									; point to shadow memory.
	xpah 	p1 													
	ld 		(p1) 												; read shadow memory
	xpah 	p1 													; zero P1.H preserving A
	ldi 	0
	xpah 	p1
	st 		@1(p1) 												; save and increment p1
	xpal 	p1 
	jp 		__PRCopy 											; keep doing till all copied.
	ld 		@1(p2) 												; read cursor position
	xpal 	p1 													; put in P1.L
	jmp 	__PRUpdateCursor

	endsection 	Print

; ****************************************************************************************************************
; ****************************************************************************************************************
;
;		Input a single character into A. Case is converted to Upper. All registers preserved except A
;
; ****************************************************************************************************************
; ****************************************************************************************************************

GetChar:
	section 	GetChar
	ldi 	0x8 												; set P1 to $8xx, and save P1.H
	xpah 	p1
	st 		@-1(p2)
__GCWaitKey: 													; wait for key press
	ld 		0(p1)
	jp 		__GCWaitKey
	ani	 	0x7F 												; throw away the upper bit.
	st 		-1(p2) 												; save it below stack
__GCWaitRelease:
	ld 		0(p1) 												; wait for release
	ani 	0x80
	jnz 	__GCWaitRelease
	ld 		@1(p2) 												; restore P1.H
	xpah 	p1
	ld 		-2(p2) 												; restore saved value
	ccl
	adi 	0x20												; will make lower case -ve
	jp 		__GCNotLower
	cai 	0x20 												; capitalise
__GCNotLower:
	adi 	0xE0 												; fix up.
	xppc 	p3 													; return
	jmp 	GetChar 											; make re-entrant
	endsection 	GetChar

; ****************************************************************************************************************
; ****************************************************************************************************************
;
;			Read an ASCIIZ string from keyboard into P1 of length A maximum (excludes NULL terminator)
;
; ****************************************************************************************************************
; ****************************************************************************************************************

GetString:
	section GetString
	st 		@-1(p2) 											; save length on stack.
	xpah 	p3 													; save P3 on stack
	st 		@-1(p2)
	xpal 	p3
	st 		@-1(p2)
	lde
	st 		@-1(p2) 											; save E on stack
	ldi 	0 													; set E (current position) to A.
	xae
__GSLoop:
	lpi 	p3,Print-1 											; print the prompt (half coloured square)
	ldi 	155
	xppc 	p3
	lpi 	p3,GetChar-1 										; get a character
	xppc 	p3
	st 		-0x80(p1) 											; save it in the current position.
	lpi 	p3,Print-1 											; erase the prompt with backspace.
	ldi 	8
	xppc 	p3
	ld 		-0x80(p1) 											; re-read character
	ani 	0xE0 												; check if control key.
	jz 		__GSControlKey 
	lde 														; get current position.
	xor 	3(p2) 												; reached maximum length of buffer ?
	jz 		__GSLoop 											; if so, ignore the key and go round again.
	ld 		-0x80(p1) 											; get character and print it
	xppc 	p3
	ldi 	1 													; increment E
	ccl
	ade
	xae
	jmp 	__GSLoop 											; and go round again.
;
;	Handle control keys (0x00-0x1F)
;
__GSControlKey:
	ld 		-0x80(p1) 											; get typed in key
	xri 	8 													; check for backspace.
	jz 		__GSBackspace 			
	xri 	8!13 												; check for CR
	jnz 	__GSLoop 											; if not, ignore the key.
;
;	Carriage Return, ending input.
;
	st 		-0x80(p1) 											; replace the CR written with NULL terminator.
	ldi 	13 													; print CR
	xppc 	p3
	ld 		@1(p2) 												; pop E
	xae
	ld 		@1(p2) 												; pop P3
	xpal 	p3
	ld 		@1(p2)
	xpah 	p3
	ld 		@1(p2)												; pop A
	xppc 	p3 													; return
	jmp 	GetString 											; make re-entrant (probably unneccessary !!)
;
;	Backspace entered
;
__GSBackspace
	lde 														; if E = 0 we can't backspace any further.
	jz 		__GSLoop
	ldi 	8 													; backspace on screen
	xppc 	p3
	ldi 	0xFF 												; decrement E
	ccl
	ade
	xae
	jmp 	__GSLoop 											; and go round again.

	endsection GetString
