:: Batch file to compile lab6 project for CMPE 12L %MPIDE_PATH%\hardware\pic32\compiler\pic32-tools\bin"
TITLE LAB 6 - CMPE 12L Fall 2012

:: Set the path so we can run MPIDE programs
set MPIDE_PATH=D:\Program Files (x86)\mpide
set PATH=%PATH%;%MPIDE_PATH%\hardware\pic32\compiler\pic32-tools\bin

:: Change to your working directory
cd /d D:\Users\Mark\Dropbox\UCSC\Fall12\CMPE12\lab6

pic32-g++ -c -mprocessor=32MX320F128H -I. "-I%MPIDE_PATH%/hardware/pic32/cores/pic32" "-I%MPIDE_PATH%/hardware/pic32/variants/Uno32" -O0 main.cpp -o main.o 

pic32-as -march=pic32mx -I. lab6.s -o lab6.o

pic32-g++ -Os -Wl,--gc-sections -mdebugger -mprocessor=32MX320F128H  -o main.elf  main.o lab6.o core.a -T  "%MPIDE_PATH%/hardware/pic32/cores/pic32/chipKIT-UNO32-application-32MX320F128L.ld"

pic32-bin2hex -a main.elf 

pic32-objdump -h -S main.elf > main.lss

pic32-nm -n main.elf > main.sym

ECHO Done! (Were there any errors or warnings?)
PAUSE