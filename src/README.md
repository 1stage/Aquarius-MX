# Aquarius MX Source Code
This folder contains the source code files for modifying the Aquarius MX software. Most users will not need to use this directory, as the files for programming the ROM and AY chips are already compiled for use in the **../software** folder of this site. This folder allows users to modify how their MX ROM and logic chips behave, and requires additional compiler software to work (see below).

## Folder Contents
 - **gal-ay** - This folder, sorted in subfolders by version, contains files used to create the JED file used in programming the GAL logic chip that controls the AY sound chip.
 - **gal-rom-ram-usb** - This folder, sorted in subfolders by version, contains the files used to create the JED file used in programming the GAL logic chip that controls the ROM, RAM, and USB interface.
 - **mx-basic** - This folder, sorted in subfolders by version, contains BASIC source code files and tools for programming in MX BASIC with the Aquarius MX (or AquaLite). These files are featured in the YouTube videos on how to use MX BASIC.
 - **rom** - This folder contains the source code files that generate the BIN file used in programming the Aquarius MX ROM, which holds the MX BASIC commands, the PT3 player, the DEBUGGER, and other tools.

## General Notes
- **JED File Development:** JED files are generated from PSD source code that defines the logic, and which are compiled with CUPL (usually WinCUPL).
- **BIN File Development:** ROM/BIN (BINary) files are created using ASM (ASseMbly language), which is compiled using a Z80 assembler (zmac recommended).
