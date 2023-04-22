# TO-DO List

This file is for recording upcoming changes and features that are being added to track them

## IN PROCESS:

- LOAD, SAVE, etc - use FRCADR instead of FRCINT 

- Test hardware behavior without RTC installed (RAM only)

- Fix issue where no result is returned from DTM$() after a successfull SDTM is made.

- Working on switchable "skins" for the stand-alone PT3 Player ROM, as well as some other goodies. Still need to go in with the weed whacker and remove the legacy aqubasic.asm code to free up some space for the goodies.


## COMPLETE:

- Created FRCADR - FRCINT replacement that accepts -32768 through 65535
  - Replaced FRCINT with FRCADR in IN/OUT/CALL

- VER() - Return version and revision

- DTM$() - Get DateTime from RTC

- CLS - Specify Screen Colors

- Fix: Allowed spaces between FN name and "(" in USB BASIC functions

- DEC("FFFF") - Hex to Decimal (unsigned)

- PEEK/POKE - Override PEEK&POKE to use a 16bit unsigned integer as well a 16 Bit Signed

- Extend FRMEVL to parse unsigned hex 16 bit hex literals prefixed with dollar sign
  - not doing binary at this time, 9 to 17 character literals seem less useful than just using hex
