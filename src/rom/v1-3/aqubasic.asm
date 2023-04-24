;===============================================================================
;    AQUBASIC: Extended BASIC ROM for Mattel Aquarius With USB MicroExpander
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
; For use with the micro-expander (CH376S USB interface, 32K RAM, AY-3-8910 PSG),
; and the Aquarius MX expander (micro expander in mini expander footprint)
; Incudes commands from BLBasic by Martin Steenoven  
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
; 2023-04-?? v1.3  Removed unimplemented PCG code
;                  Removed PT3 Player from Menu screen. Has to be loaded as a ROM from now on.
;                  Added VER command for USB BASIC version, returned as an integer (VERSION * 256) + REVISION
;                  Modified CLS to accept an optional parameter for (FG * 16 ) + BG color integer
;                  Added SDTM command and DTM$() function for RealTime Clock access

VERSION  = 1
REVISION = 3

; code options
;softrom  equ 1    ; loaded from disk into upper 16k of 32k RAM
aqubug   equ 1     ; full featured debugger (else lite version without screen save etc.)
softclock equ 1    ; using software clock
;debug    equ 1    ; debugging our code. Undefine for release version!
;
; Commands:
; CLS    - Clear screen
; LOCATE - Position on screen
; SCR    - Scroll screen
; OUT    - output data to I/O port
; PSG    - Program PSG register, value
; CALL   - call machine code subroutine
; DEBUG  - call AquBUG Monitor/debugger

; EDITEDIT   - Edit a BASIC line

; LOAD   - load file from USB disk
; SAVE   - save file to USB disk
; DIR    - display USB disk directory with wildcard
; CAT    - display USB disk directory
; CD     - change directory
; DEL    - delete file

; functions:
; IN()   - get data from I/O port
; JOY()  - Read joystick
; HEX$() - convert number to hexadecimal string
; VER()  - Version function, returns the value of the Version and Revision of MX ROM
; DTM$() - DateTime function

; Assembled with ZMAC in 'zmac' mode.
; command: zmac.exe --zmac -e --oo cim -L -n -I include aqubasic.asm
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

; Standard BASIC System Variable Extensions
;
; Persistent USB BASIC system variables (RAMTAB: $3821-$3840, 32 bytes)
;   During a cold boot, an unused table is written here, then it is never used again
LASTKEY    = $3821      ; Last key read using key_check
;    $3822 - $382F        Unassigned, 14 bytes
RTC_SHADOW = $3830      ; Real Time Clock Shadow Registers, 10 bytes
;    $383C - $383F        Reserved, 6 bytes

; Temporary USB BASIC system variables 
DTM_BUFFER = $3851      ; RTC & DTM DateTime Buffer, 8 bytes
;   FILNAM,FILNAF,INSYNC,CLFLAG: $3851-$385E. 14 bytes
DTM_STRING = $38E6      ; DTM String Buffer, 19 bytes
;   FACHO,FAC,FBUFFR,RESHO,RESMO,RESLO: $38E6-$38F8, 19 bytes
  ifdef softclock
RTC_TEMP = $38A1        ; Software Clock Temporary Shadow Register, 10 bytes  
;   TMPSTK+1...DIMFLG: $38A1-$38AA. 10 bytes
  endif

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
    BYTE   _filetype            ; file type BASIC/array/binary/etc.
    WORD   _binstart            ; binary file load/save address
    WORD   _binlen              ; binary file length
    BYTE   _dosflags            ; DOS flags
    BYTE   _sysflags            ; system flags
 ENDSTRUCT _sysvars

SysVars  = RAMEND-_sysvars.size
ReTypBuf = sysvars+_retypbuf
PathName = sysvars+_pathname
FileName = sysvars+_filename
FileType = sysvars+_filetype
BinStart = sysvars+_binstart
BinLen   = sysvars+_binlen
DosFlags = sysvars+_dosflags
SysFlags = sysvars+_sysflags

ifdef debug
  pathname = $3006  ; store path in top line of screen
endif

;system flags
SF_NTSC  = 0       ; 1 = NTSC, 0 = PAL
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
DOS_GETFILETYPE   jp  dos__getfiletype
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

; windowed text functions
   include "windows.asm"

; debugger
 ifdef aqubug
   include "aqubug.asm"
 else
   include "debug.asm"
 endif

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
  ifdef aqubug
    ld      de,MemWindows
    ld      hl,dflt_winaddrs
    ld      bc,2*4             ; initialize default memory window addresses
    ldir
  endif
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
;
; show splash screen (Boot menu)
SPLASH:
    call    usb__root          ; root directory
    ld      a,CYAN
    call    clearscreen
    ld      b,40
    ld      hl,$3000
.topline:
    ld      (hl),' '
    set     2,h
    ld      (hl),WHITE*16+BLACK ; black border, white on black chars in top line
    res     2,h
    inc     hl
    djnz    .topline
    ld      ix,BootbdrWindow
    call    OpenWindow
    ld      ix,bootwindow
    call    OpenWindow
    ld      hl,bootmenutext
    call    WinPrtStr

; set up real time clock
    

    call    INIT_RTC
   
; outer loop for boot option key so date time display gets updated
SPLLOOP:
    call    SPL_DATETIME       ; Print DateTime at the bottom of the screen
; wait for Boot option key
SPLKEY:
    ld      c,0                 ;call the clock update every 256 loops
SPLKEYInner:
    call    Key_Check
    jr      nz,SPLGOTKEY        ; We got a key pressed
    dec     c
    jr      nz,SPLKEYInner      ; loop until c=0
    call    SPL_DATETIME        ; Print DateTime at the bottom of the screen
    jr      SPLKEY
SPLGOTKEY:
  ifndef softrom
    cp      "1"                ; '1' = load ROM
    jr      z,LoadROM
  endif
    cp      "2"                ; '2' = debugger
    jr      z, DEBUG
    cp      "a"                ; 'a' = About screen
    jr      z, AboutSCR        
    cp      "A"                ; 'A' = About screen
    jr      z, AboutSCR        
    cp      $0d                ; RTN = cold boot
    jp      z, COLDBOOT
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
    call    OpenWindow
    call    WinPrtStr
    call    Wait_key
    JP      SPLASH

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
    db     " About USB BASIC ",0

AboutText:
    db     CR,CR,CR
    db     "      Version - ",VERSION+'0','.',REVISION+'0',CR,CR
    db     " Release Date - 2023-04-??",CR,CR                       ; Can we parameterize this later?
    db     " ROM Dev Team - Curtis F Kaylor",CR
    db     "                Mack Wharton",CR
    db     "                Sean Harrington",CR
    db     CR
    db     "Original Code - Bruce Abbott",CR
    db     CR
    db     "     AquaLite - Richard Chandler",CR
    db     CR
    db     "Aquarius Draw - Matt Pilz",CR
    db     CR,CR
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
    call    PRINTSTR           
    ld      hl, STR_VERSION    ;
    call    PRINTSTR           
    ret

; Show Copyright message in system ROM
;
SHOWCOPY:
    ld      hl,$0163           ; point to copyright string in ROM
    ld      a,(hl)
    cp      $79                ; is the 'y' in "Copyright"?
    ret     nz                 ; no, quit
    dec     hl
    dec     hl                 ; yes, back up to start of string
    dec     hl
SHOWIT:
    dec     hl
    call    PRINTSTR           
    ret

STR_BASIC:
    db      $0D,"USB BASIC"
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
    ld      ($38ad),hl         ; MEMSIZ, Contains the highest RAM location
    ld      de,-50             ; subtract 50 for strings space
    add     hl,de
    ld      (TOPMEM),hl        ; Top location to be used for stack
    ld      hl,PROGST
    ld      (hl), $00          ; NULL at start of BASIC program
    inc     hl
    ld      (TXTTAB), hl      ; beginning of BASIC program text
    call    $0bbe              ; ST_NEW2 - NEW without syntax check
    ld      hl,HOOK            ; RST $30 Vector (our UDF service routine)
    ld      (UDFADDR),hl       ; store in UDF vector
  ifdef RTC_TEMP
    ld      hl,RTC_TEMP        ; Copy Temporary RTC Registers to where they belong
    ld      de,RTC_SHADOW
    ld      bc,10
    ldir
  endif
    call    SHOWCOPYRIGHT      ; Show our copyright message
    xor     a
    ld      (LASTKEY),a       ; Clear KEY() buffer
    jp      $0402              ; Jump to OKMAIN (BASIC command line)


;---------------------------------------------------------------------
;                         ROM loader
;---------------------------------------------------------------------
    include "load_rom.asm"

;---------------------------------------------------------------------
;                      USB Disk Driver
;---------------------------------------------------------------------
    include "ch376.asm"

;---------------------------------------------------------------------
;                RTC Driver for Dallas DS1244
;---------------------------------------------------------------------
    include "dtm_lib.asm"
    ;Using dummy Soft Clock until driver is done
    ifdef softclock
        include "softclock.asm" 
    else
        include "ds1244rtc.asm" 
    endif

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
    db     " Aquarius USB BASIC, v"
    db     VERSION+'0','.',REVISION+'0',' ',0

BootMenuText:
    db     CR
  ifdef softrom
    db     "     1. (disabled)",CR
  else
    db     "     1. Load ROM",CR
  endif
    db     CR,CR
    db     "     2. Debug",CR
    db     CR,CR,CR,CR,CR                ; Move down a few rows
    db     "    <RTN> USB BASIC",CR
    db     CR
    db     " <CTRL-C> Warm Start",CR
    db     CR
    db     "      <A> About...",CR
    db     CR,0



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

UDFLIST:    ; xx     index caller   @addr  performing function:-
    db      $09     ; 8   EVAL      $09FD  evaluate number or string
    db      $18     ; 7   RUN       $06be  starting BASIC program
    db      $17     ; 6   NEXTSTMT  $064b  interpreting next BASIC statement
    db      $16     ; 5   PEXPAND   $0598  expanding a token
    db      $0a     ; 4   REPLCMD   $0536  converting keyword to token
    db      $1b     ; 3   FUNCTIONS $0a5f  executing a function
    db      $05     ; 2   LINKLINES $0485  updating nextline pointers in BASIC prog
    db      $02     ; 1   OKMAIN    $0402  BASIC command line (immediate mode)

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
    

; Our Commands and Functions
;
; - New commands get added to the TOP of the commands list,
;   and the BTOKEN value DECREMENTS as commands are added.
;   They also get added at the TOP of the TBLJMPS list.
;
BTOKEN       equ $d3                ; our first token number
TBLCMDS:
; Commands list
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
CDTK  =  $E0

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
    db      $80 + 'K', "EY"         ; $e7 - key function
    db      $80                     ; End of table marker

TBLJMPS:
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
    pop     af                  ; clean up stack
    pop     af                  ; restore AF
    pop     hl                  ; restore HL

    call    $19be               ; PRNHOME if we were printing to printer, LPRINT a CR and LF
    xor     a
    ld      (CNTOFL),a          ; Set Line Counter to 0
    call    $19de               ; RSTCOL reset cursor to start of (next) line
    ld      hl,$036e            ; 'Ok'+CR+LF
    call    PRINTSTR            
;
; Immediate Mode Main Loop
;l0414:

IMMEDIATE:
    ld      hl,SysFlags
    SET     SF_RETYP,(HL)       ; CRTL-R (RETYP) active
    ld      hl,-1
    ld      (CURLIN),hl         ; Current BASIC line number is -1 (immediate mode)
    ld      hl,LINBUF           ; HL = line input buffer
    ld      (hl),0              ; buffer empty
    ld      b,LINBUFLEN         ; 74 bytes including terminator
    call    EDITLINE            ; Input a line from keyboard.
    ld      hl,SysFlags
    RES     SF_RETYP,(HL)       ; CTRL-R inactive
ENTERLINE:
    ld      hl,LINBUF-1
    jr      c,immediate         ; If c then discard line
    rst     $10                 ; get next char (1st character in line buffer)
    inc     a
    dec     a                   ; set z flag if A = 0
    jr      z,immediate         ; If nothing on line then loop back to immediate mode
    push    hl
    ld      de,ReTypBuf
    ld      bc,LINBUFLEN        ; save line in history buffer
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
;    CALL    key_check           ; Poll Keyboard    
;    jr      z,.no_key           ; If Key was Pressed
;    ld      ($3000),a
;    ld      (LASTKEY),a         ;   Save It
;.no_key
    pop     bc                  ; BC = return address
    pop     af                  ; AF = token - $80, flags
    pop     hl                  ; HL = text
    jr      nc,BASTMT           ; if NC then process BASIC statement
    push    af                  ; Save Flags
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

; RUN
RUNPROG:
    pop     af                 ; clean up stack
    pop     af                 ; restore AF
    pop     hl                 ; restore HL
    jp      z,$0bcb            ; if no argument then RUN from 1st line
    push    hl
    call    FRMEVL               ; get argument type
    pop     hl
    ld      a,(VALTYP)
    dec     a                  ; 0 = string
    jr      z,_run_file
    call    $0bcf              ; else line number so init BASIC program and
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
    call    PRINTSTR
    pop     hl                 ; restore BASIC text pointer
.error:
    ld      e,ERRFC           ; function code error
    jp      ERROR           ; return to BASIC
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
    ld      de,.bin_extn
    ld      (hl),0             ; remove extn
    call    strcat             ; append ".BIN"
.load_run:
    pop     hl                 ; restore BASIC text pointer
    call    ST_LOADFILE        ; load file from disk, name in FileName
    jp      nz,.error          ; if load failed then return to command prompt
    cp      FT_BAS             ; filetype is BASIC?
    jp      z,$0bcb            ; yes, run loaded BASIC program
    cp      FT_BIN             ; BINARY?
    jp      nz,immediate       ; no, return to command line prompt
    ld      de,immediate
    push    de                 ; set return address
    ld      de,(BINSTART)
    push    de                 ; set jump address
    ret                        ; jump into binary

.bas_extn:
    db     ".BAS",0
.bin_extn:
    db     ".BIN",0

.nofile_msg:
    db     "file not found",$0D,$0A,0


;********************************************************************
;                   Command Entry Points
;********************************************************************

ST_reserved:
    ret

;----------------------------------------------------------------------------
;;; Extended POKE Statement - Write to Memory Location(s)
;;; 
;;; FORMAT: POKE <address>, <byte> [,<byte>...]
;;;  
;;; Action: Writes <byte>s to memory starting at <address>. 
;;;         
;;; EXAMPLES of POKE Statement:
;;; 
;;;   !!!TODO
;----------------------------------------------------------------------------

ST_POKE:   
    pop     af              ; Discard Saved Token, Flags
    inc     hl              ; Skip Poke Token
    call    FRMNUM          ; Get <address>
    call    FRCADR          ; Convert To Integer in DE
    SYNCHK  ','             ; Require a Comma
.poke_loop:
    cp      STEPTK          ; If STEP Token
    jr      z,.poke_step     ;   Do STEP
    push    de              ; Save Address  
    call    GETBYT          ; Get <byte> in A
    pop     de              ; Restore Address
    ld      (de),a          ; Write Byte to Memory
    ld      a,(hl)          ; If Next Character
    cp      ','             ; is Not a Comma
    ret     nz              ;   We are done
    rst     CHRGET          ; Skip Comma
    inc     de              ; Bump Poke Address
    jr      .poke_loop      ; Do the Next Byte

.poke_step:
    rst     CHRGET          ; Skip STEP 
    push    de              ; Save Poke Address
    call    GETINT          ; Get Step Amount in DE
    ex      (sp),hl         ; HL=Poke Address, STK=Text Pointer
    add     hl,de           ; Add Step to Address
    ld      d,h             ; Now DE contains
    ld      e,l             ;   new Address
    pop     hl              ; Get Text Pointer back
    SYNCHK  ','             ; Require a Comma
    jr      .poke_loop

;--------------------------------------------------------------------
;   CLS statement
;
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

;-----------------------------------
;       Clear Screen, Updated
;-----------------------------------
; - user-defined colors
; - doesn't clear last 24 bytes
; - doesn't show cursor
;
; in: A = color attribute (FG * 16) + BG

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
;;; OUT Statement - Write to Z80 I/O Port
;;; 
;;; FORMAT: OUT <address>,<byte>
;;;  
;;; Action: Writes <byte> to the I/O port specified by LSB of <address>. 
;;;         
;;; Advanced: During the write, <address> is put on the Z80 address bus.
;;;         .
;;; 
;;; EXAMPLES of OUT Statement:
;;; 
;;;   !!!TODO
;----------------------------------------------------------------------------

ST_OUT:
    call    FRMNUM              ; get/evaluate port
    call    FRCADR              ; convert number to 16 bit integer (result in DE)
    push    de                  ; stored to be used in BC
    rst     $08                 ; Compare RAM byte with following byte
    db      $2c                 ; character ',' byte used by RST 08
    call    GETBYT              ; get/evaluate data
    pop     bc                  ; BC = port
    out     (c),a               ; out data to port
    ret

;--------------------------------------------------------------------
; LOCATE statement
; Syntax: LOCATE col, row

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
    exx
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
    jp      $1de7               ; Save cursor position and return


;--------------------------------------------------------------------
;   PSG statement
;   syntax: PSG register, value [, ... ]

ST_PSG:
    cp      $00
    jp      z,$03d6          ; MO error if no args
psgloop:
    call    GETBYT           ; get/evaluate register
    out     ($f7),a          ; set the PSG register
    rst     $08              ; next character must be ','
    db      $2c              ; ','
    call    GETBYT           ; get/evaluate value
    out     ($f6),a          ; send data to the selected PSG register
    ld      a,(hl)           ; get next character on command line
    cp      $2c              ; compare with ','
    ret     nz               ; no comma = no more parameters -> return

    inc     hl               ; next character on command line
    jr      psgloop          ; parse next register & value

;----------------------------------------------------------------------------
;;; PEEK() Function - Read from Memory
;;; 
;;; FORMAT: PEEK(<address>)
;;;  
;;; Action: Reads a byte from memory location <address>. 
;;;         
;;; 
;;; EXAMPLES of PEEK Function:
;;; 
;;;   !!!TODO
;----------------------------------------------------------------------------

FN_PEEK
    rst     CHRGET  
    call    PARCHK            ; Evaluate Argument between parentheses into FAC   
    ex      (sp),hl           
    ld      de,LABBCK         ; return address for SNGFLT
    push    de                ; on stack
    call    FRCADR            ; Convert to Integer
    ld      a,(de)            ;[M80] GET THE VALUE TO RETURN
    jp      SNGFLT            ;[M80] AND FLOAT IT

;----------------------------------------------------------------------------
;;; IN() Function - Read Z80 I/O Port
;;; 
;;; FORMAT: IN(<address>)
;;;  
;;; Action: Reads a byte from the I/O port specified by LSB of <address>. 
;;;         
;;; Advanced: wtDuring the read, <address> is put on the Z80 address bus.
;;;         .
;;; 
;;; EXAMPLES of IN Function:
;;; 
;;;   PRINT IN(252)     (Prints cassette port input status)
;;;   S=IN(254)         (Set S to Printer Ready status)
;----------------------------------------------------------------------------

FN_IN:
    pop     hl
    rst     CHRGET  
    call    PARCHK           ; Read number from line - ending with a ')'
    ex      (sp),hl
    ld      de,LABBCK        ; return address for SNGFLT
    push    de               ; on stack
    call    FRCADR            ; convert argument to 16 bit integer in DE
    ld      b,d
    ld      c,e              ; bc = port
    in      a,(c)            ; a = in(port)
    jp      SNGFLT          ; return with 8 bit input value in variable var


;--------------------------------------------------------------------
;   Entry point for JOY() function
;   syntax: var = JOY( stick )
;                 stick - 0 will read left or right
;                       - 1 will read left joystick only
;                       - 2 will read right joystick only

FN_JOY:
    pop     hl             ; Return address
    rst     CHRGET  
    call    $0a37          ; Read number from line - ending with a ')'
    ex      (sp),hl
    ld      de,LABBCK      ; set return address
    push    de
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
;;; KEY() Function
;;; 
;;; Format: KEY(<number>)

FN_KEY
    pop     hl             ; Return address
    rst     CHRGET  
    call    PARCHK            ; Evaluate Argument between parentheses into FAC   
    ex      (sp),hl           
    ld      de,LABBCK         ; return address for SNGFLT
    push    de                ; on stack

    call    FRCADR            ; DE = Timeout
    ld      a,d
    or      a,e
    jr      nz,.fn_wait       ; Check until timed out

.fn_loop:
    call    key_check         ; Check for a key
    jr      nz,.fn_done       ; Found a key, return it
    jr      .fn_loop

.fn_wait
    call    key_check         ; Check for a key
    jr      nz,.fn_done       ; Found a key, return it
    dec     de                
    ld      a,d               ; If DE<>0, return
    or      a                 
    jr      nz,.fn_wait       
    ld      a,e
    or      a
    jr      nz,.fn_wait
    push    af
    xor     a
    ld      (LSTX),a
    ld      (KCOUNT),a
    pop     af
    
.fn_done
    jp      SNGFLT            ; and float it

;----------------------------------------------------------------------------
;;; DEC() Function
;;; 
;;; Format: DEC(<string>)
;;; 
;;; Action: Returns the DECimal value of the hexadecimal number in <string>.
;;;         If the first non-blank character of the string is not a decimal
;;;         digit or the letters A through F, the value returned is zero. 
;;;         String conversion is finished when the end of the string or any
;;;         character that is not a hexadecimal digit is found.
;;; 
;;; EXAMPLES of DEC Function:
;;; 
;;;   
;----------------------------------------------------------------------------

FN_DEC:
    pop     hl
    rst     CHRGET  
    call    PARCHK          ; Read number from line - ending with a ')'
    ex      (sp),hl         ; 
    ld      de,LABBCK       ; return address for SNGFLT
    push    de              ; on stack

    call    FRESTR          ; Make sure it's a String and Free up temp
    inc     hl              ; Skip String Descriptor length byte
    inc     hl              ; Set Address of String Text into HL
    ld      a,(hl)          ;
    inc     hl
    ld      h,(hl)
    ld      l,a
    dec     hl              ; Back up Text Pointer
    jp      EVAL_HEX        ; Convert the Text

;----------------------------------------------------------------------------
;;; HEX$() Function
;;; 
;;; Format: HEX$(<number>)
;;; 
;;; Action: Returns string containing <number> in hexadecimal format.
;;;         FC Error if <number> is not in the range -32676 through 65535.
;;; 
;;; EXAMPLES of HEX Function:
;;; 
;;;   PRINT HEX$(1)  !!!TODO 
;----------------------------------------------------------------------------

FN_HEX:
    pop     hl
    rst     CHRGET  
    call    PARCHK     ; evaluate parameter in brackets
    ex      (sp),hl
    ld      de,LABBCK  ; return address
    push    de         ; on stack
    ld      a,(FAC)
    cp      154         ; If more than 23 bits 
    jp      nc,FCERR    ;   Error Out
    call    FRCADR        ; convert argument to 24 bit signed integer in C,DE
    ld      hl,FBUFFR+1 ; hl = temp string
    ld      a,d
    call    .hexbyte   ; yes, convert byte in D to hex string
    ld      a,e
    call    .hexbyte   ; convert byte in E to hex string
    ld      (hl),0     ; null-terminate string
    ld      hl,FBUFFR+1
.create_string:
    jp      RETSTR     ; create BASIC string

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
    call    PRNCHR
    ld      a,b
    and     $0f
    cp      10
    jr      c,.low_nib
    add     7
.low_nib:
    add     '0'
    pop     bc
    jp      PRNCHR

;--------------------------------------------------------------------
;   VER function 
;
;  Returns 16 bit variable B,A containing the USB BASIC ROM Version

FN_VER:
    pop     hl
    rst     CHRGET  
    call    PARCHK           ; Evaluate argument between parentheses - then ignore it
    ex      (sp),hl
    ld      de,LABBCK        ; return address
    push    de               ; on stack
    ld      a, VERSION       ; returning (VERSION * 256) + REVISION
    ld      b, REVISION
    jp      FLOATB


;--------------------------------------------------------------------
;                            CALL
;--------------------------------------------------------------------
; syntax: CALL address
; address is signed integer, 0 to 32767   = $0000-$7FFF
;                            -32768 to -1 = $8000-$FFFF
;
; on entry to user code, HL = text after address
; on exit from user code, HL should point to end of statement
;
ST_CALL:
    call    FRMNUM           ; get number from BASIC text
    call    FRCADR           ; convert to 16 bit integer
    push    de
    ret                      ; jump to user code, HL = BASIC text pointer


; Convert FAC to Address or Signed Integer and Return in DE
; Converts floats from -32676 to 65535 in 16 bit integer
FRCADR: ld      a,(FAC)           ;
        cp      145               ;If Float < 65536
        jp      c,QINT            ;  Convert to Integer and Return
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


;---------------------------------------------------------------------
;                     BASIC Line Editor
;---------------------------------------------------------------------
; EDIT (line number)
;
;ST_EDIT
    include "edit.asm"

;------------------------------------------------------------------------------
;     Redraw DateTime at bottom of SPLASH screen
;------------------------------------------------------------------------------
;

SPL_DATETIME:
    push    bc          ; Save BC
  ifdef RTC_TEMP
    ld      bc,RTC_TEMP       
  else
    ld      bc,RTC_SHADOW
  endif
    ld      hl,DTM_BUFFER
    call    rtc_read      ;Read RTC
    ld      de,DTM_STRING
    call    dtm_to_fmt    ;Convert to Formatted String   
    ld      d,1                
    ld      e,17              
    call    WinSetCursor
    ld      hl,DTM_STRING
    call    WinPrtStr
    pop     bc          ;Restore BC
    ret    
    
;Starting DateTime for Software Clock
;2017-06-12 11:00:00 - Date Bruce Abbott released Micro Expander (NZ is GMT+11)
SPL_DEFAULT:
    db      $FF,$00,$00,$00,$11,$12,$06,$17,$00,$00 
            ;enl cc  ss  mm  HH  DD  MM  YY cdl cdh
 
;------------------------------------------------------------------------------
;     Initialize the Real Time Clock
;------------------------------------------------------------------------------

INIT_RTC:
  ifdef RTC_TEMP
    ld      bc,RTC_TEMP       
  else
    ld      bc,RTC_SHADOW
  endif
    ld      de,SPL_DEFAULT    ;Default Default Time
    ld      hl,DTM_BUFFER     
    call    rtc_init          ;Initialize RTC Chip
    ret

    
;------------------------------------------------------------------------------
;     DateTime Command - SET DateTime
;------------------------------------------------------------------------------
;
;  The SDTM command allows users to SET the DateTime in the Dallas RTC by
;  using the following format:
;
;    SDTM "230411101500" (where string is in "YYMMDDHHMMSS" format) - Sets DateTime to 11 APR 2023 10:15:00 (24 hour format)
;
;  - Improperly formatted string causes FC Error
;  - DateTime is set by default to 24 hour mode, with cc (hundredths of seconds) set to 0
;

ST_SDTM:
    call    FRMEVL          ; Evaluate Argument
    push    hl              ; Save text pointer
    call    FRESTR          ; Make sure it's a String and Free up tmp
    
    ld      a,c             ; If less than 12 characters long
    cp      12              ;   Return without setting date
    jp      c,RET           ;

    inc     hl              ; Skip String Descriptor length byte
    inc     hl              ; Set DE to Address of String Text
    ld      e,(hl)          ;   using it as the String Buffer
    inc     hl
    ld      d,(hl)

    ld      hl,DTM_BUFFER   ; 
    call    str_to_dtm      ; Convert String to DateTime
    ret     nz              ; Don't Write if invalid DateTime
    ld      bc,RTC_SHADOW
    call    rtc_write
    pop     hl              ; Restore text pointer
    ret

;------------------------------------------------------------------------------
;;; DTM$ Function
;;;
;;; Format: DTM$(<number>)
;;; 
;;; Action: If a Real Time Clock is installed:
;;;            if <number> is 0, returns a DateTime string "YYMMDDHHmmsscc"
;;;            otherwise returns formatted times string "YYYY-MM-DD HH:mm:ss"
;;;         Returns "" if a Real Time Clock is not detected.
;;; 
;;; EXAMPLES of DTM$ Function:
;;; 
;;;   PRINT DTM$(0)             38011903140700            
;;;   PRINT DTM$(1)             2038-01-19 03:14:07      
;;;   
;;;   PRINT LEFT$(DTM$(1),10)   2038-01-19
;;;   PRINT RIGHT$(DTM$(1),8)   03:14:07
;;;   PRINT MID$(DTM$(1),6,11)  01-19 03:14
;---------------------------------------------------------------------------


FN_DTM:
    pop     hl
    inc     hl
    call    PARCHK           ; Evaluate argument between parentheses into FAC 
    ex      (sp),hl
    ld      de,LABBCK        ; return address
    push    de               ; on stack
    call    CHKNUM
    
    ld      bc,RTC_SHADOW
    ld      hl,DTM_BUFFER    
    call    rtc_read         ;Read RTC
    ld      de,DTM_STRING
    call    dtm_to_str       ;Convert to String
    ld      a,(FAC)            
    or      a                ;If Argument is not 0
    call    nz,dtm_fmt_str   ;  Format Date
    ld      hl,DTM_STRING
    ld      a,1              ;Set Value Type to String
    ld      (VALTYP),a
    jp      RETSTR


;-------------------------------------------------------------------------
; EVAL Extension - Hook 9

EVAL_EXT:
    pop     bc                  ; BC = Hook Return Address
    pop     af                  ; AF = whatever was in AF
    pop     hl                  ; HL = Text Pointer

    rst CHRGET                  
    cp      '$'                 
    jr      z,EVAL_HEX
 
return_to_eval:
    push    bc                  ; Put HOOK Return Address back on stack
    dec     hl                  ; Back up Text Pointer
    ret

;-------------------------------------------------------------------------
; Parse Hexadecimal Literal into Floating Point Accumulator
; On Entry, HL points to first Hex Digit
; On Exit, HL points to character after Hex String

EVAL_HEX:
;    inc     hl                  ; skip $ and return
;    jp      return_to_eval      ; for now

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

FLOAT_DE:
    ;call    break
    xor     a                 ; Set HO to 0
    ld      b,$98             ; Exponent = 2^24
    push    hl
    call    FLOATR            ; Float It
    pop     hl
    ret

;=====================================================================
;                  Miscellaneous functions

; routines from Extended BASIC
    include "extbasic.asm"

; string functions
    include "strings.asm"

; keyboard scan
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

; disk file selector
   include "filerequest.asm"
   
CODE_END:   
CODE_SIZE = CODE_END - RAMEND

; fill with $FF to end of ROM

     assert !($FFFF<$)   ; ROM full!

     dc $FFFF-$+1,$FF

     end
