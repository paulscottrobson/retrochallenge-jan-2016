; ******************************************************************************************************************
;
;												Speed Test Counter
;
; ******************************************************************************************************************

		cpu	sc/mp

counter = 0xC00
countSize = 8

loopCount = counter + countSize

		org 	0x0000
		nop
cls:	xpal 	p1												; clear screen
		ldi 	' '
		st 		@1(p1)
		xpal 	p1
		jnz 	cls

		ldi 	counter/256 									; reset counter to 0
		xpah 	p1
		ldi 	counter&255 + countSize
clearLoop:
		xpal 	p1
		ldi 	'0'
		st 		@-1(p1)
		xpal 	p1
		jnz 	clearLoop

countLoop: 														; copy counter to screen
		ldi 	0
		xpah 	p2
		ldi 	countSize
		xpal 	p2
		ldi 	counter/256
		xpah 	p1
		ldi 	counter&255 + countSize
refreshLoop:
		xpal 	p1
		ld 		@-1(p1)
		st		@-1(p2)
		xpal 	p1
		jnz 	refreshLoop

		ldi 	loopCount & 255 								; loop count value
		xpal 	p1
		ldi 	255												; set to start $FF
		st 		0(p1)
execCode:
		ldi 	0x0F											; P2 points to junk
		xpah 	p2

		ldi 	(testCode-1) & 255
		xpal 	p3
		ldi 	(testCode-1) / 256
		xpah 	p3
		xppc 	p3

		dld 	0(p1)											; do it that many times.
		jnz 	execCode

		ldi 	counter/256 									; increment counter
		xpah 	p1
		ldi 	counter&255 + countSize - 1
		xpal 	p1
decrement:
		ild 	(p1)
		xri 	'0'+10
		jnz 	countLoop
		ldi 	'0'
		st 		(p1)
		ld 		@-1(p1)
		jmp 	decrement

testCode:														; execute lots of instructions.
		ld 		10(p2)
		st 		10(p2)											; (except DLY)
		and 	@1(p2)
		or 		@-1(p2)
		xor 	@1(p2)
		dad 	@-1(p2)
		add 	2(p2)
		cad 	-2(p2)
		ild 	1(p2)
		dld 	2(p2)
		ldi 	4
		ani 	4
		ori 	4
		xri 	4
		dai 	44
		adi 	4
		cai 	4
		ild 	0(p2)
		jmp 	l0
l0:		jz 		l1
l1:		jnz 	l2
l2:		jp 		l3
l3:		lde
		xae
		ane
		ore
		dae
		ade
		cae
		sio
		sr
		srl
		rr
		rrl
		ccl
		scl
		dint
		ien
		csa
		ldi 	0
		cas
		nop
		xppc 	p3
