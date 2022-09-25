![Aquarius MX Logo](img/aq_mx_logo_color.png)

## Overview
The Aquarius MX system expander brings USB compatibility to the Aquarius Computer along with a 32K RAM expansion, and features all the functionality of Bruce Abbott's Micro Expander in an easy-to-build solution that fits the footprint of the Mini Expander.

## Features
- **USB Drive Port** - Reads and writes to USB drive, for quick access to games and programs
- **32k RAM** - Removes the need for a separate RAM expansion cartridge
- **Cartridge ROM Loading** - Quick loading/running of legacy Aquarius ROM cartridges through USB
- **AY-3-8910 Sound Chip** - Three voice PSG (Programmable Sound Generator) with Control Pad IO
- **PT3 Music Player** - Built-in retro music player
- **Aquarius Control Pad Inputs** - Standard DB9 connectors for attaching Aquarius Control Pads (internal header also available)
- **USB BASIC** - Enhanced commands for USB and IO devices to improve your BASIC programs
- **Classic Design** - Matches original Aquarius design aesthetic, in a device the same size as the Mini Expander: 210mm x 120mm x 55mm / 8.5" x 4.75" x 2.125"
- **Easy to Build** - Using standard through-hole components, this is an easy-to-make project for those who like to tinker in electronics
- **Open Source** - All components of this project are open source: make or modify them to your heart's content
- **Expandable** - System expansion port available for future add-ons

## Status Updates
- **26 SEP 2022** - Released YouTube video on intro to USB BASIC programming. Added source files and tools from the videos into the src/usb-basic folder.
- **21 SEP 2022** - v1.2 of MX ROM released to fix LOAD into array bug, and added "smart" load of SCR files into Screen RAM; [**AquaLite 1.32 released**](http://aquarius.je/aqualite) with the v1.2 MX ROM included, fixes SAVE issues, and can now be used to develop MX-dependent games & software.
- **15 SEP 2022** - Four YouTube videos on the Aquarius MX are posted; see links in docs folder.
- **09 SEP 2022** - Testing complete. All components are cleared for production and sale.
- **29 AUG 2022** - Signature Version (prebuilt) serial number 0001-SPH available for purchase on eBay (SOLD, 9/5/2022).
- **28 AUG 2022** - Prototypes shipped to testers. ROM incremented to v1.1 (replaced KILL command with DEL).
- **24 AUG 2022** - Most files have been uploaded and are actively being updated directly to the Repo.
- **23 AUG 2022** - Vendors identified in USA and UK to supply components.
- **21 AUG 2022** - First prototype completed and tested locally. Others will be built and sent to designated testers through the end of AUGUST 2022.
- **16 AUG 2022** - GitHub repository site created.

## Build Process
1. **Acquire the components** - [Click for Bill of Materials](https://docs.google.com/spreadsheets/d/1y7v0VCkjMdx25ugit28F5JhuhwDJofCVQUG5Ozl9IgA)
2. **Program the ROM and Logic Chips** - [Watch the YouTube video](https://youtu.be/DqxqzWqVAIM)
3. **Assemble the PCB** - [Watch the YouTube video](https://youtu.be/_-p9Ycmr9VQ)
4. **Enclose components in the case** - [Watch the YouTube video](https://youtu.be/FKW6YiFKHf0)
5. **Format and configure USB drive**

## GitHub Folder Structure
- **case** - components to make the 3D printed enclosure
- **docs** - system documentation, including schematics, board layout, and logo files
- **img** - image files used on this site
- **pcb** - files for making or modifying the PCB
- **software** - files for creating or updating the software used to run or control the Aquarius MX
- **src** - files for programming in USB BASIC, or modifying ROM and GAL logic chips

![Aquarius MX on Desk](img/aq_mx_on_desk.jpg)
