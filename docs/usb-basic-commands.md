Full documentation online at https://github.com/1stage/Aquarius-MX

# USB BASIC Commands: #

**CLS**    - Clear screen (same as CLS command from Ext BASIC)
 - Syntax: CLS <no arguments>

**LOCATE** - Position cursor on screen
 - Syntax: LOCATE col, row

**DTM** - SET the DateTime on the Dallas DS1244 RTC (Real Time Clock), if present
 - Syntax: DTM "230411110700" - Sets the RTC to 04 APR 2023 11:08:00 (24 hour clock), uses "YYMMDDHHMMSS" format

**DTM$** - GET the DateTime from the Dallas DS1244 RTC (Real Time Clock), if present
 - Syntax: DTM$ (format)
 - format
   - 0 : Returns the DateTime as a string in "YYMMDDHHMMSSCC" format (CC = hundredths of seconds)
   - 1 : Returns the DateTime as a string in "YYYY-MM-DD HH:MM:SS" format (Century is assumed to be 20)

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
 - Syntax: Syntax: DEL "filename"
	
**HEX$**   - Convert signed integer (see CALL above) to hexadecimal string
 - Syntax: Syntax: HEX$ (value)
