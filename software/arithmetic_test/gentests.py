#
#		Arithmetic tests generator
#
import random

random.seed()

testType = "*"
blockSize = 6

testFile = open("tests.inc","w")

space = 0x1FF0 - 0x1000

for i in range(1,space / blockSize):
	isOk = False
	while not isOk:
		n1 = random.randrange(-32767,32767)
		n2 = random.randrange(-32767,32767)
		result = n1 * n2

		isOk = ((n1 != 0 or n2 != 0) and abs(result) <= 32767)

	test = [n1,n2,result]
	testFile.write("    dw "+",".join([str((x+0x10000) & 0xFFFF) for x in test])+"\n")