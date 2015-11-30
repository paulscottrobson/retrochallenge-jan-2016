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

n1 = 512
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
	xri 	'*'!'/'
	jz 		MATH_Divide

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

	section SCMPMultiply

aHi = 3 														; allocated values for A,B and Result.
aLo = 2 														; (see arithmetic.py)
bHi = 1
bLo = 0
resultHi = -1
resultLo = -2

	ldi 	0 													; clear result
	st 		resultHi(p2)
	st 		resultLo(p2)
__MultiplyLoop:
	ld 		bHi(p2) 											; if b is zero then exit
	or 		bLo(p2)
	jz 		__MultiplyExit
	ld 		bLo(p2) 											; if b bit 0 is set.
	ani 	1
	jz 		__MultiplyNoAdd
	ccl 														; add a to the result
	ld 		resultLo(p2)
	add 	aLo(p2)
	st 		resultLo(p2)
	ld 		resultHi(p2)
	add 	aHi(p2)
	st 		resultHi(p2)
__MultiplyNoAdd:
	ccl 														; shift a left one.
	ld 		aLo(p2)
	add 	aLo(p2)
	st 		aLo(p2)
	ld 		aHi(p2)
	add 	aHi(p2)
	st 		aHi(p2)		

	ccl 														; shift b right one.
	ld 		bHi(p2)
	rrl 
	st 		bHi(p2)
	ld 		bLo(p2)
	rrl 
	st 		bLo(p2)
	jmp 	__MultiplyLoop

__MultiplyExit:
	ld 		resultLo(p2) 										; copy result lo to what will be new TOS
	st 		2(p2)
	ld 		resultHi(p2)
	st 		3(p2)
	ld 		@2(p2) 												; fix up the number stack.
	endsection SCMPMultiply

MATH_Exit1:
	jmp 	MATH_Exit


; ******************************************************************************************************************
;											16 bit signed divide
; ******************************************************************************************************************

MATH_Divide:

	section 	SCMPDivide


	jmp 	MATH_Exit
	endsection	SCMPDivide
