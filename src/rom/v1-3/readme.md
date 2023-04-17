Building AquBASIC from Source 
=============================


| file         |    purpose   |
|------------------|-----------------------------------------------------------|
| aqubasic.asm     | ROM initialisation, boot menu, extended BASIC commands |
| aqubug.asm       | Aqubug debugger |
| datetime.asm     | Interface to the Dallas DS1244 RTC (Real Time Clock) chip |
| debug.asm        | 'lite' debugger (see notes below) |
| dos.asm          | interface between BASIC and USB driver |
| ch376.asm        | USB driver |
| windows.asm      | windowed text |
| filerequest.asm  | select file from list  |
| string.asm       | string functions |
| load_rom.asm     | rom loader  |
| PT3play.asm      | play PT3 music files - TO BE REMOVED !!! |
| edit.asm         | BASIC command line editor |
| keycheck.asm     | keyboard scan |
| aquarius.i       | aquarius system defines |
| windows.i        | windowed text defines     |   
| macros.i         | structure macros etc. |

27 AUG 2022 (SPH) - zmac is still the recommended method for compiling the MX ROM into a usable binary file, but the project has been turned into a Visual Studio Code project to make things simpler for most folks to work with. Here are the general steps to setting up Visual Studio Code and zmac on a Windows-based PC:
  - From the Microsoft site, download and install Visual Studio Code (not Visual Studio 2022, etc). The default install settings are fine. You should restart Windows after install is complete.
  - Download the zmac executable from http://48k.ca/zmac.html (ZIP file, usually linked in upper right corner).
  - Unzip and install somewhere easy to access (I use C:\zmac for simplicity.). Copy this path for the next step.
  - From your Start menu, begin to type "edit the system Environment Variables", click on the applet that comes up, and add a new line to the PATH variable to include the path to zmac you set previously... JUST the path to the folder, not the path to the EXE itself. SAVE this setting and restart Windows (again, sorry).
  - Assuming you've already made a copy of the Aquarius-MX GitHub repository on your local machine, from within the Aquarius-MX/src/rom/v1-1 folder, right click and select "Open with Code". It should open up the project in VS Code.
  - From the VS Code menu, you can select Terminal > Run Build Task... to compile the source code and create the AQ_MX_ROM.BIN file (64kb) in the root directory of the v1-1 folder. You can use this file to burn to your Winbond 27C512 EEPROM.
  
Note that the 64kb ROM image is the SAME 16kb ROM image (with the FULL debugger) repeated four times in a row to fill up the full 64kb of the ROM chip.

Below are the original notes from Bruce Abbott on how to create both a full and lite version of the debugger ROM, which can replace one of the four 16kb copies within the 64kb BIN image, and can be switched with the A14 and A15 HI LO jumpers beside the ROM chip. Most users will never need this feature, but it is included for completeness.

-----------

All the code was assembled with zmac, slightly modified to output only binary files. 

command: zmac.exe --zmac -n -I include aqubasic.asm

zmac creates a directory 'zout' for the binary output file. 

To create a ROM file with both the 'full' and 'lite' debugger versions, first define the variable 'aqubug' then assemble 'aqubasic.asm' to produce 'aqubasic.bin'. Rename it to 'aqubasic0.bin', undefine 'aqubug' and assemble again. Rename the new binary to 'aqubasic1.bin'. Finally run the batch file 'aqubasic.bat' which merges the two ROMs together to produce 'aqubasic10.rom'.
