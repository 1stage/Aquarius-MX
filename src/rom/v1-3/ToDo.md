# TO-DO List

This file is for recording upcoming changes and features that are being added to track them

## IN PROCESS:

- FRCINT - Create an unsigned FRCINT replacement that can be used by IN/OUT/CALL

- DEC("FFFF") - Hex to Decimal (unsigned)

- PEEK/POKE - Override PEEK&POKE to use a 16bit unsigned integer as well a 16 Bit Signed

- Extand FRMEVL to manage Hex literals (maybe Binary as well)

- Complete Dallas RTC read/write routines


## COMPLETE:

- Created FRCADR - FRCINT replacement that accepts -32768 through 65535
  - Replaced FRCINT with FRCADR in IN/OUT/CALL

- VER() - Return version and revision

- DTM$() - Get DateTime from RTC

- CLS - Specify Screen Colors
