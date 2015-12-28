; ****************************************************************************************************************
; ****************************************************************************************************************
;
;									? : Print Expression / String Literal
;
; ****************************************************************************************************************
; ****************************************************************************************************************

	jmp 	__STPRT_End

__ST_Print:
	xppc 	p3 													; check for '='
	jp 		__STPRT_End 										; if error, end.
	ld 		(p1) 												; check next character
	xri 	'"'													; if quote mark
	jz 		__STPRT_Literal 									; print literal.

; ****************************************************************************************************************
;												Print expression.
; ****************************************************************************************************************

	ld 		@-2(p2) 											; make space for P1 save later.
	xppc 	p3 													; evaluate rhs and push result
	ld 		@4(p2) 												; unstack the result and saved space
	csa 														; end if there was an error.
	jp 		__STPRT_End
	ld 		@-4(p2) 											; restack the result and saved space.
	xpah 	p1 													; save P1 above result
	st 		3(p2)
	xpal 	p1 
	st 		2(p2)
	lpi 	p3,OSMathLibrary-1 									; use the maths library to convert to decimal
	lpi 	p1,KeyboardBuffer+10 								; use the keyboard buffer as workspace.
	ldi 	'$'													; '$' function.
	xppc 	p3 													; convert it
	lpi 	p3,Print-1 											; then print it
	ldi 	0
	xppc 	p3 
	pullp 	p1 													; restore P1.
	scl 														; no error occurred.
	jmp 	__STPRT_End 										; and exit

; ****************************************************************************************************************
;													Print literal
; ****************************************************************************************************************

__STPRT_Literal:
	ld 		@1(p1) 												; skip over first quote.
	lpi 	p3,Print-1 											; print routine in P3.
__STPRT_LitLoop:
	ld 		(p1) 												; get next character
	jz 		__STPRT_Error 										; if zero, missing quote mark.
	ld 		@1(p1) 												; fetch and bump
	xri 	'"' 												; if reached quote mark
	jz 		__STPRT_LitComplete 								; exit
	ld 		-1(p1) 												; load character
	xppc 	p3 													; print it
	jmp 	__STPRT_LitLoop 
;
;	Print completed, check for ';'
;
__STPRT_LitComplete:
	ld 		@1(p1) 												; get next
	xri 	' ' 												; avoid spaces
	jz 		__STPRT_LitComplete 
	ld 		@-1(p1) 											; reget the character
	xri 	';'													; if semicolon
	scl 														; exit with CY/L = 1
	jz 		__STPRT_End 	
	ldi 	13 													; print a carriage return
	xppc 	p3
	scl 														; exit with CY/L = 1
	jmp 	__STPRT_End
;
;	Error, closing quote not found.
;
__STPRT_Error:													; missing quote mark
	ldi 	ERROR_Quote
	xae
	ccl 

__STPRT_End: