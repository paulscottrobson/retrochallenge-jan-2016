        org 0x0747
;
; 	This file is generated automatically by gencommands.py
;
__CommandList:
        dw    0x2194 ; HLT
        db    0x00
        dw    0x6025 ; XAE
        db    0x01
        dw    0x0c6c ; CCL
        db    0x02
        dw    0x4c6c ; SCL
        db    0x03
        dw    0x112e ; DIN
        db    0x04
        dw    0x24ae ; IEN
        db    0x05
        dw    0x0e61 ; CSA
        db    0x06
        dw    0x0c33 ; CAS
        db    0x07
        dw    0x39f0 ; NOP
        db    0x08
        dw    0x4d2f ; SIO
        db    0x19
        dw    0x0272 ; SR
        db    0x1c
        dw    0x4e4c ; SRL
        db    0x1d
        dw    0x0252 ; RR
        db    0x1e
        dw    0x4a4c ; RRL
        db    0x1f
        dw    0x000d ; M
        db    0x20
        dw    0x0001 ; A
        db    0x21
        dw    0x0007 ; G
        db    0x22
        dw    0x42b4 ; PUT
        db    0x23
        dw    0x1cb4 ; GET
        db    0x24
        dw    0x0003 ; C
        db    0x25
        dw    0x0002 ; B
        db    0x26
        dw    0x000c ; L
        db    0x27
        dw    0x0004 ; D
        db    0x28
        dw    0x620c ; XPL
        db    0x30
        dw    0x6208 ; XPH
        db    0x34
        dw    0x6203 ; XPC
        db    0x3c
        dw    0x3085 ; LDE
        db    0x40
        dw    0x05c5 ; ANE
        db    0x50
        dw    0x3e45 ; ORE
        db    0x58
        dw    0x6245 ; XRE
        db    0x60
        dw    0x1025 ; DAE
        db    0x68
        dw    0x0485 ; ADE
        db    0x70
        dw    0x0c25 ; CAE
        db    0x78
        dw    0x1199 ; DLY
        db    0x8f
        dw    0x29b0 ; JMP
        db    0x90
        dw    0x0150 ; JP
        db    0x94
        dw    0x015a ; JZ
        db    0x98
        dw    0x29da ; JNZ
        db    0x9c
        dw    0x2584 ; ILD
        db    0xa8
        dw    0x1184 ; DLD
        db    0xb8
        dw    0x0184 ; LD
        db    0xc0
        dw    0x3089 ; LDI
        db    0xc4
        dw    0x0274 ; ST
        db    0xc8
        dw    0x05c4 ; AND
        db    0xd0
        dw    0x05c9 ; ANI
        db    0xd4
        dw    0x01f2 ; OR
        db    0xd8
        dw    0x3e49 ; ORI
        db    0xdc
        dw    0x61f2 ; XOR
        db    0xe0
        dw    0x6249 ; XRI
        db    0xe4
        dw    0x1024 ; DAD
        db    0xe8
        dw    0x1029 ; DAI
        db    0xec
        dw    0x0484 ; ADD
        db    0xf0
        dw    0x0489 ; ADI
        db    0xf4
        dw    0x0c24 ; CAD
        db    0xf8
        dw    0x0c29 ; CAI
        db    0xfc
__CommandListEnd:
        dw    0x0000 ; End Marker	

__CommandTable:
        dw    MemoryDump_Command
        dw    Address_Command
        dw    Go_Command
        dw    PutTape_Command
        dw    LoadTape_Command
        dw    ClearScreen_Command
        dw    EnterBytes_Command
        dw    Label_Command
        dw    Disassemble_Command
