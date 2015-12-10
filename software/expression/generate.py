#
#		Expression test code generator
#
import random
random.seed(1)

def createRandom(first,last):
	if first <= last:
		n = random.randrange(first,last)
	else:
		n = 1
	ref = { "value":n,"expression":str(n) }
	if random.randrange(0,5) == 0:
		options = { "A":10,"B":20,"Z":33,"(144,0)":0x68,"(144,1)":0xC4,"(144,2)":0x0C }
		k = options.keys()
		k = k[random.randrange(0,len(k))]
		ref = { "value":options[k],"expression":k }
	v = ref["value"]
	if v >= 32 and v < 96 and v != ord("&") and v != ord("<") and v != ord('"') and v != 0x27 and v != ord('\\'):
		if random.randrange(0,4) == 0:
			ref["expression"] = "'"+chr(v)+"'"
	return ref

pos = 0x9240
while pos < 0xFF80:
	n = createRandom(0,255)
	total = n["value"]
	s = n["expression"]
	for p in range(1,random.randrange(4,8)):
		op = random.randrange(0,4)
		if op < 2:
			n = createRandom(0,255)
			if op == 0:
				total = total + n["value"]
				s = s + "+" + n["expression"]
			if op == 1:
				total = total - n["value"]
				s = s + "-" + n["expression"]
			total = total & 0xFF
		if op == 2:
			n = createRandom(1,13)
			if n["value"] * total < 256 and n["value"] > 1:
				total = total * n["value"]
				s = s + "*" + n["expression"]
		if op == 3:
			if total > 10:
				n = createRandom(1,total/3)
				total = total / n["value"]
				s = s + "/" + n["expression"]

	print("    db \"{0}\",0,{1}".format(s,total))
	pos = pos + len(s) + 2


