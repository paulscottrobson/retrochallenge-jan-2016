import random
#
#	to 2's complement
#
def to2(a):
	if a < 0:
		a = (a + 0x10000) & 0xFFFF
	return a

#
#	from 2's complement
#
def from2(a):
	a = a & 0xFFFF
	if (a & 0x8000) != 0:
		a = a - 0x10000
	return a

#
#	multiply - 16 bit multiply (HL) = (HL) * BC, breaks ABCDE.
#
def multiply(a,b):
	aOrg = a 
	bOrg = b
	a = to2(a)
	b = to2(b)
	res = 0
	while (b != 0):
		if (b & 1) != 0:
		 	res = res + a
		a = a << 1
		b = b >> 1
	res = from2(res)
	assert res == aOrg * bOrg

#
#	16 bit unsigned division. (HL) = (HL) / BC, breaks ABCDE, returns remainder in BC.
#
#	have to be done in a buffer space. HL points to buffer, BC is the remainder, DE is the temp work space.
#
#	+0 	HL Save
#	+2 	Denominator
#	+4 	Quotient
#	+6 	Bit
#	+8 	Numerator.
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

assert from2(to2(-34)) == -34
assert from2(to2(34)) == 34

multiply(4,5)
multiply(-4,-5)
multiply(-4,5)
multiply(4,-5)

print(divide(1400,10))
print(divide(14,10))
print(divide(213,37))
print(divide(40000,40))

random.seed(42)

for i in range(0,100*1000):
	if i % 1000 == 0:
		print(i)
	divide(random.randrange(0,65536),random.randrange(1,65536))
	ok = False
	while not ok:
		m1 = random.randrange(-32768,32767)
		m2 = random.randrange(-32768,32767)		
		ok = abs(m1 * m2) <= 32767
	multiply(m1,m2)