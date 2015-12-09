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

	lpi 	p2,0xFFF											; set up stack
	lpi		p1,test
	lpi 	p3,EvaluateExpression-1
	xppc 	p3
wait22:
	jmp 	wait22

test:
	db 		"(144,1)-196+Z",0  

	include expression.asm 										; screen I/O stuff.
