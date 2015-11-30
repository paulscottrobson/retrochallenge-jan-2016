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
	jmp	 	GoBoot 												; this will be at location 1.
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
;		Returns CS on error (division by zero) - in this case the parameters are not touched.
;
;		Note that division uses a fair chunk of the stack :)
;
; ******************************************************************************************************************

Maths:															; maths support routine.

;n1 = ((-524 + 0x10000) & 0xFFFF)
;n2 = ((7 + 0x10000) & 0xFFFF)
;op = '/'
;
;	ldi 	0xC 												; bodge a stack
;	xpah 	p2
;	ldi 	0x30
;	xpal 	p2
;	ldi 	n1 / 256 											; push n1
;	st 		@-1(p2)
;	ldi 	n1 & 255
;	st 		@-1(p2)
;	ldi 	n2 / 256 											; push n2
;	st 		@-1(p2)
;	ldi 	n2 & 255
;	st 		@-1(p2)
;	ldi 	op

	xri 	'+' 												; dispatch function in A to the executing code.
	jz 		MATH_Add
	xri 	'+'!'-'
	jz 		MATH_Subtract
	xri 	'-'!'*'
	jz 		MATH_Multiply
	xri 	'*'!'/'
	jz 		MATH_Divide
	scl 														; error, unknown command.
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
	ccl
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
	ccl
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

	ccl
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
signCount = -7 													; sign of result (bit 0)
eTemp = -8 														; temporary value of sign.

	ld 		denominatorLo(p2) 									; check denominator 
	or 		denominatorHi(p2) 
	scl 														; if zero return CY/L Set
	jz 		MATH_Exit1

	ldi 	0 													; clear quotient and remainder
	st 		quotientHi(p2)
	st 		quotientLo(p2)
	st 		remainderHi(p2)
	st 		remainderLo(p2)
	st 		signCount(p2)
	st 		bitLo(p2) 											; set bit to 0x8000
	ldi 	0x80 
	st 		bitHi(p2)

	lde 														; save E
	st 		eTemp(p2)

	ldi 	3
__DivideUnsignLoop:
	xae 														; store in E
	ld 		-0x80(p2) 											; read high byte
	jp 		__DivideNotSigned 									; if +ve then skip
	ild 	signCount(p2) 										; bump sign count
	ld 		@-1(p2) 											; dec P2 to access the LSB
	ldi 	0
	scl 
	cad 	-0x80(p2)
	st 		-0x80(p2)
	ld 		@1(p2) 												; inc P2 to access the MSB
	ldi 	0
	cad 	-0x80(p2)
	st 		-0x80(p2)
__DivideNotSigned:
	xae 														; retrieve E
	scl 														; subtract 2
	cai 	2
	jp 		__DivideUnsignLoop 									; not finished yet.
	jmp 	__DivideLoop

__MATH_Exit2
	jmp 	MATH_Exit1

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
	xae 														; save in E.
	ld 		remainderHi(p2)
	cad 	denominatorHi(p2) 									; temp.high is now in A
	jp 		__DivideRemainderGreater 							; if >= 0 then remainder >= denominator

__DivideContinue:
	shiftright 	bitLo 											; shift bit right
	shiftleft   numeratorLo 									; shift numerator left
	jmp 		__DivideLoop

__DivideExit:
	ld 		signCount(p2) 										; is the result signed
	ani 	0x01
	jz 		__DivideComplete
	scl 														; if so, reapply the sign.
	ldi 	0
	cad 	quotientLo(p2)
	st 		quotientLo(p2)
	ldi 	0
	cad 	quotientHi(p2)
	st 		quotientHi(p2)

__DivideComplete:
	ld 		quotientHi(p2) 										; copy quotient to what will be TOS
	st 		3(p2)
	ld 		quotientLo(p2)
	st 		2(p2)
	ld 		remainderHi(p2) 									; put remainder immediately after it if we want it
	st 		1(p2)
	ld 		remainderLo(p2) 
	st 		0(p2)

	ld 		eTemp(p2) 											; restore E
	xae 
	ld 		@2(p2) 												; fix stack back up leaving quotient and hidden remainder
	ccl 														; return no error.
	jmp 	__MATH_Exit2

__DivideRemainderGreater: 										; this is the "if temp >= 0 bit"
	st 		remainderHi(p2) 									; save temp.high value into remainder.high
	lde 														; copy temp.low to remainder.low
	st 		remainderLo(p2) 

	ld 		quotientLo(p2) 										; or bit into quotient
	or 		bitLo(p2)
	st 		quotientLo(p2)
	ld 		quotientHi(p2)
	or 		bitHi(p2)
	st 		quotientHi(p2)
	jmp 	__DivideContinue


	endsection	SCMPDivide
