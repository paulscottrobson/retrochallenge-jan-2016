#
#	Convert test.bin to binaries\__image.h
#
import os
src = open("test.bin","rb").read(-1)
src = [str(ord(x)) for x in src]
src = ",".join(src)
open("binaries"+os.sep+"__image.h","w").write(src)