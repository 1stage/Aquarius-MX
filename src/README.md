# Aquarius MX Source Code
This folder contains the source code files for modifying the Aquarius MX software.

## Folder Contents
 - **gal-ay** - This foder contains the files used to create the JED file used in programming the GAL logic chip that controls the AY sound chip.
 - **gal-rom-ram-usb** - This folder contains the files used to create the JED file used in programming the GAL logic chip that controls the ROM, RAM, and USB interface.
 - **rom** - This foder contains the source code files that generate the BIN file used in programming the Aquarius MX ROM file, including the USB BASIC commands, the PT3 player, the DEBUGGER, and other components.

## General Notes
- **JED File Development:** JED files are generated from PSD source code files that define the logic, and which are compiled with CUPL (usually WinCUPL).
- **BIN File Development:** ROM/BIN (BINary) files are created using ASM (ASseMbly language) files which are compiled using a Z80 assembler (TASM, PASM, etc.).
