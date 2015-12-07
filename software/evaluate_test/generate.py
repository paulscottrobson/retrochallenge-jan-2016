#
#		Calculation generator.
#
import random,math

def toString(n):
	return 	str(n)

random.seed(142)
tFile = open("tests.inc","w")
pos = 0x9280
while pos < 0xFF00:
	n1 = random.randrange(0,65535)
	s1 = toString(n1)
	for n in range(0,random.randrange(3,8)):
		n2 = random.randrange(0,400)
		if random.randrange(0,10) == 0:
			n2 = random.randrange(0,65535)
		op = random.randrange(0,4)
		if op == 0:
			n1 = (n1 + n2) & 0xFFFF
			s1 = s1 + "+" + toString(n2)
		if op == 1:
			n1 = (n1 - n2 + 0x10000) & 0xFFFF
			s1 = s1 + "-" + toString(n2)
		if op == 2:
			n2 = random.randrange(1,int(65535/n1)) if n1 < 32767 else 1
			if n2 <> 1 or random.randrange(0,10) == 0:
				n1 = n1 * n2
				s1 = s1 + "*" + toString(n2)
		if op == 3:
			if n1 > 10:
				n2 = random.randrange(1,int(n1/5))
				if random.randrange(0,5) > 0:
					n2 = random.randrange(1,int(math.sqrt(n1)))
				n1 = int(n1/n2)
				s1 = s1 + "/" + toString(n2)

	tFile.write("    db \"{0}\",0\n".format(s1))
	tFile.write("    dw {0}\n".format(n1))
	pos = pos + 3 + len(s1)