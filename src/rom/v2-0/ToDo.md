TO-DO List
==============

This file is for recording upcoming changes and features that are being added, and to track them.

---
## IN PROCESS:
### ROM
- [ ] Test hardware behavior without RTC installed (RAM only)

- [ ] Modify dos.asm and CH376.asm to write USB file timestamp

- [ ] Add MKDIR. RMDIR, and RENAME to dos.asm
  - [ ] Verify this is feasible
  - [ ] Add accompanying routines to CH376.asm

- [ ] Rewrite hook dispatch routine fo faster execution of BASIC Programs.

### AquaLite
- [ ] Add a second virtual AY-3-8910 (8913), responding in IO ports $F8 & $F9

- [ ] Fix LOAD/RUN of *.ROM files... shouldn't behave differently than hardware.

### Other
- [ ] SPACE option in PT3PLAY.ROM song playback doesn't go to next song. Also, second PSG is not yet supported.

## UNDER CONSIDERATION / WISH LIST
- Turn debugger into separate ROM option

- Screen copy from MSX BASIC (this is preferred over GET/PUT commands from ExtBASIC)
  - COPY (X1,Y1) - (X2,Y2) TO < array variable name >
  - COPY < array variable name > TO (X1,Y1) - (X2,Y2)  

- Implement remaining set of Extended BASIC routines (LINE, CIRCLE, DRAW, MENU, etc.)

- MOD(dividend, divisor) function for modulus/remainder
  - No hook 

- XOR logical function/operator
  
- Full Error Messages
  - Example:
    - ` Syntax Error ` instead of ` SN Error `

- RPL$(source string, match string, replacement string) replace string function
  - Example 1:
    - ` 10 NM$ = "JOHN JAMES SMITH" `
    - ` 20 NM$ = RPL$(NM$, "JAMES ", "") `
    - ` 30 PRINT NM$ `
      - "JOHN SMITH"
  - Example 2:
    - ` PRINT RPL$("Suzy Saves Stuff","S","Sh") `
      - "Shuzy Shaves Shtuff"
  - Out of Scope, although left hand MID$ is a possibility
    - ` MID$(<string expl> ,n [,m] ) = <str ing exp2> `

## COMPLETE:
- [x] PSG() now accepts registers in the 16-31 range for a second AY-3-8913.

- [x] Test/Tweak, document KEY() function

- [x] Created FRCADR - FRCINT replacement that accepts -32768 through 65535
  - [x] Replaced FRCINT with FRCADR in IN/OUT/CALL
  - [x] Override PEEK and POKE to use a 16bit unsigned integer as well a 16 Bit Signed.
  - [x] LOAD, SAVE, etc - use FRCADR instead of FRCINTn
  - [x] Modified FRCADR to TM Error if argument is string

- [x] VER() - Return version and revision

- [x] DTM$() - Get DateTime from RTC

- [x] SDTM "YYMMDDHHMMSS" - Set DateTime on RTC

- [x] CLS - Specify Screen Colors

- [x] Fix: Allowed spaces between FN name and "(" in USB BASIC functions

- [x] DEC("FFFF") - Hex to Decimal (unsigned)

- [x] Extend FRMEVL to parse unsigned hex 16 bit hex literals prefixed with dollar sign
  - [x] not doing binary at this time, 9 to 17 character literals seem less useful than just using hex

- [x] Multi-byte POKE addr, byte, byte, STEP count, byte, byte...
  - [x] Does NOT work with numeric arrays, i.e. poke a()
  - [x] DOES work with factored numeric array values, i.e. poke a(0),a(1),a(2),a(3)

- [x] POKE addr TO addr, byte

- [x] DEEK and DOKE -16 bit PEEK and POKE
  -  [x] Modified DOKE to accept list of words

- [x] Implement DEF FN and ATN()

- [x] Stand-alone PT3 Player runs both on actual hardware and AquaLite in MX mode.

- [x] Fix issue where no result is returned from DTM$() after a successfull SDTM is made.

- [x] ATN() function returning incorrect results (added 11 MAY 2023)

- [x] SAVE for CAQ and BAS will save their known headers and then the payload 
  - [x] SAVE for Array should behave as originally designed; should behave similarly to how CSAVE for arrays works
  - [x] added 15 bytes of $00 at end, written by CSAVE, required by CLOAD

- [x] SAVE for any other filetype (raw) will require a valid start address and length, otherwise SN Error; no HEADER will be added to the beginning

- [x] LOAD for Basic program and Array are loaded into their expected locations
  - [x] BASIC Program and Array Files are both CAQ format (header and tail)
  - [x] Can have any file suffix, including BAS or CAQ

- [x] LOAD for any other filetype (raw) will require a valid target address, otherwise SN Error

- [x] RUN for Basic program file (CAQ format) loads them where expected, then runs them

- [x] RUN for all other file types gives an filetype mismatch ?FC error

- [x] Modify dos.asm to read USB file timestamp
  - [x] Added dtm_to_fts and fts_to_dtm routines to dtm_lib.asm
  - [x] Modified dos__directory to convert and print last write date and time
  - [x] Modify dos.asm to call rtc_read and dtm_lib.asm routines

- [x]EDIT and Immediate Mode
  - [x] remap unused control keys to ASCII characters not on keyboard
  - [x] increase line buffer length to 127

- [x] CLEAR: use GETADR from memory size, limit to below system variables

- [x] Transition in-line documentation (;;;) to Markdown format.

- [x] Add SWAP, ERASE statements

- [x] Create CD$ pseudo-variable for PATH to string value

- [x] Debugger removed
  - [x] Debug and Break vectors added to SysVars
  - [x] Debug statement prints "Debugger not installed"
  - [x] Option commented out of splash screen - 
  
### AquaLite

- [x] Populate FAT directory entry DIR_WrtTime and DIR_WrtDate when reading directory

- [x] Update RTC emulation
  - [x] When $3821 is accessed for read populate $3821-$3929 with $FF, cc, ss, mm, HH, 1, DD, MM, YY
  - [x] Add option for RTC installed or not

