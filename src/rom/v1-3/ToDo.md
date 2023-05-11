# TO-DO List

This file is for recording upcoming changes and features that are being added to track them

## IN PROCESS:
- ATN() function returning incorrect results (added 11 MAY 2023)

- SAVE "filename.bin", address, length seems to get four extra garbage bytes added to the file. So a length of 120 will save the expected 120 bytes, but there will be an extra 4 bytes at the beginning. (added 11 MAY 2023)

- Test hardware behavior without RTC installed (RAM only)

- SPACE option in FP3PLAY.ROM song playback doesn't go to next song.


## COMPLETE:

- Test/Tweak, document KEY() function

- Created FRCADR - FRCINT replacement that accepts -32768 through 65535
  - Replaced FRCINT with FRCADR in IN/OUT/CALL

- VER() - Return version and revision

- DTM$() - Get DateTime from RTC

- SDT("YYMMDDHHMMSS") - Set DateTime on RTC

- CLS - Specify Screen Colors

- Fix: Allowed spaces between FN name and "(" in USB BASIC functions

- DEC("FFFF") - Hex to Decimal (unsigned)

- Extend FRMEVL to parse unsigned hex 16 bit hex literals prefixed with dollar sign
  - not doing binary at this time, 9 to 17 character literals seem less useful than just using hex

- Override PEEK and POKE to use a 16bit unsigned integer as well a 16 Bit Signed.

- Multi-byte POKE addr, byte, byte, STEP count, byte, byte...
  - Does NOT work with numeric arrays, i.e. poke a()
  - DOES work with factored numeric array values, i.e. poke a(0),a(1),a(2),a(3)

- POKE addr TO addr, byte

- DEEK and DOKE -16 bit PEEK and POKE

- LOAD, SAVE, etc - use FRCADR instead of FRCINT

- Implement DEF FN and ATN()

- Stand-alone PT3 Player works both on actual hardware and AquaLite in MX mode.

- Fix issue where no result is returned from DTM$() after a successfull SDTM is made.
