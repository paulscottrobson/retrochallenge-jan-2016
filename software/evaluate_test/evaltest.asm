; ****************************************************************************************************************
; ****************************************************************************************************************
;
;												Evaluation Test
;
; ****************************************************************************************************************
; ****************************************************************************************************************

; ****************************************************************************************************************
;												 Memory Allocation
; ****************************************************************************************************************

	cpu 	sc/mp
	
VariableBase = 0xD00 											; Base of variables. Variables start from here, 2 bytes
																; each, 6 bit ASCII (e.g. @,A,B,C)
																; VTL-2 other variables work backwards from here.
																	; must be on a page boundary.

MathLibrary = 3 												; Monitor Mathematics Routine Address

KeyboardBuffer = 0xC00											; dummies
KeyboardBufferSize = 16

Pointer = 0xCFE

ProgramSpace = 0x1000 											; Page with program memory.

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

	lpi 	p1,VariableBase 									; put multiples of 37 in @,A,B,C etc.
	lpi 	p2,0
Fill: 															; A = MSB, E = LSB
	xpal 	p2
	st 		@1(p1)
	ccl
	adi 	37
	xpal 	p2
	
	xpah 	p2
	adi 	0
	st 		@1(p1)
	xpah	p2

	xpah 	p1
	xri 	0xE
	jz 		SetPointer
	xri 	0xE
	xpah 	p1
	jmp 	Fill

SetPointer:
	lpi 	p1,Pointer 											; reset pointer to testdata
	ldi 	TestData & 255
	st 		0(p1)
	ldi 	TestData / 256
	st 		1(p1)

TestLoop:
	lpi 	p2,Pointer 											; read pointer into P1
	ld 		0(p2)
	xpal 	p1
	ld 		1(p2)
	xpah 	p1	
	ld 		0(p1)												; read first character
	jz 		Completed 											; if zero, test over.

	lpi 	p2,0xFFF											; reset stack
	lpi 	p3,EvaluateExpression-1 							; set P3 to evaluate
	xppc 	p3 													; evaluate expression.
	csa 														; exit if CS.
	ani 	0x80
	jnz 	Failed
	lpi 	p3,Pointer 											; read pointer into P1
	ld 		0(p3)
	xpal 	p1
	ld 		1(p3)
	xpah 	p1	
FindEnd: 														; find end of the test expression string.
	ld 		@1(p1)
	jnz 	FindEnd
	ld 		@1(p1) 												; read answer LSB
	xor 	0(p2) 												; check it
	jnz 	Failed
	ld 		@1(p1)												; read and check MSB of answer
	xor 	1(p2)
	jnz 	Failed
	xpal 	p1 													; write back to pointer
	st 		0(p3) 
	xpah 	p1
	st 		1(p3)
	ld 		@2(p2) 												; pop result
	xpal 	p2 													; check it is $0FFF
	xri 	0xFF
	jnz 	Failed
	xpah 	p2
	xri 	0x0F
	jnz 	Failed
	jmp 	TestLoop
wait:
	jmp 	wait

Failed: 														; set AE to $FF and stop.
	ldi 	255
	xae
	jmp 	Failed

Completed:														; set AE to 0 and stop.
	ldi 	0
	xae
	jmp 	Completed

GetChar:														; dummies to shut assembler up, shouldn't be called
GetString:
	jmp 	GetChar												; calling will stop program

	include ..\vtl-2\Source\evaluate.asm 						; evaluate an expression code from VTL-2 directory
;
;	Q+A test data. 
;
TestData:
	db 	"111+1000",0
	dw 	1111
	db 	"22/2",0
	dw 	11
	db 	"A",0
	dw 	37

	db 	0