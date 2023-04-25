# TO-DO List

This file is for recording upcoming changes and features that are being added to track them

## IN PROCESS:



- Test/Tweak, document KEY() function

- Test hardware behavior without RTC installed (RAM only)

- Fix issue where no result is returned from DTM$() after a successfull SDTM is made.

- Create SFX("filename.pt3") function that will load a short PT3 file and play it, ideally asynchronously (allows BASIC interpreter to still process commands). SFX(0) will STOP any PT3 file currently playing and mute all channels. SFX(1) will STOP and REPLAY any already queued PT3 file.
  - NON-STARTER???? PT3PLAY is now in a separate ROM so BASIC does not have access to any of the PT3PLAY code - You can have BASIC or PT3PLAY but not both

- Stand-alone PT3 Player doesn't work on actual hardware, only in AquaLite.


## COMPLETE:

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
