@echo off
\mingw\bin\asw -L exprtest.asm 
if errorlevel 1 goto exit
\mingw\bin\p2bin -r 36864-40959 exprtest.p
del exprtest.p
copy /Y exprtest.bin ..\..\emulator\rom9000.bin
..\..\emulator\wp1 $exprtest.bin
:exit
