Building MX BASIC from Source 
=============================

NEEDS UPDATING BEFORE 2.0 LAUNCH! - SPH

| file         |    purpose   |
|------------------|-----------------------------------------------------------|
| aqubasic.asm        | ROM initialisation, boot menu, extended BASIC commands |
| aqubug.asm          | Legacy Micro Expander debugger |
| ch376.asm           | USB driver |
| debug.asm           | 'lite' debugger (see notes below) |
| dispatch.asm        | Statement and function dispatch tables |
| dos.asm             | Interface between BASIC and USB driver |
| ds1244rtc.asm       | Interface to the Dallas DS1244 RTC (Real Time Clock) chip |
| dtm_lib.asm         | DateTime formatting and caluculation functions |
| edit.asm            | BASIC command line editor |
| enhanced.asm        | Existing Aquarius BASIC commands that have been reworked |
| extbasic.asm        | Aquarius Extended BASIC commands (non-graphical) |
| extgraph.asm        | Aquarius Extended BASIC graphics commands |
| filerequest.asm     | Select file from list  |
| keycheck.asm        | Keyboard scan |
| load_rom.asm        | ROM loader  |
| splash.asm          | MX BASIC splash / boot screen code |
| strings.asm         | String functions |
| udfhook.asm         | UDF Hook table and dispatch routine |
| windows.asm         | Windowed text |
| include/aquarius.i  | Aquarius system defines |
| include/macros.i    | Structure macros etc. |
| include/windows.i   | Windowed text defines     |   

20 MAY 2023 (SPH) - zmac is still the recommended method for compiling the MX ROM into a usable binary file, but the project has been turned into a Visual Studio Code project to make things simpler for most folks to work with. Here are the general steps to setting up Visual Studio Code and zmac on a Windows-based PC:
  - From the Microsoft site, download and install Visual Studio Code (not Visual Studio 2022, etc). The default install settings are fine. You should restart Windows after install is complete.
  - Download the zmac executable from http://48k.ca/zmac.html (ZIP file, usually linked in upper right corner).
  - Unzip and install somewhere easy to access, with a short path (I use `C:\zmac` for simplicity.). Copy this path for the next step.
  - From your Start menu, begin to type "edit the system Environment Variables", click on the applet that comes up, and add a new line to the PATH variable to include the path to zmac you set previously... JUST the path to the folder, not the path to the EXE itself. SAVE this setting and restart Windows (again, sorry).
  - Assuming you've already made a copy of the Aquarius-MX GitHub repository on your local machine, from within the `Aquarius-MX/src/rom` folder, find the latest RELEASE version (currently v2.0), right click and copy/paste the folder to duplicate it.
  - Open that new folder, right click within it, and select "Open with Code". It should open up the project in VS Code. Note that you may have to edit some of the project settings and tasks to update it for your new project folder.
  - From the VS Code menu, you can select Terminal > Run Build Task... to compile the source code and create the AQ_MX_ROM.BIN file (64kb) in the root directory of the vX-X folder. You can use this file to burn to your Winbond 27C512 EEPROM.
  - It's recommended you use the ASM Code Lens extension within VC Code to assist in coding. It offers syntax and keyword highlighting.
  
Note that the 64kb ROM image is the SAME 16kb ROM image (with the FULL debugger) repeated four times in a row to fill up the full 64kb of the ROM chip.

Below are the original notes from Bruce Abbott on how to create both a full and lite version of the debugger ROM, which can replace one of the four 16kb copies within the 64kb BIN image, and can be switched with the A14 and A15 HI LO jumpers beside the ROM chip. Most users will never need this feature, but it is included for completeness.

-----------

All the code was assembled with zmac, slightly modified to output only binary files. 

Command:
```
zmac.exe --zmac -e --oo cim --nmnv -L -n -I include aqubasic.asm
```

zmac creates a directory 'zout' for the binary output file. 

To create a ROM file with both the 'full' and 'lite' debugger versions, first define the variable 'aqubug' then assemble 'aqubasic.asm' to produce 'aqubasic.bin'. Rename it to 'aqubasic0.bin', undefine 'aqubug' and assemble again. Rename the new binary to 'aqubasic1.bin'. Finally run the batch file 'aqubasic.bat' which merges the two ROMs together to produce 'aqubasic10.rom'.
