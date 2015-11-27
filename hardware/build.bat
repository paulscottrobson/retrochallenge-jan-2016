@echo off
rem
del /Q src\*.*
mkdir src\scmp 
mkdir src\binaries

copy /Y ..\emulator\start.cpp src
copy /Y ..\emulator\sys_processor.* src
copy /Y ..\emulator\sys_debug_system.h src
copy /Y ..\emulator\hardware.cpp src
copy /Y ..\emulator\scmp\__scmp*.h src\scmp
copy /Y ..\emulator\binaries\* src\binaries
copy /Y ..\miscellany\ST7920Driver\src\ST7920*.* src

platformio run