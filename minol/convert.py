#
#	Converter
#
import re

source = open("hilo.bas").readlines()
source = [x if x.find("//") < 0 else x[:x.find("//")] for x in source]					# Remove // comments
source = [x.replace("\t"," ").rstrip() for x in source]									# Right strip all lines.
source = [x for x in source if x != ""]													# Remove blank lines.

source = ":\n".join(source) 															# join with colons
source = source.replace(":\n ",":")														# build multiple lines.

sourceCode = {}																			# dictionary line# => text
lastLineNumber = -1 																	# last line number.

for l in source.split("\n"):															# for each line.
	isAuto = False

	if l[-1] == ':':																	# remove trailing colon.
		l = l[:-1]
	if l[0] == '*':																		# use auto-number
		assert lastLineNumber > 1
		l = str(lastLineNumber+1)+l[1:]
		lastLineNumber = lastLineNumber + 1
		isAuto = True

	m = re.match("^([0-9]+)\\s*(.*)$",l)												# split it up.
	assert m is not None
	lineNumber = int(m.group(1))
	lineText = m.group(2)
	if not isAuto:
		assert lineNumber > lastLineNumber 												# check no overflow
	assert lineNumber >= 1 and lineNumber <= 254 										# check valid
	lastLineNumber = lineNumber
	sourceCode[lineNumber] = lineText													# save text

for n in sourceCode.keys():																# check no capitals in code
	if sourceCode[n] != sourceCode[n].lower():											# (caps are substitutions)
		print("Capitals in line ",n)
	sourceCode[n] = sourceCode[n].upper()

lineNumber = sourceCode.keys()															# get sorted line numbers
lineNumber.sort()
h = open("program.txt","w")																# write program as raw text.
for n in lineNumber:
	h.write("{0:-4} {1}\n".format(n,sourceCode[n]))
h.close()

binary = [0xFD, 0xB5,0xAE,0x76]															# start with the marker.
for n in lineNumber:
	l = sourceCode[n]
	binary.append(len(l)+3)																# offset
	binary.append(n)																	# line number
	for c in l:																			# text
		binary.append(ord(c))
	binary.append(0)																	# string end marker

binary.append(0xFF)																		# program end marker

h = open("program.bin","wb")
for b in binary:
	h.write(chr(b))
h.close()