# Aquarius MX PCB
This folder contains the components for creating the Aquarius MX PCB (Printed Circuit Board).

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
 - **Dimension:** 112.5 mm x 208.6mm
 - **Different Design:** 1
 - **Delivery Fomat:** Single PCB
 - **PCB Thickness:** 1.6
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
