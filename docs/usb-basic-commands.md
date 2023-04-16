Full documentation online at https://github.com/1stage/Aquarius-MX

# USB BASIC Commands: #

**CLS**    - Clear screen 
 - Syntax: CLS <no arguments> - Clears whole screen with default BLACK text on CYAN background (same as CLS command from Ext BASIC)
 - Syntax: CLS color - Clears whole screen based on integer value of BG + (FG * 16) - ***SLATED FOR v1.3 ROM***

**LOCATE** - Position cursor on screen
 - Syntax: LOCATE col, row

**GDT$** - GET / SET the DateTime on the Dallas DS1244 RTC (Real Time Clock), if present - ***SLATED FOR v1.3 ROM***
 - Syntax: GDT$ (number) - GET the DateTime
 - number
   - 0 : Returns the DateTime as a string in "YYMMDDHHMMSSCC" format (CC = hundredths of seconds)
   - 1 : Returns the DateTime as a string in "YYYY-MM-DD HH:MM:SS" format (Century is assumed to be 20)
 - Syntax: GDT$ (string) - SET the DateTime
 - string
   - "YYMMDDHHMMSS" : Sets the DateTime. Centiseconds are set to 00. Century is assumed to be 2000.

**IN**    - Read data from I/O port
 - Syntax: IN (port)

**OUT**    - Write data to I/O port
 - Syntax: OUT port, data

**PSG**    - Program PSG register, value
 - Syntax: PSG register, value [, ... ]

**JOY**    - Read joystick input
 - Syntax: JOY (stick)
 - stick = 0 read both sticks, stick = 1 read stick 1 only, stick = 2 read stick 2 only

**CALL**   - call machine code subroutine
 - Syntax: CALL address
 - Address is signed integer,  0 to 32767  = $0000 - $7FFF and -32768 to -1 = $8000 - $FFFF

**DEBUG**  - call AquBUG Monitor/debugger
 - Syntax: DEBUG <no arguments>

**EDIT**   - Edit a BASIC line
 - Syntax: EDIT <line number>

**LOAD**   - load file from USB disk
 - Syntax: LOAD "filename"        load BASIC program, binary executable
 - Syntax: LOAD "filename",12345  load file as raw binary to address 12345 (signed integer, see CALL above)
 - Syntax: LOAD "filename",*A     load data into numeric array A

**SAVE**   - save file to USB disk
 - Syntax: SAVE "filename"             save BASIC program
 - Syntax: SAVE "filename",addr,len    save binary data (signed ints)

**RUN** - execute BASIC program (extends the original BASIC command)
 - Syntax: RUN
 - Syntax: RUN "filename.bas"
	
**DIR**    - display USB disk directory with wildcard
 - Syntax: DIR "wildcard"   selective directory listing
 - Syntax: DIR              listing all files

**CAT**    - minimalist directory
 - Syntax: CAT <no arguments>

**CD**     - change directory
 - Syntax: CD "dirname"  = add 'subdir' to path
 - Syntax: CD "/path"    = set path to '/path'
 - Syntax: CD ""         = no operation
 - Syntax: CD            = show path

**DEL**    - delete file (formerly KILL)
 - Syntax: DEL "filename"
	
**HEX$**   - Convert signed integer (see CALL above) to hexadecimal string
 - Syntax: HEX$ (value)

**VER**    - Return a value with the current USB BASIC ROM version - ***SLATED FOR v1.3 ROM***
 - Syntax: VER (0) 
 - Returned value is the (VERSION * 256) + REVISION, so v1.3 would be 259... (version 1 * 256) + revision 3 = 259
