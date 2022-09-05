Full documentation online at https://github.com/1stage/Aquarius-MX

New USB BASIC Commands:

CLS    - Clear screen
	Syntax: CLS <no arguments>
LOCATE - Position on screen
	Syntax: LOCATE col, row
OUT    - output data to I/O port
	Syntax: OUT port, data
PSG    - Program PSG register, value
	Syntax: PSG register, value [, ... ]
CALL   - call machine code subroutine
	Syntax: CALL address
	Address is signed integer,  0 to 32767  = $0000 - $7FFF
                               -32768 to -1 = $8000 - $FFFF
DEBUG  - call AquBUG Monitor/debugger
	Syntax: DEBUG <no arguments>
EDIT   - Edit a BASIC line
	Syntax: EDIT <line number>
LOAD   - load file from USB disk
	Syntax: LOAD "filename"        load BASIC program, binary executable
	        LOAD "filename",12345  load file as raw binary to address 12345 (signed integer, see CALL above)
	        LOAD "filename",*A     load data into numeric array A
SAVE   - save file to USB disk
	Syntax: SAVE "filename"             save BASIC program
		    SAVE "filename",addr,len    save binary data (signed ints)
DIR    - display USB disk directory with wildcard
	Syntax: DIR "wildcard"   selective directory listing
		    DIR              listing all files
CAT    - minimalist directory
	Syntax: CAT <no arguments>
CD     - change directory
	Syntax: CD "dirname"  = add 'subdir' to path
			CD "/path"    = set path to '/path'
			CD ""         = no operation
			CD            = show path
DEL    - delete file
	Syntax: DEL "filename"
	