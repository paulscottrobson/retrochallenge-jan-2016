@echo off
\mingw\bin\asw -L mathtest.asm 
if errorlevel 1 goto exit
\mingw\bin\p2bin -r 3072-4095 mathtest.p 
del mathtest.p
..\..\emulator\wp1 @mathtest.bin
:exit
