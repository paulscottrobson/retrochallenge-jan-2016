@echo off
python generate2.py >tests.inc
\mingw\bin\asw -L expression_test.asm 
if errorlevel 1 goto exit
\mingw\bin\p2bin -r 36864-65535 expression_test.p
del expression_test.p
copy /Y expression_test.bin ..\..\emulator\rom9000.bin
..\..\emulator\wp1 $expression_test.bin
:exit
