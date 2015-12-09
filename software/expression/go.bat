@echo off
python generate.py >tests.inc
\mingw\bin\asw -L exprtest.asm 
if errorlevel 1 goto exit
\mingw\bin\p2bin -r 36864-65535 exprtest.p
del exprtest.p
copy /Y exprtest.bin ..\..\emulator\rom9000.bin
..\..\emulator\wp1 $exprtest.bin
:exit
