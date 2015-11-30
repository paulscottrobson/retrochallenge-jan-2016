; ******************************************************************************************************************
; ******************************************************************************************************************
;
;										16 bit Arithmetic routines
;
; ******************************************************************************************************************
; ******************************************************************************************************************

;
;	Priority order : * / + - anything else VTL-2 might use ASCII -> int int -> ASCII
;
;	jmp	 	GoBoot 												; this will be at location 1.
	jmp 	Maths 												; maths routine, at location 3.
	; any other routines you care to call.

GoBoot:
	ldi 	(BootMonitor-1) & 255 								; jump to Boot Monitor
	xpal 	p3
	ldi 	(BootMonitor-1) / 256
	xpah 	p3
	xppc 	p3

; ******************************************************************************************************************
;
;		Maths routines : the (P2) stack functions as a number stack.  So to push $1234 on the stack you do
;
;		ld 	#$12
;		st 	@-1(p2) 					1(p2) is the MSB of TOS
;		ld 	#$34
;		st 	@-1(p2) 					0(p2) is the LSB of TOS
;
;		on entry, A is the function (+,-,*,/ etc.). P2 should be left in the 'correct' state afterwards,
;		so if you add two numbers then p2 will be 2 higher than when the routine was entered.
;
; ******************************************************************************************************************

n1 = 13
n2 = 16

Maths:															; maths support routine.
	ldi 	0xC
	xpah 	p2
	ldi 	0x2F
	xpal 	p2

	ldi 	n2 / 256
	st 		@-1(p2)
	ldi 	n2 & 255
	st 		@-1(p2)

	ldi 	n1 / 256
	st 		@-1(p2)
	ldi 	n1 & 255
	st 		@-1(p2)
	
	ldi 	'*'

	xri 	'+'
	jz 		MATH_Add
	xri 	'+'!'-'
	jz 		MATH_Subtract
	xri 	'-'!'*'
	jz 		MATH_Multiply

MATH_Exit:
	jmp  	MATH_Exit

; ******************************************************************************************************************
;														16 Bit Add
; ******************************************************************************************************************

MATH_Add:
	ccl 										
	ld 		@1(p2) 												; read LSB of TOS and unstack
	add 	1(p2)
	st 		1(p2)
	ld 		@1(p2) 												; read MSB of TOS and unstack
	add 	1(p2)
	st 		1(p2)
	jmp 	MATH_Exit

; ******************************************************************************************************************
;													16 Bit Subtract
; ******************************************************************************************************************

MATH_Subtract:
	scl 										
	ld 		@1(p2) 												; read LSB of TOS and unstack
	cad 	1(p2)
	st 		1(p2)
	ld 		@1(p2) 												; read MSB of TOS and unstack
	cad 	1(p2)
	st 		1(p2)
	jmp 	MATH_Exit

; ******************************************************************************************************************
;												16 bit signed multiply
; ******************************************************************************************************************

MATH_Multiply:
	ld 		2(p2) 												; copy multiplicand to space below stack
	st 		-2(p2)
	ld 		3(p2)
	st 		-1(p2)
	ldi 	0 													; clear result
	st 		2(p2)
	st 		3(p2)

	jmp 	MATH_Exit