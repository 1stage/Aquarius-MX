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
; For use with the Aquarius MX and Micro Expander. 
;
; Incudes commands from BLBasic by Martin Steenoven, as well as commands from
; Aquarius Extended BASIC (MS 8K BASIC), and other BASIC derivatives.
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
;scrn_flag equ 1    ; enable screen save in lite debugger
;softclock equ 1    ; using software clock
;debug    equ 1    ; debugging our code. Undefine for release version!
;
; See readme.md for full list of Commands and Functions
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


; This will eventually be a Fixed Address Assignment
RTC_SHADOW = $37F0        ; Real Time Clock Shadow Registers, 10 bytes. 
                        
; Temporary USB BASIC system variables 
DTM_BUFFER = $3851      ; RTC & DTM DateTime Buffer, 8 bytes
;   FILNAM,FILNAF,INSYNC,CLFLAG: $3851-$385E. 14 bytes
DTM_STRING = $38E6      ; DTM String Buffer, 19 bytes
;   FACHO,FAC,FBUFFR,RESHO,RESMO,RESLO: $38E6-$38F8, 19 bytes

;; IMPLEMENTING REAL TIME CLOCK IN EMULATORS
;; The will be a read from memory location $3821 whenever the RTC is accessed
;; If $3821 contains $7F, the RTC is being written to and the following
;; bytea contain the date to be written.
;; If $3821 contains any other value, the RTC was just read and $3821 should
;; be filled with $FF and the following bytes with the current date/time.
;; See the RTC driver file for the date/time structure.

  ifdef softrom
RAMEND = $8000           ; we are in RAM, 16k expansion RAM available
  else
RAMEND = $C000           ; we are in ROM, 32k expansion RAM available
  endif

path.size = 37           ; length of file path buffer

; high RAM usage
 STRUCTURE _sysvars,0
    STRUCT _retypbuf,74         ; BASIC command line history
    STRUCT _pathname,path.size  ; file path eg. "/root/subdir1/subdir2",0
    STRUCT _filename,13         ; USB file name 1-11 chars + '.', NULL
    BYTE   _doserror            ; file type BASIC/array/binary/etc.
    WORD   _binstart            ; binary file load/save address
    WORD   _binlen              ; binary file length
    BYTE   _dosflags            ; DOS flags
    BYTE   _sysflags            ; system flags
    WORD   _errlin              ; LINE NUMBER WHERE LAST ERROR OCCURED.
    BYTE   _errflg              ; USED TO SAVE THE ERROR NUMBER SO EDIT CAN BE
    BYTE   _oneflg              ; ONEFLG=1 IF WERE ARE EXECUTING AN ERROR TRAP ROUTINE, OTHERWISE 0
    WORD   _onelin              ; THE pointer to the LINE TO GOTO WHEN AN ERROR OCCURS

 ENDSTRUCT _sysvars

SysVars  = RAMEND-_sysvars.size
ReTypBuf = sysvars+_retypbuf
PathName = sysvars+_pathname
FileName = sysvars+_filename
DosError = sysvars+_doserror
BinStart = sysvars+_binstart
BinLen   = sysvars+_binlen
DosFlags = sysvars+_dosflags
SysFlags = sysvars+_sysflags
ERRLIN   = sysvars+_errlin
ERRFLG   = sysvars+_errflg
ONEFLG   = sysvars+_oneflg
ONELIN   = sysvars+_onelin

ifdef debug
  pathname = $3006  ; store path in top line of screen
endif

;system flags
SF_NTSC  = 1       ; 1 = NTSC, 0 = PAL
SF_RETYP = 1       ; 1 = CTRL-O is retype
SF_DEBUG = 7       ; 1 = Debugger available


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
SYS_reserved1     jp  break
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
WIN_INPUTLINE     jp  InputLine
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


;---------------------------------------------------------------------
;                     windowed text functions
;---------------------------------------------------------------------
   include "windows.asm"

;---------------------------------------------------------------------
;                          debugger
;---------------------------------------------------------------------
   include "debug.asm"

;---------------------------------------------------------------------
;                         ROM loader
;---------------------------------------------------------------------
   include "load_rom.asm"

;---------------------------------------------------------------------
;                     disk file selector
;---------------------------------------------------------------------
   include "filerequest.asm"
   
;---------------------------------------------------------------------
;                RTC Driver for Dallas DS1244
;---------------------------------------------------------------------
    include "dtm_lib.asm"
    include "ds1244rtc.asm" 

;---------------------------------------------------------------------
;                       string functions
;---------------------------------------------------------------------
    include "strings.asm"

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
;
; init debugger
    ld      hl,vars
    ld      bc,v.size
.clrbugmem:
    ld      (hl),0             ; clear all debugger variables
    inc     hl
    dec     bc
    ld      a,b
    or      c
    jr      nz,.clrbugmem
    ld      a,$C3
    ld      (USRPOK),a
    ld      HL,0
    ld      (USRADD),HL       ; set system RST $38 vector
;
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
    
; show splash screen (Boot menu)
SPLASH:
    push    bc                 ; Save Ctrl-C flag
    call    usb__root          ; root directory
    ld      a,CYAN
    call    clearscreen
    ld      b,40
    ld      hl,$3000
TOPLINE: 
    ld      (hl),' '
    set     2,h
    ld      (hl),WHITE*16+BLACK ; black border, white on black chars in top line
    res     2,h
    inc     hl
    djnz    TOPLINE
REDRAW:
    ld      ix,BootbdrWindow
    call    OpenWindow
    ld      ix,bootwindow
    call    OpenWindow
    pop     bc                ; Get Ctrl-C Flag
    push    bc
    call    BootMenuPrint
    
; outer loop for boot option key so date time display gets updated
SPLLOOP:
    call    SPL_DATETIME       ; Print DateTime at the bottom of the screen
; wait for Boot option key
    ld      b,0                ; Call the clock update every 256 loops
SPLKEY:                        ;
    call    Key_Check          ;
    jr      nz,SPLGOTKEY       ; We got a key pressed
    djnz    SPLKEY             ; loop until c=0
    jr      SPLLOOP
SPLGOTKEY:
  ifndef softrom
    cp      "1"                ; '1' = load ROM
    jr      z,LoadROM
  endif
    cp      "2"                ; '2' = debugger
    jr      z, DEBUG
    cp      $0d                ; RTN = cold boot
    jp      z, COLDBOOT
    and     $DF                ; Convert letters to upper-case
    cp      "A"                ; 'A' = About screen
    jr      z, AboutSCR        
    pop     bc                 ; Get Ctrl-C Flag
    push    bc
    and     c                  ;  Make A=0 if Ctrl-C disabled
    cp      $03                ;  ^C = warm boot
    jp      z, WARMBOOT
    jr      SPLLOOP

DEBUG:
    call    InitBreak          ; set RST $38 vector to Trace Break
    ld      hl,0               ; HL = 0 (no BASIC text)
    call    ST_DEBUG           ; invoke Debugger
    JR      SPLASH

LoadROM:
    call    Load_ROM           ; ROM loader
    JR      SPLASH

; About/Credits window

AboutSCR:
    ld      ix,AboutBdrWindow           ; Draw outer window
    call    OpenWindow
    ld      ix,AboutWindow              ; Draw smaller inset window
    call    OpenWindow
    ld      hl,AboutText
    ;call    OpenWindow
    call    WinPrtStr
    call    Wait_key
    JP      REDRAW

AboutBdrWindow:
    db   (1<<WA_BORDER)|(1<<WA_TITLE)|(1<<WA_CENTER) ; attributes
    db   (BLUE*16)+CYAN               ; text colors,   (FG * 16) + BG
    db   (DKBLUE*16)+CYAN             ; border colors, (FG * 16) + BG
    db   2,3,36,20                    ; x,y,w,h
    dw   AboutBdrTitle                ; title

AboutWindow:
    db   0                            ; attributes
    db   (BLUE*16)+CYAN               ; text colors,   (FG * 16) + BG
    db   (DKBLUE*16)+CYAN             ; border colors, (FG * 16) + BG
    db   4,4,32,18                    ; x,y,w,h
    dw   0                            ; title

AboutBdrTitle:
    db     " About MX BASIC ",0

AboutText:
    db     CR,CR,CR
    db     "      Version - ",VERSION+'0','.',REVISION+'0',CR,CR
    db     " Release Date - Alpha 2023-05-19",CR,CR                       ; Can we parameterize this later?
    db     " ROM Dev Team - Curtis F Kaylor",CR
    db     "                Mack Wharton",CR
    db     "                Sean Harrington",CR
    db     CR
    db     "Original Code - Bruce Abbott",CR
    db     CR
    db     "     AquaLite - Richard Chandler",CR
    db     CR
    db     "Aquarius Draw - Matt Pilz",CR
    db     CR
    db     " github.com/1stage/Aquarius-MX",CR
    db     0

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
    ld      hl,HOOK            ; RST $30 Vector (our UDF service routine)
    ld      (UDFADDR),hl       ; store in UDF vector
    call    SCRTCH             ; ST_NEW2 - NEW without syntax check
    call    SHOWCOPYRIGHT      ; Show our copyright message
    xor     a
    jp      READY              ; Jump to OKMAIN (BASIC command line)


;---------------------------------------------------------------------
;                      USB Disk Driver
;---------------------------------------------------------------------
    include "ch376.asm"

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

; boot outer window with border
BootBdrWindow:
    db      (1<<WA_BORDER)|(1<<WA_TITLE)|(1<<WA_CENTER) ; attributes
    db      CYAN                   ; text colors
    db      CYAN                   ; border colors
    db      2,3,36,20              ; x,y,w,h
    dw      bootWinTitle           ; Titlebar text

; boot window text inside border
BootWindow:
    db     0
    db     CYAN
    db     CYAN
    db     9,5,26,18
    dw     0

BootWinTitle:
    db     " Aquarius MX "
StrBasicVersion:
    db     "BASIC "
    db     "v",VERSION+'0','.',REVISION+'0',' ',0

BootMenuPrint:
    call    WinPrtMsg
    db      CR,CR
    db      "      1. "
  ifdef softrom
    db      "(disabled)"
  else  
    db      "Load ROM"
  endif 
    db      CR,CR,CR
    db      "      2. Debug",CR
    db      CR,CR,CR,CR                      ; Move down a few rows
    db      "    <RTN> USB BASIC"
    db      CR,0
    or      c                             ; If Ctrl-C Flag is 0
    jr      z,.about                      ;   Skip Ctrl-C Message
    call    WinPrtMsg
    db      CR," <CTRL-C> Warm Start",CR,0
.about
    call    WinPrtMsg
    db      CR
    db      "      <A> About...",CR
    db      CR,CR,0
    ret

;------------------------------------------------------
;             UDF Hook Service Routine
;------------------------------------------------------
; This address is stored at $3806-7, and is called by
; every RST $30. It allows us to hook into the system
; ROM in several places (anywhere a RST $30 is located).

HOOK: 
    ex      (sp), hl            ; save HL and get address of byte after RST $30
    push    af                  ; save AF
    ld      a,(hl)              ; A = byte (RST $30 parameter)
    inc     hl                  ; skip over byte after RST $30
    push    hl                  ; push return address (code after RST $30,xx)
    ld      hl,UDFLIST          ; HL = RST 30 parameter table
    push    bc
    ld      bc,UDF_JMP-UDFLIST+1 ; number of UDF parameters
    cpir                        ; find paramater in list
    ld      a,c                 ; A = parameter number in list
    pop     bc
    add     a,a                 ; A * 2 to index WORD size vectors
    ld      hl,UDF_JMP          ; HL = Jump vector table
do_jump:
    add     a,l
    ld      l,a
    ld      a,$00
    adc     a,h
    ld      h,a                 ; HL += vector number
    ld      a,(hl)
    inc     hl
    ld      h,(hl)              ; get vector address
    ld      l,a
    jp      (hl)                ; and jump to it
                                ; will return to HOOKEND

; End of hook
HOOKEND:
    pop     hl                 ; get return address
    pop     af                 ; restore AF
    ex      (sp),hl            ; restore HL and set return address
    ret                        ; return to code after RST $30,xx


; UDF parameter table
; List of RST $30,xx hooks that we are monitoring.
; NOTE: order is reverse of UDF jumps!

UDFLIST:    ;xx     index caller    @addr  performing function:-
    db      $00     ;15   ERROR     $03DB  Display Error and stop program
    db      $0C     ;14   SCRTCH    $0BBE  NEW statement
    db      $0B     ;13   CLEAR     $0CCD  CLEAR statement
    db      $19     ;12   ONGOTO    $0780  ON statement
    db      $10     ;11   FNDOER    $0B40  FNxx() call
    db      $0F     ;10   DEF       $0B3B  DEF statement
    db      $0E     ; 9   ATN       $1985  ATN() function
    db      $09     ; 8   EVAL      $09FD  evaluate number or string
    db      $18     ; 7   RUN       $06be  starting BASIC program
    db      $17     ; 6   NEXTSTMT  $064b  interpreting next BASIC statement
    db      $16     ; 5   PEXPAND   $0598  expanding a token
    db      $0a     ; 4   REPLCMD   $0536  converting keyword to token
    db      $1b     ; 3   FUNCTIONS $0a5f  executing a function
    db      $05     ; 2   LINKLINES $0485  updating nextline pointers in BASIC prog
    db      $02     ; 1   READY     $0402  BASIC command line (immediate mode)

; UDF parameter Jump table

UDF_JMP:
    dw      HOOKEND            ; 0 parameter not found in list
    dw      AQMAIN             ; 1 replacement immediate mode
    dw      LINKLINES          ; 2 update BASIC nextline pointers (returns to AQMAIN)
    dw      AQFUNCTION         ; 3 execute AquBASIC function
    dw      REPLCMD            ; 4 replace keyword with token
    dw      PEXPAND            ; 5 expand token to keyword
    dw      NEXTSTMT           ; 6 execute next BASIC statement
    dw      RUNPROG            ; 7 run program
    dw      EVAL_EXT           ; 8 evaluate hexadecimal number
    dw      ATN1               ; 9 ATN() function
    dw      DEFX               ;10 DEF statement
    dw      FNDOEX             ;11 FNxx() call
    dw      ONGOTX             ;12 ON ERROR... hook
    dw      CLEARX             ;13 extend CLEAR statement 
    dw      SCRTCX             ;14 Clear runtime variables
    dw      ERRORX             ;15 Trap BASIC Error (from ON ERROR GOTO...)

; Our Commands and Functions
;
; - New commands get added to the TOP of the commands list,
;   and the BTOKEN value DECREMENTS as commands are added.
;   They also get added at the TOP of the TBLJMPS list.
;
BTOKEN       equ $d2                ; our first token number
TBLCMDS:
; Commands list
    db      $80 + 'D', "OKE"        ; $d2 - Double Poke
    db      $80 + 'S', "DTM"        ; $d3 - Set DateTime
    db      $80 + 'E', "DIT"        ; $d4 - Edit BASIC line (advanced editor)
    db      $80 + 'C', "LS"         ; $d5 - Clear screen
    db      $80 + 'L', "OCATE"      ; $d6 - Move cursor to position on screen
    db      $80 + 'O', "UT"         ; $d7 - Read data from serial device
    db      $80 + 'P', "SG"         ; $d8 - Send data to Programmable Sound Generator
    db      $80 + 'D', "EBUG"       ; $d9 - Run debugger
    db      $80 + 'C', "ALL"        ; $da - Call routine in memory
    db      $80 + 'L', "OAD"        ; $db - Load file
    db      $80 + 'S', "AVE"        ; $dc - Save file
    db      $80 + 'D', "IR"         ; $dd - Directory, full listing
    db      $80 + 'C', "AT"         ; $de - Catalog, brief directory listing
    db      $80 + 'D', "EL"         ; $df - Delete file/folder (previously KILL)
    db      $80 + 'C', "D"          ; $e0 - Change directory
SDTMTK  = $D3
CDTK    = $E0

; - New functions get added to the END of the functions list.
;   They also get added at the END of the TBLFNJP list.
;
; Functions list

    db      $80 + 'I', "N"          ; $e1 - Input function
    db      $80 + 'J', "OY"         ; $e2 - Joystick function
    db      $80 + 'H', "EX$"        ; $e3 - Hex value function
    db      $80 + 'V', "ER"         ; $e4 - USB BASIC ROM Version function
    db      $80 + 'D', "TM$"        ; $e5 - GET/SET DateTime function
    db      $80 + 'D', "EC"         ; $e6 - Decimal value function
    db      $80 + 'K', "EY"         ; $e7 - Key function
    db      $80 + 'D', "EEK"        ; $e8 - Double Peek function
    db      $80 + 'E', "RR"         ; $e9 - Error Number (and Line?)
    db      $80                     ; End of table marker
ERRTK =  $E9

TBLJMPS:
    dw      ST_DOKE
    dw      ST_SDTM
    dw      ST_EDIT
    dw      ST_CLS
    dw      ST_LOCATE
    dw      ST_OUT
    dw      ST_PSG
    dw      ST_DEBUG
    dw      ST_CALL
    dw      ST_LOAD
    dw      ST_SAVE
    dw      ST_DIR
    dw      ST_CAT
    dw      ST_DEL
    dw      ST_CD
TBLJEND:

BCOUNT equ (TBLJEND-TBLJMPS)/2    ; number of commands

TBLFNJP:
    dw      FN_IN
    dw      FN_JOY
    dw      FN_HEX
    dw      FN_VER
    dw      FN_DTM
    dw      FN_DEC
    dw      FN_KEY
    dw      FN_DEEK
    dw      FN_ERR
TBLFEND:

FCOUNT equ (TBLFEND-TBLFNJP)/2    ; number of functions

firstf equ BTOKEN+BCOUNT          ; token number of first function in table
lastf  equ firstf+FCOUNT-1        ; token number of last function in table


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
    pop     af                  ; clean up stack
    pop     af                  ; restore AF
    pop     hl                  ; restore HL

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
    ld      b,BUFLEN            ; 74 bytes including terminator
    call    EDITLINE            ; Input a line from keyboard.
    ld      hl,SysFlags
    RES     SF_RETYP,(HL)       ; CTRL-R inactive
ENTERLINE:
    ld      hl,BUF-1
    jr      c,immediate         ; If c then discard line
    rst     $10                 ; get next char (1st character in line buffer)
    inc     a
    dec     a                   ; set z flag if A = 0
    jr      z,immediate         ; If nothing on line then loop back to immediate mode
    push    hl
    ld      de,ReTypBuf
    ld      bc,BUFLEN           ; save line in history buffer
    ldir
    pop     hl
    jp      $0424               ; back to system ROM

; --- linking BASIC lines ---
; Redirected here so we can regain control of immediate mode
; Comes from $0485 via CALLUDF $05

LINKLINES:
    pop     af                 ; clean up stack
    pop     af                 ; restore AF
    pop     hl                 ; restore HL
    inc     hl
    ex      de,hl              ; DE = start of BASIC program
l0489:
    ld      h,d
    ld      l,e                ; HL = DE
    ld      a,(hl)
    inc     hl                 ; get address of next line
    or      (hl)
    jr      z,immediate        ; if next line = 0 then done so return to immediate mode
    inc     hl
    inc     hl                 ; skip line number
    inc     hl
    xor     a
l0495:
    cp      (hl)               ; search for next null byte (end of line)
    inc     hl
    jr      nz,l0495
    ex      de,hl              ; HL = current line, DE = next line
    ld      (hl),e
    inc     hl                 ; update address of next line
    ld      (hl),d
    jr      l0489              ; next line


;-------------------------------------
;        AquBASIC Function
;-------------------------------------
; called from $0a5f by RST $30,$1b

AQFUNCTION:
    pop     bc                  ; get return address
    pop     af
    pop     hl
    push    bc                  ; push return address back on stack
    cp      PEEKTK-$B2          ; If PEEK Token
    jp      z,FN_PEEK           ;   Do Extended PEEK
    cp      (firstf-$B2)        ; ($B2 = first system BASIC function token)
    ret     c                   ; return if function number below ours
    cp      (lastf-$B2+1)
    ret     nc                  ; return if function number above ours
    sub     (firstf-$B2)
    add     a,a                 ; index = A * 2
    push    hl
    ld      hl,TBLFNJP          ; function address table
    jp      do_jump             ; JP to our function



;-------------------------------------
;         Replace Command
;-------------------------------------
; Called from $0536 by RST $30,$0a
; Replaces keyword with token.

REPLCMD:
     ld      a,b                ; A = current index
     cp      $cb                ; if < $CB then keyword was found in BASIC table
     jp      nz,HOOKEND         ;    so return
     pop     bc                 ; get return address from stack
     pop     af                 ; restore AF
     pop     hl                 ; restore HL
     push    bc                 ; put return address back onto stack
     ex      de,hl              ; HL = Line buffer
     ld      de,TBLCMDS-1       ; DE = our keyword table
     ld      b,BTOKEN-1         ; B = our first token
     jp      $04f9              ; continue searching using our keyword table

;-------------------------------------
;             PEXPAND
;-------------------------------------
; Called from $0598 by RST $30,$16
; Expand token to keyword

PEXPAND:
    pop     de
    pop     af                  ; restore AF (token)
    pop     hl                  ; restore HL (BASIC text)
    cp      BTOKEN              ; is it one of our tokens?
    jr      nc,PEXPBAB          ; yes, expand it
    push    de
    ret                         ; no, return to system for expansion

PEXPBAB:
    sub     BTOKEN - 1
    ld      c,a                 ; C = offset to AquBASIC command
    ld      de,TBLCMDS          ; DE = table of AquBASIC command names
    jp      $05a8               ; Print keyword indexed by C


;-------------------------------------
;            NEXTSTMT
;-------------------------------------
; Called from $064b by RST 30
; with parameter $17

NEXTSTMT:
    pop     bc                  ; BC = return address
    pop     af                  ; AF = token - $80, flags
    pop     hl                  ; HL = text
    jr      nc,BASTMT           ; if NC then process BASIC statement
    push    af                  ; Save Flags
    cp      COPYTK-$80          ; If POKE Token
    jp      z,ST_COPY           ;   Do Extended POKE
    cp      POKETK-$80          ; If POKE Token
    jp      z,ST_POKE           ;   Do Extended POKE
    pop     af                  ; Else
    push    bc                  ;   Return to Standard Dispatch Routine
    ret                        

BASTMT:
    sub     (BTOKEN)-$80
    jp      c,$03c4             ; SN error if < our 1st BASIC command token
    cp      BCOUNT              ; Count number of commands
    jp      nc,$03c4            ; SN error if > out last BASIC command token
    rlca                        ; A*2 indexing WORDs
    ld      c,a
    ld      b,$00               ; BC = index
    ex      de,hl
    ld      hl,TBLJMPS          ; HL = our command jump table
    jp      $0665               ; Continue with NEXTSTMT

;----------------------------------------------------------------------------
;;; ## RUN ##
;;; Loads and runs BASIC programs (*.CAQ or *.BAS)
;;; ### FORMAT: ###
;;;  - RUN < filename >
;;;    - Action: Loads program into memory and runs it.
;;;      - If executed from within another BASIC program, the original program is cleared (same as NEW command) and the new program is loaded and excuted in it's place.
;;;      - Wildcards and paths cannot be used.
;;; ### EXAMPLES: ###
;;; ` RUN "RUN-ME.BAS" `
;;; > Loads and runs the file named `RUN-ME.BAS`. Note the program must exist within the current folder path.
;;;
;;; ` 10 PRINT "Loading Program..." `
;;;
;;; ` 20 RUN "NEXTPRG.CAQ" `
;;; > Displays "Loading Program..." on screen and then immediately loads and runs the `NEXTPRG.CAQ` program.
;----------------------------------------------------------------------------

RUNPROG:
    call    CLNERR             ; Clear Error Trapping Variables
    pop     af                 ; clean up stack
    pop     af                 ; restore AF
    pop     hl                 ; restore HL
    jp      z,RUNC             ; if no argument then RUN from 1st line
    push    hl
    call    FRMEVL             ; get argument type
    pop     hl
    ld      a,(VALTYP)
    dec     a                  ; 0 = string
    jr      z,_run_file
    call    CLEARC             ; else line number so init BASIC program and
    ld      bc,$062c
    jp      $06db              ;    GOTO line number
_run_file:
    call    dos__getfilename   ; convert filename, store in FileName
    push    hl                 ; save BASIC text pointer
    ld      hl,FileName
    call    usb__open_read     ; try to open file
    jr      z,.load_run
    cp      CH376_ERR_MISS_FILE ; error = file not found?
    jp      nz,.nofile         ; no, break
    ld      b,9                ; max 9 chars in name (including '.' or NULL)
.instr:
    ld      a,(hl)             ; get next name char
    inc     hl
    cp      '.'                ; if already has '.' then cannot extend
    jp      z,.nofile
    cp      ' '
    jr      z,.extend          ; until SPACE or NULL
    or      a
    jr      z,.extend
    djnz    .instr
.nofile:
    ld      hl,.nofile_msg
    call    STROUT
    pop     hl                 ; restore BASIC text pointer
.extend:
    dec     hl
    push    hl                 ; save extn address
    ld      de,.bas_extn
    call    strcat             ; append ".BAS"
    ld      hl,FileName
    call    usb__open_read     ; try to open file
    pop     hl                 ; restore extn address
    jr      z,.load_run
    cp      CH376_ERR_MISS_FILE ; error = file not found?
    jp      nz,.nofile         ; no, break
    ld      de,.caq_extn
    ld      (hl),0             ; remove extn
    call    strcat             ; append ".BIN"
.load_run:
    pop     hl                 ; restore BASIC text pointer
    call    ST_LOADFILE        ; load file from disk, name in FileName
    jp      RUNC               ; run loaded BASIC program

.bas_extn:
    db     ".BAS",0
.caq_extn:
    db     ".CAQ",0

.nofile_msg:
    db     "file not found",$0D,$0A,0


;********************************************************************
;                   Command Entry Points
;********************************************************************

ST_reserved:
    ret

;----------------------------------------------------------------------------
;;; ## DOKE ##
;;; Writes 16 bit word(s) to memory location(s), aka "Double Poke"
;;; ### FORMAT: ###
;;;  - DOKE < address >, < word >, [, <word> ...]
;;;    - Action: Writes < word > to memory starting at < address >.
;;; ### EXAMPLES: ###
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
;;; ## POKE (Extended) ##
;;; Writes byte(s) to memory location(s)
;;; ### FORMAT: ###
;;;  - POKE < address >, [ < byte or string >, < byte or string >... ] [,STEP count, < byte or string >...]
;;;    - Action: Writes < byte or string > to < address >, followed by < address > STEP counts away...
;;;  - POKE < address > TO < address >, < byte >
;;;    - Action: Writes < byte > to memory from < address > TO < address >.
;;; ### EXAMPLES: ###
;;; ` POKE $3000+500,64 `
;;; > Display `@` at screen center
;;;
;;; ` POKE 12347,7,6 `
;;; > Display double-ended arrow
;;;
;;; ` POKE 12366,$13,STEP 39,$14 `
;;; > Display standing person "sprite"
;;;
;;; ` POKE 12329,$D4,STEP 1023,$10 `
;;; > Display red heart on black background
;;;
;;; ` POKE $3009,T$,5,C$ `
;;; > Display T$, copyright, C$ on row 0
;;;
;;; ` POKE $3400 TO $3427,5 `
;;; > Set border color to magenta
;;;
;;; ` POKE $3028 TO $33E7,$86 `
;;; > Fill screen with checkerboard character
;----------------------------------------------------------------------------

ST_POKE:   
    pop     af              ; Discard Saved Token, Flags
    rst     CHRGET          ; Skip POKE Token
    call    GETADR          ; Get <address>
    ld      a,(hl)          ; If next character 
    cp      TOTK            ; is TO Token 
    jr      z,.poke_fill    ;   Do Fill
    SYNCHK  ','             ; Require a Comma
.poke_save:
    ld      b,d             ; Save Poke Address 
    ld      c,e             
.poke_loop:
    cp      STEPTK          ; If STEP Token
    jr      z,.poke_step     ;   Do STEP
    push    de              ; Save Address  
    call    FRMEVL          ; Evaluate Poke Argument
    ld      a,(VALTYP)      ; 
    or      a               ; If It's a String
    jr      nz,.poke_string ;   Go Poke It
    call    CONINT          ; Convert to <byte> in A
    pop     de              ; Restore Address
    ld      (de),a          ; Write Byte to Memory
    ld      b,d             ; Save Last Poke Address
    ld      c,e             
.poke_comma:
    ld      a,(hl)          ; If Next Character
    cp      ','             ; is Not a Comma
    ret     nz              ;   We are done
    rst     CHRGET          ; Skip Comma
    inc     de              ; Bump Poke Address
    jr      .poke_loop      ; Do the Next Byte

.poke_step:
    rst     CHRGET          ; Skip STEP 
    push    bc              ; Save Last Address
    call    GETINT          ; Get Step Amount in DE
    ex      (sp),hl         ; HL=Poke Address, Stack=Text Pointer
    add     hl,de           ; Add Step to Address
    ld      d,h             ; Now DE contains
    ld      e,l             ;   new Address
    pop     hl              ; Get Text Pointer back
    SYNCHK  ','             ; Require a Comma
    jr      .poke_save

.poke_string:
    ex      (sp),hl         ; HL=Poke Address, Stack=Text Pointer
    push    hl              ; Stack=Poke Address, Text Pointer
    push    hl              ; Stack=Poke Address, Poke Address, Text Pointer
    call    STRLENADR       ; Get String Length in BC, Address in HL
    pop     de              ; Get Address Back
    jr      z,.poke_skip    ; If Length isn't 0
    ldir                    ; Copy String to Memory
.poke_skip:
    dec     de              ; Compensate for INC DE after comma check
    pop     bc              ; Get Starting Poke Address Back
    pop     hl              ; Get Text Pointer Back
    jr      .poke_comma     ; and check for a Comma

.poke_fill:
    rst     CHRGET          ; Skip TO Token
    push    de              ; Stack = Start Address
    call    GETADR          ; Get to Address
    push    de              ; Stack = End Address, Start Address
    SYNCHK  ','             ; Require a Comma
    call    GETBYT          ; 
    ld      c,a             ; Get <byte> in C
    pop     de              
    inc     de              ; DE = End Address + 1
    ex      (sp),hl         ; HL = Start Address, Stack = Text Pointer
.fill_loop:
    ld      (hl),c          ; Store Byte
    inc     hl              ; Bump Poke Address
    rst     COMPAR          
    jr      c,.fill_loop    ; Loop if < DE
    pop     hl              ; Restore Text Pointer
    ret

STRLENADR:
    call    FRESTR          ; Free up Temp String, Get Length in BC, Address in HL
    inc     hl              ; Skip String Descriptor length byte
    inc     hl              ; Set Address of String Text into HL
    ld      a,(hl)          ;
    inc     hl
    ld      h,(hl)
    ld      l,a
    ld      b,0             ; BC = String Length
    ld      a,c             ; Put length in A
    or      a               ; and Set Flags
    ret

;----------------------------------------------------------------------------
;;; ## CLS (Extended) ##
;;; Clear Screen
;;; ### FORMAT: ###
;;;  - CLS [ < colors > ]
;;;    - Action: Clears the screen. The optional parameter < colors > is a number between 0 and 255 that specifies the new foreground and background color combination using this formula with the values below:  (FG * 16) + BG. The default combination is 6 (BLACK on CYAN):
;;; >
;;;     0 BLACK      4 BLUE       8  GREY        12 LTYELLOW
;;;     1 RED        5 MAGENTA    9  DKCYAN      13 DKGREEN 
;;;     2 GREEN      6 CYAN       10 DKMAGENTA   14 DKRED    
;;;     3 YELLOW     7 WHITE      11 DKBLUE      15 DKGREY   
;;;
;;;    - The colors value can be represented as a two-digit hexadecimal number (preceded by a $ as a hex number designator) where the left digit is the foreground color and the right digit is the background color, using the following chart:
;;; >
;;;     0 BLACK      4 BLUE        8 GREY        C LTYELLOW
;;;     1 RED        5 MAGENTA     9 DKCYAN      D DKGREEN
;;;     2 GREEN      6 CYAN        A DKMAGENTA   E DKRED
;;;     3 YELLOW     7 WHITE       B DKBLUE      F DKGREY
;;;
;;;    - Warning: If the foreground and background colors are the same, typed and and PRINTed text will be invisible.
;;;    - Advanced: Unlike PRINT CHR$(11), CLS does not clear memory locations 13288 - 13313 ($33E8 - $33FF) and 14312 - 14355 ($37E8 - $37FF).
;;; ### EXAMPLES: ###
;;; ` CLS `
;;; > Clear screen with default colors
;;;
;;; ` CLS 7 `
;;; > Clear screen - black text on white background
;;;
;;; ` CLS $30 `
;;; > Clear screen - yellow text on black background
;;;
;;; ` CLS F*16+B `
;;; > Clear screen - text color F, background color B (using BASIC variables)
;----------------------------------------------------------------------------

ST_CLS:
    ld      a,CYAN        ; default to black on cyan
    jr      z,do_cls      ; no parameters, use default
    call    GETBYT        ; get parameter as byte in E
    ld      a,e
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

;----------------------------------------------------------------------------
;;; ## OUT ##
;;; Write to Z80 I/O Port
;;; ### FORMAT: ###
;;;  - OUT < address >,< byte >
;;;    - Action: Writes < byte > to the I/O port specified by LSB of < address >.
;;;    - Advanced: During the write, < address > is put on the Z80 address bus.
;;; ### EXAMPLES: ###
;;; ` OUT 246, 12 `
;;; > Send a value of 12 to the SOUND chip
;;;
;;; ` 10 X=14:OUT $FC, X `
;;; > Send a value of 14 to the Cassette sound port
;----------------------------------------------------------------------------

ST_OUT:
    call    GETADR              ; get/evaluate port
    push    de                  ; stored to be used in BC
    rst     $08                 ; Compare RAM byte with following byte
    db      $2c                 ; character ',' byte used by RST 08
    call    GETBYT              ; get/evaluate data
    pop     bc                  ; BC = port
    out     (c),a               ; out data to port
    ret

;----------------------------------------------------------------------------
;;; ## LOCATE ##
;;; Move the cursor to a specific column and row on the screen
;;; ### FORMAT: ###
;;;  - LOCATE < column >,< row >
;;;    - Action: Moves the cursor to the specified spot on the screen
;;;      - Column can be 1-38 (leftmost and rightmost columns cannot be used)
;;;      - Row can be 1-23 (topmost and bottommost rows cannot be used)
;;; ### EXAMPLES: ###
;;; ` LOCATE 1, 1:print"Hello" `
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
;;; ## PSG ##
;;; Write to Programmable Sound Generator(s)
;;; ### FORMAT: ###
;;;  - PSG register, value [, ...]
;;;    - Action: Writes a pair of values to either PSG1 or PSG2
;;;      - registers  0-15 go to PSG1 at $F7 (register) and $F6 (data)
;;;      - registers 16-31 go to PSG2 at $F9 (register) and $F8 (data)
;;; ### EXAMPLES: ###
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
;----------------------------------------------------------------------------
;
; Original Single PSG Code - Restore as needed (Remove after release!!!)
;
; ST_PSG:
;     cp      $00
;     jp      z,$03d6         ; MO error if no args
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
    jp      z,$03d6             ; MO error if no args
psgloop:
    call    GETBYT              ; Get/evaluate register
    cp      16                  ; Compare to a 16 offset
    jr      nc, psg2            ; If >= 16 send to PSG2
    out     (PSG1ADDR),a        ; Otherwise, set the PSG1 register
    rst     $08                 ; Next character must be ','
    db      COMMA               ; ','
    call    GETBYT              ; Get/evaluate value
    out     (PSG1DATA),a     ; Send data to the selected PSG1 register
check_comma:
    ld      a,(hl)              ; Get next character on command line
    cp      COMMA               ; Compare with ','
    ret     nz                  ; No comma = no more parameters -> return
    inc     hl                  ; Next character on command line
    jr      psgloop             ; Parse next register & value
psg2:
    sub     16                  ; Reduce shifted registers into regular range for PSG2
    out     (PSG2ADDR),a        ; Set the PSG2 register
    rst     $08                 ; Next character must be ','
    db      COMMA               ; ','
    call    GETBYT              ; Get/evaluate value
    out     (PSG2DATA),a        ; Send data to the selected PSG2 register
    jr      check_comma

; Parse Function Argument and Put Return Address on Stack
InitFN:
    pop     hl                ; Pop Return Address
    pop     de                ; Pop Text Pointer
    ex      (sp),hl           ; Save Return Address, Discard Hook Return Address 
    ex      de,hl             ; HL = Text Pointer
    rst     CHRGET  
    call    PARCHK            ; Evaluate Argument between parentheses into FAC   
    ex      (sp),hl           ; Swap Text Pointer with Return Address
    ld      de,LABBCK         ; return address for SNGFLT, etc.
    push    de                ; on stack
    jp      (hl)              ; Fast Return 

;----------------------------------------------------------------------------
;;; ## PEEK (Extended) ##
;;; Read from Memory
;;; ### FORMAT: ###
;;;  - PEEK(< address >)
;;;    - Action: Reads a byte from memory location < address >.
;;; ### EXAMPLES: ###
;;; ` PRINT CHR$(PEEK(12288)) `
;;; > Print the current border character
;;;
;;; ` PRINT PEEK($3400) `
;;; > Print the current border color value
;----------------------------------------------------------------------------

FN_PEEK:
    push    hl                ; Save Text Pointer
    call    InitFN            ; Parse Arg and set return address
    call    FRCADR            ; Convert to Arg to Address
    ld      a,(de)            ; Read byte at Address
    jp      SNGFLT            ; and Float it

;----------------------------------------------------------------------------
;;; ## DEEK ##
;;; Read 16 bit word from Memory
;;; ### FORMAT: ###
;;; - DEEK(< address >)
;;;   - Action: Reads a word from memory location < address >, returning a number
;;; between 0 and 65535.
;;;
;;; ### EXAMPLES: ###
;;; ` POKE DEEK(14337),PEEK(14349) `
;;; > Remove cursor from screen.
;;;
;;; ` PRINT DEEK($384B) `
;;; > Print the top of BASIC memory address.
;----------------------------------------------------------------------------

FN_DEEK:
    call    InitFN            ; Parse Arg and set return address
    call    FRCADR            ; Convert to Integer
    ld      h,d               ; HL = <address>
    ld      l,e
FLOAT_M:
    ld      e,(hl)            ; Read word at address
    inc     hl
    ld      d,(hl)
    jp      FLOAT_DE          ; Float and Return
    
;----------------------------------------------------------------------------
;;; ## IN ##
;;; Read Z80 I/O Port
;;; ### FORMAT: ###
;;;  - IN(< address >)
;;;    - Action: Reads a byte from the I/O port specified by LSB of < address >.
;;;    - Advanced: During the read, < address > is put on the Z80 address bus.
;;; ### EXAMPLES: ###
;;; ` PRINT IN(252) `
;;; > Prints cassette port input status
;;;
;;; ` S=IN($FE) `
;;; > Set variable S to Printer Ready status
;----------------------------------------------------------------------------

FN_IN:
    call    InitFN            ; Parse Arg and set return address
    call    FRCADR            ; convert argument to 16 bit integer in DE
    ld      b,d
    ld      c,e              ; bc = port
    in      a,(c)            ; a = in(port)
    jp      SNGFLT          ; return with 8 bit input value in variable var

;----------------------------------------------------------------------------
;;; ## JOY ##
;;; Read AY-3-8910 Control Pad Inputs
;;; ### FORMAT: ###
;;;  - JOY(< stick >)
;;;    - Action: Reads integer input value from < stick >, where:
;;;      - `0` will read left or right contrl pad
;;;      - `1` will read left control pad only
;;;      - `2` will read right control pad only
;;; ### EXAMPLES: ###
;;; ` PRINT JOY(0) `
;;; > Prints input value of either/both control pads (not effective in immediate mode).
;;;
;;; ` 10 PRINT JOY(1) `
;;;
;;; ` 20 GOTO 10 `
;;; > Continuously reads and prints the input value from only the left control pad.
;----------------------------------------------------------------------------

FN_JOY:
    call    InitFN            ; Parse Arg and set return address
    call    FRCINT         ; convert argument to 16 bit integer in DE

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
;;; ## KEY #
;;; Read Keyboard
;;; ### FORMAT: ###
;;;  - KEY(< number >)
;;;    - Action: Checks for a key press and returns the ASCII code of the key.
;;;      - If < number > is 0, waits for a key to be pressed then returns it's ASCII code.
;;;      - If < number > is positive, checks to see if a key has been pressed, returning the key's ASCII code (or 0 if no key was pressed). A key press will only be detected once, returning 0 on subsequent calls until the key is released and pressed again.
;;;      - If < number > is negative, returns the ASCII code of the key currently being pressed (or 0 if no keys are being pressed). Subsequent calls will continue to return the key's ASCII code if the key remains pressed.
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
;;; ### EXAMPLES: ###
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
;;; > Continously decrement or increment X as long as the A or S key, respectively, is pressed.
;----------------------------------------------------------------------------

FN_KEY:
    call    InitFN            ; Parse Arg and set return address
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
;;; ## DEC ##
;;; Hexadecimal to integer conversion
;;; ### FORMAT: ###
;;;  - DEC(< string >)
;;;    - Action: Returns the DECimal value of the hexadecimal number in < string >. If the first non-blank character of the string is not a decimal digit or the letters A through F, the value returned is zero. String conversion is finished when the end of the string or any character that is not a hexadecimal digit is found.
;;; ### EXAMPLES: ###
;;; ` PRINT DEC("FFFF") `
;;; > Prints "65535"
;;;
;;; ` 10 A$=HEX$(32):PRINT DEC(A$) `
;;; > Prints "32"
;----------------------------------------------------------------------------

FN_DEC:
    call    InitFN          ; Parse Arg and set return address
    call    STRLENADR       ; Get String Text Address
    dec     hl              ; Back up Text Pointer
    jp      EVAL_HEX        ; Convert the Text

;----------------------------------------------------------------------------
;;; ## HEX$ ##
;;; Integer to hexadecimal conversion
;;; ### FORMAT: ###
;;;  - HEX$(< number >)
;;;    - Action: Returns string containing < number > in two-byte hexadecimal format. FC Error if < number > is not in the range -32676 through 65535.
;;; ### EXAMPLES: ###
;;; ` PRINT HEX$(1) `
;;; > Prints "0001"
;;;
;;; ` 10 PRINT HEX$(PEEK(12288)) `
;;; > Prints the HEX value of the border char (usually "0020", SPACE character)
;----------------------------------------------------------------------------

FN_HEX:
    call    InitFN          ; Parse Arg and set return address
    ld      a,(FAC)
    call    FRCADR          ; convert argument to 16 bit integer DE
    ld      hl,FBUFFR+1     ; hl = temp string
    ld      a,d
    call    .hexbyte        ; yes, convert byte in D to hex string
    ld      a,e
    call    .hexbyte        ; convert byte in E to hex string
    ld      (hl),0          ; null-terminate string
    ld      hl,FBUFFR+1
.create_string:
    jp      TIMSTR          ; create BASIC string

.hexbyte:
    ld      b,a
    rra
    rra
    rra
    rra
    call    .hex
    ld      a,b
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


;--------------------------
;   print hex byte
;--------------------------
; in: A = byte

PRINTHEX:
    push    bc
    ld      b,a
    and     $f0
    rra
    rra
    rra
    rra
    cp      10
    jr      c,.hi_nib
    add     7
.hi_nib:
    add     '0'
    call    TTYOUT
    ld      a,b
    and     $0f
    cp      10
    jr      c,.low_nib
    add     7
.low_nib:
    add     '0'
    pop     bc
    jp      TTYOUT

;----------------------------------------------------------------------------
;;; ## VER ##
;;; Returns 16 bit integer value of MX BASIC ROM version
;;; ### FORMAT: ###
;;;  - VER(0)
;;;    - Action: Returns integer of current MX BASIC ROM version
;;; ### EXAMPLES: ###
;;; ` PRINT VER(0) `
;;; > Prints `512`
;;;
;;; ` PRINT HEX$(VER(0)) `
;;; > Prints `0200`, the HEX value of version 2, rev 0
;----------------------------------------------------------------------------

FN_VER:
    call    InitFN            ; Parse Arg and set return address
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
;;; ## CALL ##
;;; Run to machine code at specified address
;;; ### FORMAT: ###
;;;  - CALL(< address >)
;;;    - Action: Causes Z80 to jump from it's current instruction location to the specified one. Note that there must be valid code at the specified address, or the Aquarius will crash.
;;;    - < address > can be a 16 bit signed or unsigned integer or hex value 
;;; ### EXAMPLES: ###
;;; ` CALL($A000) `
;;; > Begin executing machine code stored at upper half of middle 32k expansion RAM
;;;
;;; ` 10 LOAD "PRG.BIN",$A000 `
;;;
;;; ` 20 CALL $A000 `
;;; > Loads raw binary code into upper 16k of 32k expansion, and then begins executing it.
;----------------------------------------------------------------------------

ST_CALL:
    call    GETADR           ; get <address>
    push    de
    ret                      ; jump to user code, HL = BASIC text pointer


; Parse an Address (-32676 to 65535 in 16 bit integer)  
GETADR: call    FRMEVL      ; Evaluate Formula
; Convert FAC to Address or Signed Integer and Return in DE
; Converts floats from -32676 to 65535 in 16 bit integer
FRCADR: call    CHKNUM      ; Make sure it's a number
        ld      a,(FAC)     ;
        cp      145         ; If Float < 65536
        jp      c,QINT      ;   Convert to Integer and Return
        jp      FRCINT

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

;ST_EDIT
    include "edit.asm"

;------------------------------------------------------------------------------
;     Redraw DateTime at bottom of SPLASH screen
;------------------------------------------------------------------------------
;

SPL_DATETIME:
    ld      bc,RTC_SHADOW
    ld      hl,DTM_BUFFER
    call    rtc_read
    ld      de,DTM_STRING
    call    dtm_to_fmt    ;Convert to Formatted String   
    ld      d,2                
    ld      e,16              
    call    WinSetCursor
    ld      hl,DTM_STRING
    call    WinPrtStr
    ret    
    
;------------------------------------------------------------------------------
;;; ## SDTM ##
;;; Set DateTime
;;; ### FORMAT: ###
;;;  - SDTM < string >
;;;    - Action: If a Real Time Clock is installed, allows user to set the time on the Dallas DS1244Y RTC. DateTime string must be listed in "YYMMDDHHMMSS" format:
;;;         - Improperly formatted string causes FC Error
;;;         - DateTime is set by default to 24 hour mode,
;;;           with cc (hundredths of seconds) set to 0
;;; ### EXAMPLES: ###
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
;;; ## DTM$ ##
;;; Get DateTime
;;; ### FORMAT: ###
;;;  - DTM$(< number >)
;;;    - Action: If a Real Time Clock is installed:
;;;      - If < number > is 0, returns a DateTime string "YYMMDDHHmmsscc"
;;;      - Otherwise returns formatted times string "YYYY-MM-DD HH:mm:ss"
;;;      - Returns "" if a Real Time Clock is not detected.
;;; ### EXAMPLES: ###
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
    call    InitFN           ; Parse Arg and set return address
    call    CHKNUM
    ld      a,(FAC)          ;  
    or      a
    push    af
    ld      bc,RTC_SHADOW
    ld      hl,DTM_BUFFER
    call    rtc_read
    ld      de,DTM_STRING
    call    dtm_to_str       ; Convert to String
    pop     af 
    call    nz,dtm_fmt_str   ; If arg <> 0 Format Date
    ld      hl,DTM_STRING
    ld      a,1              ; Set Value Type to String
    ld      (VALTYP),a
    jp      TIMSTR

;-------------------------------------------------------------------------
; EVAL Extension - Hook 9

EVAL_EXT:
    pop     bc                  ; BC = Hook Return Address
    pop     af                  ; AF = whatever was in AF
    pop     hl                  ; HL = Text Pointer

    rst CHRGET                  
    cp      '$'                 
    jr      z,EVAL_HEX
    cp      '&'                 
    jr      z,GET_VARPTR
 
return_to_eval:
    push    bc                  ; Put HOOK Return Address back on stack
    dec     hl                  ; Back up Text Pointer
    ret


;------------------------------------------------------------------------------
;;; ## Hexadecimal Constants ##
;;;  - A hexadecimal constant is a value between 0 and 65535, inclusive. It consists of a dollar sign followed by 1 to 4 hexadecimal digits.
;;;    - Hexadecimal constants may be used in any numeric expression or anywhere a numeric expression is allowed.
;;;    - They may not be used in DATA statements, as entries to the INPUT statement, in string arguments to the VAL() function, or as the target of a GOTO or GOSUB statement.
;;; ### EXAMPLES: ###
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
    ld      d,a               
    ld      e,a               ; DE is the parsed Integer
.hex_loop:    
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
;;; ## & Operator ##
;;; Get Variable Address
;;; ### FORMAT: ###
;;;  - &< variable name >
;;;    - Action: Returns the address of the first byte of data identified with < variable name >. 
;;;      - A value must be assigned to < variable name > prior to execution of the & operator, otherwise an FC error results.
;;;      - Any type variable name maybe used (numeric, string, array), and the address returned will be an integer in the range of 0 and 65535.
;;;      - Note: Care should be taken when working with an array, because the addresses of arrays change whenever a new simple variable is assigned.
;;; #### EXAMPLES: ####
;;; ` A=44:COPY &A,&B,4:PRINT B `
;; > Assigns A a value, it's contents from the address of A to a new address for B, and prints the value at that address.
;-------------------------------------------------------------------------
; Get Variable Pointer
; On Entry, HL points to first character of Variable Name
; On Exit, HL points to character after Variable Name/Array Element
GET_VARPTR:
    rst     CHRGET            ; Skip '&'
    xor     a
    ld      (SUBFLG),a        ; Evaluate Array Indexes
    call    PTRGET
    xor     a
    ld      (VALTYP),a        ; Force Return Type to numeric

FLOAT_DE:
    push    hl
    xor     a                 ; Set HO to 0
    ld      b,$98             ; Exponent = 2^24
    call    FLOATR            ; Float It
    pop     hl
    ret


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
; ST_COPY
    include "extbasic.asm"


E0_END:   
E0_SIZE = E0_END - $E000

; fill with $FF to end of ROM

     assert !($FFFF<$)   ; ROM full!

     dc $FFFF-$+1,$FF

     end
