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
	n = { "value":-1 }
	avars = { "C":1029,"E":42,"A":13,"Z":69 }
	while n["value"] < min or n["value"] > max:
		n["value"] = random.randrange(min,max)
		n["expr"] = str(n["value"])
		if random.randrange(0,4) == 0:
			k = avars.keys()
			v = k[random.randrange(0,len(k))]
			n["value"] = avars[v]
			n["expr"] = v
		if random.randrange(0,4) == 0:
			n = createSum(3,5)
			n["expr"] = "(" + spc() + n["expr"] + spc()+ ")"
	return n

#
#	Create a sum with the given number of terms.
#
def createSum(minTerms,maxTerms):
	n = getNumber(0,65535)
	total = n["value"]
	expr = spc()+n["expr"]
	items = random.randrange(minTerms,maxTerms)
	for n in range(1,items):
		op = random.randrange(0,4)
		if op < 2:
			n = getNumber(0,6553)
			total = total + (n["value"] if op == 0 else -n["value"])
			expr = expr + spc() + ("+" if op == 0 else "-") + spc() + n["expr"]
			total = (total + 0x10000) & 0xFFFF
		if op == 2 and total < 32000 and total > 0:
			n = getNumber(1,65535/total)
			if n["value"] > 1:
				total = total * n["value"]
				expr = expr + spc() + "*"+ spc() + n["expr"]
		if op == 3 and total > 10:
			n = getNumber(1,total/3)
			if n["value"] > 1:
				total = int(total / n["value"])
				expr = expr + spc() + "/" + spc() + n["expr"] 

	return { "expr":expr+spc(),"value":total }


ptr = 0x9300
while ptr < 0xFF00:
	s1 = createSum(3,7)
	s1["expr"] = s1["expr"].replace(" ","")
	print('   db "{0}",0  '.format(s1["expr"]))
	print('   dw {0}'.format(s1["value"]))
	ptr = ptr + len(s1["expr"]) + 3
print('    db 0')