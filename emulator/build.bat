@echo off
cd ..\processor
call build
cd ..\emulator
python bintoc.py
mingw32-make
