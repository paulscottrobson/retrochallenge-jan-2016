import random
#
#	multiply - 16 bit unsigned multiply
#
def multiply(a,b):
	aOrg = a 
	bOrg = b
	res = 0
	while (b != 0):
		if (b & 1) != 0:
		 	res = res + a
		a = a << 1
		b = b >> 1
	assert res == aOrg * bOrg
	return res

#
#	16 bit unsigned division. 
#
def divide(numerator,denominator):

	nOrg = numerator		
	dOrg = denominator 		

	quotient = 0			
	remainder = 0 			
	bit = 0x8000

	while (bit != 0):

		remainder = remainder << 1
		if numerator & 0x8000 != 0:
			remainder = remainder + 1
		temp = remainder - denominator
		if temp >= 0:
			remainder = temp
			quotient = quotient | bit
		bit = bit >> 1
		numerator = numerator << 1

	assert nOrg / dOrg == quotient
	assert nOrg % dOrg == remainder
	return quotient

#print(multiply(4,5))
#print(multiply(16384,3))

#print(divide(1400,10))
#print(divide(14,10))
#print(divide(213,37))
#print(divide(40000,40))
print(divide(0x8ACC,0x8AA4))
random.seed(42)

for i in range(0,0):
	if i % 1000 == 0:
		print(i)
	divide(random.randrange(0,65536),random.randrange(1,6553))
	ok = False
	while not ok:
		m1 = random.randrange(0,65535)
		m2 = random.randrange(0,65535)		
		ok = m1 * m2 <= 65535
	multiply(m1,m2)
