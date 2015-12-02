; ******************************************************************************************************************
; ******************************************************************************************************************
;
;										16 bit Arithmetic routines
;
; ******************************************************************************************************************
; ******************************************************************************************************************

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
;										' Random Number generator
; ******************************************************************************************************************

MATH_Random:
	ldi 	Random & 255 										; set P1 to point to RNG, push P1 on stack.
	xpal 	p1
	st 		@-3(p2)												; we allow 2 bytes for the final result here.
	ldi 	Random / 256 	
	xpah 	p1
	st 		@-1(p2)
	ccl 														; shift random seed right.
	ld 		1(p1)
	rrl
	st 		1(p1)
	ld 		0(p1)
	rrl 
	st 		0(p1)
	csa 														; look at carry out, lost bit.
	ani 	0x80 												; is it clear ?
	jnz 	__MARandomNoXor
	ld 		0(p1) 												; xor lfsr with $A1A1
	xri 	0xA1
	st 		0(p1)
	ld 		1(p1)
	xri 	0xA1
	st 		1(p1)
__MARandomNoXor:
	ld 		0(p1) 												; put the LFSR in the result space on the stack
	st 		2(p2)
	ld 		1(p1)
	st 		3(p2)
	ld 		@1(p2) 												; restore P1
	xpah 	p1
	ld 		@1(p2)
	xpal 	p1
	ccl 														; no problems
	jmp 	MATH_Exit

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
;		Supported : + - * / ? (ASCII @ p1 -> integer, p1 updated) ' (random number) \ (unsigned divide)
;
;		Returns CS on error (division by zero, bad ASCII String) - in this case the parameters are not touched.
;
;		Note that division uses a fair chunk of the stack :)
;
; ******************************************************************************************************************

Maths:															; maths support routine.

	xri 	'+' 												; 16 bit addition
	jz 		MATH_Add 
	xri 	'+'!'-' 											; 16 bit subtraction
	jz 		MATH_Subtract
	xri 	'-'!'*'												; 16 bit signed/unsigned multiplication
	jz 		MATH_Multiply 										
	xri 	'*'!'/' 											; 16 bit signed division
	ccl 
	jz 		MATH_Divide2
	xri 	'/'!'\\' 											; 16 bit unsigned division
	scl
	jz 		MATH_Divide2
	xri 	'\\'!'?' 											; ASCII (P1) -> Integer (? operator)
	jz 		MATH_ToInteger
	xri 	'?'!0x27 											; Random number generator (' operator)
	jz 		MATH_Random 
MATH_Error:
	scl 														; error, unknown command.
MATH_Exit:
	xppc 	p3 													; return
	jmp  	Maths 												; re-entrant

; ******************************************************************************************************************
;													+ :	16 Bit Add
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
;												 - : 16 Bit Subtract
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
;									'*' : 16 bit signed or unsigned multiply
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
;								? Convert string at P1 to 16 bit integer base 10
; ******************************************************************************************************************

MATH_Divide2:
	jmp 	MATH_Divide

MATH_ToInteger:

	section SCMPToInteger

digitCount = -1													; digits converted.
resultHi = -2  													; result is pushed at the end
resultLo = -3 
shiftCount = -4 												; counter used when multiplying by 10.
tempHi = -5 													; temporary result for x 10.
tempLo = -6

	ldi 	0 													; clear digitcount and result to zero
	st 		digitCount(p2)
	st 		resultHi(p2)
	st 		resultLo(p2)
ToInt_Loop:
	ld 		0(p1) 												; read next digit
	scl 	
	cai 	'9'+1
	jp 		ToInt_End 											; if > 9 then fail.
	adi 	128+10 												; if < 0 then fail
	jp 		ToInt_End
	ild 	digitCount(p2) 										; increment count of digits converted.
	ldi 	2 													; set shift counter to 2
	st 		shiftCount(p2)
	ld 		resultHi(p2) 										; copy result current to temp
	st 		tempHi(p2)
	ld 		resultLo(p2)
	st 		tempLo(p2)
ToInt_Shift:
	shiftleft resultLo 											; shift result left
	dld 	shiftCount(p2) 										; after 2nd time round (x 4) will be zero
	jnz 	ToInt_NoAdd
	ccl 														; add original value when x 4 - e.g. x 5
	ld 		resultLo(p2)
	add 	tempLo(p2)
	st 		resultLo(p2)
	ld 		resultHi(p2)
	add 	tempHi(p2)
	st 		resultHi(p2)
ToInt_NoAdd:
	ld 		shiftCount(p2) 										; go round until -ve, e.g. 3 in total.
	jp 		ToInt_Shift

	ld 		@1(p1) 												; read the digit already tested.
	ani 	0x0F 												; to a number
	ccl 
	add 	resultLo(p2) 										; add to result
	st 		resultLo(p2)
	csa 														; if carry clear
	jp 		ToInt_Loop 											; go round again.
	ild 	resultHi(p2) 										; adds the carry to high
	jmp 	ToInt_Loop

ToInt_End:
	ld 		digitCount(p2) 										; if digit count = 0, e.g. nothing converted
	scl
	jz 		MATH_Exit1 											; exit with carry set

	ld 		resultHi(p2) 										; save result on stack
	st 		-1(p2)
	ld 		resultLo(p2)
	st 		@-2(p2)
	ccl 														; clear carry as okay, and exit.
	endsection SCMPToInteger

MATH_Exit3:
	jmp 	MATH_Exit1



; ******************************************************************************************************************
;							'/' : 16 bit signed/unsigned divide (CY/L = 0 = signed)
; ******************************************************************************************************************

MATH_DivideByZero:												; come here for divide by zero.
	scl
	jmp 	MATH_Exit3

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
tempHi = -9 													; high byte temporary

	ld 		denominatorLo(p2) 									; check denominator 
	or 		denominatorHi(p2) 
	jz 		MATH_DivideByZero 									; fail if dividing by zero.

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

	csa 														; look at carry bit
	ani 	0x80 												; if set, unsigned division.
	jnz 	__DivideLoop 										; so skip over the sign removal code.

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
	jmp 	MATH_Exit3

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
	st 		tempHi(p2) 											; temp.high now saved
	csa 														; check carry flag
	ani 	0x80 	
	jnz 	__DivideRemainderGreater 							; if set then remainder >= denominator

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
	ld 		tempHi(p2) 											; get the difference back.
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
