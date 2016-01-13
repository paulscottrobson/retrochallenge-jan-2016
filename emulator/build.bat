@echo off
cd ..\processor
call build
cd ..\emulator
python bintoc.py
mingw32-make
copy /Y wp1.exe ..\release
copy /Y \windows\SDL.dll ..\release