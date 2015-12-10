#
#	generate sums
#
import random

# TODO: Spaces
# TODO: * and /

random.seed(42)

def getNumber(min,max):
	return random.randrange(min,max)

def createSum(minTerms,maxTerms):
	total = getNumber(0,65535)
	expr = str(total)
	items = random.randrange(minTerms,maxTerms)
	for n in range(1,items):
		op = random.randrange(0,2)
		if op < 2:
			n = getNumber(0,65535)
			total = total + (n if op == 0 else -n)
			expr = expr + ("+" if op == 0 else "-") + str(n)
			total = (total + 0x10000) & 0xFFFF


	return { "expr":expr,"value":total }


ptr = 0x9300
while ptr < 0xFF00:
	s1 = createSum(3,6)
	print('   db "{0}",0  '.format(s1["expr"]))
	print('   dw {0}'.format(s1["value"]))
	ptr = ptr + len(s1["expr"]) + 3
print('    db 0')