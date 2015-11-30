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

n1 = 31085
n2 = 1638

Maths:															; maths support routine.
	ldi 	0xC
	xpah 	p2
	ldi 	0x30
	xpal 	p2

	ldi 	n1 / 256
	st 		@-1(p2)
	ldi 	n1 & 255
	st 		@-1(p2)

	ldi 	n2 / 256
	st 		@-1(p2)
	ldi 	n2 & 255
	st 		@-1(p2)
	
	ldi 	'/'

	xri 	'+' 												; dispatch function in A to the executing code.
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
	ld 		2(p2) 												; read LSB of TOS 
	cad 	0(p2)
	st 		2(p2)
	ld 		3(p2) 												; read MSB of TOS
	cad 	1(p2)
	st 		3(p2)
	ld 		@2(p2)
	jmp 	MATH_Exit

; ******************************************************************************************************************
;											16 Bit shift left/right macros
; ******************************************************************************************************************

shiftLeft macro val
	ccl 													
	ld 		val(p2)
	add 	val(p2)
	st 		val(p2)
	ld 		val+1(p2)
	add 	val+1(p2)
	st 		val+1(p2)		
	endm

shiftRight macro val
	ccl
	ld 		val+1(p2)
	rrl 
	st 		val+1(p2)
	ld 		val(p2)
	rrl 
	st 		val(p2)
	endm

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
	shiftleft aLo 												; shift A left once.
	shiftright bLo 												; shift b right one.
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

denominatorHi = 1 												; input values to division
denominatorLo = 0 												; (see arithmetic.py)
numeratorHi = 3
numeratorLo = 2
bitHi = -1 														; bit shifted for division test.
bitLo = -2
quotientHi = -3 												; quotient
quotientLo = -4
remainderHi = -5 												; remainder
remainderLo = -6
tempLo = -7 													; temp (temp Hi is kept in A)

	ldi 	0 													; clear quotient and remainder
	st 		quotientHi(p2)
	st 		quotientLo(p2)
	st 		remainderHi(p2)
	st 		remainderLo(p2)
	st 		bitLo(p2) 											; set bit to 0x8000
	ldi 	0x80 
	st 		bitHi(p2)

	; TODO: unsign numerator and denominator.

__DivideLoop:
	ld 		bitLo(p2) 											; keep going until all bits done.
	or 		bitHi(p2)
	jz 		__DivideExit

	shiftleft remainderLo 										; shift remainder left.

	ld 		numeratorHi(p2)										; if numerator MSB is set
	jp 		__DivideNoIncRemainder

	ild 	remainderLo(p2) 									; then increment remainder
	jnz 	__DivideNoIncRemainder
	ild 	remainderHi(p2)
__DivideNoIncRemainder:

	scl 														; calculate remainder-denominator (temp)
	ld 		remainderLo(p2)
	cad 	denominatorLo(p2)
	st 		tempLo(p2) 											; save in temp.low
	ld 		remainderHi(p2)
	cad 	denominatorHi(p2) 									; temp.high is now in A
	jp 		__DivideRemainderGreater 							; if >= 0 then remainder >= denominator

__DivideContinue:
	shiftright 	bitLo 											; shift bit right
	shiftleft   numeratorLo 									; shift numerator left
	jmp 		__DivideLoop

__DivideRemainderGreater: 										; this is the "if temp >= 0 bit"
	st 		remainderHi(p2) 									; save temp.high value into remainder.high
	ld 		tempLo(p2) 											; copy temp.low to remainder.low
	st 		remainderLo(p2) 

	ld 		quotientLo(p2) 										; or bit into quotient
	or 		bitLo(p2)
	st 		quotientLo(p2)
	ld 		quotientHi(p2)
	or 		bitHi(p2)
	st 		quotientHi(p2)
	jmp 	__DivideContinue

__DivideExit:
	; TODO: Copy quotient/remainder to better positions.
	; TODO: resign quotient

	jmp 	MATH_Exit1


	endsection	SCMPDivide
