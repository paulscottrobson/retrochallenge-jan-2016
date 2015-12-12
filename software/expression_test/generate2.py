#
#		Generates < = > tests.
# 
import random 
random.seed(42)

p = 0x9300
while p < 0xFF00:
	n1 = random.randrange(0,65535)
	if random.randrange(0,6) == 0:
		n1 = random.randrange(0,3)
		if random.randrange(0,2) == 0:
			n1 = 65535 - n1
	n2 = n1 + random.randrange(-5,5)
	n2 = n2 & 0xFFFF

	print('    db    "{0} < {1}",0'.format(n1,n2))
	print('    dw    {0}'.format(1 if n1 < n2 else 0))
	print('    db    "{0} = {1}",0'.format(n1,n2))
	print('    dw    {0}'.format(1 if n1 == n2 else 0))
	print('    db    "{0} > {1}",0'.format(n1,n2))
	print('    dw    {0}'.format(1 if n1 >= n2 else 0))

	p = p + (len(str(n1))+len(str(n2))+6)*3
