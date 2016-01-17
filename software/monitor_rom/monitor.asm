; ******************************************************************************************************************
; ******************************************************************************************************************
;
;												Machine Language Monitor
;
; ******************************************************************************************************************
; ******************************************************************************************************************

		cpu	sc/mp

labels 		= 0xC00												; labels, 1 byte each
labelCount 	= 24 												; number of labels.

varBase 	= labels+labelCount 								; variables after labels start here.

cursor 		= varBase 											; cursor position ($00-$7F)
current 	= varBase+1 										; current address (lo,hi)
isInit      = varBase+3 										; if already initialised, this is $A7.
parPosn		= varBase+4 										; current param offset in buffer (low addr)
modifier  	= varBase+5 										; instruction modifier (@,Pn) when assembling.
kbdBuffer 	= varBase+6 										; 16 character keyboard buffer
kbdBufferLn = 16 										

codeStart 	= kbdBuffer+kbdBufferLn								; user code starts here after the keyboard buffer.
														
tapeDelay 	= 4 												; DLY parameter for 1 tape bit width.
																; (smaller = faster tape I/O - see file end.)

		org 	0x0000
		nop 													; mandatory pre-increment NOP

; ******************************************************************************************************************
;
;								Screen Handler (scrolling type) now in ROM Monitor
;
; ******************************************************************************************************************
	
		include macros.asm
		include screen.asm 

; ******************************************************************************************************************
;
;				Boot Up. First we check for a ROM @ $9000 and if it is 0x68 we boot there instead
;
; ******************************************************************************************************************

BootMonitor:
		ldi 	0x90 											; point P1 to $9000 which is the first ROM.
		xpah 	p1
		ld 		0(p1) 											; if that byte is $68, go straight there.
		xri 	0x68  											; we can boot into VTL-2 or whatever.
		jnz 	__BootMonitor
		xppc 	p1 												; e.g. JMP $9001
__BootMonitor:

; ******************************************************************************************************************
;
;									Find Top of Memory to initialise the stack.
;
;			(slightly tweaked to work round 4+12 emulator limitations - will work on real chip)
; ******************************************************************************************************************

		ldi 	0x0F 											; point P2 to theoretical top of RAM on basic m/c
		xpah 	p2 												; e.g. 0xFFF
		ldi 	0xFF 											; ideally you'd make this 0x003F and remove the ld
		xpal 	p2 												; but the emulators don't do 4+12 math. Only matters here.
		ld 		@64(p2) 										; fix the predecrement (wrap around not emulated)
FindTopMemory:
		ldi 	0xA5 											; try to write this to memory
		st 		@-64(p2) 										; predecrementing by 64.
		xor 	(p2) 											; did it write correctly.
		jnz 	FindTopMemory 									; now P2 points to top of memory.

; ******************************************************************************************************************
;
;												Clear the screen
;
; ******************************************************************************************************************

ClearScreen_Command:
		ldi 	0 												; set P1 to zero to access VRAM via write.
		xpah 	p1
		ldi 	0
ClearScreenLoop:
		xpal 	p1												; clear screen
		ldi 	' '
		st 		@1(p1)
		xpal 	p1
		jp 		ClearScreenLoop
		ldi 	Cursor/256 										; reset the cursor position to TOS
		xpah 	p1
		ldi 	Cursor&255
		xpal 	p1 
		ldi 	0 												; Note: could save 2 bytes here, P1.H is 0.
		st 		0(p1)											

; ****************************************************************************************************************
;
;												Check if initialised.
;
; ****************************************************************************************************************

		ld 		isInit-Cursor(p1) 								; have we initialised ?
		xri 	0xA7 											; if so this byte should be $A7
		jz 		CommandMainLoop
		ldi 	0xA7 											; set the initialised byte
		st 		isInit-Cursor(p1)

		ldi 	codeStart/256 									; set the initial work address
		st 		Current-Cursor+1(p1)
		ldi 	codeStart&255
		st 		Current-Cursor(p1)
																; print boot message - can lose this if required.
		ldi 	(PrintCharacter-1)/256 							; set P3 = print character.
		xpah 	p3 
		ldi 	(PrintCharacter-1)&255
		xpal 	p3
		ldi 	Message / 256 									; set P1 = boot message
		xpah 	p1
		ldi 	Message & 255
		xpal 	p1
MessageLoop:
		ld 		@1(p1) 											; read character
		jz 		InitialBeep 									; end of message
		xppc 	p3 												; print it
		jmp 	MessageLoop

Message:
		db 		"** SC/MP OS **",13 							; short boot message
		db 		"V0.94 PSR 2016",13
		db 		0

InitialBeep:
		ldi 	1 												; Beep on booting.
		cas 													; play low tone
		dly 	0xFF
		ldi 	5												; play high tone.
		cas
		dly 	0xFF
		ldi 	0 												; sound off.
		cas

; ****************************************************************************************************************
;
;													Main Loop
;
; ****************************************************************************************************************

CommandMainLoop:
		ldi 	(PrintAddressData-1)/256						; print Address only
		xpah 	p3
		ldi 	(PrintAddressData-1)&255
		xpal 	p3
		ldi 	0 												; no data elements
		xppc 	p3

		ldi 	(PrintCharacter-1)/256 							; set P3 = print character.
		xpah 	p3
		ldi 	(PrintCharacter-1)&255
		xpal 	p3
		ldi 	']'												; print the prompt.
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

__CmdMainLoop1:
		jmp 	CommandMainLoop

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
		st 		modifier-kbdBuffer(p1)							; clear the modifier.
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

; ****************************************************************************************************************
;
;						Find command in -1 (P2) (High) E (Low) in Command table
;	
; ****************************************************************************************************************

		ldi 	__commandList & 255 							; point P1 to the command list
		xpal 	p1
		ldi 	__commandList / 256 		
		xpah 	p1	
__FindCommandLoop:
		ld 		0(p1) 											; reached the end of the table ?
		or 		1(p1)											; which is marked by word 0000
		jz 		__CommandError
		ld 		@3(p1) 											; read low byte, and point to next
		xre
		jnz 	__FindCommandLoop 								; if different to LSB loop back.
		ld 		-2(p1) 											; read the high byte
		xor 	-1(p2) 											; if different to the MSB loop back.
		jnz 	__FindCommandLoop

; ****************************************************************************************************************
;
;				Found command, figure out if ASM or Command, if Command go to that routine
;
; ****************************************************************************************************************

		ldi 	(GetParameter-1) & 255 							; point P3 to the get parameter code.
		xpal 	p3
		ldi 	(GetParameter-1) / 256
		xpah 	p3

		ld 		-1(p1) 											; read the operation code.
		ani 	0xF0 											; look at the m-s-nibble - commands are 0x20.
		xri 	0x20
		jnz 	__Assembler

		ld 		-1(p1) 											; re-read it
		ccl
		add 	-1(p1) 											; double it
		ani 	0x1F 											; lower 5 bits only.
		adi 	__CommandTable & 255 							; make P1 point to the command table entry
		xpal 	p1
		ldi 	__CommandTable / 256 					
		xpah 	p1
		ld 		0(p1) 											; read low address
		xae
		ld 		1(p1) 											; read high address
		xpah 	p1 												; put in P1.H
		lde 													; get low address
		xpal 	p1 												; put in P1.L
		ld 		@-1(p1) 										; fix up for the pre-increment
		xppc 	p1 												; and go there.

__CommandError: 												; unknown command.
		ldi 	3 												; set the beeper on
		cas
		dly 	0xFF 											; short delay
		ldi 	0 												; set the beeper off
		cas
		jmp 	__CmdMainLoop1

; ****************************************************************************************************************
;												In line Assembler
; ****************************************************************************************************************

__Assembler:
		ld 		-1(p1) 											; this is the operation code to use.
		st 		@-1(p2) 										; push on the stack.

		xppc 	p3 												; evaluate (any) parameter if present
		csa 													; check carry flag set
		jp 		__ASMNoParameter  								; if clear, no parameter was provided.

		ldi 	parPosn & 255
		xpal 	p1 												; get the parameter LSB
		st 		@-1(p2) 										; push that on the stack, set P1 to parPosn
		ldi 	parPosn / 256
		xpah 	p1
		ld 		(p1) 											; read current position
		xpal 	p1 												; P1 now points to character.
		ld 		(p1) 											; read character
		xri 	'!'												; is it the label pling ?
		jnz 	__ASMContinue 									; we don't need to change this pointer , we should technically.
		ld 		(p2) 											; read the value, which is the label number
		scl
		cai 	labelCount 										; is it a valid label number
		jp 		__CommandError 									; no, beep.
		ld 		(p2) 											; re-read the label number
		xae 													; put in E
		ldi 	Labels/256 										; point p1 to labels
		xpah 	p1
		ldi 	Labels&255 
		xpal 	p1
		ld 		-0x80(p1) 										; read label indexed using E.
		st 		(p2) 											; save as the operand
		jmp 	__ASMContinue 									; and continue

__ASMNoParameter:
		ld 		(p2) 											; read the pushed operation code
		ani 	0x80 											; is bit 7 set ?
		jnz 	__CommandError 									; if it is, we need a parameter
		st 		@-1(p2) 										; push zero on the stack as a dummy parameter.

__ASMContinue:
		ldi 	Current/256 									; p3 = &Current Address
		xpah 	p3
		ldi 	Current&255
		xpal 	p3

		ld 		modifier-Current(p3) 							; get the modifier (e.g. @,Pn etc.)
		ccl
		add 	1(p2) 											; add to the opcode and write it back
		st 		1(p2)

		ld 		(p3) 											; read current address into P1
		xpal 	p1
		ld 		1(p3)
		xpah 	p1

		ld 		1(p2) 											; read opcode.
		st 		@1(p1) 											; write out to current address and bump it.
		jp 		__ASMExit 										; if +ve then no operand byte, exit.

		ld 		(p2) 											; read the operand byte
		st 		@1(p1) 											; write that out as well.

		ld 		modifier-Current(p3) 							; look at the modifier 
		jnz 	__ASMExit 										; if non zero we don't need to do anything P0 = 00
		ld 		1(p2) 											; DLY is a special case
		xri 	0x8F 											; where the modifier is zero but not PC relative.
		jz 		__ASMExit 												

		ld 		-1(p1) 											; read operand
		ccl 													; one fewer because we want the current addr+1 low
		cad 	(p3) 											; subtract the current address low.
		st 		-1(p1) 											; write it back

		ld 		1(p2) 											; read opcode again
		ani 	0xF0 											; is it 9x (a JMP command)
		xri 	0x90
		jnz 	__ASMExit 										; if not, we are done
		dld 	-1(p1) 											; one fewer because of the pre-increment
__ASMExit:
		xpal 	p1 												; write current address back out
		st 		(p3)
		xpah 	p1
		st 		1(p3)
		ld 		@2(p2) 											; drop stack values.

		jmp 	__CmdMainLoop2 									; back to command loop

; ****************************************************************************************************************
; ****************************************************************************************************************
;
;												Commands Section
;
; ****************************************************************************************************************
; ****************************************************************************************************************

; ****************************************************************************************************************
;											A : Set Current address
; ****************************************************************************************************************

Address_Command:
		xppc 	p3 												; get parameter if exists
		xppc 	p3 												; update current if exists.
		jmp 	__CmdMainLoop2

__CmdParameterFail:
		ldi 	2 												; set the beeper on
		cas
		dly 	0xFF 											; short delay
		ldi 	0 												; set the beeper off
		cas
__CmdMainLoop2:													; and go back to the start.
		ldi 	(CommandMainLoop-1) & 255
		xpal 	p3
		ldi 	(CommandMainLoop-1) / 256
		xpah 	p3
		xppc 	p3

; ****************************************************************************************************************
;										G : Go (Address must be specified.)
; ****************************************************************************************************************

Go_Command:
		xppc 	p3 												; get parameter, which should exist.
		csa 													; look at CY/L which is set if it was.
		jp 		__CmdParameterFail 								; if it is clear, beep an error.
		xpal 	p1 												; copy P1 to P3
		xpal 	p3
		xpah 	p1
		xpah 	p3
		ld 		@-1(p3) 										; fix up for pre increment
		xppc 	p3 												; call the routine.		
__CmdMainLoop3:
		jmp 	__CmdMainLoop2 									; re-enter monitor.

; ****************************************************************************************************************
;			PUT Write to tape : data mandatory, it is the byte count from the current address.
; ****************************************************************************************************************

PutTape_Command:
		xppc 	p3 												; get the bytes to write.
		csa 													; if CC, no value was provided
		jp 		__CmdParameterFail 								; which is an error.
		xpal 	p1 												; store low byte count in -1(P2)
		st 		-1(p2)
		xpah 	p1 												; store high byte count in -2(P2)
		st 		-2(p2)
		ccl 													; skip over the update current address
		xppc 	p3 												; this won't update current address as CY/L = 0
		xppc 	p3 												; and load the current address into P1.
		ldi 	0 												; set the output tape bit low
		xae
		sio
		ldi 	32 												; tape leader
		st 		-3(p2)
_PutTapeLeader:
		dly 	0xFF
		dld 	-3(p2)
		jnz 	_PutTapeLeader
_PutTapeByte:													; output byte at P1
		ldi 	0 												; set output bit to 0
		xae 	
		sio
		dly 	tapeDelay * 4 									; 0 continuation bit + gap between tapes with no signal 
		ldi 	0x1 											; set bit high
		xae
		sio 
		ldi 	0
		dly 	tapeDelay 										; output the start bit.
		ld 		@1(p1) 											; read the byte and put it in E.
		xae
		ldi 	8 												; output 8 bits
		st 		-3(p2)
_PutTapeBit:
		sio 													; output MSB and shift
		ldi 	0
		dly 	tapeDelay 								
		dld 	-3(p2) 											; do all 8 bits.
		jnz 	_PutTapeBit
		dld 	-1(p2) 											; decrement counter
		jnz 	_PutTapeByte
		dld 	-2(p2) 											; note MSB goes 0 to -1 when finished.
		jp 		_PutTapeByte
		ldi 	0x01 											; add the termination bit.
		xae
		sio
		ldi 	0 												; put that out.
		dly 	TapeDelay
		ldi 	0 												; and set the leve back to 0
		xae 
		sio
__CmdMainLoop4:
		jmp 	__CmdMainLoop3

__CmdParameterFail1:
		jmp 	__CmdParameterFail

; ****************************************************************************************************************
;						GET [addr] load tape to current position or given address.
; ****************************************************************************************************************

LoadTape_Command:
		xppc	p3 												; get parameter
		xppc 	p3												; update current address
		xppc 	p3 												; current address to P1.
		ldi 	0x8 											; point P3 to the keyboard.
		xpah 	p3
__GetTapeWait:
		ld 		0(p3) 											; check keyboard break
		ani 	0x80
		jnz 	__CmdParameterFail1
		sio 													; wait for the start bit, examine tape in.
		lde 
		jp 		__GetTapeWait
		dly 	tapeDelay * 3 / 2 								; half way into the first bit.
		ldi 	8 												; read in 8 bits.
		st 		-1(p2)
__GetTapeBits:
		sio 													; read in one bit
		ldi 	0
		dly 	tapeDelay 										; delay to next bit
		dld 	-1(p2) 											; read 8 bits.
		jnz 	__GetTapeBits 
		lde 													; store byte at current address
		st 		@1(p1)
		sio 													; read in the byte, which is zero if continuing.
		lde  													; examine bit 7 shifted in.
		jp 		__GetTapeWait 									; if zero, wait for the next start bit.
__CmdMainLoop5:
		jmp 	__CmdMainLoop4

; ****************************************************************************************************************
;										L : nn Set Label to current address
; ****************************************************************************************************************

Label_Command:
		xppc 	p3 												; get parameter
		csa 													; check it exists, CY/L must be set
		jp 		__CmdParameterFail1
		xpal 	p1 												; get into A
		xae 													; put into E
		lde 													; get back
		scl
		cai 	labelCount 										; check is < number of labels
		jp 		__CmdParameterFail1

		ldi 	Current/256 									; point P1 to current address
		xpah 	p1
		ldi 	Current&255
		xpal 	p1
		ld 		(p1) 											; read current address
		xpal 	p1 												; save in P1.Low
		ldi 	Labels&255 										; get labels low byte in same page as current address
		ccl
		ade 													; add label # to it
		xpal 	p1 												; put in P1.L and restore current address low
		st 		(p1) 											; store current address low in label space.
		jmp 	__CmdMainLoop5 									; and exit.

; ****************************************************************************************************************
;											M :	Dump Memory
; ****************************************************************************************************************

MemoryDump_Command:
		xppc 	p3 												; get parameter if exists
		xppc 	p3 												; update current if exists.
		ldi 	7 												; print seven rows
		st 		@-1(p2)
__DCLoop:
		ldi 	(PrintAddressData-1)/256						; print one row of address and data.
		xpah 	p3
		ldi 	(PrintAddressData-1)&255
		xpal 	p3
		ldi 	4
		xppc 	p3
		ldi 	Current/256 									; point P1 to current
		xpah 	p1
		ldi 	Current&255 
		xpal 	p1
		ld 		0(p1) 											; add 4 to current address
		ccl
		adi 	4
		st 		0(p1)
		ld 		1(p1)
		adi 	0
		st 		1(p1)
		dld 	(p2) 											; do it 7 times
		jnz 	__DCLoop
		ld 		@1(p2) 											; fix up stack.
__CmdMainLoop6:
		jmp 	__CmdMainLoop5


; ****************************************************************************************************************
;								B: Enter Bytes (no address, sequence of byte data)
; ****************************************************************************************************************

EnterBytes_Command:
		ldi 	(GetParameter-1) & 255 							; P3 = Get Parameter routine
		xpal 	p3
		ldi 	(GetParameter-1) / 256 	
		xpah 	p3
		xppc 	p3 												; get the parameter.
		csa 													; look at carry
		jp 		__CmdMainLoop5 									; carry clear, no value.
		ldi 	Current/256 									; make P1 point to current
		xpah 	p1
		ldi 	Current&255 										
		xpal 	p1 												; this pulls the byte value into A
		xae 													; save it in E
		ld 		0(p1) 											; copy address to save to into P3
		xpal 	p3
		ld 		1(p1) 
		xpah 	p3 
		lde 													; get byte back
		st 		(p3) 											; save it in that location
		ild 	0(p1) 											; bump current address and go back and try again.
		jnz 	EnterBytes_Command
		ild 	1(p1)
		jmp 	EnterBytes_Command

; ****************************************************************************************************************
;											D [aaaa] Disassembler
; ****************************************************************************************************************

Disassemble_Command:	
		xppc 	p3 												; evaluate
		xppc 	p3 												; update current if new value
		ldi 	7												; instructions to disassemble counter
		st 		@-4(p2)											; p2 + 0 = counter p2 + 1 = opcode p2 + 2 = operand
__DAssLoop:														; p2 + 3 = opcode - base opcode.
		ldi 	(PrintAddressData-1)/256						; print Address only
		xpah 	p3
		ldi 	(PrintAddressData-1)&255
		xpal 	p3
		ldi 	0
		xppc 	p3
		ldi 	Current / 256 									; point P1 to current address
		xpah 	p1
		ldi 	Current & 255
		xpal 	p1
		ld 		0(p1) 											; load current address into P3
		xpal 	p3
		ld 		1(p1)
		xpah 	p3
		ld 		@1(p3) 											; read opcode
		st 		1(p2) 											; save it
		jp 		__DAssNoOperand 								; if +ve no operand
		ld 		@1(p3) 											; read operand
		st 		2(p2) 											; save it
__DAssNoOperand:
		ldi 	(__CommandListEnd-3) & 255
		xpal 	p3 												; update current position, setting P3 to last entry
		st 		0(p1)											; in command table.
		ldi 	(__CommandListEnd-3) / 256
		xpah 	p3
		st 		1(p1)

__DAssFindOpcode: 												; the table is : text (word) opcode (byte)
		ld 		1(p2) 											; get opcode
		xor 	2(p3) 											; check in the same 8 byte page.
		ani 	0xF0
		jnz 	__DAssNextOpcode
		ld 		1(p2) 											; get opcode
		scl
		cad 	2(p3) 											; subtract the base opcode.
		st 		3(p2) 											; save a the offset (possible)
		ani 	0xE0 											; it needs to be 0x20 or less
		jz 		__DAssFoundOpcode 								; if >= 0 then found the correct opcode.
__DAssNextOpcode:
		ld 		@-3(p3) 										; go to previous entry in table
		jmp 	__DAssFindOpcode

__DAssLoop2:
		jmp 	__DAssLoop
__CmdMainLoop7:
		jmp 	__CmdMainLoop6

__DAssFoundOpcode:
		ld 		2(p3) 											; look at opcode that matched.
		ani 	0x87 											; match with 1xxx x100
		xri 	0x84 											; which is all the immediate instructions.		
		jnz 	__DAssNotImmediate
		ld 		3(p2) 											; only do immediate if base offset is zero
		jnz 	__DAssNextOpcode 								; fixes C0-C7 being LD, but C4 being LDI.
__DAssNotImmediate:
		ld 		0(p3) 											; save LSB of text on stack
		st 		@-1(p2)
		ld 		1(p3) 											; and the MSB of text on stack
		st 		@-1(p2)

		ldi 	(PrintCharacter-1) / 256 						; set P3 up to print characters
		xpah 	p3
		ldi 	(PrintCharacter-1) & 255 
		xpal 	p3
		ldi 	' '												; print a space.
		xppc 	p3

		ldi 	3 												; print 3 characters
		st 		@-1(p2) 										; so +0 is count, +1 = text MSB, +2 = text LSB
__DAssPrintMnemonic:
		ld 		1(p2) 											; get text MSB which is in bits .xxxxx..
		sr 														; shift right twice.
		sr
		ani 	0x1F 											; lower 5 bits only
		jz 		__DAssSkipSpace 								; don't print spaces (00000)
		ccl 													; make it 7 bit ASCII code.
		adi 	64 							
		xppc 	p3 												; display the character
__DAssSkipSpace:
		ldi 	5 												; now shift the encoded data left 5 times
		st 		-1(p2)
__DAssShiftEncode:
		ccl
		ld 		2(p2)
		add 	2(p2)
		st 		2(p2)
		ld 		1(p2)
		add 	1(p2)
		st 		1(p2)
		dld 	-1(p2)
		jnz 	__DAssShiftEncode
		dld 	0(p2) 											; done all three characters
		jnz 	__DAssPrintMnemonic 							; if not keep going.

		ld 		@3(p2) 											; remove mnemonic stuff off the stack.

		ld 		3(p2) 											; print instruction modifier if required.
		jnz 	__DAssPrintModifier

__DAssPrintOperand:
		ld 		1(p2) 											; get original opcode
		jp 		__DAssNext 										; if no operand go to next line of disassembly.
		ldi 	(PrintHexByte-1) / 256 							; set P3 to point to the hex printer
		xpah 	p3
		ldi 	(PrintHexByte-1) & 255
		xpal 	p3
		ld 		2(p2) 											; get operand
		scl 
		xppc 	p3 												; print it out with a leading space.

__DAssNext:
		ldi 	(PrintCharacter-1) / 256 						; set P3 up to print characters
		xpah 	p3
		ldi 	(PrintCharacter-1) & 255 
		xpal 	p3
		ldi 	13												; print a newline.
		xppc 	p3

		dld 	0(p2) 											; done all 6 lines
		jnz 	__DAssLoop2 									; no, go round again.
		ld 		@4(p2) 											; fix up the stack.
		jmp 	__CmdMainLoop7 									; and time to exit.


__DAssPrintModifier:
		ldi 	' '												; print leading space
		xppc 	p3
		ld 		3(p2) 											; read modifier
		ani 	0x04 											; is @ bit set
		jz 		__DAssNotAutoIndexed
		ldi 	'@'												; print '@'
		xppc 	p3
__DAssNotAutoIndexed:
		ldi 	'P'												; print 'P'
		xppc 	p3
		ld 		3(p2) 											; print pointer register
		ani 	3
		ori 	'0'
		xppc 	p3
		jmp 	__DAssPrintOperand 								; and print operand.


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
		ld 		1(p1) 											; read high byte of address
		ccl
		xppc 	p3												; print w/o leading space
		ld 		0(p1)											; read low byte of address
		ccl 	
		xppc 	p3 												; print w/o leading space.
		xae 													; put in E
		ld 		1(p1) 											; high byte to P1.H
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

; ****************************************************************************************************************
;
;		Look at the parameter string for a parameter, processing @ and Pn as you go, CS if parameter found
; 		CC otherwise. Return parameter value in P1. Falls through
;
; ****************************************************************************************************************

GetParameter:
		ldi 	parPosn/256 									; current position into P1
		xpah 	p1
		ldi 	parPosn&255 					
		xpal 	p1
		ldi 	0 												; -1(p2) is the low byte result
		st 		-1(p2) 											; -2(p2) is the high byte result
		st 		-2(p2)

		ld 		(p1) 											; read the current position,P1 points to character
		xpal 	p1 												; when we put it in P1.L

__GPASkip:														; skip over spaces to first alphanumeric.
		ld 		(p1) 											; read character
		jz 		__GPAExitFail 									; if zero, then end of the input string.
		ld 		@1(p1) 											; read it, advancing.
		xri 	32 												; is it space ?
		jz 		__GPASkip 
		xri 	32!'@'											; is it @ ?
		jz 		__GPAAtModifier 
		xri 	'@'!'P' 										; is it P ?
		jz 		__GPAPointerModifier

__GPANextCharacter:
		ld 		-1(p1) 											; get value back after post increment.
		ccl
		adi 	128-48 											; this will be +ve if A < '0'
		jp 		__GPAExitFail
		cai 	9 												; will be +ve if A < '9', CY/L was clear.	
		jp 		__GPAFoundHex
		cai 	7 												; will be +ve if A < 'A', CY/L was set
		jp 		__GPAExitFail
		adi 	0xFF-0x85-1 									; will be +ve if A > 'F', CY/L was set.
		jp 		__GPAExitFail 					
		adi 	(0x70-0xFA) & 0xFF 								; make the range as below, CY/L was clear
__GPAFoundHex: 													; enter here 0-9 = $76..$7F, A-F = $70..$75
		ccl  													; convert that to a hex nibble.
		adi 	10
		ani 	0xF
		xae 													; save in E, temporarily
		ldi 	4 												; now shift the result 4 bits to the left.
		st 		-3(p2) 											; -3(p2) is the counter
__GPAShift:
		ccl
		ld 		-1(p2) 											; shift 16 bit result 1 bit to the left.
		add 	-1(p2)
		st 		-1(p2)
		ld 		-2(p2)
		add 	-2(p2)
		st 		-2(p2)
		dld 	-3(p2) 											; do it four times
		jnz 	__GPAShift 	
		ld 		-1(p2) 											; Or E into the LSB
		ore
		st 		-1(p2)

		ld 		@1(p1) 											; look at next character, post incrementing.
		scl
		cai 	34 												; if it is after space and ! (label marker)
		jp 		__GPANextCharacter 								; go back and put it in place.

		ld 		@-1(p1) 										; undo the increment, incase we've just read zero.

		ldi 	parPosn & 255 									; put the parPosn address in P1.L, new posn into A
		xpal 	p1
		st 		(p1) 											; and write it back
		ld 		-1(p2) 											; put the result into P1
		xpal 	p1
		ld 		-2(p2)
		xpah 	p1
		scl 													; set CY/L to indicate okay
		jmp 	__GPAExit

__GPAPointerModifier:
		ld 		(p1) 											; read P<something> ?
		ani 	0xFC 											; is it '0' .. '3'?
		xri 	'0'
		jnz 	__GPAExitFail 									; it didn't work, not 0..3
		ld 		@1(p1) 											; re-read it and advance
		ani 	3												; lower 2 bits only
		jmp 	__GPAAdjustModifier
__GPAAtModifier:
		ldi 	4 												; set modifier adjustment to +4
__GPAAdjustModifier:
		st 		-3(p2) 
		ldi 	modifier & 255 									; point P1 to modifier, save current address in E
		xpal 	p1
		xae 
		ld 		(p1) 											; read modifier
		ccl
		add 	-3(p2) 											; add the modifying value to it.
		st 		(p1) 											; write modifier.
		lde 													; restore current address to P1.L
		xpal 	p1
		jmp 	__GPASkip 										; go back to skip over.

__GPAExitFail:
		ccl 													; carry clear, e.g. nothing read in / error.
__GPAExit:
		xppc 	p3

; ****************************************************************************************************************
;
;		Store parameter value in P1 in the current address, if CS. Falls through.
;
; ****************************************************************************************************************

UpdateCurrentAddress:
		csa 													; get status reg
		jp 		__UCAExit 										; if carry flag clear then exit.

		ldi 	current & 255 									; current address to P1.L, acquired address to E
		xpal 	p1
		xae
		ldi 	current / 256 									; current address to P1.H, acquired to A
		xpah 	p1
		st 		1(p1) 											; store address back
		lde
		st 		0(p1)
__UCAExit:
		xppc 	p3

; ****************************************************************************************************************
;
;		Get current address into P1.
;
; ****************************************************************************************************************

GetCurrentAddress:
		ldi 	current/256 									; current address ptr in P1
		xpah 	p1
		ldi 	current&255
		xpal 	p1
		ld 		0(p1) 											; low byte to E
		xae
		ld 		1(p1) 											; high byte to A
		xpah 	p1 												; then to P1.H
		lde 													; low byte to P1.L
		xpal 	p1 
		xppc 	p3

; ****************************************************************************************************************
;
;											List of commands and Jump Table
;
; ****************************************************************************************************************

		include commands.inc 									; must be at the end, so the command table is in
																; the same page.

; ****************************************************************************************************************
;
;													Tape Format. 
;
; ****************************************************************************************************************
;
;		1 x start bit 		'1' value is held for period of time.
;		8 x data bits  		'0 or 1' value is held for a period of time.
;		1 x continuation	'0' if another bit follows, '1' if end.
;		at least 2 bit times between bytes.
;
;		Use DLY 4 with A = 0 (DLY 6 to skip half-start)
; 		= 13 + 2 * 0 + 514 * 4 microcycles
;		= 2,069 microcycles
;	
;		which is about 240 bits per second.
;
; ****************************************************************************************************************
;
;												Monitor Commands
;
; ****************************************************************************************************************
;
;		A [aaaa] 			Set current address to aaaa
;		B [cc] [dd] [ee]..	Put Bytes cc dd ee etc. in memory from current address onwards.
; 		C 					Clear screen
;		D [aaaa] 			Disassemble from aaaa (7 lines of disassembly)
;		G aaaa 				Run from address - address must be given - return with XPPC P3
; 		L n 				Set label n to the current address (up to 24 labels 00-17)
; 		M [aaaa] 			Memory dump from current address/aaaa (7 lines, 4 bytes per line)
; 		GET [aaaa] 			Load tape to current address/aaa
;		PUT [nnnn]			Write nnnn bytes from current address onwards to tape.
;
;		Command Line Assembler:
;
;		Standard SC/MP mnemonics, except for XPAH, XPAL, XPPC, HALT and DINT which are XPH XPL XPC HLT DIN
;		respectively (4 character mnemonics not supported)
;
;		Address modes are written as such:
;
;		Direct:			LD 	address 					(offset auto calculated, also for jump)
;		Indexed:		LD  P1 7 						(normally ld 7(p1))
;		Immediate:		DLY 42 					
;		AutoIndexed:	LD @P1 4 						(normally ld @4(p1))
;
;		Labels are accessed via the pling, so to jump to label 4 rather than address 4 you write
;
;		JMP 4!
;
;		Documentation of the Mathematics functions are in the included file maths.asm. Sort of.
;
; ****************************************************************************************************************
