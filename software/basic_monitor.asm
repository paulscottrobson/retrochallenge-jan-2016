; ******************************************************************************************************************
;
;											WallPaper One Basic Monitor No. 1
;											=================================
;
;	Designed for one ROM, one RAM chip, one set of toggle switches, one set of LEDs and SA/SB/RST buttons.
;
;	Written by Paul Robson sometime in the mid 1970s, updated January 2016.
;
;	Operation:
;		On RESET, the working address is set to whatever is on the toggle switches
;		On A, the working address is incremented and displayed while A is held down, then data is displayed.
;		On B, the data on toggle is copied into the working area and incremented.
;		On RESET, execute from address if A or B pressed.
;
; ******************************************************************************************************************

		cpu	sc/mp

		org 	0x0000
		nop

		ldi 	0x0A												; point P1 to keyboard at $AAA. Keyboard is $800
		xpah 	p1													; to $BFF - this address is an emulator hack which
		ldi 	0xAA												; means we want to read the toggle switches
		xpal 	p1

		ld 		0(p1) 												; read the toggle switch, address on Reset.
		ani 	0x7F 												; we are accessing memory $C00-$C7F
		xpal 	p3 													; p3 is the current working address
		ldi 	0x0C 												; so P3 is 0C:[toggles]	
		xpah 	p3

		csa 														; check if sense A/sense B is pressed
		ani 	0x30 												; if it is not 11 then execute
		xri 	0x30
		jnz 	Execute

UpdateData:
		ld 		0(p3) 												; read memory at current address
		st 		0 													; write to the LED latches.
		csa 														; read the flag registers
		ani 	0x30 												; isolate SA + SB
		xri 	0x30 												; if neither pressed e.g. xx11 xxxx
		jz 		UpdateData

		csa 														; re-read flag register
		ani 	0x20 												; if SB is pressed
		jnz 	NoSenseB 											
		ld 		0(p1) 												; read the toggle switches
		st 		0(p3)												; store at current address.
NoSenseB:
		ld 		@1(p3) 												; increment the address
		xpal 	p3 									
		ani 	0x7F 												; force into range 00-7F
		st 		0 													; display on LEDs
		xpal 	p3
WaitRelease:
		csa 														; wait for SA+SB to be released
		ani 	0x30
		xri 	0x30
		jnz 	WaitRelease
		jmp 	UpdateData 											; update displayed data and start again.

Execute:
		ld 		@-1(p3) 											; fix up for the pre-fetch.
		xppc 	p3 													; execute program
		jmp 	0 													; restart.