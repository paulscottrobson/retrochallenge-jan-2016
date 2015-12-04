; ******************************************************************************************************************
;
;												Simple H/W Test
;
;					Echo keystrokes and beep on lower 3 bits of ASCII code. Basic hardware check.
;
; ******************************************************************************************************************

		cpu	sc/mp

		org 	0x0000
		nop
cls:	xpal 	p1												; clear screen
		ldi 	' '
		st 		@1(p1)
		xpal 	p1
		jnz 	cls
		xpal 	p1 												; P1 will be $100

		ldi 	0x08 											; point P2 to the keyboard
		xpah 	p2

nextKey:ldi 	0x7F											; solid block cursor
		st 		0(p1)

waitKey:ld 		0(p2) 											; wait for key press
		jp 		waitKey
		ani 	0x7F 											; throw away bit 7
		ccl
		adi 	0x20 											; will now be +ve if lower case
		jp 		_Continue
		ccl 
		adi 	0xE0
_Continue:
		scl 	
		cai 	0x20+0x20 										; unpick 0x20, sub 0x20 will be +ve if not ctrl
		jp 		_SkipControl
		ccl 													; convert Ctrl+x to x
		adi 	0x40
		xae 
		ldi 	'^' & 0x3F 										; output control marker.
		st 		@1(p1)
		xae
_SkipControl:
		ccl 													; fix up subtract
		adi 	0x20	
		ani 	0x3F											; 6 bit ASCII
		st 		@1(p1) 											; output it

		ani 	7 												; and set beep tone.
		cas
_WaitRelease:													; wait for key release.
		ld 		0(p2)
		jp 		nextKey
		jmp 	_WaitRelease

