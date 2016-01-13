#
#	Convert test.bin to binaries\__image.h
#
import os

def convert(srcFile,hFile,m = 1):
	src = open(srcFile,"rb")
	if scr is not None:
		src.read(-1)
	else:
		src = [ 0xFF] * 4096
	src = [str(ord(x)*m) for x in src]		
	src = ",".join(src)
	open("binaries"+os.sep+hFile,"w").write(src)

convert("monitor.bin","__monitor_rom.h")
convert("rom9000.bin","__rom_9000.h",0)
