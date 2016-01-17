; ****************************************************************************************************************
; ****************************************************************************************************************
;
;											Integer (Byte) Printer
;											======================
;	
;	Print Integer in E as String to output routine. Uses stack space as temporary storage. Changes A/E but not
;	P1 or P2. Unsigned.
;	
; ****************************************************************************************************************
; ****************************************************************************************************************

PrintInteger:
	pushp 	p3													; save P3
	ldi 	0xFF 												; use $FF to mark stack top.
	st 		@-1(p2)
	st 		@-3(p2) 											; allocate space for results.
	ldi 	100 												; start with 100s
__PIDivideOuter:
	st 		1(p2) 												; save subtractor at stack (1)
	ldi 	0xFF 												; clear stack (0) (count) to -1 because we pre-increment.
	st 		0(p2)
__PIDivideLoop:
	ild 	0(p2) 												; bump the counter.
	lde 														; get value
	scl 														; subtract divider
	cad 	1(p2) 												
	xae 														; put back in E
	csa 														; if no borrow
	ani 	0x80
	jnz 	__PIDivideLoop 
	lde 														; add the divider.
	ccl
	add 	1(p2)
	xae
	ld 		1(p2) 												; get the divider back
	xri 	10 													; is it 10 ?
	jz 		__PIDivideEnd 										; we have finished the division bit.
	ld 		@1(p2) 												; push stack up one.
	ldi 	10 													; and divide by 10
	jmp 	__PIDivideOuter
;
__PIDivideEnd:

	lde 														; write out the last digit.
	st 		1(p2)
	lpi 	p3,Print-1 											; point P3 to the print routine.
;
;	Remove leading spaces
;
	ld 		@-1(p2) 											; look at first digit, if non-zero go to print
	jnz 	__PIPrint 
	ld 		@1(p2) 												; skip it, eliminate trailing zeros.
	ld 		(p2) 												; now look at second digit
	jnz 	__PIPrint 											; skip it, eliminate trailing zeros.
	ld 		@1(p2)
;
__PIPrint:
	ld 		@1(p2) 												; read digit
	ani 	0x80												; if found -ve value then exit.
	jnz 	__PIExit
	ld 		-1(p2) 												; re-read it.
	ori 	'0'													; make ASCII
	xppc 	p3 													; print it
	jmp 	__PIPrint 											; and keep printing.
;
__PIExit:
	pullp 	p3 													; restore P3
	xppc 	p3 													; and exit
	
__PIFail:														; because we dropped this setting up P3 afterwards...
	jmp 	__PIFail