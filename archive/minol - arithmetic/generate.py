#
#	Generate math tests
#
import random

random.seed(42)

monitor = [ord(x) for x in open("..\monitor_rom\monitor.bin","rb").read(-1)]

def rnd(maxval):
	n = maxval+1
	term = ""
	while n >= maxval:
		n = random.randrange(0,255)
		term = str(n)
		if random.randrange(0,5) == 0:
			n = random.randrange(32,96)
			term = "'"+chr(n)+"'"
			if n==34 or n == 0x27 or n == ord("\\"):
				n = maxval+1
		if random.randrange(0,5) == 0:
			h = random.randrange(0,8)
			h = [h,str(h)]
			if random.randrange(0,8) == 0:
				h = rnd(8)
			l = rnd(256)
			n = monitor[h[0]*256+l[0]]
			term = "({0},{1})".format(h[1],l[1])
	return [n,term]

ptr = 0x9300
while ptr < 0xFF00:
	n1 = rnd(255)
	result = n1[0]
	expr = n1[1]
	for parts in range(0,random.randrange(2,7)):
		op = random.randrange(0,4)
		if op < 2:
			n1 = rnd(255)
			result = result + (n1[0] if op == 0 else -n1[0])
			result = (result + 256) & 255
			expr = expr + ("+" if op == 0 else "-") + str(n1[1])
		if op == 2 and result < 50 and result > 0:
			n1 = rnd(int(255/result))
			result = result * n1[0]
			expr = expr + "*" + n1[1]
		if op == 3 and result > 10:
			n1 = rnd(int(result/2))
			if n1[0] > 0:
				result = int(result / n1[0])
				expr = expr + "/" + n1[1]

	print('    db     "{0}",0,{1}'.format(expr,result))
	ptr = ptr + len(expr)+2


