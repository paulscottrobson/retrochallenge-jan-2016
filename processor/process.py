#
#	SC/MP Processor
#
import re

def process(s,op):
	s = s.replace("%EOFFSET","offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand)")
	s = s.replace("%OFFSET","offset = SEXT(operand)")
	s = s.replace("%APREDEC","if (offset & 0x80) %P += offset")
	s = s.replace("%APOSTINC","if ((offset & 0x80) == 0) %P += offset")
	return s.replace("%P","P"+str(op % 4))

source = open("scmp.def").readlines()
source = [x if x.find("//") < 0 else x[:x.find("//")] for x in source]
source = [x.rstrip().replace("\t"," ") for x in source if x.rstrip() != ""]
source = [x+";" if x[0] == ' ' else x+" " for x in source]

source = "\n".join(source)
source = source.replace("\n ","").split("\n")

source = "\n".join(source)
while source.find("  ") >= 0:
	source = source.replace("  "," ")
while source.find(";;") >= 0:
	source = source.replace(";;",";")
source = source.split("\n")

mnemonics = [ None ] * 256
code = [ None ] * 256

for l in source:
	m = re.match("^([0-9A-F\-]+)\s*\"(.*?)\"\s*([0-9]+)\s*(.*)$",l)
	assert m is not None
	r = re.match("^([0-9A-F]+)\-([0-9A-F]+)",m.group(1)+"-"+m.group(1))
	for opcode in range(int(r.group(1),16),int(r.group(2),16)+1):
		assert mnemonics[opcode] is None
		mnemonics[opcode] = process(m.group(2),opcode).lower().replace("#","!").replace("!","##")
		scode = "{0}CYCLES({1});break;".format(m.group(4),m.group(3))
		code[opcode] = process(scode,opcode)

for i in range(0,256):
	if mnemonics[i] is None:
		if i < 0x80:
			mnemonics[i] = 'db {0:02x}'.format(i)
		else:
			mnemonics[i] = 'db {0:02x} #'.format(i)
open("__scmp_mnemonics.h","w").write(",".join(['"'+x+'"' for x in mnemonics]))

handle = open("__scmp_opcodes.h","w")
for i in range(0,256):
	if code[i] is not None:
		handle.write("\ncase 0x{0:02x}: /***** {1} *****/\n".format(i,mnemonics[i]))
		parts = ["     "+x for x in code[i].replace(";",";@").split("@")]
		handle.write("\n".join(parts))

		