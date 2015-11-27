@echo off
python process.py
copy /Y __font8x8.h ..\..\emulator\binaries
mkdir  ..\ST7920Driver\src\binaries
copy  __font8x8.h ..\ST7920Driver\src\binaries
