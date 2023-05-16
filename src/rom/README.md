# Aquarius MX ROM Source Code
This folder contains the source code files for the Aquarius MX ROM.

## Release Folders
 - **v2-0** - This is the current DEVELOPMENT version of the MX ROM. See readme.md within folder for full list of commands and functions.
 - **v1-2** - This is the current PRODUCTION version of the MX ROM.
   - Fixed error in LOAD to array function (Mack)
   - Adding filetype SCR to **LOAD** command to default to starting location 12288 ($3000) if no address is given
   - Fixed minor errors in COMMENTS
 - **archive** - Old versions of the MX ROM.
   - **v1-1** - Changed KILL to DEL
   - **v1-0** - Last version used by the Micro Expander.

## General Notes
- ROM/BIN (BINary) files are created using ASM (ASseMbly language), which is compiled using a Z80 assembler (usually zmac).
