# Aquarius MX
## Abstract
The Aquarius MX system expander brings USB compatibility to the Aquarius, along with a 32K RAM expansion, featuring all the functionality of Bruce Abbott's Micro Expander in an easy-to-build solution that fits the footprint of the Mini Expander.

## [Bill of Materials](https://docs.google.com/spreadsheets/d/1y7v0VCkjMdx25ugit28F5JhuhwDJofCVQUG5Ozl9IgA)
Click the heading above for the current BOM with estimated costs.

## Build Process
1. Acquire the components
1. Assemble the PCB
1. Program the ROM and Logic Chips
1. Enclose components in the case
1. Format and configure USB drive

## GitHub Folder Structure
- **case** - components to make the 3D printed enclosure
- **docs** - system documentation, including schematics and board layouts
- **pcb** - files for making or modifying the PCB
  - **eagle** - Eagle files for creating or modifying the PCB and schematic
  - **gerber** - PCB creation files for sending to service bureaus
- **src** - files for programming or modifying ROM and GAL logic chips
  - **rom** - MX ROM code and BIN files
  - **gal-ay** - CUPL code and JED image files for AY Sound Chip GAL programming
  - **gal-ram-rom-usb** - CUPL code and JED image files for RAM/ROM/USB GAL programming
