; ******************************************************************************************************************
;								Simple Test program , keyboard and display
; ******************************************************************************************************************

		cpu	sc/mp

		org 	0x0000
		nop
		ldi 	0
		xpah 	p1
		ldi 	0
loop:	xae
		lde
		xpal 	p1
		lde
		xri		0x7F
		st 		@1(p1)
		xpal 	p1
		jp 		loop

		ldi 	0x8
		xpah 	p2
		ldi 	0
		xpal 	p1

echo:	ld 		0(p2)
		jp 		echo
		ani 	0x3F
		st 		@1(p1)
release:
		ld 		0(p2)
		ani 	0x80
		jnz 	release
		jmp 	echo

wait:	jmp 	wait