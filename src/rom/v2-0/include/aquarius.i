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
TEMP3   = $38C3 ; 14531 - 14532   temp space used by FOR etc.
TEMP8   = $38C5 ; 14533 - 14534
ENDFOR  = $38C7 ; 14535 - 14536
DATLIN  = $38C9 ; 14537 - 14538   Address of current DATA line
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

SAVSTK   = $38F9 ; 14585           Stack Pointer saved by NEWSTT
                 ;  ...
PROGST   = $3900 ; 14592           NULL before start of BASIC program

; end of system variables = start of BASIC program in stock Aquarius
;          $3901 ; 14593

; buffer lengths
BUFLEN   = ENDBUF-BUF-1
STRBUFLEN   = FRETOP-TEMPPT
SYSTEMPLEN  = DATLIN-TEMP3
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
CHRGOT  = $11     ; Check Current Character, Skipping Spaces
OUTCHR  = $18     ; Output Character
COMPAR  = $20     ; Compare HL to DE
FSIGN   = $28     ; Get sign of Floating Point Accumulator

REDDY   = $036E   ; Text "Ok" CR,LF,NUL
READY   = $0402   ; Display "Ok" and Enter Immediate Mode
KLOOP   = $04C5   ; CRUNCH Main Loop Entry Point
CRUNCX  = $04F9   ; CRUNCH Alternate Entry Point
GONE4   = $063C   ; Execute Next Statement
GONE    = $064B   ; Execute Statement
GONE5   = $0665   ; Add Offset to Table and Dispatch Statement
CHRGTR  = $066B   ; Alternate CHRGET for conditional CALL
CHRGT2  = $066C   ; Alternate CHRGOT for CALL
NTOERR  = $0782   ; Execute ON ... GOTO
OMGOTO  = $0785   ; Execute GOTO part of ON ... GOTO

FINPRT  = $0866   ; Finish up PRINT
INPDIR  = $0898   ; INPUT Statement, bypassing Hook and Direct Mode Check

STROUT  = $0E9D   ; Print null or quote terminated string
STRPRT  = $0EA0   ; Print String with Descriptor in Floating Point Accumulator
LINPRT  = $1675   ; Print line number in HL
LINOUT  = $1679   ; convert 16 bit ingeter in HL to text at FPSTR (starts with ' ')
FOUT2   = $168C   ; Alternate entry into FOUT

CRDONZ  = $19DE   ; Print CR/LF if not at beginning of line
CRDO    = $19EA   ; Print CR+LF
FINLPT  = $19BE   ; Terminate Printer Output
TRYIN   = $1A2F   ; Wait for character from keyboard
TTYCHR  = $1D72   ; Print character in A with pause/break at end of page
TTYOUT  = $1D94   ; Print character in A to screen
TTYFIS  = $1DE7   ; Save cursor position, character under cursor, and display cursor
SCROLL  = $1DFE   ; scroll the screen up 1 line
TTYSAV  = $1E3E   ; save cursor position (HL = address, A = column)

LINEDONE    = $19e5  ; line entered (CR pressed)
ERROR   = $03DB   ; Generate Error with Error Code in E
ERRCRD  = $03E0   ; Print Error Message and Return to Immediate Mode
ERRCRH  = $03E6   ; ERRCRD rst $30
ERRPRT  = $03EA   ; Print Error pointed to by HL and Return to Immediate Mode
FNDLIN  = $049F   ; Find address of BASIC line (DE = line number)

GOTO    = $06DC   ; Execute GOTO statement
DATA    = $071C   ; Execute DATA statement
ERRDIR  = $0B45   ; Issue Error if in Direct Mode
BLTU    = $0B92   ; Block Transfer Routine
SCRTCH  = $0BBE   ; Execute NEW Command (without syntax check)
RUNC    = $0BCB   ; RUN Program
CLEARC  = $0BCF   ; Initialize Variables and Arrays, Reset Stack 
STOPC   = $0C20   ; Stop Program (Ctrl-C)
CLEARS  = $0CEB   ; Set VARTAB, TOPMEM, and MEMSIZ

FRMNUM  = $0972   ; Evaluate Numeric Formula
FRMEQL  = $0980   ; Evaluate Formula Preceded by Equal Sign
FRMPRN  = $0983   ; Evaluate Formula Preceded by Left Parenthesis
FRMEVL  = $0985   ; Evaluate Formula starting at Text Pointer
FRMCHK  = $0986   ; Evaluate Formula starting at Next Character
EVAL    = $09FD   ; Evaluate Variable, Constant, or Function Call
QDOT    = $0A14   ; EVAL - Check for Decimal Point
PARCHK  = $0A37   ; Evaluate Formula in Parentheses
LABBCK  = $0A49   ; Functions that don't return string values come back here
GETBYT  = $0B54   ; Evaluate Numeric Formula between 0 and 255
GIVINT  = $0B21   ; Float Integer MSB=[A], LSB=[C] into Floating Point Accumulator
FLOATB  = $0B22   ; Float Integer MSB=[A], LSB=[B] into Floating Point Accumulator
FLOATD  = $0B23   ; Float Integer MSB=[A], LSB=[D] into Floating Point Accumulator
SNGFLT  = $0B36   ; Float Unsigned Byte in A
GTBYTC  = $0B53   ; Skip Character and Evaluate Byte into A
CONINT  = $0B57   ; Convert Floating Point Accumulator to Byte in A
FLOATR  = $14FB   ; Float Signed Number in B,A,D,E
GETINT  = $1AD0   ; Parse an Integer

NORMAL  = $12B0   ; Normalize Floating Point Accumulator
ZERO    = $12C3   ; Zero FAC

MOVFM   = $1520   ; Move Number from (HL) to Floating Point Accumulator
MOVFR   = $1523   ; Move Number fron Registers to Floating Point Accumulator
MOVRF   = $152E   ; Move Number from Floating Point Accumulator to Registers
MOVRM   = $1531   ; Move Number from (HL) to Registers
MOVMF   = $153A   ; Move Number from Floating Point Accumulator to (HL)
MOVE    = $153D   ; Move Number from (DE) to (HL)
MOVE1   = $153F   ; Move B bytes fro (DE) to (HL)

EVAL    = $09FD   ; Evaluate Variable, Constant, Function Call
ISVAR   = $0A4E   ; Evaluate Variable 
RETVAR  = $0A51   ; Evaluate Variable with descriptor in DE
ISLET   = $0CC5   ; Return No Carry is (HL) is an uppercase letter
ISLETC  = $0CC6   ; Return No Carry is A is an uppercase letter
FIN     = $15E5   ; Evaluate Floating Point Number


TIMSTR  = $0E2F   ; Return string in HL from function  
STRINI  = $0E50   ; Create string with length in A
STRLIT  = $0E5F   ; Create string (HL = text ending with NULL)
STRADX  = $0E59   ; Entry into end of STRCPY
PUTNEW  = $0E7E   ; Return Temporary String
GETSPA  = $0EB3   ; Allocate Space for Temporary String
STRLTI  = $0E60   ; Create string (HL = text starting with '"')
GARBA2  = $0EDB   ; Force Garbage Collection
LEN1    = $0FF7   ; get string length (in: FACLO = string block; out: HL = string block, A = length)
ASC2    = $1006   ; Get pointer to string text (out: DE = filename, A = 1st char)
FINBCK  = $101D   ; Skip CHKNUM and Return to Higher Level
LEFT2   = $1027   ; Entry into LEFT$ from MID$
FRE     = $10A8   ; FRE Function

FRESTR  = $0FC6   ; Free up Temporary String
FREFAC  = $0FC9   ; Free up String in FACLO
FRETM2  = $0FCC   ; Free up String in HL

CHKNUM  = $0975   ; Issue "TM" Error if result is not a number
CHKSTR  = $0976   ; Issue "TM" Error if evaluated expression not string
CHKVAL  = $0977   ; Issue "TM" Error if type does not match carry flag
  
INTID2  = $067B   ; Get Integer between 0 and 32767 into DE
FRCINT  = $0682   ; Convert Floating Point Accumulator to Signed Integer in DE
FRCIN1  = $068A   ; Alternate entry point into FRCINT
SCNLIN  = $069C   ; Back up and scan line number into DE
LINGET  = $069D   ; DE = value of decimal number string at HL
QINT    = $1586   ; Convert Floating Point Accumulator to Signed Integer in C,DE

PTRGET  = $10D1   ; Get Pointer to Variable
PTRGT2  = $10D6   ; Get Pointer to Variable after reading first char

FSUBS   = $1258   ; Floating Point Subtract
FMULT   = $13CB   ; Floating Point Multiply
FDIV    = $142F   ; Floating Point Divide
NEG     = $150B   ; Negate Value in Floating Point Accumulator
PUSHF   = $1513   ; Put Floating Point Accumulator on Stack
FCOMP   = $155B   ; Floating Point Compare
UMULT   = $15CA   ; Integer Multiply: DE = BC * DE
PSHNEG  = $1770   ; Push address of NEG routine on Stack
POLYX   = $1837   ; Polynomial Evaluator
PI2     = $1953   ; Floating Point Constant Pi/2  

OUTDO   = $198A   ; Execute OUTCHR
INCHR   = $19DA   ; Flush keyboard buffer and wait for keypress
ISCNTC  = $1A25   ; Check for ^C and ^S
CONIN   = $1A33   ; Wait for keypress (out: A = key)
INCHRH  = $1E7E   ; Get current key pressed (through UDF)
INCHRC  = $1E80   ; Get current key pressed (direct)

GETSTK  = $0BA0   ; Check for stack space (in: C = number of words required)
POPHRT  = $141A   ; Pop HL and Return

PPRSDO  = $1A55   ; Execute PSET/PRESET: BC = X-coord, DE = Y-coord, A = 0 for PRESET, else PSET
SCALXY  = $1A8E   ; Convert PSET Coordinates to Screen Position and Character Mask
BITTAB  = $1ACA   ; Semigraphic Pixel Index to Bit Mask Table
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
COMMA   = $2C   ; comma

; PSG IO Ports
PSG1DATA    = $F6       ; AY-3-8910 data port 
PSG1REGI    = $F7       ; AY-3-8910 register port
PSG2DATA    = $F8       ; Second AY-3-8910 data port
PSG2REGI    = $F9       ; Second AY-3-8910 register port

; RTC Enabled/Valid Flags
CLK_FOUND   = $FF
CLK_SOFT    = $80
CLK_WRITE   = $7F
CLK_NONE    = $00

ERROR_NO_CH376    equ   1 ; CH376 not responding
ERROR_NO_USB      equ   2 ; not in USB mode
ERROR_MOUNT_FAIL  equ   3 ; drive mount failed
ERROR_BAD_NAME    equ   4 ; bad name
ERROR_NO_FILE     equ   5 ; no file
ERROR_FILE_EMPTY  equ   6 ; file empty
ERROR_BAD_FILE    equ   7 ; file header mismatch
ERROR_RMDIR_FAIL  equ   8 ; can't remove directory
ERROR_READ_FAIL   equ   9 ; read error
ERROR_WRITE_FAIL  equ  10 ; write error
ERROR_CREATE_FAIL equ  11 ; can't create file
ERROR_NO_DIR      equ  12 ; can't open directory
ERROR_PATH_LEN    equ  13 ; path too long
ERROR_FILE_EXISTS equ  14 ; file with name exists
ERROR_UNKNOWN     equ  15 ; other disk error

;----------------------------------------------------------------------------
;                         BASIC Error Codes
;----------------------------------------------------------------------------
; code is offset to error name (2 characters)
;
;name       code            description
ERRNF  =    $00             ; NF NEXT without FOR
ERRSN  =    $02             ; SN Syntax error
ERRRG  =    $04             ; RG RETURN without GOSUB
ERROD  =    $06             ; OD Out of DATA
ERRFC  =    $08             ; FC Function Call error
ERROV  =    $0A             ; OV Overflow
ERROM  =    $0C             ; OM Out of Memory
ERRUS  =    $0E             ; UL Undefined Line number (Undefined Statement)
ERRBS  =    $10             ; BS Bad Subscript
ERRDD  =    $12             ; DD Re-DIMensioned array (Duplicate Definition)
ERRDZ  =    $14             ; /0 Division by Zero 
ERRID  =    $16             ; ID Illegal direct
ERRTM  =    $18             ; TM Type mismatch
ERROS  =    $1A             ; OS Out of String space
ERRLS  =    $1C             ; LS String too Long
ERRST  =    $1E             ; WT String formula too complex
ERRCN  =    $20             ; CN Cant CONTinue
ERRUF  =    $22             ; UF UnDEFined FN function
ERRMO  =    $24             ; MO Missing operand
ERRRE  =    $26             ; IO Disk I/O Error
ERRIO  =    $28             ; IO Disk I/O Error
ERRUE  =    $2A             ; UE Unprintable Error
LSTERR =    $2C             ; End of Error List

;----------------------------------------------------------------------------
;      jump addresses for BASIC errors (loads E and jumps to ERROR)
;----------------------------------------------------------------------------
SNERR    = $03C4  ; Syntax Error
FCERR    = $0697  ; Function Call Error
OVERR    = $03D3  ; Overflow
MOERR    = $03D6  ; Missing Operand 
OMERR    = $0BB7  ; Out of Memory
USERR    = $06F3  ; Undefined Line Number
BSERR    = $11CD  ;   bad subscript
DDERR    = $03CD  ;   re-dimensioned array
DV0ERR   = $03C7  ;   divide by zero
IDERR    = $0B4E  ;   illegal direct
TMERR    = $03D9  ;   type mismatch
OSERR    = $0CEF  ;   out of string space
STERR    = $0E97  ;   string formula too complex
CNERR    = $0C51  ;   cant continue
UFERR    = $03D0  ;   undefined function
                     
; Standard BASIC Tokens
ENDTK       = $80   ; END Token
DIMTK       = $85   ; DIM Token
GOTOTK      = $88   ; GOTO Token
ONTK        = $90   ; ON Token
COPYTK      = $92   ; COPY Token
POKETK      = $94   ; POKE Token
PSETTK      = $9C   ; PSET Token
PRESTK      = $9D   ; PRESET Token
SOUNDTK     = $9E   ; SOUND Token
TOTK        = $A1   ; TO Token
FNTK        = $A2   ; FN Token
NOTTK       = $A6   ; NOT Token
STEPTK      = $A7   ; STEP Token
PLUSTK      = $A8   ; + Token
MINUTK      = $A9   ; - Token
MULTK       = $AA   ; * Token
ANDTK       = $AD   ; AND Token
ORTK        = $AE   ; OR Token
EQUATK      = $B0   ; = Token
ONEFUN      = $B2   ; First Function Token
FRETK       = $B6   ; FRE Token
PEEKTK      = $C1   ; PEEK Token
LENTK       = $C2   ; LEN Token
STRTK       = $C3   ; STR$ Token
ASCTK       = $C5   ; ASC Token

;Adddress of Byte following Hook RST
HOOK0       = $03DF
HOOK1       = $03E7
HOOK2       = $0403
HOOK3       = $0430
HOOK4       = $0481
HOOK5       = $0486
HOOK6       = $07BD
HOOK7       = $0867
HOOK8       = $0881
HOOK9       = $09FE
HOOK10      = $0537
HOOK11      = $0CCE
HOOK12      = $0BBF
HOOK13      = $198B
HOOK14      = $1986
HOOK15      = $0B3C
HOOK16      = $0B41
HOOK17      = $1AE9
HOOK18      = $1E7F
HOOK19      = $1D73
HOOK20      = $1C2D
HOOK21      = $1C09
HOOK22      = $05A1
HOOK23      = $0659
HOOK24      = $06BF
HOOK25      = $0781
HOOK26      = $0894
HOOK27      = $0A60
HOOK28      = $08F1


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
