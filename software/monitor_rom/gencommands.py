#
#	Create 3-char look up table. Two types
#
#	SC/MP Commands. 	These are every value outside 20-2F
#	Monitor Commands. 	These are every value 20-2F, and a lookup table is generated.
#
def convert(name):
	name = name.upper()
	result = 0
	for c in name:
		result = result * 32 + (ord(c) & 0x1F)
		result = result & 0x7FFF
	return result

assert convert("ALZ") == 0x59A

scmp = "LD:C0,ST:C8,AND:D0,OR:D8,XOR:E0,DAD:E8,ADD:F0,CAD:F8,ILD:A8,DLD:B8,"
scmp += "LDI:C4,ANI:D4,ORI:DC,XRI:E4,DAI:EC,ADI:F4,CAI:FC,JMP:90,JP:94,JZ:98,JNZ:9C,"
scmp += "DLY:8F,LDE:40,XAE:01,ANE:50,ORE:58,XRE:60,DAE:68,ADE:70,CAE:78,XPL:30,XPH:34,XPC:3C,"
scmp += "SIO:19,SR:1C,SRL:1D,RR:1E,RRL:1F,HLT:00,CCL:02,SCL:03,DIN:04,IEN:05,CSA:06,CAS:07,NOP:08"

entries = {}
commandLabels = {}

for instr in scmp.split(","):
	assert len(instr) <= 6
	entries[instr.split(":")[0]] = int(instr.split(":")[1],16)

commands = "D:Dump,A:Address,G:Go,PUT:PutTape,GET:LoadTape,C:ClearScreen,B:EnterBytes"

cmdID = 0x20

for cmd in commands.split(","):
	commandLabels[cmdID] = cmd.split(":")[1]+"_Command"
	entries[cmd.split(":")[0]] = cmdID
	cmdID += 1

keys = entries.keys()
keys.sort(key = lambda x:entries[x])

print("        org 0x{0:04x}".format(0x800-(cmdID-0x20)*2-len(keys)*3-2))

print(";\n; 	This file is generated automatically by gencommands.py\n;")
print("__CommandList:")
for k in keys:
	print("        dw    0x{0:04x} ; {1}".format(convert(k),k))
	print("        db    0x{0:02x}".format(entries[k]))
print("        dw    0x0000 ; End Marker	\n")

print("__CommandTable:")

for i in range(0x20,cmdID):
	print("        dw    {0}".format(commandLabels[i]))