

InCommand:
	; TODO process input, P1 ^ line returns CY/L = 0 if ok, CY/L = 1 and A = Error if not OK.
	ccl
	ldi 	0xFF
	xppc 	p3