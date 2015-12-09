; ****************************************************************************************************************
; ****************************************************************************************************************
;
;												Expression Test
;
; ****************************************************************************************************************
; ****************************************************************************************************************


	cpu 	sc/mp

Variables = 0xCA0

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
	lpi 	p1,Variables
	ldi 	10 													
	st 		0(p1)												; A = 10
	ldi 	20
	st 		1(p1)												; B = 20
	ldi 	33
	st 		25(p1) 												; Z = 33

	lpi 	p1,0xCB0 											; $CB0 is the pointer
	ldi 	TestData&255 										; reset it.
	st 		0(p1)
	ldi 	TestData/256
	st 		1(p1)

TestLoop:
	lpi 	p3,0xCB0 											; read the pointer into P1.
	ld 		0(p3)
	xpal 	p1
	ld 		1(p3)
	xpah 	p1
	ld 		0(p1) 												; reached end of list.
	jz 		Complete

	lpi 	p2,0xFFF											; set up stack
	lpi 	p3,EvaluateExpression-1
	xppc 	p3
	xae 														; result in E
	csa 														; check error

	jp 		FailError
	lpi 	p3,0xCB0 											; read the pointer into P1.
	ld 		0(p3)
	xpal 	p1
	ld 		1(p3)
	xpah 	p1
FindEOS: 														; find end of string
	ld 		@1(p1)
	jnz 	FindEOS
	ld 		@1(p1) 												; get expected result
	xre
	jnz 	FailWrong 											; result doesn't match.
	xpal 	p1 													; write pointer back.
	st 		0(p3) 												
	xpah 	p1
	st 		1(p3)
	jmp 	TestLoop

FailWrong:
	ldi 	0xFF
	xae
	jmp 	FailWrong

FailError:
	lde 		
	jmp 	FailError

Complete:
	ldi 	0
	xae
	jmp 	Complete

	include expression.asm 										; screen I/O stuff.

TestData:
	include tests.inc
	db		0

