#
#	generate sums
#
import random

random.seed(42)

#
#	Random spacing between tokens
#
def spc():
	s = ""
	if random.randrange(0,7) == 0:
		s = " " if random.randrange(0,4) != 0 else "  "
	return s
#
#	Random number selection.
#
def getNumber(min,max):
	return random.randrange(min,max)
#
#	Create a sum with the given number of terms.
#
def createSum(minTerms,maxTerms):
	total = getNumber(0,65535)
	expr = spc()+str(total)
	items = random.randrange(minTerms,maxTerms)
	for n in range(1,items):
		op = random.randrange(0,4)
		if op < 2:
			n = getNumber(0,65535)
			total = total + (n if op == 0 else -n)
			expr = expr + spc() + ("+" if op == 0 else "-") + spc() + str(n)
			total = (total + 0x10000) & 0xFFFF
		if op == 2 and total < 32000:
			n = getNumber(1,65535/total)
			if n > 1:
				total = total * n
				expr = expr + spc() + "*"+ spc() + str(n)
		if op == 3 and total > 10:
			n = getNumber(1,total/3)
			if n > 1:
				total = int(total / n)
				expr = expr + spc() + "/" + spc() + str(n) 

	return { "expr":expr+spc(),"value":total }


ptr = 0x9300
while ptr < 0xFF00:
	s1 = createSum(3,6)
	print('   db "{0}",0  '.format(s1["expr"]))
	print('   dw {0}'.format(s1["value"]))
	ptr = ptr + len(s1["expr"]) + 3
print('    db 0')