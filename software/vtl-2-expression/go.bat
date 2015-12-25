@echo off
python generate2.py >tests.inc
\mingw\bin\asw -L vtl-2.asm 
if errorlevel 1 goto exit
\mingw\bin\p2bin -r 36864-65535 vtl-2.p
del vtl-2.p
copy /Y vtl-2.bin ..\..\emulator\rom9000.bin
..\..\emulator\wp1 $vtl-2.bin
:exit
