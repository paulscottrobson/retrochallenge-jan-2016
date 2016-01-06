@echo off
del tests.inc
python generate.py >tests.inc
\mingw\bin\asw -L minolmath.asm 
if errorlevel 1 goto exit
\mingw\bin\p2bin -r 36864-65535 minolmath.p
del minolmath.p
copy /Y minolmath.bin ..\..\emulator\rom9000.bin
..\..\emulator\wp1 $minolmath.bin
:exit
