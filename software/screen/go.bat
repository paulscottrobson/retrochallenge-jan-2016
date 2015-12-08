@echo off
\mingw\bin\asw -L screentest.asm 
if errorlevel 1 goto exit
\mingw\bin\p2bin -r 36864-40959 screentest.p
del screentest.p
copy /Y screentest.bin ..\..\emulator\rom9000.bin
..\..\emulator\wp1 $screentest.bin
:exit
