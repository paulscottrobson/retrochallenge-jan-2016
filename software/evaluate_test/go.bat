@echo off
python generate.py
\mingw\bin\asw -L evaltest.asm 
if errorlevel 1 goto exit
\mingw\bin\p2bin -r 36864-65535 evaltest.p
del evaltest.p
copy /Y evaltest.bin ..\..\emulator\rom9000.bin
..\..\emulator\wp1 $evaltest.bin
:exit
