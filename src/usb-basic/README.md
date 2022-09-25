# USB BASIC Source Code
This folder contains BASIC source code files and tools for programming in USB BASIC with the Aquarius MAX (or AquaLite). These files are featured in the YouTube videos on how to use USB BASIC.

## Folder Contents
 - **tutorial** - This folder contains the files used in the first video, demonstrating LOAD, SAVE, and RUN commands, as well as DIR (DIRectory) and CD (Change Directory).
 - **bas2txt.py** - This is a Python3 script that converts Aquarius BASIC files to text files, for easier review and editing.
 - **txt2bas.py** - This is a Python3 script that converts text files formatted as Aquarius BASIC (with line numbers) into actual, runnable .BAS files.

## General Notes
- **Python Files** - Thanks to Frank van den Hoef for the development of these files for easier editing and conversion. Note that these will NOT work on Aquarius/AquaLite. They must be run from your modern system (Windows, MacOS, Linux) in Python3 using the following formats:
  - `python bas2txt.py infile.bas outfile.txt` (where infile is the input file name and outfile is the desired output file name).
  - `python txt2bas.py infile.txt outfile.bas` (where infile is the input file name and outfile is the desired output file name).
- **Use on Emulators or Hardware** - Copy individual folders into either the root folder of the USB drive or the "usb" folder within AquaLite. Remember that the USB hardware drivers only recognize filenames with eight or fewer characters in the filename, and three or fewer characters in the suffix. Also, odd characters that don't exist on the Aquarius will cause problems, so stick to simple letters, numbers, and hyphens... essentially anything you can type on a REAL Aquarius keyboard.
