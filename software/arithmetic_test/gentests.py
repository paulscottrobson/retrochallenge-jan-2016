#
#		Arithmetic tests generator
#
import random

random.seed(42)															# seed RNG
testType = "/"															# * or /
space = 0x1FF8 - 0x1000													# where it goes.

blockSize = 8 if testType == "/" else 6 								# 6 normally but 8 bytes for divide (remainder)

typesFile = open("types.inc","w")										# create types.inc
typesFile.write("operator = '{0}'\n".format(testType))
typesFile.write("testBlockSize = {0}\n".format(blockSize))

testFile = open("tests.inc","w")										# create tests.inc


for i in range(0,space / blockSize):									# create tests
	isOk = False
	while not isOk:														# we want a good test
		if testType == "*":												# multiply two numbers
			n1 = random.randrange(-32767,32767)
			n2 = random.randrange(-32767,32767)
			result = n1 * n2
			test = [n1,n2,result]
			isOk = ((n1 != 0 or n2 != 0) and abs(result) <= 32767)		# one must be non-zero,|product| <= 32767

		if testType == "/":												# divide two numbers

			n1 = random.randrange(1,32767)								# numerator
			n2 = random.randrange(1,178)								# denominator skewed to the bottom
			n2 = int(pow(n2,2))+random.randint(0,1000)
			if random.random() < 0.3:
				n2 = random.randrange(2,99)
			assert n2 <= 32767
			n1s = -1 if random.random() < 0.5 else 1
			n2s = -1 if random.random() < 0.5 else 1

			result = int(n1 / n2) * n1s * n2s
			remainder = n1 % n2
			test = [n1*n1s,n2*n2s,result,remainder]
			isOk = 1
			isOk = (result != 0 or random.random() < 0.05)

	testFile.write("    dw "+",".join([str((x+0x10000) & 0xFFFF) for x in test])+"\n")