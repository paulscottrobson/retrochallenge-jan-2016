; ******************************************************************************************************************
;
;												Maths testing program
;
; ******************************************************************************************************************

		cpu 	sc/mp
		org 	0xC40

		include types.inc 											; defines operator and testBlockSize

testStart:
		ldi 	testTable/256 										; make P1 point to test table.
		xpah 	p1
		ldi 	testTable&255
		xpal 	p1

processNext:
		ld 		0(p1) 												; stop if all input values are 0.
		or 		1(p1)
		or 		2(p1)
		or 		3(p1)		
		jz 		Halt

		ldi 	0x0F 												; make P2 point to the stack
		xpah 	p2
		ldi 	0xFF
		xpal 	p2

		ld 		1(p1) 												; push first two values on the stack.
		st 		@-1(p2)
		ld 		0(p1)
		st 		@-1(p2)
		ld 		3(p1)
		st 		@-1(p2)
		ld 		2(p1)
		st 		@-1(p2)
		ldi 	0 													; set P3 to point to Maths routine
		xpah 	p3
		ldi 	2
		xpal 	p3
		ldi 	operator 											; pick operator
		xppc 	p3

		ld 		0(p2)
		xor 	4(p1)
		jnz 	Failed
		ld 		1(p2)
		xor 	5(p1)
		jnz 	Failed

		ldi 	operator 											; division ?
		xri 	'/'
		jnz 	advanceNext 

		ld 		-2(p2)												; check remainder.
		xor 	6(p1)
		jnz 	Failed
		ld 		-1(p2)
		xor 	7(p1)
		jnz 	Failed

advanceNext:
		ld 		@testBlockSize(p1) 									; go to next test
		jmp 	processNext

Failed:	ldi 	0xFF 												; error P1 points to sum, P2 answer
Halt:	xae 														; display result in E and A
		lde
		jmp 	Halt 												; just stop.

		org 	0x1000
testTable:
		include tests.inc		
		dw		0 													; 0 func 0 marks the end of the table.
		dw		0
