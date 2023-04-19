# Aquarius MX ROM Source Code
This folder contains the source code files for the Aquarius MX ROM.

## Release Folders
 - **v1-3** - This is the current DEVELOPMENT version of the MX ROM.
   - Dallas DS1244 RTC (Real Time Clock) implementation with new SDTM (SET DateTime) command and DTM$() (GET DateTime) for getting/setting RTC. The DS1244 can replace the 32kb RAM chip in the stock design
   - CLS now takes an optional color parameter
   - VER() function returns version and revision number
   - More to come!
 - **v1-2** - This is the current PRODUCTION version of the MX ROM.
   - Fixed error in LOAD to array function (Mack)
   - Adding filetype SCR to **LOAD** command to default to starting location 12288 ($3000) if no address is given
   - Fixed minor errors in COMMENTS
 - **archive** - Old versions of the MX ROM.
   - **v1-1** - Changed KILL to DEL
   - **v1-0** - Last version used by the Micro Expander.

## General Notes
- ROM/BIN (BINary) files are created using ASM (ASseMbly language), which is compiled using a Z80 assembler (usually zmac).
