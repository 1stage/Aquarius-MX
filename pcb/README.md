# Aquarius MX PCB
This folder contains the components and procedures for creating the Aquarius MX PCB (Printed Circuit Board).

## Overview of Assembling the PCB
For those who want to build their own Aquarius MX, there are a number of options and features that can alter the cost and complexity of the process. Solutions range from a bare PCB with only the components necessary to run and use USB BASIC and the core Aquarius MX software, all the way to a fully assembled and finished Aquarius MX. The following items offer details of the range of options.
- **Bare Bones** - The simplest version of the Aquarius MX features the PCB, the ROM (socket recommended), RAM, USB module (headers recommended), GAL-RRU logic chip (socket recommended), address buffers, ROM address headers, balance capacitors, audio amp, and reset circuit. It does not include a 3D printed enclosure, so the PCB feet MUST be used to keep the PCB aligned with the Aquarius computer Expansion Port. The AY-3-8910 sound chip and the GAL-AY logic chip are ommitted, so there will be no enhanced sound or Control Pad input, and since there is not Control Pad input, the DB9 Control Pad ports are omitted, along with the PSG control header. It is estimated this version of the Aquarius MX can be built for less than US$50.
  - **PROS** - Cheapest solution; easy & quick to build; still maintains USB file access; all USB BASIC commands accessible (if not functional).
  - **CONS** - No three-voice sound or Control Pad input; vulnerable to damage for both the MX and the Aquarius computer due to exposed components.
- **Bare with Sound and IO** - Includes everything from Bare Bones, but adds the AY-3-8910 sound chip (socket recommended), GAL-AY logic chip (socket recommended), and a 2x10 Control Pad pin header (still no DB9 ports). With the additional components, it is estimated this version of the Aquarius MX can be built for less than US$75.
  - **PROS** - Inexpesive solution that has full software functionality of the MX; easy & quick to build.
  - **CONS** - Still vulnerable to damage to the MX and the Aquarius computer due to exposed components.
- **MX to Go** - Adds the 3D printed case and attached DB9 ports to allow Control Pad input at a reduced cost. USB card is more securely mounted to the MX PCB with Nylon stand-offs, both for stability and to keep it at the proper height within the case. Rubber feet are added to the case for proper alignment. DB9 ports are added by using the male end of two, less expensive "ATARI joystick" extension cables, either soldered directly to the DB9 pads on the PCB, or added to a 2x10 pin header, then trailed out the back of the MX case. With the additional components, it is estimated this version of the Aquarius MX can be built for less than US$100.
  - **PROS** - Adds Control Pad input, inexpensively; components are no longer at risk of damage now that they're inside a case
  - **CONS** - Lacks a professional, finished appearance; cables rattle around a bit
- **Complete Aquarius MX** - Adds the official DB9 ports used on the Mini Expander for a finished, professional appearance. It is estimated this version of the Aquarius MX can be built for less than US$125.
  - **PROS** - Professional appearance; perfect for resale
  - **CONS** - More expensive than the other options

## Folder Contents
 - **eagle** - This foder contains the files for Eagle (PCB design and layout tool published by Autodesk)
   - **aq_mx_v1-3-0c.brd** - Eagle Board file, describing the physical layout for the PCB, including all copper, solder masks, and silkscreen markings
   - **aq_mx_v1-3-0c.cam** - Eagle CAM board manufacturing profile for exporting proper layers to Gerber format
   - **aq_mx_v1-3-0c.epf** - Eagle Project file
   - **aq_mx_v1-3-0c.sch** - Eagle Schematic file, describing the electronic architecture of the Aquarius MX
 - **gerber** - This folder contains a ZIP archive file used to upload to PCB manufacturers such as OSH Park, JLCPCB, PCBWay, and others.

## Recommended PCB Manufacturing Settings
- **Base Material:** FR-4
 - **Layers:** 2
 - **Dimension:** 112.5mm x 208.6mm
 - **Different Design:** 1
 - **Delivery Fomat:** Single PCB
 - **PCB Thickness:** 1.6mm
 - **Layer stackup:** PCB
 - **Color:** Blue (recommended)
 - **Silkscreen:** White (default with Blue color)
 - **Surface Finish:** HASL (with lead)
 - **Outer Copper Weight:** 1
 - **Gold Fingers:** No
 - **Flying Probe Test:** Fully Test
 - **Castellated Holes:** No
 - **Remove Order Number:** Yes
 - **Paper between PCBs:** No
 - **Appearance Quality:** IPC Class 2 Standard
 - **Confirm Production file:** No
 - **Silkscreen Technology:** Ink-jet/Screen Printing Silkscreen
