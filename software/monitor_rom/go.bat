@echo off
\mingw\bin\asw -L monitor.asm 
if errorlevel 1 goto exit
\mingw\bin\p2bin -r 0-2047 monitor.p
del monitor.p
..\..\emulator\wp1 monitor.bin
:exit
