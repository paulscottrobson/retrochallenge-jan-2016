; ****************************************************************************************************************
; ****************************************************************************************************************
;
;											List Program 
;
;							Lists program Spectrum style, 4 lines at a time.
;
; ****************************************************************************************************************
; ****************************************************************************************************************

ListProgram:
	pushp	p3 													; save return address
	ldi 	0 													; push zero (counter of lines printed) onto stack
	st 		@-1(p2)
	lpi 	p3,ProgramBase 										; load the base address onto TOS
	ld 		1(p3) 												
	st 		@-1(p2)
	ld 		0(p3)
	st 		@-1(p2)

; ****************************************************************************************************************
;									Main loop, come back to test if completed
; ****************************************************************************************************************

__LPR_Loop:
	ld 		0(p2) 												; read TOS into P1
	xpal 	p1
	ld 		1(p2)
	xpah 	p1
	ld 		(p1) 												; read offset to next.
	jz 		__LPR_Exit 											; exit if zero

; ****************************************************************************************************************
;		   	 				  Print line number and space, clear screen if new page
; ****************************************************************************************************************

_	ld 		2(p1) 												; push line# on stack
	st 		@-1(p2)
	ld 		1(p1)
	st 		@-1(p2)
	lpi 	p3,OSMathLibrary-1 									; convert it to ASCII.
	lpi	 	p1,KeyboardBuffer+6
	ldi 	'$'
	xppc 	p3
	lpi 	p3,Print-1 											; get ready to print
	ld 		2(p2) 												; is it a clear screen ?
	ani 	3
	jnz 	__LPR_NoClear
	ldi 	12 													; clear the screen
	xppc 	p3
__LPR_NoClear:
	ldi 	0
	xppc 	p3
	ldi 	' '													; print a space
	xppc 	p3

; ****************************************************************************************************************
;											Print the line itself
; ****************************************************************************************************************

	ld 		0(p2) 												; reget the address into P1
	xpal 	p1
	ld 		1(p2)
	xpah 	p1
	ld 		@3(p1) 												; skip space and line numbers, reading offset into A
	xae 														; save offset into E temporarily
	ldi 	0 													; and print that
	xppc 	p3
	ldi 	13													; print new line.
	xppc 	p3
	ccl 														; add offset to pointer
	lde
	add 	0(p2)
	st 		0(p2)
	ld 		1(p2)
	adi 	0
	st 		1(p2)
	ild 	2(p2) 												; increment and load counter
	ani 	3 													; if not reached 4.
	jnz 	__LPR_Loop											; and go round again

	lpi 	p3,GetChar-1 										; get keyboard character
	xppc 	p3 										
	xri 	' '													; if it is space
	jz 		__LPR_Loop 											; list another page.
;
;	Exit
;
__LPR_Exit:
	ld 		@3(p2) 												; throw away stacked address.
	pullp 	p3 													; pop return address and exit.
	xppc 	p3