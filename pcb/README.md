# Aquarius MX PCB
This folder contains the components and procedures for creating the Aquarius MX PCB (Printed Circuit Board).

[PCB is available for order direclty from **PCBWay by clicking here!**](https://www.pcbway.com/project/shareproject/Aquarius_Computer_Aquarius_MX_USB_Expander_c4a2f027.html) Don't forget to like and vote for our project!

## Overview of PCB Assembly Options
For those who want to build their own Aquarius MX, there are a number of options and features that can alter the cost and complexity of the process. Solutions range from a bare PCB with only the components necessary to run and use USB BASIC and the core Aquarius MX software, all the way to a fully assembled and finished Aquarius MX. The following items offer details of the range of options.
- **Bare Bones** - The simplest version of the Aquarius MX features the PCB, the ROM (socket recommended), RAM, USB module (headers recommended), GAL-RRU logic chip (socket recommended), address buffers, ROM address headers, balance capacitors, audio amp, and reset circuit. It does not include a 3D printed enclosure, so the PCB feet MUST be used to keep the PCB aligned with the Aquarius computer Expansion Port. The AY-3-8910 sound chip and the GAL-AY logic chip are ommitted, so there will be no enhanced sound or Control Pad input, and since there is not Control Pad input, the DB9 Control Pad ports are omitted, along with the PSG control header. It is estimated this version of the Aquarius MX can be built for less than US$50.
  - **PROS** - Cheapest solution; easy & quick to build; still maintains USB file access; all USB BASIC commands accessible (if not functional).
  - **CONS** - No three-voice sound or Control Pad input; vulnerable to damage for both the MX and the Aquarius computer due to exposed components.
- **Bare with Sound and IO** - Includes everything from Bare Bones, but adds the AY-3-8910 sound chip (socket recommended), GAL-AY logic chip (socket recommended), and a 2x10 Control Pad pin header (still no DB9 ports). With the additional components, it is estimated this version of the Aquarius MX can be built for less than US$75.
  - **PROS** - Inexpesive solution that has full software functionality of the MX; easy & quick to build.
  - **CONS** - Still vulnerable to damage to the MX and the Aquarius computer due to exposed components.
- **MX to Go** - Adds the 3D printed case and cable-attached DB9 ports to allow Control Pad input at a reduced cost. USB card is more securely mounted to the MX PCB with Nylon stand-offs, both for stability and to keep it at the proper height within the case. Rubber feet are added to the case for proper alignment. DB9 ports are added by using the male end of two, less expensive "ATARI joystick" extension cables, either soldered directly to the DB9 pads on the PCB, or added to a 2x10 pin header, then trailed out the back of the MX case. With the additional components, it is estimated this version of the Aquarius MX can be built for less than US$100.
  - **PROS** - Adds Control Pad input, inexpensively; components are no longer at risk of damage now that they're inside a case
  - **CONS** - Lacks a professional, finished appearance; cables rattle around a bit
- **Complete Aquarius MX** - Adds the official DB9 ports used on the Mini Expander for a finished, professional appearance. It is estimated this version of the Aquarius MX can be built for less than US$125.
  - **PROS** - Professional appearance; perfect for resale
  - **CONS** - More expensive than the other options

## Folder Contents
 - **eagle** - This foder contains the files for Eagle (PCB design and layout tool published by Autodesk)
   - **archive** - Contains previous versions of the PCB source files
   - **aq_mx_v1-4-0b.brd** - Eagle Board file, describing the physical layout for the PCB, including all copper, solder masks, and silkscreen markings
   - **aq_mx_v1-4-0b.cam** - Eagle CAM board manufacturing profile for exporting proper layers to Gerber format
   - **aq_mx_v1-4-0b.epf** - Eagle Project file
   - **aq_mx_v1-4-0b.sch** - Eagle Schematic file, describing the electronic architecture of the Aquarius MX
 - **gerber** - This folder contains a ZIP archive file used to upload to PCB manufacturers such as OSH Park, JLCPCB, PCBWay, and others.
 
## CH376S USB Interface Modules
There are two types of CH376S USB interface modules available. Here is how to identify the type of CH376S module you have:
 - **Type A Module** (referred to as an "LC Tech module" by Bruce Abbott during development of Micro Expander). Here's how to identify a **Type A** module:
    - Two sets of 1x3 jumper pins next to the USB port
    - Data header row (D0-D7) is at the BACK of the module, furthest away from the USB port
    - LED (D1) is near the 2x8 header pins
 - **Type B Module** (referred to as an "IC Station module" by Bruce Abbott during development of Micro Expander). Here's how to identify a **Type B** module:
    - One set of 1x3 jumper pins next to the USB port
    - Data header row (D0-D7) is towards the MIDDLE of the board, closest to the CH376S chip
    - LED (D1) is between the USB port and the 1x3 jumper pins

Beginning with v1-4-0b the Aquarius MX supports both **Type A** and **Type B** modules on a single PCB. Versions v1-3-0c and prior of the Aquarius MX PCB support only the **Type A** modules.
 - **Type A** modules install into the two columns of header pins closer to the BACK of the Aquarius MX. 
 - **Type B** modules install into the two columns of pins closer to the FRONT of the Aquarius MX. Note that since the **Type B** module is 1/10" further away from the back of the case, some USB thumb drives may be more difficult to insert. 


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
