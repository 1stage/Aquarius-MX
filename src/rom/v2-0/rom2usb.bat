@REM Move Assembled ROM to AquaLite USB Directory
@REM Requires environment variable "AquaLite" SET to 
@REM   AquaLite base directory
copy zout\aqubasic.cim %AquaLite%\usb\aqubasic.rom
