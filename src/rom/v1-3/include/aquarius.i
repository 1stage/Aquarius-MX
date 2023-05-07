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
FDIVC   = $3810 ; 14352 - 14365   Division routine - self modifying code
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
BUF     = $3860 ; 14432 - 14504   Line Input Buffer (72 bytes).
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
SUBFLG  = $38CB ; 14439           flag FOR:, PTRGET: 0=variable, 1=array
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
VARPNT  = $38E0 ; 14560 - 14561   Pointer to Variable
FNPARM  = $38E2 ; 14562 - 14563   Defined Function Parameter
                ;                 Floating Point Accumulator
FACLO   = $38E4 ; 14564           Low Order of Mantissa
FACMO   = $38E5 ; 14565           Middle Order of Mantissa
FACHO   = $38E6 ; 14566           High Order of Mantissa
FAC     = $38E7 ; 14567           Exponent 

FBUFFR  = $38E8 ; 14568           Floating Point String Buffer 

RESHO   = $38F6 ; 14582           Result of Multiplier and Divider
RESMO   = $38F7 ; 14583
RESLO   = $38F8 ; 14584

SAVSTK   = $38F9 ; 14585           used by keybord routine
                 ;  ...
PROGST   = $3900 ; 14592           NULL before start of BASIC program

; end of system variables = start of BASIC program in stock Aquarius
;          $3901 ; 14593

; buffer lengths
BUFLEN   = ENDBUF-BUF-1
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
  
SYNCHR  = $08     ; Syntax Check
CHRGET  = $10     ; Scan for Next Character
COMPAR  = $20     ; Compare HL to DE
FSIGN   = $28     ; Get sign of Floating Point Accumulator

REDDY   = $036E   ; Text "Ok" CR,LF,NUL
READY   = $0402   ; Display "Ok" and Enter Immediate Mode

STROUT  = $0E9D   ; Print null or quote terminated string
LINPRT  = $1675   ; Print line number in HL
CRDONZ  = $19DE   ; Print CR/LF if not at beginning of line
CRDO    = $19EA   ; Print CR+LF
FINLPT  = $19BE   ; Terminate Printer Output
TTYCHR  = $1D72   ; Print character in A with pause/break at end of page
TTYOUT  = $1D94   ; Print character in A to screen
TTYFIS  = $1DE7   ; Save cursor position, character under cursor, and display cursor
SCROLL  = $1DFE   ; scroll the screen up 1 line
TTYSAV  = $1E3E   ; save cursor position (HL = address, A = column)

LINEDONE    = $19e5  ; line entered (CR pressed)
FNDLIN  = $049f  ; Find address of BASIC line (DE = line number)

DATA    = $071C   ; Execute DATA statement
ERRDIR  = $0B45   ; Issue Error if in Direct Mode
SCRTCH  = $0BBE   ; Execute NEW Command (without syntax check)

FRMNUM  = $0972   ; Evaluate Numeric Formula
FRMEVL  = $0985   ; Evaluate Formula
EVAL    = $09FD   ; Evaluate Variable, Constant, or Function Call
PARCHK  = $0A37   ; Evaluate Formula in Parentheses
LABBCK  = $0A49   ; Functions that don't return string values come back here
GETBYT  = $0B54   ; Evaluate Numeric Formula between 0 and 255
GIVINT  = $0B21   ; Float Integer MSB=[A], LSB=[C] into Floating Point Accumulator
FLOATB  = $0B22   ; Float Integer MSB=[A], LSB=[B] into Floating Point Accumulator
FLOATD  = $0B23   ; Float Integer MSB=[A], LSB=[D] into Floating Point Accumulator
SNGFLT  = $0B36   ; Float Unsigned Byte in A
CONINT  = $0B57   ; Convert Floating Point Accumulator to Byte in A
FLOATR  = $14FB   ; Float Signed Number in B,A,D,E
GETINT  = $1AD0   ; Parse an Integer

NORMAL  = $12B0   ; Normalize Floating Point Accumulator
ZERO    = $12C3   ; Zero FAC

MOVFR   = $1523   ; Move Number fron Registers to  Floating Point Accumulator
MOVMF   = $153A   ; Move Number from Floating Point Accumulator to (HL)
MOVE    = $153D   ; Move Number from (DE) TO (HL)

TIMSTR  = $0E2F   ; Return string in HL from function  
STRLIT  = $0E5F   ; Create string (HL = text ending with NULL)
STRADX  = $0E59   ; Entry into end of STRCPY
GETSPA  = $0EB3   ; Allocate Space for Temporary String
STRLTI  = $0E60   ; Create string (HL = text starting with '"')
LEN1    = $0FF7   ; get string length (in: FACLO = string block; out: HL = string block, A = length)
ASC2    = $1006   ; Get pointer to string text (out: DE = filename, A = 1st char)

FRESTR  = $0FC6   ; Free up temporary string
FREFAC  = $0FC9
CHKNUM  = $0975   ; Issue "TM" Error if result is not a number
CHKSTR  = $0976   ; Issue "TM" Error if evaluated expression not string
CHKVAL  = $0977   ; Issue "TM" Error if type does not match carry flag
  
FRCINT  = $0682   ; Convert Floating Point Accumulator to Signed Integer in DE
FRCIN1  = $068A   ; Alternate entry point into FRCINT
SCNLIN  = $069C   ; Back up and scan line number into DE
LINGET  = $069D   ; DE = value of decimal number string at HL
QINT    = $1586   ; Convert Floating Point Accumulator to Signed Integer in C,DE
LINOUT  = $1679   ; convert 16 bit ingeter in HL to text at FPSTR (starts with ' ')

PTRGET  = $10D1   ; Get Pointer to Variable
PTRGT2  = $10D6   ; Get Pointer to Variable after reading first char

FSUBS   = $1258   ; Floating Point Subtract
FDIV    = $142F   ; Floating Point Divide
NEG     = $150B   ; Negate Value in Floating Point Accumulator
PSHNEG  = $1770   ; Push address of NEG routine on Stack
POLYX   = $1837   ; Polynomial Evaluator
PI2     = $1953   ; Floating Point Constant Pi/2  

CONIN   = $1A33   ; Wait for keypress (out: A = key)
INCHR   = $19DA   ; Flush keyboard buffer and wait for keypress
INCHRH  = $1E7E   ; Get current key pressed (through UDF)
INCHRC  = $1E80   ; Get current key pressed (direct)

GETSTK  = $0BA0   ; Check for stack space (in: C = number of words required)

COPY    = $1B15   ; COPY statement

;-----------------------------------------------------------------------------
;                         RST  macros
;-----------------------------------------------------------------------------
SYNCHK  MACRO char
        RST    $08    ; syntax error if char at (HL) is not equal to next byte
        db    'char'
        ENDM

;CHRGET  MACRO
;        RST    $10    ; get next char and test for numeric
;        ENDM

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
IDERR    = $0B4E  ;   illegal direct
TMERR    = $03D9  ;   type mismatch
OSERR    = $0CEF  ;   out of string space
STERR    = $0E97  ;   string formula too complex
CNERR    = $0C51  ;   cant continue
UFERR    = $03D0  ;   undefined function
                     
; process error code, E = code (offset to 2 char error name)
ERROR    = $03db  ; The canonical name is ERROR - close enough!

; Standard BASIC Statement Tokens
COPYTK      = $92   ; COPY Token
POKETK      = $94   ; POKE Token
TOTK        = $A1   ; TO Token
FNTK        = $A2   ; FN Token
STEPTK      = $A7   ; STEP Token
EQUATK      = $B0   ; = Token
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
