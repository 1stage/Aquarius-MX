# Aquarius MX
## Abstract
The Aquarius MX system expander brings USB compatibility to the Aquarius, along with a 32K RAM expansion, featuring all the functionality of Bruce Abbott's Micro Expander in an easy-to-build solution that fits the footprint of the Mini Expander.

## Build Process
- Acquire the components
- Assemble the PCB
- Program the ROM and Logic Chips
- Enclose in the case

## GitHub Folder Structure
- case - components to make the 3D printed enclosure
- docs - system documentation, including schematics and board layouts
- pcb - files for making or modifying the PCB
  - eagle - Eagle files for creating or modifying the PCB and schematic
  - gerber - PCB creation files for sending to service bureaus
- src - files for programming or modifying ROM and GAL logic chips
  - gal-ram-rom-udb - CUPL code and JED image files for GAL programming
  - gal-ay - CUPL code and JED image files for GAL programming
  - rom - MX ROM code and BIN files
