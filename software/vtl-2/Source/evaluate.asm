; ****************************************************************************************************************
; ****************************************************************************************************************
;
;											Evaluate, VTL-2 ROM
;											===================
;
;	R-Expression Evaluator.
;
; ****************************************************************************************************************
; ****************************************************************************************************************

Test:db 	"01234",0

Evaluate:
	ldi 	ExpressionLevel/256									; push return address on stack, point P3 to explevel
	xpah 	p3  				
	st 		@-1(p2)
	ldi 	ExpressionLevel&255
	xpal 	p3 									
	st 		@-1(p2)

	ldi 	0 													; we push $0000 and '+' on, as if we'd gone into
	st 		@-1(p2) 											; the middle of an evaluation. The next thing is 
	st 		@-1(p2)												; a term, but we don't have to make the first case
 	st 		(p3)												; a special one. It is like putting '0+' on the front.
	ldi 	'+'	 												; we also reset the expression level.
	st 		@-1(p2)
;
;	We have a term, and an operator (albeit faked first time), so get another term to work with it.
;
__EVNextTerm:
	ld 		@1(p1) 												; get the next character
	scl
	cai 	' '													; is it a space character
	jz 		__EVNextTerm 										; go back and get the next character.
	ani 	0xC0 												; this will be 00xx xxxx if was 32-95, legal value
	jz 		__EVLegalTerm
	ldi 	'T'													; return 'T' (bad term error)

__EVError:
	jmp 	__EVError

__EVLegalTerm: 													; we now know it is 33-95
	ld 		-1(p1) 												; reload the legal term ASCII value.
	scl 
	cai 	'9'+1 												; this will be +ve if > '9' (e.g. not a number)
	jp 		__EVVariableTerm 									
	cai 	128-10-1 							 				; will now be +ve if < '0'
	jp 		__EVVariableTerm
;
;	At this point, we know we have a number. P1 points to the character after the first digit.
;
	ld 		@-1(p1) 											; point back to first digit
	lpi 	p3,MathLibrary-1 									; point P3 to math library
	ldi 	'?' 												; function '?' (ASCII->Int) (Cannot fail as checked digit)
	xppc 	p3 													; calculate it, on exit P1 points to next character.
	jmp 	__EVPerformOperation 								; go and perform the operation pending.
;
;	We now have a legal term (e.g. 33 > 95) and it is not a number. It is either a variable or a parenthesised
;	Expression.
;
__EVVariableTerm:												; at this point, it is either parentheses or variable.
	jmp 	__EVVariableTerm

	; if parenthesis, bump level and go back to start. on exit parenthesis after operation, pop level.
;
;	Perform operation. Note stack is (value 2) (operator) (value 1) so a little rearranging is required.
;
__EVPerformOperation:

wait2:jmp 	wait2

	; can be numeric.   (0-9)
	; can be an open parenthesis, indicating a parenthesised term.
	; can be a variable (anything else < 96) including 'special' variables.

