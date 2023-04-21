;====================================================================
;         Mattel Aquarius Hardware and System ROM Definitions
;====================================================================
; based on work by Kenny Millar and V D Steenovan
;
;
; 2015-11-4  V0.0 created by Bruce Abbott
; 2015-11-13 V0.1 changed ROWCOUNT to LISTCNT to avoid conflict with
;                 BLBASIC graphics variable ROWCOUNT
; 2016-01-18 V0.2 added macros for RST instructions
; 2016-1-30  V0.3 added PROGST (start of BASIC program area) using
;                 'set' directive. This can be overridden to extend
;                 the system variable area.
; 2017-05-06 V0.4 compute equates for buffer lengths
; 2017-06-12 V1.0 bumped to release version
; 2023-04-11 V1.1 Revised color names to more common values
; 2023-04-18 V1.2 Changed symbols to canonical names from Microsoft
;                 source code for CP/M Basic and 6502 Basic
;-------------------------------------------------------------------
;                            IO Ports
;-------------------------------------------------------------------
;   Address         Write                         Read
;      FC       bit 0 = Speaker & tape out    bit 0 = Tape in
;      FD       bit 0 = CP/M memory map       bit 0 = Vertical sync
;      FE       bit 0 = Printer TXD           bit 0 = Printer CTS
;      FF     bits7-0 = Exp bus lock       bits 0-6 = Keyboard
;

; string variable entry
; byte
;  0  variable name eg. 'A' = A$
;  1  null
;  2  string length
;  3  null
;  5  string text pointer low byte
;  6          ''          high byte

; constants:

CTRLC     = $03
BKSPC     = $08
LF        = $0A
CR        = $0D

; colors
BLACK     = 0
RED       = 1
GREEN     = 2
YELLOW    = 3
BLUE      = 4
MAGENTA   = 5
CYAN      = 6
WHITE     = 7
GREY      = 8
DKCYAN    = 9
DKMAGENTA = 10
DKBLUE    = 11
LTYELLOW  = 12
DKGREEN   = 13
DKRED     = 14
DKGREY    = 15

;-------------------------------------------------------------------
;                         Screen RAM
;-------------------------------------------------------------------
; 1k for characters followed by 1k for color attributes.
; 1000 visible characters on screen, leaving 24 unused bytes at end.
; First character in screen also sets the border character and color.
; The first row (40 bytes), and first & last columns of each row are
; normally filled with spaces, giving an effective character matrix
; of 38 columns x 24 rows.

CHRRAM   = $3000 ; 12288           start of character RAM
;          $33E7 ; 13287           end of character RAM
                 ;                 24 unused bytes
COLRAM   = $3400 ; 13312           Start of colour RAM
;          $37E7 ; 14311           end of color RAM
                 ;                 24 unused bytes

;-------------------------------------------------------------------
;                       System Variables
;-------------------------------------------------------------------
;Name    location Decimal Description
TTYPOS  = $3800 ; 14336           Current cursor column
CURRAM  = $3801 ; 14337           Position in CHARACTER RAM of cursor
USRPOK  = $3803 ; 14339           JMP instruction for USR.
USRADD  = $3804 ; 14340 - 14341    address of USR() function
UDFADDR = $3806 ; 14342  HOKDSP   RST $30 vector, hooks into various system routines
                ; 14343
CNTOFL  = $3808 ; 14344           Counter for lines listed (pause every 23 lines)
SCRMBL  = $3809 ; 14345           Last protection code sent to port($FF)
CHARC   = $380A ; 14346           ASCII value of last key pressed.
RESPTR  = $380B ; 14347           Address of keyword in the keyword table.
                ; 14348
CURCHR  = $380D ; 14349           holds character under the cursor.
LSTX    = $380E ; 14350           SCAN CODE of last key pressed
KCOUNT  = $380F ; 14351           number of SCANS key has been down for
FDIV    = $3810 ; 14352 - 14365   Division routine - self modifying code
        ; $381E ; 14366           RND function pertubation count
RNDCNT  = $381F ; 14367 - 14368   used by random number generator
RNDTAB  = $3821 ; 14369 - 14400   Unused 32 byte Random Number Table 
RNDX    = $3841 ; 14401 - 14405   Last random number generated, between 0 and 1
LPTPOS  = $3846 ; 14406           The current printer column (0-131).
PRTFLG  = $3847 ; 14407           Output goes to: 0=screen, 1=printer.
LINLEN  = $3848 ; 14408           line length (initially set to 40 ???)
CLMLST  = $3849 ; 14409           position of last comma column
RUBSW   = $384A ; 14410           rubout switch
TOPMEM  = $384B ; 14411 - 14412   High address of stack. followed by string storage space
CURLIN  = $384D ; 14413 - 14414   Current BASIC line number (-1 in direct mode)
TXTTAB  = $384F ; 14415 - 14416   Pointer to start of BASIC program
FILNAM  = $3851 ; 14417           tape filename (6 chars)
FILNAF  = $3857 ; 14423           tape read filename (6 chars)
INSYNC  = $385D ; 14429           tape flag
CLFLAG  = $385E ; 14430           tape flag (break key check)
BUFMIN  = $385F ; 14431           buffer used by INPUT statement
LINBUF  = $3860 ; 14432  BUF      line input buffer (73 bytes).
                ;  ...
TMPSTK  = $38A0 ;                 Temporary Stack - Set by INIT
ENDBUF  = $38A9 ; 14505           End of line unput buffer
DIMFLG  = $38AA ; 14506           dimension flag 1 = array
VALTYP  = $38AB ; 14507           Type Indicator 0=numeric 1=string
DORES   = $38AC ; 14508           flag for crunch
MEMSIZ  = $38AD ; 14509 - 14510   Address of top of physical RAM.
TEMPPT  = $38AF ; 14511 - 14512               
TEMPST  = $38B1 ; 14513 -               
DSCTMP  = $38BD ;       - 14528         
FRETOP  = $38C1 ; 14529 - 14530   Pointer to top of string space
TENP3   = $38C3 ; 14531 - 14532   temp space used by FOR etc.
TEMP8   = $38C5 ; 14533 - 14534
ENDFOR  = $38C7 ; 14535 - 14536
DATLIN  = $38c9 ; 14537 - 14538   Address of current DATA line
SUBFLG  = $38CB ; 14439           flag FOR:, GETVAR: 0=variable, 1=array
USFLG   = $38CC ; 14440           Direct Mode Flag    
FLGINP  = $38CD ; 14441           FLAGS WHETHER WE ARE DOING "INPUT" OR A READ
SAVTXT  = $38CE ; 14542 - 14543   temp holder of next statement address
TENP2   = $38D0 ; 14544 - 14545   Formula Evaluator temporary
OLDLIN  = $38D2 ; 14546 - 14547   Line number to CONTinue from.
OLDTXT  = $38D4 ; 14548 - 14549   Old Text Pointer - address of line to CONTinue from.
VARTAB  = $38D6 ; 14550 - 14551   Start of Variable Table (end of BASIC program)
ARYTAB  = $38D8 ; 14552 - 14553   Start of array table
STREND  = $38DA ; 14554 - 14555   end of array table
DATPTR  = $38DC ; 14556 - 14557   Address of line last DATPTRd
                 ; 
VARNAM  = $38DE ; 14558 - 14559   Variable Name
                 ;  ...
                 ;                 Floating Point Accumulator
FACLO    = $38E4 ; 14564  FPNUM    Low Order of Mantissa
FACMO    = $38E5 ; 14565           Middle Order of Mantissa
FACHO    = $38E6 ; 14566           High Order of Mantissa
FAC      = $38E7 ; 14567           Exponent 

FBUFFR   = $38E8 ; 14568           Floating Point String Buffer 

RESHO    = $38F6 ; 14582           Result of Multiplier and Divider
RESMO    = $38F7 ; 14583
RESLO    = $38F8 ; 14584

SAVSTK   = $38F9 ; 14585           used by keybord routine
                 ;  ...
PROGST   = $3900 ; 14592           NULL before start of BASIC program

; end of system variables = start of BASIC program in stock Aquarius
;          $3901 ; 14593

; buffer lengths
LINBUFLEN   = DIMFLG-LINBUF
STRBUFLEN   = FRETOP-TEMPPT
SYSTEMPLEN  = DATLIN-TENP3
SAVTXTLEN  = OLDLIN-SAVTXT
FBUFFRLEN   = RESHO-FBUFFR

;----------------------------------------------------------------------------
;                          system routines
;----------------------------------------------------------------------------
;
; RST $08,xx SYNCHK    syntax error if char at (HL) is not eqaul to xx
; RST $10    GETNXT    get char at (HL)+, Carry set if '0' to '9'
; RST $18    PRNTCHR   print char in A
; RST $20    CMPHLDE   compare HL to DE. Z if equal, C if DE is greater
; RST $28    TSTSIGN   test sign of floating point number
; RST $30,xx CALLUDF   hooks into various places in the ROM (identified by xx)
; RST $38    CALLUSR   maskable interrupt handler
; RST $66       -      NMI entry point. No code in ROM for this, do NOT use it!

PRNCHR      = $1d94  ; print character in A
PRNCHR1     = $1d72  ; print character in A with pause/break at end of page
PRNCRLF     = $19ea  ; print CR+LF
PRINTSTR    = $0e9d  ; print null-terminated string
PRINTINT    = $1675  ; print 16 bit integer in HL

SCROLLUP    = $1dfe  ; scroll the screen up 1 line
SVCURCOL    = $1e3e  ; save cursor position (HL = address, A = column)

LINEDONE    = $19e5  ; line entered (CR pressed)
FINDLIN     = $049f  ; find address of BASIC line (DE = line number)

FRMNUM      = $0972  ; Evaluate Numeric Formula
FRMEVL      = $0985  ; Evaluate Formula
EVAL        = $09FD  ; Evaluate Variable, Constant, or Function Call
PARCHK      = $0A37  ; Evaluate Formula in Parentheses
LABBCK      = $0A49  ; Functions that don't return string values come back here
GETBYT      = $0B54  ; Evaluate Numeric Formula between 0 and 255
GIVINT      = $0B21  ; Float Integer MSB=[A], LSB=[C] into Floating Point Accumulator
FLOATB      = $0B22  ; Float Integer MSB=[A], LSB=[B] into Floating Point Accumulator
FLOATD      = $0B23  ; Float Integer MSB=[A], LSB=[D] into Floating Point Accumulator
SNGFLT      = $0B36  ; Float Unsigned Byte in A

RETSTR      = $0e2f  ; return string in HL from function  
CRTST       = $0e5f  ; create string (HL = text ending with NULL)
QSTR        = $0e60  ; create string (HL = text starting with '"')
GETFLNM     = $1006  ; get tape filename string (out: DE = filename, A = 1st char)
GETVAR      = $10d1  ; get variable (out: BC = addr, DE = len)

GETLEN      = $0ff7  ; get string length (in: (FACLO) = string block)
                     ;                   (out: HL = string block, A = length)
FRESTR      = $0FC6  ; Free up temporary string
FREFAC      = $0fc9
CHKNUM      = $0975  ; Issue "TM" Error if result is not a number
TSTSTR      = $0976  ; error if evaluated expression not string
CHKTYP      = $0977  ; error if type mismatch

FRCINT      = $0682  ; Convert Floating Point Accumulator to Signed Integer in DE
FRCIN1      = $068A  ; Alternate entry point into FRCINT
STRTOVAL    = $069c  ; DE = value of decimal number string at HL-1 (65529 max)
STR2INT     = $069d  ; DE = value of decimal number string at HL
QINT        = $1586  ; Convert Floating Point Accumulator to Signed Integer in C,DE
INT2STR     = $1679  ; convert 16 bit ingeter in HL to text at FPSTR (starts with ' ')

KEYWAIT     = $1a33  ; wait for keypress (out: A = key)
UKEYCHK     = $1e7e  ; get current key pressed (through UDF)
KEYCHK      = $1e80  ; get current key pressed (direct)
CLRKEYWT    = $19da  ; flush keyboard buffer and wait for keypress

CHKSTK      = $0ba0  ; check for stack space (in: C = number of words required)


;-----------------------------------------------------------------------------
;                         RST  macros
;-----------------------------------------------------------------------------
SYNCHK  MACRO char
        RST    $08    ; syntax error if char at (HL) is not equal to next byte
        db    'char'
        ENDM

CHRGET  MACRO
        RST    $10    ; get next char and test for numeric
        ENDM

PRNTCHR MACRO
        RST   $18     ; print char in A
        ENDM

CMPHLDE MACRO
        RST   $20     ; compare HL to DE. Z if equal, C if HL < DE
        ENDM

;ASCII codes
CTRLC   = $03   ; ^C = break
CTRLG   = $07   ; ^G = bell
BKSPC   = $08   ; backspace
TAB     = $09   ; TAB
LF      = $0A   ; line feed
CR      = $0D   ; carriage return
CTRLS   = $13   ; ^S = wait for key
CTRLU   = $15   ; ^U = abandon line
CTRLX   = $18   ; ^X = undo line

;----------------------------------------------------------------------------
;                         BASIC Error Codes
;----------------------------------------------------------------------------
; code is offset to error name (2 characters)
;
;name       code            description
ERRNF  =    $00             ; NEXT without FOR
ERRSN  =    $02             ; Syntax error
ERRRG  =    $04             ; RETURN without GOSUB
ERROD  =    $06             ; Out of DATA
ERRFC  =    $08             ; Function Call error
ERROV  =    $0A             ; Overflow
ERROM  =    $0C             ; Out of memory
ERRUS  =    $0E             ; Undefined Line Number (Undefined Statement)
ERRBS  =    $10             ; Bad subscript
ERRDD  =    $12             ; Re-DIMensioned array
ERRDZ  =    $14             ; Division by zero (/0)
ERRID  =    $16             ; Illegal direct
ERRTM  =    $18             ; Type mismatch
ERROS  =    $1A             ; out of string space
ERRLS  =    $1C             ; String too long
ERRST  =    $1E             ; String formula too complex
ERRCN  =    $20             ; Cant CONTinue
ERRUF  =    $22             ; UnDEFined FN function
ERRMO  =    $24             ; Missing operand


;----------------------------------------------------------------------------
;     jump addresses for BASIC errors (returns to command prompt)
;----------------------------------------------------------------------------
SNERR    = $03C4  ; Syntax Error
FCERR    = $0697  ; Function Call Error
OVERR    = $03D3  ; Overflow
OMERR    = $0BB7  ; Out of Memory
USERR    = $06F3  ;   undefined line number
BSERR    = $11CD  ;   bad subscript
DDERR    = $03CD  ;   re-dimensioned array
DV0ERR   = $03C7  ;   divide by zero
IDERR    = $0B4F  ;   illegal direct
TMERR    = $03D9  ;   type mismatch
OSERR    = $0CEF  ;   out of string space
STERR    = $0E97  ;   string formula too complex
CNERR    = $0C51  ;   cant continue
UFERR    = $03D0  ;   undefined function
                     
; process error code, E = code (offset to 2 char error name)
ERROR    = $03db   ; The canonical name is ERROR - close enough!

; Standard BASIC Statement Tokens
POKETK      = $94   ; POKE Token
PEEKTK      = $C1   ; PEEK Token

;-------------------------------------------------
;          AquBASIC Binary File Header
;-------------------------------------------------
; Embeds load address into binary file.
;
; benign code can be executed without affecting
; any registers.
;
BINHEADER macro addr
    CP    A        ; $BF resets Carry flag
    JP    C,$-1    ; $DA nnnn (load address)
    endm
