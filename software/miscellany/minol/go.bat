@echo off
\mingw\bin\asw -L minol.asm 
if errorlevel 1 goto exit
\mingw\bin\p2bin -r 36864-40959 minol.p
del minol.p
copy /Y minol.bin ..\..\emulator\rom9000.bin
..\..\emulator\wp1 $minol.bin
:exit
