#
#	Create the WP1 Graphics ROM.
#	
#	The original spec allowed for 64 ASCII characters (6 bit ASCII) only. I have extended
#	this with something allowing 32x24 pixel resolution, and some graphics characters which
#	come from a mixture of the Superboard II/UK101 Character ROM, and the Sharp MZ80K Rom
#
#	At present, characters 224-239 of the ROM do not have any graphic allocated to them.
#
from PIL import Image,ImageDraw

def copy(src,fr,to,tgt,pos):
	for i in range(fr * 8,(to + 1) * 8):
		tgt[pos * 8 - fr * 8 + i] = src[i]

def reverse(n):
	if n == 0 or n == 255:
		return n 
	r = 0
	for i in range(0,8):
		if (n & (0x80 >> i)) != 0:
			r = r | (0x01 << i)
	return r

sbr = open("chargen.rom","rb").read(-1)									# read in SB2 ROM
sbr = [reverse(ord(x)) for x in sbr]									# convert to numbers
mz = open("mz80k.rom","rb").read(-1)									# read in MZ80K ROM
mz = [ord(x) for x in mz]												# convert to numbers

wp1 = [ 0 ] * 256 * 8													# empty wp1

for i in range(128,240):												# default is RS for top half
	wp1[i*8+0] = 0x3C
	wp1[i*8+1] = 0x66
	wp1[i*8+2] = 0x42
	wp1[i*8+3] = 0x42
	wp1[i*8+4] = 0x66
	wp1[i*8+5] = 0x7E
	wp1[i*8+6] = 0x66
	wp1[i*8+7] = 0x3C

for i in range(32,96):													# 6 bit ASCII up front (0-64)
	copy(sbr,i,i,wp1,i & 0x3F)
for i in range(1,26):													# Use MZ80K Alphanumerics
	copy(mz,i,i,wp1,i)
for i in range(0,10):
	copy(mz,i+32,i+32,wp1,i+48)

for i in range(64,128):													# 64..127 is 2 x 3 graphics

	if ((i & 1) != 0):
		wp1[i*8+0] |= 0xF0
		wp1[i*8+1] |= 0xF0
		wp1[i*8+2] |= 0xF0
	if ((i & 2) != 0):
		wp1[i*8+0] |= 0x0F
		wp1[i*8+1] |= 0x0F
		wp1[i*8+2] |= 0x0F
	if ((i & 4) != 0):
		wp1[i*8+3] |= 0xF0
		wp1[i*8+4] |= 0xF0
	if ((i & 8) != 0):
		wp1[i*8+3] |= 0x0F
		wp1[i*8+4] |= 0x0F
	if ((i & 16) != 0):
		wp1[i*8+5] |= 0xF0
		wp1[i*8+6] |= 0xF0
		wp1[i*8+7] |= 0xF0
	if ((i & 32) != 0):
		wp1[i*8+5] |= 0x0F
		wp1[i*8+6] |= 0x0F
		wp1[i*8+7] |= 0x0F

copy(sbr,128,143,wp1,128)												# 128..143 are single h/v lines
copy(sbr,175,178,wp1,144)												# 144..147 diagonal blocks
copy(sbr,188,190,wp1,148)												# 148..150 diagonal lines/cross
copy(sbr,183,187,wp1,151)												# 151..155 half-colours
copy(sbr,207,210,wp1,156)												# 156..159 square edges
copy(sbr,229,232,wp1,160)												# 160..163 card suits
copy(sbr,236,239,wp1,164)												# 164..167 plane
copy(sbr,248,255,wp1,168)												# 168..175 tanks
copy(sbr,16,23,wp1,176)													# 176..183 missiles
copy(sbr,242,247,wp1,184)												# 184..189 guns
copy(sbr,4,4,wp1,190)													# 190 	   bush
copy(sbr,13,15,wp1,191)													# 191..193 tree, houses
copy(mz,200,207,wp1,194)												# 194..201 car, people, face
copy(mz,199,199,wp1,202)												# 202 	   invader
copy(mz,71,72,wp1,203)													# 203,204  filled, unfilled circle
copy(sbr,226,226,wp1,205)												# 205 	   larger circle
copy(sbr,5,12,wp1,206)													# 206..213 sub, enterprise
copy(sbr,179,182,wp1,214)												# 214..217 ship
copy(sbr,154,155,wp1,218)												# 218..219 half blocks
copy(sbr,165,168,wp1,220)												# 220..223 corner blocks

for i in range(240,256):												# 240..255 grid

	c = 0
	if (i & 1) != 0:
		wp1[i*8+0] = wp1[i*8+1] = wp1[i*8+2] = wp1[i*8+3] = 0x08
	if (i & 2) != 0:
		wp1[i*8+4] = wp1[i*8+5] = wp1[i*8+6] = wp1[i*8+7] = 0x08
	if (i & 4) != 0:
		wp1[i*8+3] |= 0xF8;
	if (i & 8) != 0:
		wp1[i*8+3] |= 0x0F;


size = 4																# pixel size
spacing = 8																# character spacing
iSize = 16 * (size * 8 + spacing)										# render height + width
render = Image.new("RGBA",(iSize,iSize),0xFF0000)
iDraw = ImageDraw.Draw(render)
for c in range(0,256):
	x = (c % 16) * (size * 8 + spacing) + spacing / 2
	y = (c / 16) * (size * 8 + spacing) + spacing / 2
	iDraw.rectangle([x,y,x+size*8,y+size*8],0x000000,None)
	for y1 in range(0,8):
		b = wp1[c*8+y1]
		for x1 in range(0,8):
			if (b & (0x80 >> x1)) != 0:
				iDraw.rectangle([x+x1*size,y+y1*size,x+x1*size+size-1,y+y1*size+size-1],0xFFFFFF,None)

open("__font8x8.h","w").write(",".join([str(x) for x in wp1]))			# write it out.

render.show()

