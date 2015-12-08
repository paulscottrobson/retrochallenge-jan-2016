import random
#
#	multiply - 8 bit unsigned multiply
#
def multiply(a,b):
	aOrg = a 
	bOrg = b
	res = 0
	while (b != 0):
		if (b & 1) != 0:
		 	res = (res + a) & 0xFF
		a = (a << 1) & 0xFF
		b = (b >> 1) & 0xFF
	assert res == aOrg * bOrg
	return res

#
#	8 bit unsigned division. 
#
def divide(numerator,denominator):

	nOrg = numerator		
	dOrg = denominator 		

	quotient = 0			
	remainder = 0 			
	bit = 0x80

	while (bit != 0):

		remainder = remainder << 1
		if numerator & 0x80 != 0:
			remainder = (remainder + 1) & 0xFF
		temp = remainder - denominator
		if temp >= 0:
			remainder = temp
			quotient = quotient | bit
		bit = (bit >> 1) & 0xFF
		numerator = (numerator << 1) & 0xFF

	assert nOrg / dOrg == quotient
	assert nOrg % dOrg == remainder
	return quotient

print(multiply(4,5))
print(divide(213,37))

random.seed(42)

for i in range(0,1000*1000*10):
	if i % 1000 == 0:
		print(i)
	divide(random.randrange(0,255),random.randrange(1,100))
	ok = False
	while not ok:
		m1 = random.randrange(0,255)
		m2 = random.randrange(0,255)		
		ok = m1 * m2 <= 255
	multiply(m1,m2)
