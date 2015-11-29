
case 0x00: /***** halt *****/
     CYCLES(8);
     break;
     
case 0x01: /***** xae *****/
     temp8 = AC;
     AC = EX;
     EX = temp8;
     CYCLES(7);
     break;
     
case 0x02: /***** ccl *****/
     carryFlag = 0;
     CYCLES(5);
     break;
     
case 0x03: /***** scl *****/
     carryFlag = 1;
     CYCLES(5);
     break;
     
case 0x04: /***** dint *****/
     SR &= 0xF7;
     CYCLES(6);
     break;
     
case 0x05: /***** ien *****/
     SR |= 0x08;
     CYCLES(6);
     break;
     
case 0x06: /***** csa *****/
     AC = _GetStatusReg();
     CYCLES(5);
     break;
     
case 0x07: /***** cas *****/
     SR = AC;
     carryFlag = (AC >> 7) & 1;
     overflowFlag = (AC >> 6) & 1;
     UPDATEFLAGS(SR & 0x7);
     CYCLES(6);
     break;
     
case 0x08: /***** nop *****/
     CYCLES(6);
     break;
     
case 0x19: /***** sio *****/
     EX = EX << 1;
     CYCLES(5);
     break;
     
case 0x1c: /***** sr *****/
     AC = AC >> 1;
     CYCLES(5);
     break;
     
case 0x1d: /***** srl *****/
     AC = (AC >> 1) | (carryFlag << 7);
     CYCLES(5);
     break;
     
case 0x1e: /***** rr *****/
     AC = ((AC >> 1) | (AC << 7)) & 0xFF;
     CYCLES(5);
     break;
     
case 0x1f: /***** rrl *****/
     temp8 = AC & 1;
     AC = (AC >> 1) | (carryFlag << 7);
     carryFlag = temp8;
     CYCLES(5);
     break;
     
case 0x30: /***** xpal p0 *****/
     temp8 = P0;
     P0 = (P0 & 0xFF00) | AC;
     AC = temp8;
     CYCLES(8);
     break;
     
case 0x31: /***** xpal p1 *****/
     temp8 = P1;
     P1 = (P1 & 0xFF00) | AC;
     AC = temp8;
     CYCLES(8);
     break;
     
case 0x32: /***** xpal p2 *****/
     temp8 = P2;
     P2 = (P2 & 0xFF00) | AC;
     AC = temp8;
     CYCLES(8);
     break;
     
case 0x33: /***** xpal p3 *****/
     temp8 = P3;
     P3 = (P3 & 0xFF00) | AC;
     AC = temp8;
     CYCLES(8);
     break;
     
case 0x34: /***** xpah p0 *****/
     temp8 = P0 >> 8;
     P0 = (P0 & 0x00FF) | (AC << 8);
     AC = temp8;
     CYCLES(8);
     break;
     
case 0x35: /***** xpah p1 *****/
     temp8 = P1 >> 8;
     P1 = (P1 & 0x00FF) | (AC << 8);
     AC = temp8;
     CYCLES(8);
     break;
     
case 0x36: /***** xpah p2 *****/
     temp8 = P2 >> 8;
     P2 = (P2 & 0x00FF) | (AC << 8);
     AC = temp8;
     CYCLES(8);
     break;
     
case 0x37: /***** xpah p3 *****/
     temp8 = P3 >> 8;
     P3 = (P3 & 0x00FF) | (AC << 8);
     AC = temp8;
     CYCLES(8);
     break;
     
case 0x3c: /***** xppc p0 *****/
     temp16 = P0;
     P0 = P0;
     P0 = temp16;
     CYCLES(7);
     break;
     
case 0x3d: /***** xppc p1 *****/
     temp16 = P0;
     P0 = P1;
     P1 = temp16;
     CYCLES(7);
     break;
     
case 0x3e: /***** xppc p2 *****/
     temp16 = P0;
     P0 = P2;
     P2 = temp16;
     CYCLES(7);
     break;
     
case 0x3f: /***** xppc p3 *****/
     temp16 = P0;
     P0 = P3;
     P3 = temp16;
     CYCLES(7);
     break;
     
case 0x40: /***** lde *****/
     AC = EX;
     CYCLES(6);
     break;
     
case 0x50: /***** ane *****/
     AC ^= EX;
     CYCLES(6);
     break;
     
case 0x58: /***** ore *****/
     AC |= EX;
     CYCLES(6);
     break;
     
case 0x60: /***** xre *****/
     AC ^= EX;
     CYCLES(6);
     break;
     
case 0x68: /***** dae *****/
     MB = EX;
     _DecimalAdd();
     CYCLES(11);
     break;
     
case 0x70: /***** ade *****/
     MB = EX;
     _BinaryAdd();
     CYCLES(7);
     break;
     
case 0x78: /***** cae *****/
     MB = EX ^ 0xFF;
     _BinaryAdd();
     CYCLES(8);
     break;
     
case 0x8f: /***** dly ## *****/
     _StartDelay(operand,AC);
     AC = 0;
     CYCLES(13);
     break;
     
case 0x90: /***** jmp ##(p0) *****/
     offset = SEXT(operand);
     P0 = P0 + offset;
     CYCLES(11);
     break;
     
case 0x91: /***** jmp ##(p1) *****/
     offset = SEXT(operand);
     P0 = P1 + offset;
     CYCLES(11);
     break;
     
case 0x92: /***** jmp ##(p2) *****/
     offset = SEXT(operand);
     P0 = P2 + offset;
     CYCLES(11);
     break;
     
case 0x93: /***** jmp ##(p3) *****/
     offset = SEXT(operand);
     P0 = P3 + offset;
     CYCLES(11);
     break;
     
case 0x94: /***** jp ##(p0) *****/
     offset = SEXT(operand);
     if ((AC & 0x80) == 0) P0 = P0 + offset;
     CYCLES(10);
     break;
     
case 0x95: /***** jp ##(p1) *****/
     offset = SEXT(operand);
     if ((AC & 0x80) == 0) P0 = P1 + offset;
     CYCLES(10);
     break;
     
case 0x96: /***** jp ##(p2) *****/
     offset = SEXT(operand);
     if ((AC & 0x80) == 0) P0 = P2 + offset;
     CYCLES(10);
     break;
     
case 0x97: /***** jp ##(p3) *****/
     offset = SEXT(operand);
     if ((AC & 0x80) == 0) P0 = P3 + offset;
     CYCLES(10);
     break;
     
case 0x98: /***** jz ##(p0) *****/
     offset = SEXT(operand);
     if (AC == 0) P0 = P0 + offset;
     CYCLES(10);
     break;
     
case 0x99: /***** jz ##(p1) *****/
     offset = SEXT(operand);
     if (AC == 0) P0 = P1 + offset;
     CYCLES(10);
     break;
     
case 0x9a: /***** jz ##(p2) *****/
     offset = SEXT(operand);
     if (AC == 0) P0 = P2 + offset;
     CYCLES(10);
     break;
     
case 0x9b: /***** jz ##(p3) *****/
     offset = SEXT(operand);
     if (AC == 0) P0 = P3 + offset;
     CYCLES(10);
     break;
     
case 0x9c: /***** jnz ##(p0) *****/
     offset = SEXT(operand);
     if (AC != 0) P0 = P0 + offset;
     CYCLES(10);
     break;
     
case 0x9d: /***** jnz ##(p1) *****/
     offset = SEXT(operand);
     if (AC != 0) P0 = P1 + offset;
     CYCLES(10);
     break;
     
case 0x9e: /***** jnz ##(p2) *****/
     offset = SEXT(operand);
     if (AC != 0) P0 = P2 + offset;
     CYCLES(10);
     break;
     
case 0x9f: /***** jnz ##(p3) *****/
     offset = SEXT(operand);
     if (AC != 0) P0 = P3 + offset;
     CYCLES(10);
     break;
     
case 0xa8: /***** ild ##(p0) *****/
     offset = SEXT(operand);
     MA = P0 + offset;
     READ();
     MB = AC = (MB + 1);
     WRITE();
     CYCLES(22);
     break;
     
case 0xa9: /***** ild ##(p1) *****/
     offset = SEXT(operand);
     MA = P1 + offset;
     READ();
     MB = AC = (MB + 1);
     WRITE();
     CYCLES(22);
     break;
     
case 0xaa: /***** ild ##(p2) *****/
     offset = SEXT(operand);
     MA = P2 + offset;
     READ();
     MB = AC = (MB + 1);
     WRITE();
     CYCLES(22);
     break;
     
case 0xab: /***** ild ##(p3) *****/
     offset = SEXT(operand);
     MA = P3 + offset;
     READ();
     MB = AC = (MB + 1);
     WRITE();
     CYCLES(22);
     break;
     
case 0xb8: /***** dld ##(p0) *****/
     offset = SEXT(operand);
     MA = P0 + offset;
     READ();
     MB = AC = (MB - 1);
     WRITE();
     CYCLES(22);
     break;
     
case 0xb9: /***** dld ##(p1) *****/
     offset = SEXT(operand);
     MA = P1 + offset;
     READ();
     MB = AC = (MB - 1);
     WRITE();
     CYCLES(22);
     break;
     
case 0xba: /***** dld ##(p2) *****/
     offset = SEXT(operand);
     MA = P2 + offset;
     READ();
     MB = AC = (MB - 1);
     WRITE();
     CYCLES(22);
     break;
     
case 0xbb: /***** dld ##(p3) *****/
     offset = SEXT(operand);
     MA = P3 + offset;
     READ();
     MB = AC = (MB - 1);
     WRITE();
     CYCLES(22);
     break;
     
case 0xc0: /***** ld ##(p0) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     MA = P0 + offset;
     READ();
     AC = MB;
     CYCLES(18);
     break;
     
case 0xc1: /***** ld ##(p1) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     MA = P1 + offset;
     READ();
     AC = MB;
     CYCLES(18);
     break;
     
case 0xc2: /***** ld ##(p2) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     MA = P2 + offset;
     READ();
     AC = MB;
     CYCLES(18);
     break;
     
case 0xc3: /***** ld ##(p3) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     MA = P3 + offset;
     READ();
     AC = MB;
     CYCLES(18);
     break;
     
case 0xc4: /***** ldi ## *****/
     AC = operand;
     CYCLES(10);
     break;
     
case 0xc5: /***** ld @##(p1) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     if (offset & 0x80) P1 += offset;
     MA = P1;
     READ();
     AC = MB;
     if ((offset & 0x80) == 0) P1 += offset;
     CYCLES(18);
     break;
     
case 0xc6: /***** ld @##(p2) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     if (offset & 0x80) P2 += offset;
     MA = P2;
     READ();
     AC = MB;
     if ((offset & 0x80) == 0) P2 += offset;
     CYCLES(18);
     break;
     
case 0xc7: /***** ld @##(p3) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     if (offset & 0x80) P3 += offset;
     MA = P3;
     READ();
     AC = MB;
     if ((offset & 0x80) == 0) P3 += offset;
     CYCLES(18);
     break;
     
case 0xc8: /***** st ##(p0) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     MA = P0 + offset;
     MB = AC;
     WRITE();
     CYCLES(18);
     break;
     
case 0xc9: /***** st ##(p1) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     MA = P1 + offset;
     MB = AC;
     WRITE();
     CYCLES(18);
     break;
     
case 0xca: /***** st ##(p2) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     MA = P2 + offset;
     MB = AC;
     WRITE();
     CYCLES(18);
     break;
     
case 0xcb: /***** st ##(p3) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     MA = P3 + offset;
     MB = AC;
     WRITE();
     CYCLES(18);
     break;
     
case 0xcd: /***** st @##(p1) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     if (offset & 0x80) P1 += offset;
     MA = P1;
     MB = AC;
     WRITE();
     if ((offset & 0x80) == 0) P1 += offset;
     CYCLES(18);
     break;
     
case 0xce: /***** st @##(p2) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     if (offset & 0x80) P2 += offset;
     MA = P2;
     MB = AC;
     WRITE();
     if ((offset & 0x80) == 0) P2 += offset;
     CYCLES(18);
     break;
     
case 0xcf: /***** st @##(p3) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     if (offset & 0x80) P3 += offset;
     MA = P3;
     MB = AC;
     WRITE();
     if ((offset & 0x80) == 0) P3 += offset;
     CYCLES(18);
     break;
     
case 0xd0: /***** and ##(p0) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     MA = P0 + offset;
     READ();
     AC &= MB;
     CYCLES(18);
     break;
     
case 0xd1: /***** and ##(p1) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     MA = P1 + offset;
     READ();
     AC &= MB;
     CYCLES(18);
     break;
     
case 0xd2: /***** and ##(p2) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     MA = P2 + offset;
     READ();
     AC &= MB;
     CYCLES(18);
     break;
     
case 0xd3: /***** and ##(p3) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     MA = P3 + offset;
     READ();
     AC &= MB;
     CYCLES(18);
     break;
     
case 0xd4: /***** ani ## *****/
     AC &= operand;
     CYCLES(10);
     break;
     
case 0xd5: /***** and @##(p1) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     if (offset & 0x80) P1 += offset;
     MA = P1;
     READ();
     AC &= MB;
     if ((offset & 0x80) == 0) P1 += offset;
     CYCLES(18);
     break;
     
case 0xd6: /***** and @##(p2) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     if (offset & 0x80) P2 += offset;
     MA = P2;
     READ();
     AC &= MB;
     if ((offset & 0x80) == 0) P2 += offset;
     CYCLES(18);
     break;
     
case 0xd7: /***** and @##(p3) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     if (offset & 0x80) P3 += offset;
     MA = P3;
     READ();
     AC &= MB;
     if ((offset & 0x80) == 0) P3 += offset;
     CYCLES(18);
     break;
     
case 0xd8: /***** or ##(p0) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     MA = P0 + offset;
     READ();
     AC |= MB;
     CYCLES(18);
     break;
     
case 0xd9: /***** or ##(p1) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     MA = P1 + offset;
     READ();
     AC |= MB;
     CYCLES(18);
     break;
     
case 0xda: /***** or ##(p2) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     MA = P2 + offset;
     READ();
     AC |= MB;
     CYCLES(18);
     break;
     
case 0xdb: /***** or ##(p3) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     MA = P3 + offset;
     READ();
     AC |= MB;
     CYCLES(18);
     break;
     
case 0xdc: /***** ori ## *****/
     AC |= operand;
     CYCLES(10);
     break;
     
case 0xdd: /***** or @##(p1) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     if (offset & 0x80) P1 += offset;
     MA = P1;
     READ();
     AC |= MB;
     if ((offset & 0x80) == 0) P1 += offset;
     CYCLES(18);
     break;
     
case 0xde: /***** or @##(p2) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     if (offset & 0x80) P2 += offset;
     MA = P2;
     READ();
     AC |= MB;
     if ((offset & 0x80) == 0) P2 += offset;
     CYCLES(18);
     break;
     
case 0xdf: /***** or @##(p3) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     if (offset & 0x80) P3 += offset;
     MA = P3;
     READ();
     AC |= MB;
     if ((offset & 0x80) == 0) P3 += offset;
     CYCLES(18);
     break;
     
case 0xe0: /***** xor ##(p0) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     MA = P0 + offset;
     READ();
     AC ^= MB;
     CYCLES(18);
     break;
     
case 0xe1: /***** xor ##(p1) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     MA = P1 + offset;
     READ();
     AC ^= MB;
     CYCLES(18);
     break;
     
case 0xe2: /***** xor ##(p2) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     MA = P2 + offset;
     READ();
     AC ^= MB;
     CYCLES(18);
     break;
     
case 0xe3: /***** xor ##(p3) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     MA = P3 + offset;
     READ();
     AC ^= MB;
     CYCLES(18);
     break;
     
case 0xe4: /***** xri ## *****/
     AC ^= operand;
     CYCLES(10);
     break;
     
case 0xe5: /***** xor @##(p1) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     if (offset & 0x80) P1 += offset;
     MA = P1;
     READ();
     AC ^= MB;
     if ((offset & 0x80) == 0) P1 += offset;
     CYCLES(18);
     break;
     
case 0xe6: /***** xor @##(p2) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     if (offset & 0x80) P2 += offset;
     MA = P2;
     READ();
     AC ^= MB;
     if ((offset & 0x80) == 0) P2 += offset;
     CYCLES(18);
     break;
     
case 0xe7: /***** xor @##(p3) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     if (offset & 0x80) P3 += offset;
     MA = P3;
     READ();
     AC ^= MB;
     if ((offset & 0x80) == 0) P3 += offset;
     CYCLES(18);
     break;
     
case 0xe8: /***** dad ##(p0) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     MA = P0 + offset;
     READ();
     _DecimalAdd();
     CYCLES(23);
     break;
     
case 0xe9: /***** dad ##(p1) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     MA = P1 + offset;
     READ();
     _DecimalAdd();
     CYCLES(23);
     break;
     
case 0xea: /***** dad ##(p2) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     MA = P2 + offset;
     READ();
     _DecimalAdd();
     CYCLES(23);
     break;
     
case 0xeb: /***** dad ##(p3) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     MA = P3 + offset;
     READ();
     _DecimalAdd();
     CYCLES(23);
     break;
     
case 0xec: /***** dai ## *****/
     MB = operand;
     _DecimalAdd();
     CYCLES(15);
     break;
     
case 0xed: /***** dad @##(p1) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     if (offset & 0x80) P1 += offset;
     MA = P1;
     READ();
     _DecimalAdd();
     if ((offset & 0x80) == 0) P1 += offset;
     CYCLES(23);
     break;
     
case 0xee: /***** dad @##(p2) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     if (offset & 0x80) P2 += offset;
     MA = P2;
     READ();
     _DecimalAdd();
     if ((offset & 0x80) == 0) P2 += offset;
     CYCLES(23);
     break;
     
case 0xef: /***** dad @##(p3) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     if (offset & 0x80) P3 += offset;
     MA = P3;
     READ();
     _DecimalAdd();
     if ((offset & 0x80) == 0) P3 += offset;
     CYCLES(23);
     break;
     
case 0xf0: /***** add ##(p0) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     MA = P0 + offset;
     READ();
     _BinaryAdd();
     CYCLES(19);
     break;
     
case 0xf1: /***** add ##(p1) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     MA = P1 + offset;
     READ();
     _BinaryAdd();
     CYCLES(19);
     break;
     
case 0xf2: /***** add ##(p2) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     MA = P2 + offset;
     READ();
     _BinaryAdd();
     CYCLES(19);
     break;
     
case 0xf3: /***** add ##(p3) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     MA = P3 + offset;
     READ();
     _BinaryAdd();
     CYCLES(19);
     break;
     
case 0xf4: /***** adi ## *****/
     MB = operand;
     _BinaryAdd();
     CYCLES(11);
     break;
     
case 0xf5: /***** add @##(p1) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     if (offset & 0x80) P1 += offset;
     MA = P1;
     READ();
     _BinaryAdd();
     if ((offset & 0x80) == 0) P1 += offset;
     CYCLES(19);
     break;
     
case 0xf6: /***** add @##(p2) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     if (offset & 0x80) P2 += offset;
     MA = P2;
     READ();
     _BinaryAdd();
     if ((offset & 0x80) == 0) P2 += offset;
     CYCLES(19);
     break;
     
case 0xf7: /***** add @##(p3) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     if (offset & 0x80) P3 += offset;
     MA = P3;
     READ();
     _BinaryAdd();
     if ((offset & 0x80) == 0) P3 += offset;
     CYCLES(19);
     break;
     
case 0xf8: /***** cad ##(p0) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     MA = P0 + offset;
     READ();
     MB ^= 0xFF;
     _BinaryAdd();
     CYCLES(20);
     break;
     
case 0xf9: /***** cad ##(p1) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     MA = P1 + offset;
     READ();
     MB ^= 0xFF;
     _BinaryAdd();
     CYCLES(20);
     break;
     
case 0xfa: /***** cad ##(p2) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     MA = P2 + offset;
     READ();
     MB ^= 0xFF;
     _BinaryAdd();
     CYCLES(20);
     break;
     
case 0xfb: /***** cad ##(p3) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     MA = P3 + offset;
     READ();
     MB ^= 0xFF;
     _BinaryAdd();
     CYCLES(20);
     break;
     
case 0xfc: /***** cai ## *****/
     MB = operand;
     MB ^= 0xFF;
     _BinaryAdd();
     CYCLES(12);
     break;
     
case 0xfd: /***** cad @##(p1) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     if (offset & 0x80) P1 += offset;
     MA = P1;
     READ();
     MB ^= 0xFF;
     _BinaryAdd();
     if ((offset & 0x80) == 0) P1 += offset;
     CYCLES(20);
     break;
     
case 0xfe: /***** cad @##(p2) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     if (offset & 0x80) P2 += offset;
     MA = P2;
     READ();
     MB ^= 0xFF;
     _BinaryAdd();
     if ((offset & 0x80) == 0) P2 += offset;
     CYCLES(20);
     break;
     
case 0xff: /***** cad @##(p3) *****/
     offset = (operand == 0x80) ? SEXT(EX) : SEXT(operand);
     if (offset & 0x80) P3 += offset;
     MA = P3;
     READ();
     MB ^= 0xFF;
     _BinaryAdd();
     if ((offset & 0x80) == 0) P3 += offset;
     CYCLES(20);
     break;
     