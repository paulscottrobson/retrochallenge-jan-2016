@echo off
python gentests.py
\mingw\bin\asw -L mathtest.asm 
if errorlevel 1 goto exit
\mingw\bin\p2bin -r 3072-8191 mathtest.p 
del mathtest.p
..\..\emulator\wp1 @mathtest.bin
:exit
