#
#		Galois LFSR
#

lfsr = 0xACE1

for i in range(1,32):
	print("{0:04x} {0:016b}".format(lfsr))	
	bit = lfsr & 1
	lfsr = lfsr >> 1
	if bit == 0:
		lfsr = lfsr ^ 0xA1A1

