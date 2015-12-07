@echo off
\mingw\bin\asw -L evaltest.asm 
if errorlevel 1 goto exit
\mingw\bin\p2bin -r 36864-40959 evaltest.p
del evaltest.p
copy /Y evaltest.bin ..\..\emulator\rom9000.bin
..\..\emulator\wp1 $evaltest.bin
:exit
