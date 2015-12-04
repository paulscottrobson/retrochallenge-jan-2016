@echo off
python gencommands.py >commands.inc
\mingw\bin\asw -L monitor.asm 
if errorlevel 1 goto exit
\mingw\bin\p2bin -r 0-2047 monitor.p
del monitor.p
copy /Y monitor.bin ..\..\emulator\test.bin
..\..\emulator\wp1 monitor.bin
:exit
