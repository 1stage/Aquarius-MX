;===============================================================================
;  Aquarius MX BASIC: Extended BASIC ROM for Mattel Aquarius with MX Expander
;===============================================================================
; Original code by:
;        Bruce Abbott                         www.bhabbott.net.nz (domain down?)
;                                 bruce.abbott@xtra.co.nz (email non-responsive)
;        Martin van der Steenoven                            www.vdsteenoven.com
;
; Additional code by:
;        Curtis Kaylor                                      revcurtisp@gmail.com
;        Mack Wharton                              Mack@Aquarius.je, aquarius.je
;        Sean P. Harrington                  sph@1stage.com, aquarius.1stage.com
;
;
; Lines beginning with three semicolons ;;; are inline docs and are collected 
; into file README.md by script makedoc.py
;
; Lines beginning with two semicolons ;;; are developer notes and are collected 
; into file DEVNOTES.md by script makedev.py
;
; Includes commands from BLBasic by Martin Steenoven, as well as commands from
; Aquarius Extended BASIC (MS 8K BASIC), and other Microsoft BASIC dialects.
;
; Changes:
; 2015-11-4  v0.0  created
; 2015-11-5        EDIT command provides enhanced editing of BASIC lines.
; 2015-11-6  v0.01 PRINT token expands to '?' on edit line (allows editing longer lines).
; 2015-11-9  v0.02 Added Turboload cassette routines
;                  Faster power-on memtest
; 2015-11-13 v0.03 Turbo tape commands TSAVE and TLOAD
;                  Enhanced edit functions on command line (immediate mode)
;                  Fixed scroll issue caused by conflicting ROWCOUNT definitions
; 2015-12-22 v0.04 fixed ctrl-c not removing colored cursor
; 2015-01-17 v0.05 CAT catalog files (minimalist directory listing)
; 2016-01-18 v0.06 RUN command can take name of file (BASIC or BINARY) to load and run
; 2016-01-30 v0.07 added PROGST to allow for extra system variables.
; 2016-02-21 v0.08 CALL passes txt pointer (in HL) to user code.
; 2016-04-11 v0.09 disk function vectors at $C000
; 2016-10-10 v0.10 changed cold boot menu to suit uexp (no ROM menu)
; 2017-01-22 v0.11 DOS commands take fully evaluated arguments eg. LOAD LEFT$(A$,11)
;                  DIR with wildcards
;                  CAT prints 3 filenames per line
; 2017-02-20 v0.12 DEBUG
; 2017-03-03 v0.13 change displayed name to Aquarius USB BASIC
; 2017-03-06 v0.14 Incorporate ROM initialization, boot menu, ROM loader.
; 2017-03-09 v0.15 add PT3 player, tidy vector and function names
; 2017-03-12 v0.16 HEX$() function: convert number to Hexadecimal string
; 2017-04-14 v0.17 HL = 0 on entry to debugger from splash screen
; 2017-04-18 v0.18 CRTL-R = retype line
; 2017-04-25 v0.19 Reserve high RAM for retype buffer, debugger, DOS
; 2017-04-29 v0.20 FileName, FileType, DOSflags moved from BASIC variables to private RAM
; 2017-05-04 v0.21 sys_KeyChk: replacement keyboard scan routine
; 2017-05-06 v0.22 clear history buffer before entering BASIC
;                  bugfix: ST_EDIT buffer length equate 1 less than actual buffer size
; 2017-05-08 v0.23 refactored code to get more space in ROM!
; 2017-05-16 v0.24 CLS clears 1000 chars/colors, doesn't touch last 24 bytes.
; 2017-05-22 v0.25 updated vectors
;                  moved wait_key from aqubug.asm to here
; 2017-05-30 v0.26 increased path.size from 36 to 37 (space for at least 4 subdirecties)
; 2017-06-11 v0.27 return to root dir after debug, pt3play etc. in boot menu
; 2017-06-12 v1.0  bumped to release version
; 2022-08-27 v1.1  Changed KILL command to DEL
; 2022-09-21 v1.2  Fixed array saving by removing the 4 spurious bytes (Mack)
;                  Correct comments regarding loading of .BIN files to $C9,$C3 (was $BF,$DA)
;                  Added SCR logic for binary load to Screen RAM without ADDR parameter (Harrington)
; 2023-05-16 v1.3  Unreleased v1.3 merged into v2.0, below
; 2023-05-xx v2.0  Removed unimplemented PCG code
;                  Removed PT3 Player from Menu screen. Has to be loaded as a ROM from now on.
;                  Added hexadecimal constants in formulas, anywhere formula can be used
;                  Added VER command for USB BASIC version, returned as an integer (VERSION * 256) + REVISION
;                  Revise CLS to accept an optional parameter for (FG * 16 ) + BG color integer OR 2-byte word
;                  Added support for DS1244 Real Time Clock including 
;                  Added SDTM statement to set, DTM$() function to read RealTime Clock
;                  Revised PEEK/POKE commands: added TO / STEP keywords, hex numbers, signed/unsigned ints, strings
;                  Added DEEK/DOKE (Double pEEK/pOKE): read/write 16-bit word from/to memory
;                  Updated COPY command to copy block of bytes from one memory location to another
;                  Updated IN/OUT commands to allow ports 0-65535
;                  Added KEY() function to wait for/check for key press
;                  RUN "filename" only loads and runs BASIC program in CAQ format.

VERSION  = 2
REVISION = 0

; code options
;softrom  equ 1    ; loaded from disk into upper 16k of 32k RAM
scrn_flag equ 1    ; enable screen save in lite debugger
;debug    equ 1    ; debugging our code. Undefine for release version!
;
; See README.md for full list of Commands and Functions
;
; Assembled with ZMAC in 'zmac' mode.
; command: zmac.exe --zmac -e --oo cim --nmnv -L -n -I include aqubasic.asm
;
; symbol scope:-
; .label   local to current function
; _label   local to current source file
; label    global to entire ROM and system (aquarius.i)
; function naming:-
; MODULE_FUNCTION    vector for use by external progams
; module__function   internal name for code in this ROM

    include  "aquarius.i" ; aquarius hardware and system ROM
    include  "macros.i"   ; structure macros
    include  "windows.i"  ; fast windowed text functions

;; ---
;; ## Register Usage
;; ### IX 
;; - Used in module windows.asm to point to the window structure.
;;   - Should not conflict with usage in MX BASIC, as the module is never used from within BASIC itself
;; - Used in MX BASIC by the UDF Hook call and dispatch routines and the statement and function dispatch routines. 
;; - Can be used as a temporary variable in any routine 
;;   - Assume that it will be changes by CALLs to most BASIC system routines
;; ### IY 
;; - Used in the debuggers.
;;   - Should not conflist with usage in MX BASIC, as the debuggers save all the registers when handling a Break
;; - Used in dos.asm to point to the system variable DosFlags
;;   - Can be used as variable that persists through any BASIC statement handling routine.
;; - Do *not* use as a temporary variable in any subroutines that may be called by a statement handler.
;
;; ---
;; ## Real Time Clock
;; ### System Variables
;; - The 24 bytes of RAM between Screen RAM and Color RAM and the 24 bytes between the end of Color RAM and System Variables are used as temporary variables by the RTC and DateTime Routines. These areas are overwritten when the screen is cleared via PRINT CHR$(11)

DTM_STRING = $33E8        ; DTM String Buffer, 24 bytes (19 currently used)
DTM_BUFFER = $37E8        ; RTC & DTM DateTime Buffer, 8 bytes
RTC_SHADOW = $37F0        ; Real Time Clock Shadow Registers, 10 bytes. 
;    $37FA - $37FF        ; Reserved

;;                       
;; ### Implementing Real Time Clock in Emulators
;; - The will be a read from memory location $37F0 whenever the RTC is accessed
;; - If $37F0 contains $7F, the RTC is being written to and the following bytea contain the date to be written.
;; - If $37F0 contains any other value, the RTC was just read and $37F0 should be filled with $FF and the following bytes with the current date/time.
;; - See the RTC driver file for the date/time structure.

  ifdef softrom
RAMEND = $8000           ; we are in RAM, 16k expansion RAM available
  else
RAMEND = $C000           ; we are in ROM, 32k expansion RAM available
  endif

path.size = 37           ; length of file path buffer

LineBufLen = 128
KeyBufLen = 16

; high RAM usage
 STRUCTURE _sysvars,0
    STRUCT _keybuf,KeyBufLen    ; KEY Statement Buffer
    STRUCT _pathname,path.size  ; file path eg. "/root/subdir1/subdir2",0
    STRUCT _filename,13         ; USB file name 1-11 chars + '.', NULL
    BYTE   _doserror            ; file type BASIC/array/binary/etc.
    BYTE   _chstatus            ; status after last CH368 command
    WORD   _binstart            ; binary file load/save address
    WORD   _binlen              ; binary file length
    WORD   _binofs              ; offset into binary file on disk
    WORD   _binend              ; actual end address of load
    BYTE   _dosflags            ; DOS flags
    WORD   _lnbufptr            ; Address of Line Buffer
    BYTE   _lnbuflen            ; Length of Line Buffer
    BYTE   _keyflags            ; Keyboard Behavior Flags
    BYTE   _sysflags            ; system flags
    VECTOR _break               ; Debugger Break
    VECTOR _godebug             ; Start Debugger
    STRUCT _linebuf,LineBufLen  ; Line Input/Edit Buffer
    STRUCT _retypbuf,LineBufLen ; BASIC command line history
 ENDSTRUCT _sysvars

SysVars  = RAMEND-_sysvars.size
KeyBuf   = sysvars+_keybuf
PathName = sysvars+_pathname
FileName = sysvars+_filename
DosError = sysvars+_doserror
ChStatus = sysvars+_chstatus
BinStart = sysvars+_binstart
BinLen   = sysvars+_binlen
BinOfs   = sysvars+_binofs
BinEnd   = sysvars+_binend
DosFlags = sysvars+_dosflags
LnBufPtr = sysvars+_lnbufptr
LnBufLen = sysvars+_lnbuflen
KeyFlags = sysvars+_keyflags
SysFlags = sysvars+_sysflags
Break    = sysvars+_break
GoDebug  = sysvars+_godebug
LineBuf  = sysvars+_linebuf         ;Keep LineBuf, ReTypBuf at the top so they dont cross a 256 byte boundary
ReTypBuf = sysvars+_retypbuf

 STRUCTURE _extvars,0
    WORD   _forclr              ; Foreground Color
    BYTE   _atrbyt              ; Current Graphics Attributes
    WORD   _gxpos               ; X Position of Second Coordinate
    WORD   _gypos               ; Y Position of Second Coordinate
    WORD   _grpacy              ; Previous Y Coordinate
    WORD   _grpacx              ; Previous X Coordinate
    VECTOR _maxupd              ; Jump Instruction
    VECTOR _minupd              ; Jump Instruction
    WORD   _maxdel              ; Largest Delta for Line
    WORD   _mindel              ; Smaller of 2 Deltas for Line
    WORD   _aspect              ; ASPECT RATIO
    WORD   _cencnt              ; END CIRCLE POINT COUNT
    BYTE   _glinef              ; LINE-TO-CENTER FLAG
    WORD   _cnpnts              ; 1/8 NO. OF PTS IN CIRCLE
    BYTE   _cplotf              ; PLOT FLAG
    WORD   _cpcnt               ; ;1/8 NO. OF PTS IN CIRCLE
    WORD   _cpcnt8              ; NO. OF PTS IN CIRCLE
    WORD   _crcsum              ; CIRCLE SUM
    WORD   _cstcnt              ; START COUNT
    BYTE   _csclxy              ; FLAG WHETHER ASPECT WAS .GT. 1
    WORD   _curloc              ; Current Point Address
    BYTE   _pindex              ; Point Bit Mask Index
    WORD   _cxoff               ; X OFFSET FROM CENTER SAVE LOC
    WORD   _cyoff               ; Y OFFSET SAVE LOCATION
    WORD   _extgap              ; possibly unused 
    WORD   _bufret              ; BUFLIN Return Address
    WORD   _bufptr              ; Pointer into BUF while Unpacking Line
    BYTE   _drwscl              ; DRAW: SCALE - DRAW POS,Scaling factor
    BYTE   _drwflg              ; OPTION FLAGS - DRAW flag
    BYTE   _drwang              ; DRAW "ANGLE" (0..3) - DRAW translation angle
    WORD   _mclptr              ; MAC LANG PTR
    BYTE   _mcllen              ; STRING LENGTH
    WORD   _mcltab              ; ;PTR TO COMMAND TABLE
    BYTE   _putflg              ; WHETHER DOING PUT() OR GET()
    WORD   _arypnt              ; Pointer into GET/PUT Array
    BYTE   _opcjmp              ; Jump Instruction
    WORD   _opcadr              ; Draw Operator Routine Address
    BYTE   _gymax               ; Maximum X Position: 39
    BYTE   _gxmax               ; Maximum Y Position: 23
    STRUCT _unused,5            ; possibly unused
    WORD   _errlin              ; LINE NUMBER WHERE LAST ERROR OCCURED.
    BYTE   _errflg              ; USED TO SAVE THE ERROR NUMBER SO EDIT CAN BE
    BYTE   _oneflg              ; ONEFLG=1 IF WERE ARE EXECUTING AN ERROR TRAP ROUTINE, OTHERWISE 0
    WORD   _onelin              ; THE pointer to the LINE TO GOTO WHEN AN ERROR OCCURS
    LONG   _swptmp              ; Holds value of the first SWAP variable
 ENDSTRUCT _extvars

;ExtVars = SysVars-_extvars.size
ExtVars = $BE00
FORCLR   = extvars+_forclr
ATRBYT   = extvars+_atrbyt
GXPOS    = extvars+_gxpos 
GYPOS    = extvars+_gypos 
GRPACY   = extvars+_grpacy
GRPACX   = extvars+_grpacx
MAXUPD   = extvars+_maxupd
MINUPD   = extvars+_minupd
MAXDEL   = extvars+_maxdel
MINDEL   = extvars+_mindel
ASPECT   = extvars+_aspect
CENCNT   = extvars+_cencnt
GLINEF   = extvars+_glinef
CNPNTS   = extvars+_cnpnts  
CPLOTF   = extvars+_cplotf
CPCNT    = extvars+_cpcnt 
CPCNT8   = extvars+_cpcnt8
CRCSUM   = extvars+_crcsum
CSTCNT   = extvars+_cstcnt
CSCLXY   = extvars+_csclxy
CURLOC   = extvars+_curloc
PINDEX   = extvars+_pindex
CXOFF    = extvars+_cxoff 
CYOFF    = extvars+_cyoff 
BUFRET   = extvars+_bufret
BUFPTR   = extvars+_bufptr
DRWSCL   = extvars+_drwscl
DRWFLG   = extvars+_drwflg
DRWANG   = extvars+_drwang
MCLPTR   = extvars+_mclptr
MCLLEN   = extvars+_mcllen
MCLTAB   = extvars+_mcltab
PUTFLG   = extvars+_putflg
ARYPNT   = extvars+_arypnt
OPCJMP   = extvars+_opcjmp
OPCADR   = extvars+_opcadr
GYMAX    = extvars+_gymax 
GXMAX    = extvars+_gxmax 
ERRLIN   = extvars+_errlin          ;These must be in in consecutive order: ERRLIN,ERRFLG,ONEFLG,ONELIN
ERRFLG   = extvars+_errflg
ONEFLG   = extvars+_oneflg
ONELIN   = extvars+_onelin
SWPTMP   = extvars+_swptmp

vars = ExtVars ; for now

ifdef debug
  pathname = $3006  ; store path in top line of screen
endif

;system flags
SF_NTSC  = 1       ; 1 = NTSC, 0 = PAL
SF_RETYP = 1       ; 1 = CTRL-O is retype
SF_DEBUG = 7       ; 1 = Debugger available

;keyboard flags
KF_CLICK  = 0     ; Key Click Enabled

;=======================================
;             ROM Code
;=======================================
;
; 16k ROM start address
     ORG $C000

;----------------------------------------------
;            External Vectors
;----------------------------------------------
;
; User programs should call ROM functions
; via these vectors only!
;
; system vectors

SYS_BREAK         jp  Break
SYS_DEBUG         jp  ST_DEBUG
SYS_KEY_CHECK     jp  Key_Check
SYS_WAIT_KEY      jp  Wait_key
SYS_EDITLINE      jp  EditLine
SYS_SET_STACK     jp  Set_Stack
SYS_reserved2     jp  break
SYS_reserved3     jp  break

; USB driver vectors
USB_OPEN_READ     jp  usb__open_read
USB_READ_BYTE     jp  usb__read_byte
USB_READ_BYTES    jp  usb__read_bytes
USB_OPEN_WRITE    jp  usb__open_write
USB_WRITE_BYTE    jp  usb__write_byte
USB_WRITE_BYTES   jp  usb__write_bytes
USB_CLOSE_FILE    jp  usb__close_file
USB_DELETE_FILE   jp  usb__delete
USB_FILE_EXIST    jp  usb__file_exist
USB_SEEK_FILE     jp  usb__seek
USB_WILDCARD      jp  usb__wildcard
USB_DIR           jp  usb__dir
USB_SORT          jp  usb__sort
USB_SET_FILENAME  jp  usb__set_filename
USB_MOUNT         jp  usb__mount
USB_SET_USB_MODE  jp  usb__set_usb_mode
USB_CHECK_EXISTS  jp  usb__check_exists
USB_READY         jp  usb__ready
USB_Wait_Int      jp  usb__wait_int
USB_GET_PATH      jp  usb__get_path
USB_ROOT          jp  usb__root
USB_OPEN_PATH     jp  usb__open_path
USB_OPEN_DIR      jp  usb__open_dir
USB_reserved1     jp  Break
USB_reserved2     jp  Break

; DOS vectors
DOS_GETFILENAME   jp  dos__getfilename
DOS_DIRECTORY     jp  dos__directory
DOS_PRTDIRINFO    jp  dos__prtDirInfo
DOS_CLEARERROR    jp  dos__clearError
DOS_NAME          jp  dos__name
DOS_CHAR          jp  dos__char
DOS_SET_PATH      jp  dos__set_path
DOS_reserved1     jp  break
DOS_reserved2     jp  break

; file requester
FRQ_FILEREQ       jp  RequestFile
FRQ_LISTFILES     jp  ListFiles
FRQ_SHOWLIST      jp  ShowList
FRQ_SELECT        jp  SelectFile
FRQ_reserved      jp  break

; windows
WIN_OPENWINDOW    jp  OpenWindow
WIN_SETCURSOR     jp  WinSetCursor
WIN_CLEARWINDOW   jp  ClearWindow
WIN_SHOWTITLE     jp  ShowTitle
WIN_DRAWBORDER    jp  DrawBorder
WIN_COLORWINDOW   jp  ColorWindow
WIN_PRTCHR        jp  WinPrtChr
WIN_PRTCHARS      jp  WinPrtChrs
WIN_PRTSTR        jp  WinPrtStr
WIN_PRTMSG        jp  WinPrtMsg
WIN_CURSORADDR    jp  CursorAddr
WIN_TEXTADDR      jp  WinTextAddr
WIN_SCROLLWINDOW  jp  ScrollWindow
WIN_NEWLINE       jp  NewLine
WIN_CLEARTOEND    jp  ClearToEnd
WIN_BACKSPACE     jp  BackSpace
WIN_WAITKEY       jp  Wait_Key
WIN_CAT_DISK      jp  WinCatDisk
WIN_removed       jp  break
WIN_reserved1     jp  break
WIN_reserved2     jp  break

; real time clock
RTC_INIT_RTC      jp  rtc_init
RTC_READ_RTC      jp  rtc_read
RTC_WRITE_RTC     jp  rtc_write
RTC_DTM_TO_STR    jp  dtm_to_str
RTC_DTM_TO_FMT    jp  dtm_to_fmt
RTC_STR_TO_DTM    jp  str_to_dtm
RTC_DTM_TO_FTS    jp  dtm_to_fts
RTC_FTS_TO_DTM    jp  fts_to_dtm

; room for 9 more JP's before crossing $C100

;---------------------------------------------------------------------
;                        UDF Hook Routine
;      starts with Hook Table, aligned to page boundary ($C100)
;---------------------------------------------------------------------
    include "udfhook.asm"

;---------------------------------------------------------------------
;                       string functions
;   no more than 180 bytes, to fit between UDF Hook and Dispatch
;---------------------------------------------------------------------
    include "strings.asm"

;---------------------------------------------------------------------
;              Dispatch and Keyword Tables and Routines
;      starts with Jump Tables, aligned to page boundary ($C200)
;---------------------------------------------------------------------
    include "dispatch.asm" 

;---------------------------------------------------------------------
;                     splash screen / boot menu
;---------------------------------------------------------------------
    include "splash.asm"

;---------------------------------------------------------------------
;                     windowed text functions
;---------------------------------------------------------------------
    include "windows.asm"

;---------------------------------------------------------------------
;                         ROM loader
;---------------------------------------------------------------------
    include "load_rom.asm"

;---------------------------------------------------------------------
;                     disk file selector
;---------------------------------------------------------------------
    include "filerequest.asm"

;---------------------------------------------------------------------
;                      USB Disk Driver
;---------------------------------------------------------------------
    include "ch376.asm"
   
;---------------------------------------------------------------------
;                RTC Driver for Dallas DS1244
;---------------------------------------------------------------------
    include "dtm_lib.asm"
    include "ds1244rtc.asm" 

;---------------------------------------------------------------------
;                       keyboard scan
;---------------------------------------------------------------------
    include "keycheck.asm"

;-----------------------------------------------
;          Wait for Key Press
;-----------------------------------------------
; Wait for next key to be pressed.
;
;   out A = char

Wait_key:
    CALL    key_check    ; check for key pressed
    JR      Z,Wait_Key   ; loop until key pressed
.key_click:
    push    af
    ld      a,$FF        ; speaker ON
    out     ($fc),a
    ld      a,128
.click_wait:
    dec     a
    jr      nz,.click_wait
    out     ($fc),a      ; speaker OFF
    pop     af
    RET

;-----------------------------------------------
;       Set Stack to Address in SAVSTK
;-----------------------------------------------

Set_Stack:
    pop     IX                    ; Get Return Address
    ld      sp,(SAVSTK)           ; Set Stack Pointer
    jp      (IX)                  ; Fast Return

;---------------------------------------------------------------------
;                       DOS commands
;---------------------------------------------------------------------
; ST_CD
; ST_LOAD
; ST_SAVE7
; ST_DIR
; ST_CAT
; ST_DEL
    include "dos.asm"


;-------------------------------------------------------------------
;                  Test for PAL or NTSC
;-------------------------------------------------------------------
; Measure video frame period, compare to 1.80ms
; NTSC = 16.7ms, PAL = 20ms
;
; out: nc = PAL, c = NTSC
;
; NOTE: waits for ~17-41ms. Do not use in timing-critical code!

PAL__NTSC:
    PUSH BC
.wait_vbl1:
    IN   A,($FD)
    RRA                   ; wait for start of vertical blank
    JR   C,.wait_vbl1
.wait_vbh1:
    IN   A,($FD)
    RRA                   ; wait for end of vertical blank
    JR   NC,.wait_vbh1
    LD   BC,0
.wait_vbl2:               ; 1.117us/cycle
    INC  BC               ; 2 count                 ]
    IN   A,($FD)          ; 3 read status reg       ]
    RRA                   ; 1 test VBL bit          ]   9 cycles per loop
    JR   C,.wait_vbl2     ; 3 loop until VLB high   ]   10.06us/loop
.wait_vbh2:               ; cycles (1.12us/cycle)
    INC  BC               ; 2 count                 ]
    IN   A,($FD)          ; 3 read status reg       ]   9 cycles per loop
    RRA                   ; 1 test VBL bit          ]   10.06us/loop
    JR   NC,.wait_vbh2    ; 3 loop until VLB high   ]
    LD   C,A
    LD   A,B              ; ~1657 = 60Hz, ~1989 = 50Hz
    CP   7                ; c = NTSC, nc = PAL
    LD   A,C
    POP  BC
    RET

C0_END:   
C0_SIZE = C0_END - $C000

; fill with $FF to $E000
     assert !($E000 < $) ; low rom full!!!
     dc  $E000-$,$FF

;=================================================================
;                     AquBASIC BOOT ROM
;=================================================================

     ORG $E000

; Rom recognization
; 16 bytes
;
RECOGNIZATION:
    db      66, 79, 79, 84
    db      83, 156, 84, 176
    db      82, 108, 65, 100
    db      80, 168, 128, 112

ROM_ENTRY:
; set flag for NTSC or PAL
    call    PAL__NTSC     ; measure video frame period: nc = PAL, c = NTSC
    ld      a,0
    jr      nc,.set_sysflags
    set     SF_NTSC,a
.set_sysflags:
    ld      (Sysflags),a
; set keyflags
    ld      a,1<<KF_CLICK     ; Key Click Enabled, Not Muted
    ld      (KeyFlags),a

; init Debugger Vectors
    ld      hl,debug_defs      ;default jumps for Break and GoDebug
    ld      de,Break           ;Break and GoDebug Vectors
    ld      bc,6               ;6 bytes for 2 jumps
    ldir                       ;Copy

; init CH376
    call    usb__check_exists  ; CH376 present?
    jr      nz,.no_ch376
    call    usb__set_usb_mode  ; yes, set USB mode
.no_ch376:
    call    usb__root          ; root directory

; init keyboard vars
    xor     a
    ld      (LSTX),a
    ld      (KCOUNT),a

; set up real time clock
    call    rtc_init

; check for power on or reset
    ld      hl,FDIVC
    ld      de,$0194
    ld      bc,$0600        ;B=10, C=0      
.fdivc_loop
    ld      a,(de)
    cp      (hl)
    jr      nz,.no_warm
    inc     hl
    inc     hl
    inc     de 
    inc     de 
    djnz    .fdivc_loop
    dec     c               ;C = $FF
.no_warm:
    
    jp      SPLASH



; CTRL-C pressed in boot menu
WARMBOOT:
    xor     a
    ld      (RETYPBUF),a       ; clear history buffer
    ld      a,$0b
    rst     $18                ; clear screen
    call    $0be5              ; clear workspace and prepare to enter BASIC
    call    $1a40              ; enter BASIC at KEYBREAK
JUMPSTART:
    jp      COLDBOOT           ; if BASIC returns then cold boot it

;
; Show copyright message
;
SHOWCOPYRIGHT:
    call    SHOWCOPY           ; Show system ROM copyright message
    ld      hl,STR_BASIC       ; "USB BASIC"
    call    STROUT
    ld      hl, STR_VERSION    ;
    call    STROUT
    ret
    
; Show Copyright message in system ROM
;
SHOWCOPY:
    ld      hl,$0163           ; point to copyright string in ROM
    ld      a,(hl)
    cp      $79                ; is the 'y' in "Copyright"?
    jr      nz,S1ROM
    dec     hl
    dec     hl                 ; yes, back up to start of string
    dec     hl
    jr      SHOWIT
S1ROM:
    cp      $43                ; is the 'C' in "Copyright"?
    ret     nz
SHOWIT:
    dec     hl
    call    STROUT           
    ret

STR_BASIC:
    db      $0D,"Aquarius MX BASIC"
    db      $00
STR_VERSION:
    db      " v",VERSION+'0','.',REVISION+'0',$0D,$0A,0

SHOWRAM:
    ld      a,high(RAMEND)
    sub     high(CHRRAM)          ; Get Pages of Total RAM
    srl     a
    srl     a                     ; Divide by 4 to get KB
    ld      l,a                   ; Put in HL
    ld      h,0
    ld      a,2                   ; Default to 2 digits
    call    print_integer         ; Print Total KB 
    ld      hl,STR_RAM_SYSTEM      
    call    prtstr                
    ld      hl,0                  ; Get Bottom of Stack
    add     hl,sp                  
    ld      de,(STREND)           ; Get Top of Array Spaces
    sbc     hl,de                 ; Subtract to get Bytes Free
    ld      de,10                 
    sbc     hl,de                 ; Subtract 10 more to match FRE(0)
    ld      a,5
    call    print_integer         ; Print It
    ld      hl,STR_BYTES_FREE     
    jp      prtstr
    
STR_RAM_SYSTEM:
    db      "K RAM - ",0
STR_BYTES_FREE:
    db      " Bytes Free",13,10,0

; The bytes from $0187 to $01d7 are copied to $3803 onwards as default data.
COLDBOOT:

    ld      hl,$0187           ; default values in system ROM
    ld      bc,$0051           ; 81 bytes to copy
    ld      de,$3803           ; system variables
    ldir                       ; copy default values
    xor     a
    ld      (ENDBUF),a         ; NULL end of input buffer
    ld      (BINSTART),a       ; NULL binary file start address
    ld      (RETYPBUF),a       ; NULL history buffer
    ld      a,$0b
    rst     $18                ; clear screen
    call    XSTART             ; Initialize Extended BASIC Variables

; Test the memory
; only testing 1st byte in each 256 byte page!

    ld      hl,$3A00           ; first page of free RAM
    ld      a,$55              ; pattern = 01010101
MEMTEST:
    ld      c,(hl)             ; save original RAM contents in C
    ld      (hl),a             ; write pattern
    cp      (hl)               ; compare read to write
    jr      nz,MEMREADY        ; if not equal then end of RAM
    cpl                        ; invert pattern
    ld      (hl),a             ; write inverted pattern
    cp      (hl)               ; compare read to write
    jr      nz,MEMREADY        ; if not equal then end of RAM
    ld      (hl),c             ; restore original RAM contents
    cpl                        ; uninvert pattern
    inc     h                  ; advance to next page
    jr      nz,MEMTEST         ; continue testing RAM until end of memory
MEMREADY:
    ld      a,h
ifdef softrom
    cp      $80                ; 16k expansion
else
    cp      $c0                ; 32k expansion
endif
    jp      c,$0bb7            ; OM error if expansion RAM missing
    dec     hl                 ; last good RAM addresss
    ld      hl,vars-1          ; top of public RAM
MEMSIZE:
    ld      (MEMSIZ),hl        ; Contains the highest RAM location
    ld      de,-1024           ; subtract 50 for strings space
    add     hl,de
    ld      (TOPMEM),hl        ; Top location to be used for stack
    ld      hl,PROGST
    ld      (hl), $00          ; NULL at start of BASIC program
    inc     hl
    ld      (TXTTAB), hl       ; beginning of BASIC program text
    ld      hl,FASTHOOK        ; RST $30 Vector (our UDF service routine)
    ld      (UDFADDR),hl       ; store in UDF vector
    call    SCRTCH             ; ST_NEW2 - NEW without syntax check
    call    SHOWCOPYRIGHT      ; Show our copyright message
    call    SHOWRAM            ; Show Total RAM, BASIC Bytes Free
    xor     a
    jp      READY              ; Jump to OKMAIN (BASIC command line)




;--------------------------------------------------------------------
;                          Command Line
;--------------------------------------------------------------------
; Replacement Immediate Mode with Line editing
;
; UDF hook number $02 at OKMAIN ($0402)

AQMAIN:
    ld      hl,(OLDTXT)         ; Get CONT Text pointer
    ld      a,h
    or      l
    jr      nz,.main            ; If 0
    ld      (ONELIN),hl         ;   Clear Error Trap
.main:    
;    pop     af                  ; clean up stack
;    pop     af                  ; restore AF
;    pop     hl                  ; restore HL

    call    FINLPT              ; If we were printing to printer, LPRINT a CR and LF
    xor     a
    ld      (CNTOFL),a          ; Set Line Counter to 0
    call    CRDONZ               ; RSTCOL reset cursor to start of (next) line
    ld      hl,REDDY            ; 'Ok'+CR+LF
    call    STROUT            
;
; Immediate Mode Main Loop
;l0414:

IMMEDIATE:
    ld      hl,SysFlags
    SET     SF_RETYP,(HL)       ; CRTL-R (RETYP) active    
    ld      hl,-1
    ld      (CURLIN),hl         ; Current BASIC line number is -1 (immediate mode)
    ld      hl,BUF              ; HL = line input buffer
    ld      (hl),0              ; buffer empty
    ld      b,BUFLEN            ; 
    call    EDITLINE            ; Input a line from keyboard.
    ld      hl,SysFlags
    RES     SF_RETYP,(HL)       ; CTRL-R inactive
ENTERLINE:
    ld      hl,BUF-1            ; Point to byte before line buffer
    jr      c,immediate         ; If c then discard line
    rst     CHRGET              ; get next char (1st character in line buffer)
    inc     a
    dec     a                   ; set z flag if A = 0
    jr      z,immediate         ; If nothing on line then loop back to immediate mode
    push    hl
    ld      de,ReTypBuf
    ld      bc,BUFLEN
    ldir                        ; save line in history buffer
    pop     hl
    push    af                  ; SAVE STATUS INDICATOR FOR 1ST CHARACTER
    call    SCNLIN              ; READ IN A LINE #
    push    de                  ; SAVE LINE #
    ld      de,BUF
    xor     a                   ; SAY EXPECTING FLOATING NUMBERS
    ld      (DORES),a           ; ALLOW CRUNCHING
    ld      c,5                 ; LENGTH OF KRUNCH BUFFER
    call    KLOOP               ; CRUNCH THE LINE DOWN
    ld      hl,BUF-1
    ld      (de),a              ; NEED THREE 0'S ON THE END
    inc     de                  ; ONE FOR END-OF-LINE
    ld      (de),a              ; AND 2 FOR A ZERO LINK
    inc     de                  ; SINCE IF THIS IS A DIRECT STATEMENT
    ld      (de),a              ; ITS END MUST LOOK LIKE THE END OF A PROGRAM
    ld      b,a                 ; RETAIN CHARACTER COUNT.
    pop     de                  ; RESTORE LINE #
    pop     af                  ; WAS THERE A LINE #?
    jp      nc,GONE             ;
    push    de                  ;
    push    bc                  ; SAVE LINE # AND CHARACTER COUNT
    xor     a                   ;
    ld      (USFLG),a           ; RESET THE FLAG
    rst     CHRGET              ; REMEMBER IF THIS LINE IS
    or      a                   ; SET THE ZERO FLAG ON ZERO
    push    af                  ; BLANK SO WE DON'T INSERT IT
    call    FNDLIN              ; GET A POINTER TO THE LINE
    jr      c,.lexist           ; LINE EXISTS, DELETE IT
    pop     af                  ; GET FLAG SAYS WHETHER LINE BLANK
    push    af                  ; SAVE BACK
    jp      z,USERR             ; SAVE BACK
    or      a                   ; TRYING TO DELETE NON-EXISTANT LINE, ERROR
.lexist:  
    push    bc                  ; SAVE THE POINTER
    jr      nc,.NODEL           ;
    ex      de,hl               ; [D,E] NOW HAVE THE POINTER TO NEXT LINE
    ld      hl,(VARTAB)         ; COMPACTIFYING TO VARTAB
.mloop:  
    ld      a,(de)              ;
    ld      (bc),a              ; SHOVING DOWN TO ELIMINATE A LINE
    inc     bc                  ;
    inc     de                  ;
    rst     COMPAR              ;
    jr      nz,.mloop           ; DONE COMPACTIFYING?
    ld      h,b                 ;
    ld      l,c                 ;;HL = new end of program
    ld      (VARTAB),hl         ; SETUP [VARTAB]
.nodel:  
    pop     de                  ; POP POINTER AT PLACE TO INSERT
    pop     af                  ; SEE IF THIS LINE HAD ANYTHING ON IT
    jr      z,.fini             ; IF NOT DON'T INSERT
    ld      hl,(VARTAB)         ; CURRENT END
    ex      (sp),hl             ; [H,L]=CHARACTER COUNT. VARTAB ONTO STACK
    pop     bc                  ; [B,C]=OLD VARTAB
    add     hl,bc               ;
    push    hl                  ; SAVE NEW VARTAB
    call    BLTU                ;;Create space for new line
    pop     hl                  ; POP OFF VARTAB
    ld      (VARTAB),hl         ; UPDATE VARTAB
    ex      de,hl               ;
    ld      (hl),h              ; FOOL CHEAD WITH NON-ZERO LINK
    pop     de                  ; GET LINE # OFF STACK
    inc     hl                  ; SO IT DOESN'T THINK THIS LINK
    inc     hl                  ; IS THE END OF THE PROGRAM
    ld      (hl),e              ;
    inc     hl                  ; PUT DOWN LINE #
    ld      (hl),d              ;
    inc     hl                  ;
    ld      de,BUF              ; MOVE LINE FRM BUF TO PROGRAM AREA
.mloopr:  
    ld      a,(de)              ; NOW TRANSFERING LINE IN FROM BUF
    ld      (hl),a              ;
    inc     hl                  ;
    inc     de                  ;
    or      a                   ; If not line terminator, keep going
    jr      nz,.mloopr          ;
.fini:
    call    RUNC                ; DO CLEAR & SET UP STACK 
; Hook 5 (LINKER) comes here to force MX BASIC immediate Mode
; It shouldn't get hit anymore, but left in just in casy
LINKLINES:
    ld      bc,immediate          ; When done linking
    push    bc                    ; Enter MX BASIC immediate mode
    inc     hl
    ex      de,hl              ; DE = start of BASIC program
; Rebuild BASIC Line Links
; In: DE = Start of BASIC Program
link_lines
    ld      h,d
    ld      l,e                ; HL = DE
    ld      a,(hl)
    inc     hl                 ; get address of next line
    or      (hl)
    ret     z                  ; if next line = 0 then done so return to immediate mode
    inc     hl
    inc     hl                 ; skip line number
    inc     hl
    xor     a
.czloop:
    cp      (hl)               ; search for next null byte (end of line)
    inc     hl
    jr      nz,.czloop
    ex      de,hl              ; HL = current line, DE = next line
    ld      (hl),e
    inc     hl                 ; update address of next line
    ld      (hl),d
    jr      link_lines         ; next line



;********************************************************************
;                   Command Entry Points
;********************************************************************

ST_reserved:
    ret

;----------------------------------------------------------------------------
; Invoke Debugger
;----------------------------------------------------------------------------

ST_DEBUG:
    jp      GoDebug

debug_defs:
    jp      debug_ret   ;Break vector
    jp      no_debug    ;GoDebug vector
    
no_debug:
    push    hl
    ld      hl,no_debug_msg
    call      prtstr
    pop     hl
debug_ret:
    ret

no_debug_msg:
    db      "Debugger not installed",$0D,$0A,0

;----------------------------------------------------------------------------
;;; ---
;;; ## DOKE
;;; Writes 16 bit word(s) to memory location(s), aka "Double Poke"
;;; ### FORMAT:
;;;  - DOKE *address*, *word*, [, *word* ...]
;;;    - Action: Writes *word* to memory starting at *address*.
;;; ### EXAMPLES:
;;; ` DOKE 14340, 1382 `
;;; > Set USR() function address
;;;
;;; ` DOKE $3028, $6162 `
;;; > Put the characters `ba` at the top left of the screen
;;;
;;; ` DOKE $3028, $3130, $3332 `
;;; > Put the characters `0123` at the top left of the screen
;----------------------------------------------------------------------------

ST_DOKE:   
    call    GETADR          ; Get <address>
    SYNCHK  ','             ; Require a Comma
.doke_loop:
    push    de              ; Stack = address  
    call    GETADR          ; Get <word> in DE
    ex      (sp),hl         ; HL = address, Stack = Text Pointer
    ld      (hl),e          ; Write word to <address> 
    inc     hl
    ld      (hl),d
    ex      de,hl           ; DE = Address
    pop     hl
    ld      a,(hl)          ; If Next Character
    cp      ','             ; is Not a Comma
    ret     nz              ;   We are done
    rst     CHRGET          ; Skip Comma
    inc     de              ; Bump Poke Address
    jr      .doke_loop      ; Do the Next Word
    ret


;----------------------------------------------------------------------------
;;; ---
;;; ## CLS (Extended)
;;; Clear Screen / Clear Screen with specified foreground and background colors
;;; ### FORMAT:
;;;  - CLS [ *foreground, background* ]
;;;    - Action: Clears the screen. The optional *foreground* and *background* parameters are numbers between 0 and 15 that specifies the new foreground and background colors.
;;;      - If either parameter is specified, both must be specified.
;;;      - If *foreground* and *background* , the screen is cleared with the default BLACK characters on CYAN background.
;;; >
;;;     0 BLACK      4 BLUE       8  GREY        12 LTYELLOW
;;;     1 RED        5 MAGENTA    9  DKCYAN      13 DKGREEN 
;;;     2 GREEN      6 CYAN       10 DKMAGENTA   14 DKRED    
;;;     3 YELLOW     7 WHITE      11 DKBLUE      15 DKGREY   
;;;
;;;    - Warning: If the foreground and background colors are the same, typed and PRINTed text will be invisible.
;;;    - Advanced: Unlike PRINT CHR$(11), CLS does not clear memory locations 13288 - 13313 ($33E8 - $33FF) and 14312 - 14355 ($37E8 - $37FF).
;;; ### EXAMPLES:
;;; ` CLS `
;;; > Clear screen with default colors
;;;
;;; ` CLS 0,7 `
;;; > Clear screen - black text on white background
;;;
;;; ` CLS 3,0 `
;;; > Clear screen - yellow text on black background
;;;
;;; ` CLS F,B `
;;; > Clear screen - text color F, background color B (using BASIC variables)
;----------------------------------------------------------------------------

ST_CLS:
    ld      a,CYAN                ; default to black on cyan
    jr      z,do_cls              ; no parameters, use default
    call    get_color             ; get foreground color
    push    af                    ; save it
    SYNCHK  ','                   ; require commae
    call    get_color             ; get background color
    pop     af                    ; get back foreground color
    or      a                     ; clear carry
    rla       
    rla       
    rla       
    rla                           ; shift to high nybble
    or      e                     ; combine background color
do_cls:
    call    clearscreen
    ld      de,$3001+40   ; DE cursor at 0,0
    ld      (CURRAM),de
    xor     a
    ld      (TTYPOS),a    ; column 0
    ld      a,' '
    ld      (CURCHR),a   ; SPACE under cursor
    ret

clearscreen:
    push    hl
    ld      hl,$3000
    ld      c,25
.line:
    ld      b,40
.char:
    ld      (hl),' '
    set     2,h
    ld      (hl),a
    res     2,h
    inc     hl
    djnz    .char
    dec     c
    jr      nz,.line
    pop     hl
    ret

get_color:
    call    GETBYT        ; get foreground color in e
    cp      16            ; if > 15
    jp      nc,FCERR      ;   FC Error
    ret

;----------------------------------------------------------------------------
;;; ---
;;; ## KEY Statement
;;; Controls keyboard functions
;;; ### FORMAT:
;;;  - KEY SOUND [ON | OFF]
;;;    - Action: Turns key click ON or OFF
;;;  - KEY *string*
;;;    - Action: Causes BASIC to act as though the characters in *string* are being typed on the keyboard.
;;;      - Returns LS Error if *string* is longer than 15 characters.
;;;
;;; ### EXAMPLES:
;;; ` KEY SOUND OFF `
;;; > Turns key click off.
;;;
;;; ` KEY SOUND ON `
;;; > Turns key click on.
;----------------------------------------------------------------------------
ST_KEY:
    cp      SOUNDTK               ; If Next Character
    jp      nz,.notsound          ; is SOUND Token
    ld      iy,KeyFlags
    rst     CHRGET                ;   Skip to Next Character
    ld      c,a                   ;   Save Character
    rst     CHRGET                ;   Advance Text Pointer
    ld      a,c                   ;   Restore Character
    cp      ONTK                  ;   
    jr      nz,.not_ontk          ;   If ON Token
    set     KF_CLICK,(iy+0)       ;     Turn Key Click On
    ret                           ;     and Return
.not_ontk:
    cp      OFFTK                 ;   If Not OFF Token
    jp      nz,FCERR              ;     FC Error
    res     KF_CLICK,(iy+0)       ;   Turn Key Click On
    ret
.notsound                         ; Else
    call    FRMEVL                ;   Evaluate Argument
    push    hl                    ;   Save Text Pointer
    call    STRLENADR             ;   Get Length and Address, TM Error if not string
    cp      KeyBufLen             ;   If Not Shorter than Key Buffer
    jp      nc,LSERR              ;      String Too Long error
    ld      de,KeyBuf-1           ;   Get Key Buffer Address
    ld      (RESPTR),de           ;   and Make it the Keyword to Expand
    inc     de
    ldir                          ;   Copy String to Key Buffer
    ld      a,$80                 ;   Put Reserved Word Terminator
    ld      (de),a                ;   at end of Key Buffer
    pop     hl                    ;   Restore Text Pointer
    ret

;----------------------------------------------------------------------------
;;; ---
;;; ## LOCATE
;;; Move the cursor to a specific column and row on the screen
;;; ### FORMAT:
;;;  - LOCATE *column*,*row*
;;;    - Action: Moves the cursor to the specified spot on the screen
;;;      - *column* can be 1-38 (leftmost and rightmost columns cannot be used)
;;;      - *row* can be 1-23 (topmost and bottommost rows cannot be used)
;;; ### EXAMPLES:
;;; ` LOCATE 1,1:print"Hello" `
;;; > Prints `Hello` at top left of screen
;;;
;;; ` CLS:LOCATE 19,11:PRINT"&" `
;;; > Clears the screen and prints `&` in the middle
;----------------------------------------------------------------------------
ST_LOCATE:
    call    GETBYT              ; read number from command line (column). Stored in A and E
    push    af                  ; column store on stack for later use
    dec     a
    cp      38                  ; compare with 38 decimal (max cols on screen)
    jp      nc,$0697            ; If higher then 38 goto FC error
    rst     $08                 ; Compare RAM byte with following byte
    db      $2c                 ; character ',' byte used by RST 08
    call    GETBYT              ; read number from command line (row). Stored in A and E
    cp      $18                 ; compare with 24 decimal (max rows on screen)
    jp      nc,$0697            ; if higher then 24 goto FC error
    inc     e
    pop     af                  ; restore column from store
    ld      d,a                 ; column in register D, row in register E
    ex      de,hl               ; switch DE with HL
    call    GOTO_HL             ; cursor to screenlocation HL (H=col, L=row)
    ex      de,hl
    ret

GOTO_HL:
    push    af
    push    hl
    exx                          ; save Registers for TTYFIS
    ld      hl,(CURRAM)          ; address of cursor within matrix
    ld      a,(CURCHR)           ; storage of the character behind the cursor
    ld      (hl),a               ; return the original character on screen
    pop     hl
    ld      a,l
    add     a,a
    add     a,a
    add     a,l
    ex      de,hl
    ld      e,d
    ld      d,$00
    ld      h,d
    ld      l,a
    ld      a,e
    dec     a
    add     hl,hl
    add     hl,hl
    add     hl,hl               ; hl is now 40 * rows
    add     hl,de               ; added the columns
    ld      de,$3000            ; screen character-matrix (= 12288 dec)
    add     hl,de               ; putting it al together
    jp      TTYFIS              ; Save cursor position and return

;----------------------------------------------------------------------------
;;; ---
;;; ## PSG
;;; Write to Programmable Sound Generator(s)
;;; ### FORMAT:
;;;  - PSG *register*, *value* [, ...]
;;;    - Action: Writes a *register* *value* pair to either PSG1 or PSG2
;;;      - *register*  0-15 goes to PSG1 at $F7 (register) and $F6 (data)
;;;      - *register* 16-31 goes to PSG2 at $F9 (register) and $F8 (data)
;;; ### EXAMPLES:
;;; ` PSG 8,15,0,148,1,1,7,56 `
;;; > Play a Db4 note on PSG1 channel A, continuously
;;;
;;; ` PSG 8,0,7,0 `
;;; > Turn the PSG1 sound off
;;;
;;; ` PSG 24,15,16,148,17,1,23,56 `
;;; > Play a Db4 note on PSG2 channel A, continuously
;;;
;;; ` PSG 24,0,23,0 `
;;; > Turn the PSG2 sound off

;; ---
;; ## PSGs (Programmable Sound Generators)
;; ### Hardware 
;; - The Aquarius MX, Micro Expander, and Mini Expander have an on-board AY-3-8910 sound chip (referred to in the code as PSG1) on IO addresses $F7 *register* and $F6 *data*.
;; - The Aquarius MX has an option for a second AY-3-8913 sound chip (referred to in the code as PSG2) on IO addresses $F9 *register* and $F8 *data*. This device does not have the capability for controller input.
;; ### Software
;; - If writing to a PSG to modify sound output, the *register* must be written to first, followed by the *data*
;; - If reading from a PSG to process controller input, the *register* must be written to first to select which controllers will be polled, then the *register* is read to receive the input bytes.
;; ### AY PSG Registers
;; - 0  - Channel A Tone Period, fine
;; - 1  - Channel A Tone Period, coarse
;; - 2  - Channel B Tone Period, fine
;; - 3  - Channel B Tone Period, coarse
;; - 4  - Channel C Tone Period, fine 
;; - 5  - Channel C Tone Period, coarse
;; - 6  - Channel Noise Period
;; - 7  - Enable Channels/Noise/IO
;; - 10 - Channel A Amplitude
;; - 11 - Channel B Amplitude
;; - 12 - Channel C Amplitude
;; - 13 - Envelop Period, fine
;; - 14 - Envelop Period, coarse
;; - 15 - Envelope Shape/Cycle 
;; - 16 - IO Port A Data Store
;; - 17 - IO Port B Data Store
;;
;----------------------------------------------------------------------------
;
; Original Single PSG Code - Restore as needed (Remove after release!!!)
;
; ST_PSG:
;     cp      $00
;     jp      z,MOERR         ; MO error if no args
; psgloop:
;     call    GETBYT          ; get/evaluate register
;     out     ($f7),a         ; set the PSG register
;     rst     $08             ; next character must be ','
;     db      $2c             ; ','
;     call    GETBYT          ; get/evaluate value
;     out     ($f6),a         ; send data to the selected PSG register
;     ld      a,(hl)          ; get next character on command line
;     cp      $2c             ; compare with ','
;     ret     nz              ; no comma = no more parameters -> return
;     inc     hl              ; next character on command line
;     jr      psgloop         ; parse next register & value
;
; Dual PSG Code
ST_PSG:
    cp      $00
    jp      z,MOERR             ; MO error if no args
psgloop:
    call    GETBYT              ; Get/evaluate register
    cp      16                  ; Compare to a 16 offset
    jr      nc, psg2            ; If >= 16 send to PSG2
    out     (PSG1REGI),a        ; Otherwise, set the PSG1 register
    rst     $08                 ; Next character must be ','
    db      COMMA               ; ','
    call    GETBYT              ; Get/evaluate value
    out     (PSG1DATA),a        ; Send data to the selected PSG1 register
check_comma:
    ld      a,(hl)              ; Get next character on command line
    cp      COMMA               ; Compare with ','
    ret     nz                  ; No comma = no more parameters -> return
    inc     hl                  ; Next character on command line
    jr      psgloop             ; Parse next register & value
psg2:
    sub     16                  ; Reduce shifted registers into regular range for PSG2
    out     (PSG2REGI),a        ; Set the PSG2 register
    rst     $08                 ; Next character must be ','
    db      COMMA               ; ','
    call    GETBYT              ; Get/evaluate value
    out     (PSG2DATA),a        ; Send data to the selected PSG2 register
    jr      check_comma

;----------------------------------------------------------------------------
;;; ---
;;; ## DEEK
;;; Read 16 bit word from Memory
;;; ### FORMAT:
;;; - DEEK(*address*)
;;;   - Action: Reads a word from memory location *address*, returning a number between 0 and 65535.
;;;
;;; ### EXAMPLES:
;;; ` POKE DEEK(14337),PEEK(14349) `
;;; > Remove cursor from screen.
;;;
;;; ` PRINT DEEK($384B) `
;;; > Print the top of BASIC memory address.
;----------------------------------------------------------------------------

FN_DEEK:
    rst     CHRGET            ; Skip Token and Eat Spaces
    call    PARCHK
    push    hl
    ld      bc,LABBCK
    push    bc
    call    FRCADR            ; Convert to Integer
    ld      h,d               ; HL = <address>
    ld      l,e
FLOAT_M:
    ld      e,(hl)            ; Read word at address
    inc     hl
    ld      d,(hl)
    jp      FLOAT_DE          ; Float and Return

;----------------------------------------------------------------------------
;;; ---
;;; ## JOY
;;; Read AY-3-8910 Control Pad Inputs
;;; ### FORMAT:
;;;  - JOY(*stick*)
;;;    - Action: Reads integer input value from *stick*, where:
;;;      - `0` will read left or right control pad
;;;      - `1` will read left control pad only
;;;      - `2` will read right control pad only
;;; ### EXAMPLES:
;;; ` PRINT JOY(0) `
;;; > Prints input value of either/both control pads (not effective in immediate mode).
;;;
;;; ```
;;; 10 PRINT JOY(1)
;;; 20 GOTO 10 
;;; ```
;;; > Continuously reads and prints the input value from only the left control pad.
;----------------------------------------------------------------------------

FN_JOY:
    rst     CHRGET            ; Skip Token and Eat Spaces
    call    PARCHK
    push    hl
    ld      bc,LABBCK
    push    bc
    call    FRCINT            ; convert argument to 16 bit integer in DE

    ld      a,e
    or      a
    jr      nz, joy01
    ld      a,$03

joy01:   
    ld      e,a
    ld      bc,$00f7
    ld      a,$ff
    bit     0,e
    jr      z, joy03
    ld      a,$0e
    out     (c),a
    dec     c
    ld      b,$ff

joy02:   
    in      a,(c)
    djnz    joy02
    cp      $ff
    jr      nz,joy05

joy03:   
    bit     1,e
    jr      z,joy05
    ld      bc,$00f7
    ld      a,$0f
    out     (c),a
    dec     c
    ld      b,$ff

joy04:   
    in      a,(c)
    djnz    joy04

joy05:   
    cpl
    jp      SNGFLT


;----------------------------------------------------------------------------
;;; ---
;;; ## KEY
;;; Read Keyboard
;;; ### FORMAT:
;;;  - KEY(*number*)
;;;    - Action: Checks for a key press and returns the ASCII code of the key.
;;;      - If *number* is 0, waits for a key to be pressed then returns it's ASCII code.
;;;      - If *number* is positive, checks to see if a key has been pressed, returning the key's ASCII code (or 0 if no key was pressed). A key press will only be detected once, returning 0 on subsequent calls until the key is released and pressed again.
;;;      - If *number* is negative, returns the ASCII code of the key currently being pressed (or 0 if no keys are being pressed). Subsequent calls will continue to return the key's ASCII code if the key remains pressed.
;;;      - KEY() does not expand control-key combinations to keywords. Instead CTRL-A through CTRL-Z generate ASCII 1 through 27 (^A-^Z) The rest of the control characters are assigned as follows:
;;; ```
;;;   KEY:  ;   =   0   :   /   -  8   9   7   ,   1   .   2  <--
;;; ASCII: 128  27  28  29  30  31 91  93  96 123 124 125 126 127
;;;  NOTE:  ^@ ESC  ^\  ^]  ^^  ^_ [   ]   `  {    |   }   ~  DEL
;;;
;;;   KEY:   3    4    5    6   SPACE  RTN  Shift-SPC  Shift-RTN
;;; ASCII:  158  143  159  142   $C6   255     160        134
;;;  NOTE: LEFT  UP  DOWN RIGHT  dot  black   blank   checkerboard
;;; ```
;;;
;;; ### EXAMPLES:
;;; ` PRINT KEY(0) `
;;; > Wait for a key press then print ASCII code
;;;
;;; ` 10 K=KEY(1) `
;;;
;;; ` 20 IF K THEN S$=S$+CHR$(K) `
;;; > Check for key press and add key character to string once per key press
;;;
;;; ` 10 K=KEY(-1) `
;;;
;;; ` 2O IF K=97 THEN X=X-1 `
;;;
;;; ` 30 IF K=115 THEN X=X+1 `
;;; > Continuously decrement or increment X as long as the A or S key, respectively, is pressed.
;----------------------------------------------------------------------------

FN_KEY:
    rst     CHRGET            ; Skip Token and Eat Spaces
    call    PARCHK
    push    hl
    ld      bc,LABBCK
    push    bc
    call    CHKNUM
    ld      a,(FAC)           ;
    or      a                 ; If Argument <> 0
    jr      nz,.fnk_notz       ;   Do Timeout

.fnk_wait:
    call    key_check         ; Check for a key
    jr      nz,.fnk_return       ; Found a key, return it
    jr      .fnk_wait

.fnk_notz
    ld      a,(FACHO)
    rla
    jr      nc,.fnk_plus
    xor     a
    ld      (LSTX),a          ; Clear debounce 
    ld      (KCOUNT),a
.fnk_plus:
    ld      b,8
.fnk_loop:
    call    key_check         ; Check for a key
    jr      nz,.fnk_return       ; Found a key, return it
    djnz    .fnk_loop

.fnk_return
    jp      SNGFLT            ; and float it

;----------------------------------------------------------------------------
;;; ---
;;; ## DEC
;;; Hexadecimal to integer conversion
;;; ### FORMAT:
;;;  - DEC(*hexadecimal string*)
;;;    - Action: Returns the DECimal value of the hexadecimal number in *hexadecimal string*.
;;;      - If the first non-blank character of the string is not a decimal digit or the letters A through F, the value returned is zero.
;;;      - String conversion is finished when the end of the string or any character that is not a hexadecimal digit is found.
;;;      - See the HEX function for number-to-hex conversion.
;;; ### EXAMPLES:
;;; ` PRINT DEC("FFFF") `
;;; > Prints "65535"
;;;
;;; ` 10 A$=HEX$(32):PRINT DEC(A$) `
;;; > Prints "32"
;----------------------------------------------------------------------------

FN_DEC:
    rst     CHRGET            ; Skip Token and Eat Spaces
    call    PARCHK
    push    hl
    ld      bc,LABBCK
    push    bc
    call    STRLENADR       ; Get String Text Address
    dec     hl              ; Back up Text Pointer
    xor     a               ; Set A to 0
    inc     c               ; Bump Length for DEC C
    jp      _eval_hex       ; Convert the Text

;----------------------------------------------------------------------------
;;; ---
;;; ## HEX$
;;; Integer to hexadecimal conversion
;;; ### FORMAT:
;;;  - HEX$(*number* [,*length*])
;;;    - Action: Returns string containing *number* in two-byte hexadecimal format. 
;;;      - If *length* is 0 or omitted, the returned string will be two characters if *number* is between 0 and 255, otherwise it will be four characters.
;;;      - If *length* is 1, the returned string will be two characters long. If *nunmber* is greater than 255 or less than 0, only the LSB will be returned.
;;;      - If *length* is 2, the returned string will be four characters long.
;;;      - Returns FC Error if *number* is not in the range -32676 through 65535 or *length* is not in the range 0 through 2.
;;;      - See the DEC function for hex-to-number conversion.
;;;  - HEX$("*string*")
;;;    - Action: Returns string containing a series of two digit hexadecimal numbers representing the characters in *string*.
;;;      - Length of returned string is twice that *string*.
;;;      - LS Error results if length of *string* is greater than 127.
;;;      - See the ASC$ function for hex-to-string conversion.
;;; ### EXAMPLES:
;;; ` PRINT HEX$(1) `
;;; > Prints "01"
;;;
;;; ` PRINT HEX$(1,2) `
;;; > Prints "0001"
;;;
;;; ` PRINT HEX$(-1,1) `
;;; > Prints "FF"
;;;
;;; ` 10 PRINT HEX$(PEEK(12288)) `
;;; > Prints the HEX value of the border char (usually "20", SPACE character)
;;;
;;; ` PRINT HEX$("123@ABC") `
;;; > Prints "31323340414243"
;;;
;----------------------------------------------------------------------------

FN_HEX:
    rst     CHRGET          ; Skip Token and Eat Spaces
    SYNCHK  '('             ; Require Open Parenthesis
    call    FRMEVL          ; Evaluate First Argument
    call    GETYPR          ; Get Type of Argument
    jr      z,HEX_STRING    ; If String, Convert It and Return
    call    FRCADR          ; Convert argument to 16 bit integer DE
    push    de              ; Save It
    ld      a,(hl)          ; Get Current Character
    cp      ','             ; See if Comma
    ld      e,0             ; Default Second Argument to 0
    jr      nz,.notcomma    ; If Comma
    rst     CHRGET          ;   Skip It`
    call    GETBYT          ;   Evaluate Second Argument
.notcomma:    
    SYNCHK  ')'             ; Require Close Parenthesis
    ld      a,e             ; A = Second Argument
    pop     de              ; DE = First Argument
    push    hl              ; Save Text Pointer
    push    bc              ; Dummy Return Address for FINBCK to discard
    ld      hl,FBUFFR       ; Creating Text String in FOUT Buffer`
    push    hl              ; Save Address
    or      a               ; If Second Argument is 0 (or omitted)
    jr      z,.check_msb    ;   Print MSB (if not 0) and LSB
    dec     a               ; If Second Argument is 1
    jr      z,.do_lsb       ;   Print LSB only
    dec     a               ; If Second Argument is 2
    jr      z,.do_msb       ;   Print MSB and LSB
    jp      FCERR           ; Else Function Call Error
.check_msb:
    ld      a,d             ; Get MSB
    or      a               ; If Zero
    jr      z,.do_lsb       ;   Skip It
.do_msb:
    ld      a,d             ; Get MSB
    call    _hexbyte        ; Convert to Hex String
.do_lsb:  
    ld      a,e             ; Get LSB 
    call    _hexbyte        ; Convert to Hex String
    ld      (hl),0          ; null-terminate string
    pop     hl              ; Restore Buffer Address
.create_string:
    jp      TIMSTR          ; create BASIC string

HEX_STRING:
    SYNCHK  ')'             ; Require Close Parenthesis
    push    hl              ; Save Text Pointer
    push    bc              ; Dummy Return Address for FINBCK to discard
    call    STRLENADR       ; Get Arg Length in A, Address in HL
    or      a               ; If Null String
    jp      z,TIMSTR        ;   Return it as the Result
    push    hl              ; Stack=Arg Text Address
    push    af              ; Stack=Arg Length, Arg Text Address
    add     a,a             ; New String will be Twice as long
    jr      c,LSERR         ; LS Error if greater than 255
    call    STRINI          ; Create Result String returning HL=Descriptor, DE=Text Address
    pop     af              ; A=Arg Length, Stack=Arg Text Address
    pop     hl              ; HL=Arg Text Address
    ex      de,hl           ; DE=Arg Text Address, HL=Result Text Address
    ld      b,a             ; Loop through Arg String Text 
.hexloop:
    ld      a,(de)          ; Get Arg String Character
    inc     de              ; and Bump Pointer
    call    _hexbyte        ; Convert to Hex in Result String
    djnz    .hexloop        ; Loop until B=0
    jp      FINBCK          ; Return Result String

_hexbyte:
    ld      c,a
    rra
    rra
    rra
    rra
    call    .hex
    ld      a,c
.hex:
    and     $0f
    cp      10
    jr      c,.chr
    add     7
.chr:
    add     '0'
    ld      (hl),a
    inc     hl
    ret

LSERR:
    ld      e,ERRLS       ;String Too Long Error
    jp      ERROR

;----------------------------------------------------------------------------
;;; ---
;;; ## VER
;;; Returns 16 bit integer value of MX BASIC ROM version
;;; ### FORMAT:
;;;  - VER(0)
;;;    - Action: Returns integer of current MX BASIC ROM version
;;; ### EXAMPLES:
;;; ` PRINT VER(0) `
;;; > Prints `512`
;;;
;;; ` PRINT HEX$(VER(0)) `
;;; > Prints `0200`, the HEX value of version 2, rev 0
;----------------------------------------------------------------------------

FN_VER:
    rst     CHRGET            ; Skip Token and Eat Spaces
    call    PARCHK
    push    hl
    ld      bc,LABBCK
    push    bc
    ld      a, VERSION       ; returning (VERSION * 256) + REVISION
    ld      b, REVISION
    jp      FLOATB


;--------------------------------------------------------------------
; CALL
;
; on entry to user code, HL = text after address
; on exit from user code, HL should point to end of statement
;
;----------------------------------------------------------------------------
;;; ---
;;; ## CALL
;;; Jump to and run machine code at specified address
;;; ### FORMAT:
;;;  - CALL *address*
;;;    - Action: Causes Z80 to jump from it's current instruction location to the specified one. Note that there must be valid code at the specified address, or the Aquarius will crash.
;;;    - *address* can be a 16 bit signed or unsigned integer or hex value 
;;; ### EXAMPLES:
;;; ` CALL $A000 `
;;; > Begin executing machine code stored at upper half of middle 32k expansion RAM
;;;
;;; ` 10 LOAD "PRG.BIN",$A000 `
;;;
;;; ` 20 CALL $A000 `
;;; > Loads raw binary code into upper 16k of 32k expansion, and then begins executing it.
;----------------------------------------------------------------------------

ST_CALL:
    call    GETADR                ; get <address>
    push    de                    ; put it on the stack
    ret                           ; jump to user code, HL = BASIC text pointer

;----------------------------------------------------------------------------
;;; ---
;;; ## SLEEP
;;; Pause program execution.
;;; ### FORMAT:
;;;  - SLEEP *number*
;;;    - Action: Causes BASIC to pause for approximately *number* milliseconds.
;;;      - If *number* is zero, does not pause.
;;;      - Returns FC Error if *number* is not between 0 and 65535, inclusive.
;;;      - Ctrl-C will interrupt the SLEEP command and the BASIC Program
;;; ### EXAMPLES:
;;; ` SLEEP 250 `
;;; > Pauses for 1/4 second.
;;;
;;; ` SLEEP S `
;;; > Pauses for S / 1000 seconds.
;----------------------------------------------------------------------------

ST_SLEEP:
    call    FRMEVL                ; Get Argument
    push    hl                    ; Save Text Pointer
    rst     FSIGN                 ; Get Sign of Argument
    jr      z,.done               ; If Zero Do Nothing
    jp      m,FCERR               ; If Negative, FC Error
    call    FRCADR                ; Convert Argument to Unsigned Int

.deloop                           ; 3,579 cycles = 1 millisecond
    ;Check for CTL Key - No Debounce
    ld      bc,$7fff              ;  10 Scan A15 column
    in      a,(c)                 ;  12 Read the results
    cp      $df                   ;   7 z = only D5 row is down
    jr      nz,.notctl            ;  12 Not CTL, skip check for C
    ;Check for C Key - No Debounce   Total 41
    ld      bc,$efff              ; Scan A12 column
    in      a,(c)                 ; Read the results
    cp      $ef                   ; z = only D4 row is down
    jp      z,STOPC               ; CTL-C, interrupt program
.notctl
    ld      bc,152                ; 10
.bcloop                           ; .bcloop total 152 * (10 + 13) = 3296
    djnz    .bcloop               ; 13 
                                  ; .deloop total: 41 + 3496 + 26 = 3563 = 995 microseconds
    dec     de                    ; 6     
    ld      a,d                   ; 4
    or      e                     ; 4
    jr      nz,.deloop            ; 12 
.done                                  ; Total 26
    pop     hl                    ; restore text pointer
    ret

; Require Open Parenthesis and Read Address
PARADR:
        rst     CHRGET
        SYNCHK  '('               ; Require Parenthesis
        db      $3E               ; LD A, over RST CHRGET
; Advance Text Pointer and Parse Address
CHKADR: rst     CHRGET
; Parse an Address (-32676 to 65535 in 16 bit integer)  
GETADR: call    FRMEVL      ; Evaluate Formula
; Convert FAC to Address or Signed Integer and Return in DE
; Converts floats from -32676 to 65535 in 16 bit integer
FRCADR: call    CHKNUM      ; Make sure it's a number
        ld      a,(FAC)     ;
        cp      145         ; If Float < 65536
        jp      c,QINT      ;   Convert to Integer and Return
        jp      FRCINT

;ST_EDIT
    include "edit.asm"

;------------------------------------------------------------------------------
;;; ---
;;; ## SDTM
;;; Set DateTime
;;; ### FORMAT:
;;;  - SDTM "*string*"
;;;    - Action: If a Real Time Clock is installed, allows user to set the time on the Dallas DS1244Y RTC. DateTime string must be listed in "YYMMDDHHMMSS" format:
;;;         - Improperly formatted string causes FC Error
;;;         - DateTime is set by default to 24 hour mode,
;;;           with cc (hundredths of seconds) set to 0
;;; ### EXAMPLES:
;;; ` SDTM "230411101500" `
;;; > Sets DateTime to 11 APR 2023 10:15:00 (24 hour format)
;;;
;;; ` 10 SDTM "010101000000" `
;;; > Sets DateTime to 01 JAN 2001 00:00:00 (24 hour format)
;---------------------------------------------------------------------------

ST_SDTM:
    call    FRMEVL          ; Evaluate Argument
    push    hl              ; Save text pointer
    ld      hl,POPHRT       ; Make return address POPHRT
    push    hl              ;   (POP HL and RET)
    call    FRESTR          ; Make sure it's a String and Free up tmp

    ld      a,c             ; If less than 12 characters long
    cp      12              ;   Return without setting date
    ret     c

    inc     hl              ; Skip String Descriptor length byte
    inc     hl              ; Set DE to Address of String Text
    ld      e,(hl)          ;   using it as the String Buffer
    inc     hl
    ld      d,(hl)

    ld      hl,DTM_BUFFER   ; 
    call    str_to_dtm      ; Convert String to DateTime
    ret     z               ; Don't Write if invalid DateTime

    ld      bc,RTC_SHADOW
    jp      rtc_write       ; Write to RTC and Return

;------------------------------------------------------------------------------
;;; ---
;;; ## DTM$
;;; Get DateTime
;;; ### FORMAT:
;;;  - DTM$(*number*)
;;;    - Action: If a Real Time Clock is installed:
;;;      - If *number* is 0, returns a DateTime string "YYMMDDHHmmsscc"
;;;      - Otherwise returns formatted times string "YYYY-MM-DD HH:mm:ss"
;;;      - Returns "" if a Real Time Clock is not detected.
;;; ### EXAMPLES:
;;; ` PRINT DTM$(0) `
;;; > 38011903140700
;;;
;;; ` PRINT DTM$(1) `
;;; > 2038-01-19 03:14:07
;;;
;;; ` PRINT LEFT$(DTM$(1),10) `
;;; > 2038-01-19
;;;
;;; ` PRINT RIGHT$(DTM$(1),8) `
;;; > 03:14:07
;;;
;;; ` PRINT MID$(DTM$(1),6,11) `
;;; > 01-19 03:14
;---------------------------------------------------------------------------

FN_DTM:
    rst     CHRGET                ; Skip Token and Eat Spaces
    SYNCHK  '('                   ; Require Open Parenthesis
    call    GETBYT                ; Parse a Byte Value
    ld      a,(hl)                ; Get Current Character
    cp      ','                   ; If comma
    jr      z,_dtm2args           ;   Process 2nd Argument
    SYNCHK  ')'                   ; Require Close Parenthesis
    push    hl                    ; Save Text Pointer
    ld      a,e                   ; 
    call    get_rtc               ; Read RTC returning String in DE
    ex      de,hl                 ; HL = DateTime String
    push    bc                    ; Push Dummy Return Address
return_string:       
    jp      TIMSTR

_dtm2args:
    inc     hl                    ; Skip comma 
    jp      FCERR                 ; FC Error for now
    SYNCHK  ')'                   ; Require Close Parenthesis
        


;-------------------------------------------------------------------------
; EVAL Extension - Hook 9

EVAL_EXT:
;    pop     bc                  ; BC = Hook Return Address
;    pop     af                  ; AF = whatever was in AF
;    pop     hl                  ; HL = Text Pointer

    xor     a               ;
    ld      (VALTYP),a      ; ASSUME VALUE WILL BE NUMERIC
    rst     CHRGET          ;
    jp      z,MOERR         ; TEST FOR MISSING OPERAND - IF NONE GIVE ERROR
    jp      c,FIN           ; IF NUMERIC, INTERPRET CONSTANT
    call    ISLETC          ; VARIABLE NAME?
    jp      nc,ISVAR        ; AN ALPHABETIC CHARACTER MEANS YES
    cp      '$'                 
    jr      z,.eval_hex
    cp      '&'                 
    jp      z,GET_VARPTR
    cp      ANDTK
    jp      z,FN_AND
    cp      ORTK
    jp      z,FN_OR
    cp      PLUSTK          ; IGNORE "+"
    jp      z,EVAL_EXT      ;
    jp      QDOT     

;------------------------------------------------------------------------------
;;; ---
;;; ## Hexadecimal String Literal
;;;  -  
;;;    
;;; ### EXAMPLES:
;;; ` PRINT $"414243" `
;;; > Prints ` ABC `
;;; `  `
;;; > 
;------------------------------------------------------------------------------

.eval_hex:
    inc     hl              ; Bump Text Pointer
    ld      a,(hl)          ; Get Next Character
    dec     hl              ; and Move Back
    cp      '"'             ; If Not a Quote
    jp      nz,EVAL_HEX     ;   Convert HEX Number
    inc     hl              ; Bump Again
    call    STRLTI          ; Get String Literal
    push    hl              ; Save Text Pointer
    jp      hex_to_asc      ; Convert to ASCII

;------------------------------------------------------------------------------
;;; ---
;;; ## Hexadecimal Constants
;;;  - A hexadecimal constant is a value between 0 and 65535, inclusive. It consists of a dollar sign followed by 1 to 4 hexadecimal digits.
;;;    - Hexadecimal constants may be used in any numeric expression or anywhere a numeric expression is allowed.
;;;    - They may not be used in DATA statements, as entries to the INPUT statement, in string arguments to the VAL() function, or as the target of a GOTO or GOSUB statement.
;;; ### EXAMPLES:
;;; ` PRINT $FFFF `
;;; > Prints 65535
;;;
;;; ` A = $101 `
;;; > Sets A to 257
;;;
;;; ` P = $3000+40*R+C `
;;; > Sets P to screen row 1, column 1 address
;------------------------------------------------------------------------------
; Parse Hexadecimal Literal into Floating Point Accumulator
; On Entry, HL points to first Hex Digit
; On Exit, HL points to character after Hex String

EVAL_HEX:
    xor     a
    ld      (VALTYP),a        ; Returning Number
    ld      c,a               ; Parse up to 255 characters
_eval_hex:
    ld      d,a               
    ld      e,a               ; DE is the parsed Integer
.hex_loop:    
    dec     c
    jr      z,FLOAT_DE        ; Last Character - float it
    rst     CHRGET
    jr      z,FLOAT_DE        ; End of Line - float it
    jr      c,.dec_digit      ; Decimal Digit - process it
    cp      CDTK              ; If CD token
    jr      z,.hex_cdtoken    ;   Handle it
    and     $DF               ; Convert to Upper Case
    cp      'A'               ; If < 'A'
    jr      c,FLOAT_DE        ;   Not Hex Digit - float it
    cp      'G'               ; If > 'F'
    jp      nc,FLOAT_DE       ;   Not Hex Digit - float it
    sub     'A'-':'           ; Make 'A' come after '9'
.dec_digit:
    sub     '0'               ; Convert Hex Digit to Binary
    ld      b,4               ; Shift DE Left 4 bits
.sla_loop
    sla     e                
    rl      d
    jp      c,OVERR           ;   Overflow!
    djnz    .sla_loop
    or      e                 ; Put into low nybble
    ld      e,a
    jr      .hex_loop         ; Look for Next Hex Digit

.hex_cdtoken:
    ld      a,d               
    or      a                 ; If there's anything in the MSB
    jp      nz,OVERR          ;   Overflow!
    ld      d,e               ; Move LSB to MSB
    ld      e,$CD             ; Make LSB CD  
    jr      .hex_loop


;------------------------------------------------------------------------------
;;; ---
;;; ## & Operator
;;; Get Variable Address
;;; ### FORMAT:
;;;  - &*varname*
;;;    - Action: Returns the address of the first byte of data identified with variable *varname*. 
;;;      - Variable *varname* can be either a simple variable or an indexed array element, either string or numeric in both cases.
;;;      - For numeric variables and array elements, the returned address points to the binary floating point number.
;;;      - For string variables and array elements, the returned address points to the string descriptor.
;;;      - If the variable or array does not exist, it is automatically created.
;;;      - The address returned will be an integer in the range of 0 and 65535.
;;;  - &&*varname*
;;;    - Action: Returns the address of the first byte of the string text associated with *stringvar*.
;;;      - Variable *arrayname* can be either a simple string variable or string array element.
;;;      - Returns TM error if *varname* is not a string variable.
;;;      - If the variable or array does not exist, it is automatically created.
;;;      - Returns 0 if the variable or array element was automatically created.
;;;  - &\**arrayname*
;;;    - Action: Returns the address of the first byte of data identified with array *arrayname*. 
;;;      - Array *arrayname* can be either a numeric or string array. It is specified without following parenthesis.
;;;      - Returns FC error if the array does not exist.
;;;  - Note: Care should be taken when working with an array, because the addresses of arrays change whenever a new simple variable is assigned.
;;; ### EXAMPLES:
;;; ` A=44:COPY &A,&B,4:PRINT B `
;;; > Assigns A a value, copies its contents from the address of A to a new address for B, and prints the value at that address.
;;;
;;; ` DIM A(9):PRINT &*A `
;;; > Prints start address of array A() definition.
;;;
;;; ` PRINT PEEK(&A$) `
;;; > Prints the length of A$.
;;;
;;; ` PRINT DEEK(&A$+2) `
;;; > Prints the address of the text for A$.
;;;
;;; ` PRINT &&A$ `
;;; > Also prints the address of the text for A$.
;;;
;-------------------------------------------------------------------------
; Get Variable Pointer
; On Entry, HL points to first character of Variable Name
; On Exit, HL points to character after Variable Name/Array Element
GET_VARPTR:
    rst     CHRGET                ; Skip &
    cp      MULTK                 ; Check Next Character
    push    af                    ; Save Character and Flags
    jr      nz,.not_multk         ; If '*'
    rst     CHRGET                ;   Skip It
    ld      a,1                   ;   Evaluate Array Name
    jr      .get_ptr              ;  
.not_multk:
    cp      '&'                   ; 
    jr      nz,.not_ampersand     ; Else If '&'
    rst     CHRGET                ;   Skip It
.not_ampersand:
    xor     a
.get_ptr
    ld      (SUBFLG),a            ; Evaluate Array Indexes
    call    PTRGET                ; Get Pointer
    jp      nz,FCERR              ; FC Error if Not There
    ld      (SUBFLG),a            ; Reset Sub Flag
    pop     af                    ; Get Back Character after &
    jr      nz,.not_array_ptr     ; If it was *
    dec     bc                    ;   Back Up to Beginning
    dec     bc                    ;   of Array Definition
    jr      FLOAT_BC              ;   and Float It
.not_array_ptr
    cp      '&'                   ; If it wasn't &
    jr      nz,FLOAT_DE           ;   Float It
    call    CHKSTR                ; Make Sure it was a String
    ex      de,hl                 ; HL = String Descriptor
    inc     hl
    inc     hl                    ; Move to Text Pointer
    ld      c,(hl)
    inc     hl                    ; BC = Text Address
    ld      b,(hl)                
    ex      de,hl                 ; HL = Text Pointer

FLOAT_BC:
    ld      d,b                   ;  Copy into DE
    ld      e,c                   ;  
FLOAT_DE:
    push    hl
    xor     a                     ; Set HO to 0
    ld      (VALTYP),a            ; Force Return Type to numeric
    ld      b,$98                 ; Exponent = 2^24
    call    FLOATR                ; Float It
    pop     hl
    ret

;---------------------------------------------------------------------
;                 Enhanced BASIC Commands and Functions 
;---------------------------------------------------------------------
; ST_COPY
    include "enhanced.asm"


;---------------------------------------------------------------------
;                 Extended BASIC Commands and Functions 
;---------------------------------------------------------------------
; DEFX
; FNDOEX
; ATN1
; ONGOTX
; ERRORX
; FN_ERR
; CLEARX
; SCRTCX
    include "extbasic.asm"

;---------------------------------------------------------------------
;                 Extended BASIC Graphics Commands 
;---------------------------------------------------------------------
; ST_PRESET
; ST_PSET
; ST_LINE
; ST_CIRCLE
; ST_DRAW
; ST_GET
; ST_PUT
    include "extgraph.asm"

E0_END:   
E0_SIZE = E0_END - $E000

; fill with $FF to end of ROM

     assert !($FFFF<$)   ; ROM full!

     dc $FFFF-$+1,$FF

     end
