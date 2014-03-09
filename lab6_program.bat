:: Batch file to compile lab6 project for CMPE 12L
TITLE LAB 6 - CMPE 12L Fall 2012

:: Set the path so we can run MPIDE programs
set MPIDE_PATH=D:\Program Files (x86)\mpide
set PATH=%PATH%;%MPIDE_PATH%\hardware\tools\avr\bin

:: Change to your working directory
cd /d D:\Users\Mark\Dropbox\UCSC\Fall12\CMPE12\lab6


avrdude "-C%MPIDE_PATH%/hardware/tools/avr/etc/avrdude.conf" -p32MX320F128H -P\\.\COM3 -cstk500v2 -b115200 -Uflash:w:main.hex:i

ECHO Done! (Were there any errors or warnings?)
PAUSE