@echo off
\mingw\bin\asw -L vtl2.asm 
if errorlevel 1 goto exit
\mingw\bin\p2bin -r 36864-40959 vtl2.p
del vtl2.p
copy /Y vtl2.bin ..\..\emulator\rom9000.bin
..\..\emulator\wp1 $vtl2.bin
:exit
