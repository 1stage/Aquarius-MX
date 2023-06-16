;====================================================================
;                  Aquarius USB DOS Commands
;====================================================================
;
; Changes:
; 2015-11-11 v0.00 Extracted from babasicV0.2f
; 2016-01-02 v0.01 Save file implemented.
;                  File type analysis.
; 2016-01-11 v0.02 Improved file type analysis.
;                  Using IY register to reference system variables.
;                  Changed name from 'usb_dos' to 'dos' in preparation
;                  for handling different types of storage media.
; 2016-01-18 v0.03 KILL, CAT, DIR.
;                  ST_LOAD returns filetype if successful.
; 2016-01-20 v0.04 getfilename now returns error code offset rather than
;                  returning to BASIC prompt if filename is invalid.
; 2016-01-27 v0.05 Load/save numeric array.
; 2016-01-31 v0.06 internal Init_BASIC routine
; 2016-02-06 v0.07 trim trailing zeros off BASIC (CAQ) file after loading
; 2016-02-19 v0.08 close file after reading
; 2016-02-21 v0.09 DIR supports wildcards
; 2017-01-19 v0.10 string operands evaluated, eg. LEFT$(A$,11)
; 2017-01-22 v0.11 CAT prints 3 filenames per line
; 2017-03-04 v0.12 binary header is now $BF,$DA,addr
; 2017-03-05 v0.13 removed PRNTAB
; 2017-03-13 v0.14 incresed max filename chars from 11 to 12 (8+"."+3)
;                  moved get_next, getarg, chk_arg to strings.asm
; 2017-04-05 v0.15 strip header off binary file
; 2017-04-24 v0.16 ST_CD change directory
; 2017-04-26 v0.17 CD without arg shows current directory
; 2017-05-01 v0.18 KILL error returns to BASIC with FC error
; 2017-05-13 v0.19 CD checks for disk ready (resets path to root if disk changed)
;                  move valid path chacks to usb_ready
; 2017-06-01 v0.20 CD to a file (invalid) now removes the filename from the path
; 2017-06-12 v1.0  bumped to release version
; 2022-08-27 v1.1  Changed KILL command to DEL
; 2022-09-21 v1.2  Fixed array saving by removing the 4 spurious bytes (Mack)
;                  Correct comments regarding loading of .BIN files to $C9,$C3 (was $BF,$DA)
;                  Added SCR logic for binary load to Screen RAM without ADDR parameter (Harrington)
; 2023-05-11 v2.0  SAVE: Removed header when writing binary files, added 15 x $00 tail to CAQ container
;                  when writing Basic program or array. Fixed SN error when SAVE array in program (CFK)
; 2023-05-12 v2.0  LOAD: Removed file ST_DIRtype parsing. File type is based on arguments only. 
;                  Removed dos_getfiletype and all related code, constants, and strings
;                  Replaced get_next and get_arg calls with chrget and chrgot calls
; 2023-05-17 v2.0  DIR: Print last write date and time. Do not show hidden or system files.                 
; 2023-05-?? v2.0  Added MKDIR - CFK
; 2023-05-?? v2.0  Update Create and Modify Time to when writing file, creating directory
; 2023-06-01 v2.0  Moved print_hex and print_integer to strings.asm
;                  Moved error message lookup routine, lookup table, and message strings to dispatch.asm
;                  Moved DOS Error Number defines to aquarius.i

; bits in dosflags
DF_ADDR   = 0      ; set = address specified
DF_LEN    = 1      ; set = length specified
DF_OFS    = 2      ; set = offset specified
DF_SDTM   = 6      ; set = show file date/time
DF_ARRAY  = 7      ; set = numeric array


;------------------------------------------------------------------------------
;;; ---
;;; ## CD
;;; Change directory / current path
;;; ### FORMAT:
;;;  - CD
;;;    - Action: show current path
;;;  - CD "*dirname*"
;;;    - Move into directory indicated by *dirname*
;;; ### EXAMPLES:
;;; ` CD "songs3" `
;;; > Move into `songs3` (add `songs3` to current path)
;;;
;;; ` CD "/" `
;;; > Move to root of the USB drive
;;;
;;; ` CD ".." `
;;; > Back up one level to folder containing this one
;;;
;;; ` CD `
;;; > Show the current path
;------------------------------------------------------------------------------

ST_CD:
    push   hl                    ; push BASIC text pointer
    ld     c,a
    call   dos__clearError
    call   usb__ready            ; check for USB disk (may reset path to root!)
    jp     nz,_dos_do_error
    ld     a,c
    OR     A                     ; any args?
    JR     NZ,.change_dir        ; yes,
.show_path:
    LD     HL,PathName
    call   STROUT                ; print path
    call   CRDO
    jp     _pop_hl_ret           ; pop HL and return
.change_dir:
    pop    hl                    ; pop BASIC text pointer
    CALL   FRMEVL                  ; evaluate expression
    PUSH   HL                    ; push BASIC text pointer
    CALL   CHKSTR                ; type mismatch error if not string
    CALL   LEN1                  ; get string and its length
    JR     Z,_dos_opendir        ; if null string then open current directory
    inc    hl
    inc    hl                    ; skip to string text pointer
    ld     b,(hl)
    inc    hl
    ld     h,(hl)                ; hl = string text
    ld     l,b
    call   dos__set_path         ; update path (out: DE = end of old path)
    jr     z,.open
    ld     a,ERROR_PATH_LEN
    jp     _dos_do_error         ; path too long
.open:
    pop    hl
_dos_opendir:
    push   hl
    call   usb__open_path        ; try to open directory
    jp     z,_pop_hl_ret         ; if opened OK then done
    cp     CH376_ERR_MISS_FILE   ; directory missing?
    jr     z,.undo
    cp     CH376_INT_SUCCESS     ; 'directory' is actually a file?
    jp     nz,_dos_do_error      ; no, disk error
.undo:
    ex     de,hl                 ; HL = end of old path
    ld     (hl),0                ; remove subdirectory from path
    ld     a,ERROR_NO_DIR        ; error = missing directory
    jp     _dos_do_error         ; display DOS error and generate FCERR

;------------------------------------------------------------------------------
;;; ---
;;; ## CD$
;;; Get Current Directory path as a string
;;; ### FORMAT:
;;;  - CD$
;;;    - Action: Returns the current directory path as displayed by the CD command with no arguments
;;; ### EXAMPLES:
;;; ` PRINT CD$ `
;;; > Prints the current directory path to the screen
;;;
;;; ` 10 A$=CD$:PRINT A$ `
;;; > Assigns the current path string to A$, then prints it.
;------------------------------------------------------------------------------
FN_CD:
    inc     hl                ; Skip CD Token
    SYNCHK  '$'               ; Require $
    push    hl                ; Text Pointer on Stack
    ex      (sp),hl           ; Swap Text Pointer with Return Address
    push    bc                ; put dummy return address on stack
    call    usb__get_path     ; Get pointer to current path in HL
    jp      TIMSTR
  
;------------------------------------------------------------------------------
;;; ---
;;; ## MKDIR
;;; Create directory in current path
;;; ### FORMAT: 
;;;  - MKDIR "*dirname*"
;;;    - Action: Create directory *dirname* in the current directory (see CD).
;;;      - Returns without error if directory already exists.
;;;      - Returns Disk I/O Error "file exists" if a file with the same name is in the current directory.
;;; ### EXAMPLE:
;;; ` MKDIR "mydir" `
;;; > Creates new directory MYDIR in the current directory.
;------------------------------------------------------------------------------
ST_MKDIR:
    call    dos__getfilename      ; parse directory name
    jp      nz,_badname_error
    push    hl                    ; save BASIC text pointer
    call    dos__clearError
    call    usb__ready            ; check for USB disk (may reset path to root!)
    jp      nz,_dos_do_error
    call    _dos_opendir          ; open current path
    ld      hl,FileName
    call    usb__create_dir       ; create directory
    jp      nz,_dos_mkdir_got_Error        
    call    set_dos_File_datetime
    jp      z,_pop_hl_ret         ; if successful return
 _dos_mkdir_got_Error:
    cp      CH376_ERR_FOUND_NAME
    jr      z,_dos_file_exists
_dos_unknown_error:
    ld      a,ERROR_UNKNOWN
    jp      _dos_do_error
_dos_file_exists:
    ld      a,ERROR_FILE_EXISTS
    jp      _dos_do_error

;------------------------------------------------------------------------------
;;; ---
;;; ## LOAD Statement (updated)
;;; Load File from USB Drive
;;; ### FORMAT:
;;;  - LOAD *filespec* 
;;;    - Action: Load BASIC program *filespec* into memory
;;;      - *filename* can be any string expression
;;;      - If *filename* is shorter than 9 characters and does not contain a ".", the extension ".BAS" is appended.
;;;      - File on USB drive must be in CAQ format. The internal filename is ignored.
;;;      - If *filspec* is a literal string, the end quotation mark is optional.
;;;  - LOAD *filespec* , \**arrayname*
;;;    - Action: Load contents of array file *filespec* into array *arrayname*
;;;      - If *filename* is shorter than 9 characters and does not contain a ".", the extension ".CAQ" is added.
;;;      - File on USB drive mus be in CAQ format with the internal filename "######".
;;;  - LOAD *filespec* , *address* [ , *length* [, *offset*]]
;;;  - LOAD *filespec* , \**arrayname*
;;;    - Action: Load contents of array file *filespec* into array *arrayname*
;;;  - LOAD *filespec* , *address* [ , *length* [, *offset*]]
;;;    - Action: Load contents of binary file *filespec* into memot
;;;      - *length* specifies the number of bytes to load from the file
;;;      - *offset* specifies the position in the file to start loadin from
;;; ### ERRORS
;;;  - If *filespec* is not included, an MO Error results
;;;  - If file *filespec* does not exist, an IO Error with DOS Error "file not found" results.
;;;  - If only *filespec* is specified and the file is not a BASIC program in CAQ format, an IO Error with DOS Error "filetype mismatch" results.
;;;  - If *arrayname* is specified and the array is not DIMmed, an FC Error results.
;;;  - If *arrayname* is specified and the file is not array data in CAQ format, an IO Error with DOS Error "filetype mismatch" results.
;;; ### EXAMPLES:
;;; ` LOAD "progname.bas" `
;;; > Load basic program into memory.
;;;
;;; ` LOAD "array.caq",*A `
;;; > Load contents of file into array A().
;;;
;;; ` LOAD "capture.scr",12288 `
;;; > Loads the file "capture.scr" into SCREEN RAM.
;------------------------------------------------------------------------------
ST_LOAD:
    call    _get_file_args        ; Set Up SysVars and Get LOAD Arguments
    push    hl                    ; >>>> push BASIC text pointer
    ld      hl,FileName
    bit     DF_ADDR,(iy+0)        ; address specified?
    jr      z,_stl_caq            ; no, load CAQ file
; load binary file to address
_stl_load_bin:
    call    usb__open_read        ; try to open file
    jp      nz,_stl_no_file
    bit     DF_OFS,(iy+0)
    jr      z,.no_ofs
    ld      de,(BINOFS)
    call    usb__seek
    jp      nz,_dos_do_error
.no_ofs
    ld      hl,(BINSTART)         ; HL = address
    jr      _stl_read             ; read file into RAM
; load BASIC Program with filename in FileName
; BASIC program or array, has CAQ header
_stl_caq:
    bit     DF_ARRAY,a            ; loading into array?
    jr      z,_stl_basprog
; Loading array
    ld      de,dos_caq_ext        ; default extension ".CAQ"
    call    _sts_open_caqfile     ; open file, read sync and filename
    ld      hl,FILNAF
    ld      b,6                   ; 6 chars in name
    ld      a,'#'                 ; all chars should be '#'
_stl_array_id:
    cp      (hl)
    jr      nz,_stl_bad_file      ; if not '#' then bad tape name
    djnz    _stl_array_id
    ld      hl,(BINSTART)         ; HL = array data address
    ld      de,(BINLEN)           ; DE = array data length
    jr      _stl_read_len         ; read file into array
; loading BASIC program
_stl_basprog:
    ld      de,dos_bas_ext        ; default extension ".BAS"
    call    _sts_open_caqfile     ; open file, read sync and filename
    ld      hl,FILNAF
    ld      b,6                   ; 6 chars in name
    ld      a,'#'                 ; checking for all #'s
_stl_basic_id:
    cp      (hl)
    jr      nz,_stl_basic_ok      ; if not '#' then not an array file
    djnz    _stl_basic_id
    jr      _stl_bad_file         ; all #'s - error out
_stl_basic_ok:
    call    st_read_sync          ; read seoond sync sequence
    ld      hl,(TXTTAB)           ; HL = start of BASIC program
    ld      de,$ffff              ; DE = read to end of file
    call    usb__read_bytes       ; read BASIC program into RAM
    ld      (BinEnd),hl           ; save LOAD end address
    jr      nz,_stl_read_error
_stl_bas_end:
    dec     hl
    xor     a
    cp      (hl)                  ; back up to last line of BASIC program
    jr      z,_stl_bas_end
    inc     hl
    inc     hl
    inc     hl                    ; forward past 3 zeros = end of BASIC program
    inc     hl
    ld      (VARTAB),hl           ; set end of BASIC program
    call    Init_BASIC            ; clear variables etc. and update line addresses
    jr      _stl_done
; read file into RAM
; HL = load address
_stl_read:
    ld      de,$ffff              ; set length to max (will read to end of file)
    bit     DF_LEN,(iy+0)           
    jr      z,_stl_read_len       ; if length was specified
    ld      de,(BINLEN)           ;   read that length
_stl_read_len:
    call    usb__read_bytes       ; read file into RAM
    ld      (BinEnd),hl           ; save LOAD end address
    jr      z,_stl_done           ; if good load then done
_stl_read_error:
    ld      a,ERROR_READ_FAIL     ; disk error while reading
    jr     _stl_show_error
_stl_no_file:
    ld      a,ERROR_NO_FILE       ; file not found
    jr      _stl_show_error
_stl_bad_file:
    ld      a,ERROR_BAD_FILE      ; file type incompatible with load method
    jr      _stl_show_error
_stl_rmdir_err:
    ld      a,ERROR_RMDIR_FAIL    ; no load address specified
_stl_show_error:
    jp      _dos_do_error         ; return to BASIC with error code in E
_stl_done:
    call    usb__close_file       ; close file
    pop     hl                    ; restore BASIC text pointer
    ret

_sts_open_caqfile:
    ld      hl,FileName
    call    dos_append_ext
    call    usb__open_read        ; open file for read
    jp      nz,_stl_no_file
    call    st_read_sync          ; no, read 1st CAQ sync sequence
    jr      nz,_stl_bad_file
    ld      hl,FILNAF             ; Cassette File Name
    ld      de,6                  ; read internal tape name
    call    usb__read_bytes
    jr      nz,_stl_bad_file
    ret

; Called from RUNROG
ST_LOADFILE:
    call    _convert_filename     ; get filename from parsed arg
    jp      nz,_badname_error
    push    hl                    ; save text pointer
    ld      iy,DosFlags
    xor     a
    ld      (iy+0),a              ; clear all DOS flags
    jp      _stl_basprog          ; Load BASIC program

;-------------------------------------------------
;           Print DOS error message
;-------------------------------------------------
;
;  in: A = error code
;

_show_error:
    ld      (DosError),a          ; save error number
    ld      d,a                   ; copy error number into D
    ld      hl,(ONELIN)           
    ld      a,h                   
    or      l                     ; if trapping errors
    ret     nz                    ;   don't display error message
    
    ld      a,d                   ; get error number back
    call    dos__lookup_error     ; look up error message
    jr      nc,_show_error_hex    ;   if unknown error, show hex code show hex code
    call    prtstr                ; print error message
    jp      CRDO

_show_error_hex:
    push    af                   ; no, push error code
    ld      hl,disk_error_msg
    call    prtstr               ; print "disk error $"
    pop     af                   ; pop error code
    call    print_hex
    jp      CRDO


;--------------------------------------------------------------------
;                  Read CAQ Sync Sequence
;--------------------------------------------------------------------
; CAQ BASIC header is 12x$FF, $00, 6 bytes filename, 12x$FF, $00.
; This subroutine reads and checks the sync sequence 12x$FF, $00.
;
; out: Z = OK
;     NZ = bad header
;
; uses: A, B
;
st_read_sync:
    ld      b,12
_st_read_caq_lp1
    call    usb__read_byte
    ret     nz
    inc     a
    ret     nz                    ; NZ if not $FF
    djnz    _st_read_caq_lp1
    call    usb__read_byte
    ret     nz
    and     a                     ; Z if $00
    ret


;--------------------------------------------------------------------
;                   Initialize BASIC Program
;--------------------------------------------------------------------
; Resets variables, arrays, string space etc.
; Updates nextline pointers to match location of BASIC program in RAM
;
Init_BASIC:
        ld      hl,(TXTTAB)
        dec     hl
        ld      (SAVTXT),hl       ; set next statement to start of program
        ld      (DATPTR),hl       ; set DATPTR to start of program
        ld      hl,(MEMSIZ)
        ld      (FRETOP),hl        ; clear string space
        ld      hl,(VARTAB)
        ld      (ARYTAB),hl        ; clear simple variables
        ld      (STREND),hl        ; clear array table
        ld      hl,TEMPST
        ld      (TEMPPT),hl        ; clear string buffer
        xor     a
        ld      l,a
        ld      h,a
        ld      (OLDTXT),hl       ; set CONTinue position to 0
        ld      (SUBFLG),a         ; clear locator flag
        ld      (VARNAM),hl       ; Clear Variable Name
_link_lines:
        ld      de,(TXTTAB)       ; DE = start of BASIC program
        jp      link_lines        ; rebuild line links and return

;------------------------------------------------------------------------------
;;; ---
;;; ## SAVE Statement (Updated)
;;; Save File to USB Drive
;;; ### FORMAT:
;;;  - SAVE "*filename*"
;;;    - Action: Save BASIC program to file *filename* on USB drive.
;;;      - *filename* can be any string expression
;;;      - If *filename* is shorter than 9 characters and does not contain a ".", the extension ".BAS" is appended.
;;;      - If *filspec* is a literal string, the end quotation mark is optional.
;;;      - Advanced: File on USB drive will be in CAQ format with the internal filename set to the first 6 characters of *filename*.
;;;  - SAVE "*filespec*",\**arrayname*
;;;    - Action: Save contents of array *arrayname* to file *filename* on USB drive.
;;;      - If *filename* is shorter than 9 characters and does not contain a ".", the extension ".CAQ" is added.
;;;      - Advanced: File on USB drive will be in CAQ format with the internal filename set to "######".
;;;  - SAVE *filespec*,*address*,*length*[,*offset*]
;;;    - Action: Saves *length* bytes of memory starting at *address* to file *filename* on USB drive.
;;; ### ERRORS
;;;  - If *filespec* is not included, an MO Error results
;;;  - If file *filespec* does not exist, an IO Error with DOS Error "file not found" results.
;;;  - If *arrayname* is specified and the array is not DIMmed, an FC Error results.
;;; ### EXAMPLES:
;;; ` SAVE "progname" `
;;; > Save current program to USB drive with file name "PROGNAME.BAS"
;;;
;;; ` SAVE "progname." `
;;; > Save current program to USB drive with file name "PROGNAME"
;;;
;;; ` SAVE "progname.caq" `
;;; > Save current program to USB drive with file name "PROGNAME.CAQ"
;;;
;;; ` SAVE "array",*A `
;;; > Save contents of array A() to USB drive with file name "ARRAY.CAQ"
;;;
;;; ` SAVE "capture.src",12288,2048 `
;;; > Save Screen and Color RAM as raw binary file
;------------------------------------------------------------------------------

ST_SAVE:
    call    _get_file_args      ; Get Filename, Address, Length, Offset
    push    hl                  ; PUSH BASIC text pointer
    ld      hl,FileName
    bit     DF_OFS,(iy+0)       ; If Offset was specified
    jr      nz,_sts_offset      ;   Write to that Position in File
    bit     DF_ADDR,(iy+0)
    jr      nz,_sts_binary
; saving BASIC program or array
    bit     DF_ARRAY,(iy+0)     ; saving array?
    jr      z,_sts_bas
; saving array
    ld      de,dos_caq_ext
    call    _sts_open_wrsync
    ld      hl,dos_array_name   ; "######"
    ld      de,6
    call    usb__write_bytes
    jr      nz,_sts_write_error
    ld      hl,(BINSTART)
    ld      de,(BINLEN)
    jr      _sts_write_data 
; saving BASIC program
_sts_bas:
    ld      de,dos_bas_ext
    call    _sts_open_wrsync
    ld      hl,FileName
    ld      de,6                ; write 1st 6 chars of filename
    call    usb__write_bytes
    jr      nz,_sts_write_error
    call    st_write_sync       ; write 2nd caq sync $FFx12,$00
    jr      nz,_sts_write_error
    ld      de,(TXTTAB)         ; DE = start of BASIC program
    ld      hl,(VARTAB)         ; HL = end of BASIC program
    or      a
    sbc     hl,de
    ex      de,hl               ; HL = start, DE = length of BASIC program
_sts_write_data:
    call    usb__write_bytes    ; write data block to file
    ld      b,15                ; write CAQ tail $00x15
_sts_tail
    ld      a,0
    call    usb__write_byte     
    jr      nz,_sts_write_error
    djnz    _sts_tail
    jr      _sts_write_done
; saving BINARY
_sts_offset:
    call    usb__open_rewrite     ; create/open new file
    jr      nz,_sts_open_error
    ld      de,(BINOFS)
    call    usb__seek
    jp      nz,_dos_do_error
    jr      _sts_write_bin
_sts_binary:
    call    usb__open_write     ; create/open new file
    jr      nz,_sts_open_error
_sts_write_bin:
    ld      hl,(BINSTART)       ; raw binary file - no header, no tail
    ld      de,(BINLEN)
    call    usb__write_bytes    ; write data block to file
_sts_write_done:
    push    af
    call    usb__close_file     ; close file
    pop     af
    jr      z,_sts_done         ; if wrote OK then done
; error while writing
_sts_write_error:
    ld      a,ERROR_WRITE_FAIL
    jr      _sts_show_error
; error opening file
_sts_open_error:
    ld      a,ERROR_CREATE_FAIL
_sts_show_error:
    jp      _dos_do_error       ; show DOS error message and error out
_sts_done:
    call    set_dos_File_datetime
    pop     hl                  ; restore BASIC text pointer
    ret

_sts_open_wrsync:
    call    dos_append_ext
    call    usb__open_write     ; create/open new file
    jr      nz,_sts_open_error
    call    st_write_sync       ; write caq sync 12 x $FF, $00
    jr      nz,_sts_write_error
    ret


;----------------------------------------------------------------------------
; Parse LOAD/SAVE Arguments
;----------------------------------------------------------------------------
_get_file_args:
    ld      iy,DosFlags
    call    dos__getfilename      ; Clear DOS SysVars, Parse FileName
    jp      nz,_badname_error     ; 
    call    CHRGT2                ; Check character after FIlename
    cp      ','                   ; If not a comma
    ret     nz                    ;   Return with No DOS Flags Set
    rst     CHRGET                ; Get character after comma
    cp      MULTK                 ; If it's the '*' token?
    jr      z,_get_array_arg      ;   Parse Array arg, set flag, Return
    call    GETADR                ; Parse Address
    ld      (BINSTART),de         ; Store It
    set     DF_ADDR,(iy+0)        ; Set Flag
    call    CHRGT2                ; Check character after Address
    cp      ','                   ; If not a comma
    ret     nz                    ;   Return
    rst     CHRGET                ; Get character after comma
    cp      ','                   ; If a comma
    jr      z,.nolen              ;   Go Straight to Offset
    call    GETADR                ; Skip Comma and Parse Length
    ld      (BINLEN),de           ; Store It
    set     DF_LEN,(iy+0)         ; Set Flag
    call    CHRGT2                ; Check character after Length
    cp      ','                   ; If not a comma
    ret     nz                    ;   Return
.nolen:
    call    CHKADR                ; Skip Comma and Parse Offset
    ld      (BINOFS),de           ; Store It
    set     DF_OFS,(iy+0)         ; Set Flag
    ret

;----------------------------------------------------------------------------
; Parse LOAD/SAVE Array Argument
;----------------------------------------------------------------------------
_get_array_arg:
    rst     CHRGET                ; skip '*' token
    ld      a,1
    ld      (SUBFLG),a            ; set array flag
    call    PTRGET                ; get array (out: BC = address, DE = length)
    ld      (SUBFLG),a            ; clear array flag
    jp      nz,FCERR              ; FC Error if array not found
    call    CHKNUM                ; TM error if not numeric
_get_array_parms:
    push    hl                    ; push BASIC text pointer
    ld      h,b
    ld      l,c                   ; HL = address
    ld      c,(hl)
    ld      b,0                   ; BC = index
    add     hl,bc
    add     hl,bc
    inc     hl                    ; HL = array data
    ld      (BINSTART),hl
    dec     de
    dec     de                    ; subtract array header to get data length
    dec     de
    ld      (BINLEN),de
    ld      a,1<<DF_ARRAY
    ld      (DOSFLAGS),a          ; set 'loading to array' flag
    pop     hl                    ; POP text pointer
    ret



;--------------------------------------------------------------------
;             Check for Extension, Add if Not Found
;--------------------------------------------------------------------
; in: HL = FileName
;     DE = Extension
; our: HL = FileName
dos_append_ext:
    push    hl                    ; Save FileName Pointer
    call    dos_find_ext          ; Find Position of '.' or NUL
    jp      nz,_pop_hl_ret        ; Return if Extension Found
    ld      a,b                   ; Check Position of Terminator
    cp      9                     ;   If greater than 8
    jp      nc,_pop_hl_ret        ;   return
    ex      de,hl                 ; Appending Extension to FileName
    ld      bc,5                  ; 5 characters total
    ldir
    pop     hl
    ret

;--------------------------------------------------------------------
;             Find Position of File Extension in FileName
;--------------------------------------------------------------------
; in: HL = Address of FileName
; out: HL = Address of Dot or Null Terminator
;      A = character at (HL), Flags Set Accordingly
;      B = Position of Dot or Null Terminator
dos_find_ext:
    ld      b,0
.loop:
    ld      a,(HL)                ; Get Next Character
    or      a                     ; If ASCII Null
    ret     z                     ;   Return
    cp      '.'                   ; 
    jr      z,_ora_ret            ; If Not Period
    inc     hl                    ;   Increment Pointer
    inc     b                     ;   Increment Position
    jr      .loop
_ora_ret:
    or      a                     ; Else Set Flags
    ret                           ;   and Return




;--------------------------------------------------------------------
;             Write CAQ Sync Sequence  12x$FF, $00
;--------------------------------------------------------------------
; uses: A, B
;
st_write_sync:
    ld      b,12
.write_caq_loop:
    ld      a,$FF
    call    usb__write_byte     ; write $FF
    ret     nz                  ; return if error
    djnz    .write_caq_loop
    ld      a,$00
    jp      usb__write_byte     ; write $00

;--------------------------------------------------------------------
;;; ---
;;; ## CAT
;;; Catalog disk (quick DIR listing)
;;; ### FORMAT:
;;;  - CAT
;;;    - Action: Show a brief listing of all files and folders in the current directory.
;;;      - File size, date, and time are not shown.
;;;      - Directory names are shown in < >.
;;; ### EXAMPLE:
;;; ` CAT `
;;; > List all files and folders in current directory in a 3-across format
;------------------------------------------------------------------------------

ST_CAT:
    push    hl                      ; save BASIC text pointer
    LD      A,$0D                   ; print carriage return
    CALL    TTYCHR
    ld      a,23
    ld      (CNTOFL),a              ; set initial number of lines per page
.cat_disk:
    call    dos__clearError
    call    usb__ready              ; check for USB disk
    jr      nz,.disk_error
    call    usb__open_dir           ; open '*' for all files in directory
    jr      z,.cat_loop
; usb_ready or open "*" failed
.disk_error:
    call    _show_error             ; show error code
    pop     hl
    ld      e,ERRFC
    jp      ERROR                   ; return to BASIC with FC error
.cat_loop:
    LD      A,CH376_CMD_RD_USB_DATA
    OUT     (CH376_CONTROL_PORT),A  ; command: read USB data (directory entry)
    IN      A,(CH376_DATA_PORT)     ; A = number of bytes in CH376 buffer
    OR      A                       ; if bytes = 0 then read next entry
    JR      Z,.cat_next
    LD      HL,-16
    ADD     HL,SP                   ; allocate 16 bytes on stack
    LD      SP,HL
    LD      B,12                    ; B = 11 bytes filename, 1 byte file attributes
    LD      C,CH376_DATA_PORT
    INIR                            ; get filename, attributes
    LD      B,16
.absorb_bytes:
    IN      A,(CH376_DATA_PORT)     ; absorb bytes until filesize
    DJNZ    .absorb_bytes
    LD      B,4                     ; B = 4 bytes file size
.read_size:
    INIR                            ; get file size
    LD      BC,-5
    ADD     HL,BC                   ; HL = attributes
    LD      A,(HL)                  ; get attributes
    LD      BC,-11                  ; HL = filename
    ADD     HL,BC
    LD      C,A                     ; C = attributes
    LD      B,8                     ; 8 chars in file name
    BIT     ATTR_B_DIRECTORY,C
    JR      Z,.cat_name
    LD      A,'<'
    CALL    TTYCHR                  ; print '<' in front of directory name
.cat_name:
    LD      A,(HL)
    INC     HL
    CALL    TTYCHR                  ; print name char
    DJNZ    .cat_name
    BIT     ATTR_B_DIRECTORY,C
    JR      NZ,.extn
    LD      A," "                   ; print ' ' between file name and extension
.separator:
    CALL    TTYOUT
.extn:
    LD      A,(HL)
    INC     HL
    CALL    TTYOUT                  ; print 1st extn char
    LD      A,(HL)
    INC     HL
    CALL    TTYOUT                  ; print 2nd extn char
    LD      A,(HL)
    CP      ' '
    JR      NZ,.last                ; if 3rd extn char is SPACE
    BIT     ATTR_B_DIRECTORY,C      ; and name is directory then
    JR      Z,.last
    LD      A,'>'                   ; replace with '>'
.last:
    CALL    TTYOUT                  ; print 3rd extn char
    LD      HL,16
    ADD     HL,SP                   ; clean up stack
    LD      SP,HL
    LD      A,(TTYPOS)
    AND     A                       ; if column = 0 then already on next line
    JR      Z,.cat_go
    LD      A," "                   ; else padding space after filename
    CALL    TTYOUT
.cat_go:
    LD      A,CH376_CMD_FILE_ENUM_GO
    OUT     (CH376_CONTROL_PORT),A  ; command: read next filename
    CALL    usb__wait_int           ; wait until done
.cat_next:
    CP      CH376_INT_DISK_READ     ; more entries?
    JR      Z,.cat_loop             ; yes, get next entry
.cat_done:
    pop     hl                      ; restore BASIC text pointer
    RET

;--------------------------------------------------------------------
;;; ---
;;; ## DIR
;;; Get a listing of the files on the current USB directory
;;; ### FORMAT:
;;;  - DIR [ "*wildcard*" ]
;;;    - Action: Show files in current directory with size, with an optional wildcard on filename
;;;  - DIR SDTM [ "*wildcard*" ]
;;;    - Action: Show files in current directory with size, date, and time, with optional *wildcard* on filename
;;;    - Final quotation mark at end of *wildcard* string is optional.
;;; ### EXAMPLES:
;;; ` DIR `
;;; > Show all files in current directory
;;;
;;; ` DIR "*.BAS" `
;;; > Show BASIC program files in current directory
;;;
;;; ` DIR "*." `
;;; > List all folder (or files without an extension) in current directory
;;;
;;; ` DIR SDTM "*A*" `
;;; > Show any files with a letter A in the name, along with their last DateTime stamp
;------------------------------------------------------------------------------

ST_DIR:
    ld      a,ATTR_HIDDEN+ATTR_SYSTEM
    ld      (DosFlags),a      ; filter out system and hidden files
    call    dos__clearError   ; returns A = 0
    ld      (FileName),a      ; wildcard string = NULL
    call    CHRGOT            ; check for arguments
    jp      p,.st_dir_wc      ; if token
    cp      SDTMTK            ;   check for SDTM
    jp      nz,FCERR          ;   if not, FC error
    ld      a,1<<DF_SDTM      ;   
    ld      (DosFlags),a      ;   set 'show DateTime' flag    
    rst     chrget            ;   skip SDTM Token
.st_dir_wc:
    jr      z,.st_dir_go      ; if no wildcard then show all files
    call    dos__getfilename  ; wildcard -> FileName
.st_dir_go:
    push    hl                ; PUSH text pointer
    call    usb_ready         ; check for USB disk (may reset path to root!)
    jr      nz,.error
    call    STROUT            ; print path
    call    CRDO
    call    dos__directory    ; display directory listing
    jr      z,.st_dir_done    ; if successful listing then done
.error:
    call    _show_error       ; else show error message (A = error code)
    ld      e,ERRFC
    pop     hl
    jp      ERROR             ; return to BASIC with FC error
.st_dir_done:
    pop     hl                ; POP text pointer
    ret

;-----------------------------------------
;      FAT Directory Info structure
;-----------------------------------------
; structure FAT_DIR_INFO
;    STRUCT DIR_Name,11;         ; $00 0
;     UINT8 DIR_Attr;            ; $0B 11
;     UINT8 DIR_NTRes;           ; $0C 12
;     UINT8 DIR_CrtTimeTenth;    ; $0D 13
;    UINT16 DIR_CrtTime;         ; $0E 14
;    UINT16 DIR_CrtDate;         ; $10 16
;    UINT16 DIR_LstAccDate;      ; $12 18
;    UINT16 DIR_FstClusHI;       ; $14 20
;    UINT16 DIR_WrtTime;         ; $16 22
;    UINT16 DIR_WrtDate;         ; $18 24
;    UINT16 DIR_FstClusLO;       ; $1A 26
;    UINT32 DIR_FileSize;        ; $1C 28
; endstruct FAT_DIR_INFO;        ; $20 32

;------------------------------------------------------------------------------
;                     Read and Display Directory
;------------------------------------------------------------------------------
; Reads all filenames in directory, printing only those names that match the
; wildcard pattern.
;
; in: FILENAME = wildcard string (null string for all files)
;
; out: Z = OK, NZ = no disk
;
; uses: A, BC, DE, HL
;
dos__directory:
        LD      A,$0D
        CALL    TTYOUT                  ; print CR
        CALL    usb__open_dir           ; open '*' for all files in directory
        RET     NZ                      ; abort if error (disk not present?)
        ld      a,22
        ld      (CNTOFL),a              ; set initial number of lines per page
.dir_loop:
        LD      A,CH376_CMD_RD_USB_DATA
        OUT     (CH376_CONTROL_PORT),A  ; command: read USB data
        LD      C,CH376_DATA_PORT
        IN      A,(C)                   ; A = number of bytes in CH376 buffer
        CP      32                      ; must be 32 bytes!
        RET     NZ
        LD      B,A
        LD      HL,-32
        ADD     HL,SP                   ; allocate 32 bytes on stack
        LD      SP,HL
        PUSH    HL
        INIR                            ; read directory info onto stack
        POP     HL
        ld      bc,11                   
        add     hl,bc                   ; move to attribute byte
        ld      a,(DosFlags)            ; get attribute mask
        and     (hl)                    ; check attribute bits
        jr      nz,.dir_skip            ; if match, skip file
        sbc     hl,bc                   ; move back to first byte
        ld      DE,FileName             ; DE = wildcard pattern
        call    usb__wildcard           ; Z if filename matches wildcard
        call    z,dos__prtDirInfo       ; display file info (type, size)
.dir_skip:
        LD      HL,32
        ADD     HL,SP                   ; clean up stack
        LD      SP,HL
        LD      A,CH376_CMD_FILE_ENUM_GO
        OUT     (CH376_CONTROL_PORT),A  ; command: read next filename
        CALL    usb__wait_int           ; wait until done
.dir_next:
        CP      CH376_INT_DISK_READ     ; more entries?
        JP      Z,.dir_loop             ; yes, get next entry
        CP      CH376_ERR_MISS_FILE     ; Z if end of file list, else NZ
        RET



;--------------------------------------------------------------------
;                      Print File Info
;--------------------------------------------------------------------
; in: HL = file info structure (32 bytes)
;
; if directory then print "<dir>"
; if file then print size in Bytes, kB or MB
;
dos__prtDirInfo:
        LD      B,8                     ; 8 characters in filename
.dir_name:
        LD      A,(HL)                  ; get next char of filename
        INC     HL
.dir_prt_name:
        call    TTYCHR                  ; print filename char, with pause if end of screen
        DJNZ    .dir_name
        LD      A," "                   ; space between name and extension
        call    TTYOUT
        LD      B,3                     ; 3 characters in extension
.dir_ext:
        LD      A,(HL)                  ; get next char of extension
        INC     HL
        call    TTYOUT                  ; print extn char
        DJNZ    .dir_ext
        LD      A,(HL)                  ; get file attribute byte
        INC     HL
        push    af
        LD      A,' '                   ; print ' '
        CALL    TTYOUT
        LD      BC,10                   ; DIR_WrtTime-DIR_NTres
        ADD     HL,BC                   ; skip to write time
        ld      a,(DosFlags)
        bit     DF_SDTM,a
        jr      z,.dir_skip_datetime
.dir_time_stamp:
        call    format_fts              ; Convert FTS at (HL) to formatted date string
        ld      b,16
.dir_datetime:
        ld      a,(de)                  ; get next char formatted DateTime
        inc     de
        call    TTYOUT                  ; 
        djnz    .dir_datetime
        LD      A,' '                   ; print ' '
        CALL    TTYOUT
.dir_skip_datetime:
        pop     af
        AND     ATTR_DIRECTORY          ; directory bit set?
        JP      NZ,.dir_folder
        ld      bc,6                    ; DIR_FileSize-DIR_WrtTime
        add     hl,bc                   ; skip to file size
.dir_file_size:
        LD      E,(HL)
        INC     HL                      ; DE = size 15:0
        LD      D,(HL)
        INC     HL
        LD      C,(HL)
        INC     HL                      ; BC = size 31:16
        LD      B,(HL)

        LD      A,B
        OR      C
        JR      NZ,.kbytes
        LD      A,D
        CP      high(10000)
        JR      C,.bytes
        JR      NZ,.kbytes              ; <10000 bytes?
        LD      A,E
        CP      low(10000)
        JR      NC,.kbytes              ; no,
.bytes:
        LD      H,D
        LD      L,E                     ; HL = file size 0-9999 bytes
        JR      .print_bytes
.kbytes:
        LD      L,D
        LD      H,C                     ; C, HL = size / 256
        LD      C,B
        LD      B,'k'                   ; B = 'k' (kbytes)
        LD      A,D
        AND     3
        OR      E
        LD      E,A                     ; E = zero if size is multiple of 1 kilobyte
        SRL     C
        RR      H
        RR      L
        SRL     C                       ; C,HL = size / 1024
        RR      H
        RR      L
        LD      A,C
        OR      A
        JR      NZ,.dir_MB
        LD      A,H
        CP      high(1000)
        JR      C,.dir_round            ; <1000kB?
        JR      NZ,.dir_MB
        LD      A,L
        CP      low(1000)
        JR      C,.dir_round            ; yes
.dir_MB:
        LD      A,H
        AND     3
        OR      L                       ; E = 0 if size is multiple of 1 megabyte
        OR      E
        LD      E,A

        LD      B,'M'                   ; 'M' after number

        LD      L,H
        LD      H,C
        SRL     H
        RR      L                       ; HL = kB / 1024
        SRL     H
        SRL     L
.dir_round:
        LD      A,H
        OR      L                       ; if 0 kB/MB then round up
        JR      Z,.round_up
        INC     E
        DEC     E
        JR      Z,.print_kB_MB          ; if exact kB or MB then don't round up
.round_up:
        INC     HL                      ; filesize + 1
.print_kB_MB:
        LD      A,3                     ; 3 digit number with leading spaces
        CALL    print_integer           ; print HL as 16 bit number
        LD      A,B
        CALL    TTYOUT                  ; print 'k', or 'M'
        JR      .dir_tab
.print_bytes:
        LD      A,4                     ; 4 digit number with leading spaces
        CALL    print_integer           ; print HL as 16 bit number
        LD      A,' '
        CALL    TTYOUT                  ; print ' '
        JR      .dir_tab
.dir_folder:
        LD      HL,dos_dir_msg          ; print "<dir>"
        call    STROUT
.dir_tab:
        LD      A,(TTYPOS)
        CP      19
        RET     Z                       ; if reached center of screen then return
        JR      NC,.tab_right           ; if on right side then fill to end of line
        LD      A,' '
        CALL    TTYOUT                  ; print " "
        JR      .dir_tab
.tab_right:
        LD      A,(TTYPOS)
        CP      0
        RET     Z                       ; reached end of line?
        LD      A,' '
        CALL    TTYOUT                  ; no, print " "
        JR      .tab_right


;--------------------------------------------------------------------
;;; ---
;;; ## DEL
;;; Delete a file
;;; ### FORMAT:
;;;  - DEL *filespec*
;;;    - Action: Deletes the file named *filespec* from the current directory.
;;;      - *filespec* can be any string expression
;;;      - No warnings are given.
;;;      - Wildcards and paths cannot be used.
;;;      - If *filspec* is a literal string, the end quotation mark is optional.
;;; ### ERRORS
;;;  - If *filespec* is not included, an MO Error results
;;;  - If file *filespec* does not exist, an IO Error with DOS Error "file not found" results.
;;; ### EXAMPLES:
;;; ` DEL "THISFILE.BAS" `
;;; > Deletes the file named `THISFILE.BAS` from the current directory.
;;;
;;; ` 10 DEL "SAVEGAME.DAT" `
;;; > Deletes the file named `SAVEGAME.DAT` from the current folder from within a program.
;------------------------------------------------------------------------------
;
ST_DEL:
    call   dos__getfilename  ; filename -> FileName
    push   hl                ; push BASIC text pointer
    jr     nz,_badname_error
    ld     hl,FileName
    call   usb__delete       ; delete file
    jr     z,_pop_hl_ret
    ld     a,ERROR_NO_FILE
_dos_do_error:
    call   _show_error       ; print error message
IOERR:
    ld     e,ERRIO
    jp     ERROR
_pop_hl_ret:
    pop    hl                ; pop BASIC text pointer
    ret
_badname_error:
    ld     a,ERROR_BAD_NAME
    jr     _dos_do_error


;----------------------------------------------------------------
;                         Set Path
;----------------------------------------------------------------
;
;    In:    HL = string to add to path (NOT null-terminated!)
;            A = string length
;
;   out:    DE = original end of path
;            Z = OK
;           NZ = path too long
;
; path with no leading '/' is added to existing path
;         with leading '/' replaces existing path
;        ".." = removes last subdir from path
;
dos__set_path:
        PUSH   BC
        LD     C,A               ; C = string length
        LD     DE,PathName
        LD     A,(DE)
        CP     '/'               ; does current path start with '/'?
        JR     Z,.gotpath
        CALL   usb__root         ; no, create root path
.gotpath:
        INC    DE                ; DE = 2nd char in pathname (after '/')
        LD     B,path.size-1     ; B = max number of chars in pathname (less leading '/')
        LD     A,(HL)
        CP     '/'               ; does string start with '/'?
        JR     Z,.rootdir        ; yes, replace entire path
        JR     .path_end         ; no, goto end of path
.path_end_loop:
        INC    DE                ; advance DE towards end of path
        DEC    B
        JR     Z,.fail           ; fail if path full
.path_end:
        LD     A,(DE)
        OR     A
        JR     NZ,.path_end_loop
; at end-of-path
        LD     A,'.'             ; does string start with '.' ?
        CP     (HL)
        JR     NZ,.subdir        ; no
; "." or ".."
        INC    HL
        CP     (HL)              ; ".." ?
        JR     NZ,.ok            ; no, staying in current directory so quit
.dotdot:
        DEC    DE
        LD     A,(DE)
        CP     '/'               ; back to last '/'
        JR     NZ,.dotdot
        LD     A,E
        CP     low(PathName)     ; at root?
        JR     NZ,.trim
        INC    DE                ; yes, leave root '/' in
.trim:  XOR    A
        LD     (DE),A            ; NULL terminate pathname
        JR     .ok               ; return OK
.rootdir:
        PUSH   DE                ; push end-of-path
        JR     .nextc            ; skip '/' in string, then copy to path
.subdir:
        PUSH   DE                ; push end-of-path before adding '/'
        LD     A,E
        CP     low(PathName)+1   ; at root?
        JR     Z,.copypath       ; yes,
        LD     A,'/'
        LD     (DE),A            ; add '/' separator
        INC    DE
        DEC    B
        JR     Z,.undo           ; if path full then undo
.copypath:
        LD     A,(HL)            ; get next string char
        CALL   dos__char         ; convert to MSDOS
        LD     (DE),A            ; store char in pathname
        INC    DE
        DEC    B
        JR     Z,.undo           ; if path full then undo and fail
.nextc: INC    HL
        DEC    C
        JR     NZ,.copypath      ; until end of string
.nullend:
        XOR    A
        LD     (DE),A            ; NULL terminate pathname
        JR     .copied
; if path full then undo add
.undo:  POP    DE                ; pop original end-of-path
.fail:  XOR    A
        LD     (DE),A            ; remove added subdir from path
        INC    A                 ; return NZ
        JR     .done
.copied:
        POP    DE                ; DE = original end-of-path
.ok     CP     A                 ; return Z
.done:  POP    BC
        RET


;--------------------------------------------------------------------
;                        Get Filename
;--------------------------------------------------------------------
; Get Filename argument from BASIC text or command line.
; May be literal string, or an expression that evaluates to a string
; eg. LOAD "filename"
;     SAVE left$(A$,11)
;
; in:  HL = BASIC text pointer
;
; out: Uppercase filename in FileName, 1-12 chars null-terminated
;      HL = BASIC text pointer
;       z = OK
;      nz = error, A = $08 null string, $18 not a string
;
; uses: BC,DE
;
dos__getfilename:
    call    dos__clearVars    ; Set All DOS SysVars to 0
    call    FRMEVL            ; evaluate expression
_convert_filename:
    push    hl                ; save BASIC text pointer
    call    CHKSTR
    call    LEN1              ; get string and its length
    jr      z,.null_str       ; if empty string then return
    cp      12
    jr      c,.string         ; trim to 12 chars max
    ld      a,12
.string:
    ld      b,a               ; B = string length
    inc     hl
    inc     hl                ; skip to string text pointer
    ld      a,(hl)
    inc     hl
    ld      h,(hl)
    ld      l,a               ; hl = string text pointer
    ld      de,FileName       ; de = filename buffer (13 bytes)
.copy_str:
    ld      a,(hl)            ; get string char
    CALL    UpperCase         ; 'a-z' -> 'A-Z'
    CP      '='
    jr      nz,.dos_char
    LD      A,'~'             ; convert '=' to '~'
.dos_char:
    ld      (de),a            ; copy char to filename
    inc     hl
    inc     de
    djnz    .copy_str         ; loop back to copy next char
    jr      .got_name         ; done
.null_str:
    ld      a,$08             ; function code error
    jr      .done
.type_mismatch:
    ld      a,$18             ; type mismatch error
    jr      .done
.got_name:
    xor     a                 ; no error
    ld      (de),a            ; terminate filename
.done:
    pop     hl                ; restore BASIC text pointer
    or      a                 ; test error code
    ret

;Check/Convert DOS File Name Character
;In/Out: A = Character
;Returns Carry Set if Illegal Character
; Legal characters: A-Z 0-9 $ _ ~ 
dos__filechar:
    cp      '$'               ; If $
    ret     z                 ;   Return No Carry
    cp      '_'               ; If _
    ret     z                 ;   Return No Carry
    cp      '='               ; 
    jr      nz,.noteq         ; If =
    ld      a,'~'             ;   Change to ~
    cp      '~'               ; If ~
    ret     z                 ;   Return No Carry
.noteq    
    cp      '0'               ; If < 0
    ret     c                 ;   Return Carry Set
    cp      ':'               ; If < :
    jr      c,.ccfret         ;   Return No Carry
    cp      'a'               
    jr      nc,.notlower      ; If >= a
    and     $5F               ;   Make Uppercase
.notlower
    cp      '['               ; If > Z
    jr      nc,.ccfret
    cp      'A'               ; Compare to A
    ret                       ; and Return  
.ccfret
    ccf                       ; Complement Carry
    ret                       ; and Return

;----------------------------------------------------------
;      Convert FAT filename to DOS filename
;----------------------------------------------------------
;
; eg. "NAME    EXT" -> "NAME.EXT",0
;
;   in: HL = FAT filename (11 chars)
;       DE = DOS filename string (13 chars)
;
; NOTE: source and destination can be the same string, but
;       string must have space for 13 chars.
;
;
dos__name:
   push  bc
   push  de
   push  hl
   ld    b,8
.getname:
   ld    a,(hl)       ; get name char
   inc   hl
   cp    " "          ; don't copy spaces
   jr    z,.next
   ld    (de),a       ; store name char
   inc   de
.next:
   djnz  .getname
   ld    a,(hl)       ; A = 1st extn char
   cp    " "
   jr    z,.end       ; if " " then no extn
   ex    de,hl
   ld    (hl),"."     ; add separator
   ex    de,hl
   inc   de
   ld    b,3          ; 3 chars in extn
.extn:
   inc   hl
   ld    c,(hl)       ; C = next extn char
   ld    (de),a       ; store current extn char
   inc   de
   dec   b
   jr    z,.end       ; if done 3 chars then end of extn
   ld    a,c
   cp    ' '          ; if space then end of extn
   jr    nz,.extn
.end:
   xor   a
   ld    (de),a       ; NULL end of DOS filename string
.done:
   pop   hl
   pop   de
   pop   bc
   ret

;------------------------------------------------------------------------------
;              Convert Character to MSDOS equivalent
;------------------------------------------------------------------------------
;  Input:  A = char
; Output:  A = MDOS compatible char
;
; converts:-
;     lowercase to upppercase
;     '=' -> '~' (in case we cannot type '~' on the keyboard!)
;
dos__char:
        CP      'a'
        JR      C,.uppercase
        CP      'z'+1          ; convert lowercase to uppercase
        JR      NC,.uppercase
        AND     $5f
.uppercase:
        CP      '='
        RET     NZ             ; convert '=' to '~'
        LD      A,'~'
        RET



;------------------------------------------------------------------------------
;              Set DosError and ChStatus to 0
;              Set all DOS SysVars to 0
;------------------------------------------------------------------------------
; Ouput: A = 0, with flags set
dos__clearError:
    ld      b,2                   ; Clear first four bytes
    db      $11                   ; LD DE, over following LD B,
dos__clearVars:
    ld      b,11                  ; Clear 11 Bytes
    xor     a
    ld      de,DosError           
.loop
    ld      (de),a
    inc     de
    djnz    .loop
    ret

;------------------------------------------------------------------------------
;              Sets File Date time stamp on Write
;------------------------------------------------------------------------------
;  Input:  None - Expects Filename to be in the buffer already
;  Output:  NZ set if error
;
;  Reads the RTC and sets the Created & Modified timestamps in the File FS Details
;  If we ever start using interupts, then this will need DI/EI type code   
;

set_dos_File_datetime:
    push    hl                      ; Save Registers
    push    bc
    push    de
    ld      bc,RTC_SHADOW           ; setup BC to RTC_SHADOW
    ld      hl,DTM_BUFFER           ; Setup HL to DTM_BUFFER
    call    rtc_read                ; get current Date/time into DTM_Buffer
    jr      z,._sdfdt_ErrorOrNoCLK   ; exit if no clock
    ld      hl,FileName             ; get current filename
    call    usb__read_dir_Info      ; try to open file and read DIR info
    jr      nz,._sdfdt_ErrorOrNoCLK ; got an error - goto handler
.sdfdt_Process_Entry
    LD      A,CH376_CMD_RD_USB_DATA ; No error - so will read the 32 bytes 
    OUT     (CH376_CONTROL_PORT),A  ; command: read USB data
    LD      C,CH376_DATA_PORT
    IN      A,(C)                   ; A = number of bytes in CH376 buffer
    ld      b,a                     ; copy into B (for the inir loop later)
    CP      32                      ; must be 32 bytes!
    jr      nz,._sdfdt_ErrorOrNoCLK ; got an error - goto handler
    LD      HL,-32
    ADD     HL,SP                   ; allocate 32 bytes on stack
    LD      SP,HL
    PUSH    HL
    INIR                            ; read directory info onto stack
    POP     HL
    ld      bc,14                     
    add     hl,bc                   ; move to Create Date Time byte
    ex      de,hl                   ; swap de & hl - de now contains pointer to DateTime
    ld      hl,DTM_BUFFER           ; HL to DTM_Buffer 
    call    dtm_to_fts              ; convert DTM_Buffer to FS Timestamp 
    ld      h,d                     ; copy DE into HL
    ld      l,e
    push    hl                      ; save hl for later (writing the data to the ch)
    ld      bc,8                    ; Add 8
    add     hl,bc                   ; HL points to Modified Timestamp
    ex      de,hl                   ; Swap HL DE
    ld      bc,4                    ; want to copy 4 bytes
    ldir                            ; copy create time to modified time
    pop     hl
    LD      A,CH376_CMD_WR_OFS_DATA ; So Now send the command to write the FS data back to the CH376
    OUT     (CH376_CONTROL_PORT),A  ; 
    ld      a,14                    ; start writing from byte 14
    LD      C,CH376_DATA_PORT       ;
    OUT     (C),a                   ; Send to CH376
    ld      a,12                    ; going to write 12 bytes
    OUT     (C),a                   ; Send to Ch376
    ld      b,a                     ; so we write created & modified
    otir                            ; write the 12 bytes (pointed to by HL)
    call    usb__Write_dir_Info     ; actually write the data back to the CH376
.sdfd_cleanup:
   LD      HL,32
   ADD     HL,SP                   ; clean up stack
   LD      SP,HL
._sdfdt_ErrorOrNoCLK
    pop     de
    pop     bc
    pop     hl
    ret

; Get File Information:
; In: FileName
; Out: DTM_STRING = File Write Date and Time
;      FACLO..FAC = File Size
; Destroys: A, BC, DE, HL
dos__open_getinfo:
    ld      hl,FileName             ; get current filename
    call    usb__read_dir_Info     ; try to open file and read DIR info
    ret     nz                      ; return if error
    ld      a,CH376_CMD_RD_USB_DATA ; No error - so will read the 32 bytes 
    out     (CH376_CONTROL_PORT),a  ; command: read USB data
    ld      c,CH376_DATA_PORT
    in      a,(c)                   ; A = number of bytes in CH376 buffer
    ld      b,a                     ; copy into B (for the inir loop later)
    cp      32                      ; must be 32 bytes!
    ret     nz                      ; return if error
    ld      hl,-32
    add     hl,sp                   ; allocate 32 bytes on stack
    ld      sp,hl
    push    hl
    inir                            ; read directory info onto stack
    pop     hl
    ld      bc,22                     
    add     hl,bc                   ; Move toDate/Time
    push    hl                      ; Save Address
    ex      de,hl                   ; DE = Pointer to FTS
    ld      hl,dtm_buffer
    call    fts_to_dtm              ; Convert TimeStamp to DateTime
    ld      de,DTM_STRING
    call    dtm_to_str              ; Convert to String
    pop     hl                      ; Restore Address of Mod Date/Time
    ld      bc,6                    ; 
    add     hl,bc                   ; Move to File Size
    ld      de,FACLO
    ld      bc,4
    ldir                            ; Copy File Size to Floating Point Accumulator
    ld      sp,hl                   ; Now at end of allocated space, restore Stack Pointer
    jp      usb__close_file         ; close file and return

;------------------------------------------------------------------------------
;;; ---
;;; ## FILE$
;;; Get Last Filename
;;; ### FORMAT:
;;;  - FILE$
;;;    - Action: Returns the contents of the FileName buffer.
;;; ### EXAMPLES:
;;; ` PRINT FILE$ `
;;; > Prints the name of the last file accessed.
;------------------------------------------------------------------------------
;;; ---
;;; ## FILEEND
;;; Get End Address of Last LOADed File
;;; ### FORMAT:
;;;  - FILE$
;;;    - Action: Returns the end address of the last successful LOAD. This is the address of the last byte loaded plus one.
;;; ### EXAMPLES:
;;; ```
;;; LOAD "BINFILE.RAW",START
;;; PRINT FILEEND-START
;;; ```
;;; > Loads file then prints the total bytes loaded.
;------------------------------------------------------------------------------
FN_FILE:
    inc     hl                    ; Skip FILE Token
    ld      a,(hl)                ; Get Next Character
    cp      '$'                   ;  
    jr      nz,.not_dollar        ; If Dollar Sign  
    rst     CHRGET                ;   Skip it
    push    hl                    ;   Text Pointer on Stack
    push    bc                    ;   put dummy return address on stack
    ld      hl,FileName           ;   Get pointer to Filename in HL
    jp      TIMSTR                ;   and return it
.not_dollar:                      ; 
    cp      ENDTK                 ; 
    jr      nz,.not_endtk         ; If End Token
    rst     CHRGET                ;   Skip it
    push    hl                    ;   Text Pointer on Stack
    ld      bc,LABBCK             ;   Put Return Address 
    push    bc                    ;   for FLOAT_DE on stack
    ld      de,(BinEnd)           ;   DE = Last LOAD End Address
    jp      FLOAT_DE              ;   Float it and Return
.not_endtk:
    ; FILELEN and FILEDTM will be implemented in the next release
    ; after CH376 command CMD_DIR_INFO_READ is added to Aqualite 
    jp      SNERR               

    push    af                    ;   Save Character after FILE Token
    rst     CHRGET                ;   and Skip it
    SYNCHK  '('                   ;   Require Open Parenthesis
    call    dos__getfilename      ;   Parse FileName
    SYNCHK  ')'                   ;   Require Close Parenthesis
    ex      (sp),hl               ;   Save Text Pointer, Get Character after FILE
    push    hl                    ;   Re-Save Character after FILE Token
    call    dos__open_getinfo     ;   Get Directory Entry for FileName
    jp      nz,_dos_do_error      ;   Handle Read Error
    pop     af                    ;   Get Back Character after FILE Token
    cp      DTMTK                 ;   Check Character after Pointer`
    jr      nz,.not_dtmtk         ;   If LEN Token
    ld      hl,DTM_STRING         ;   Returning Write Timestamp as DateTime
    push    bc                    ;   Push Dummy Return Address
    jp      TIMSTR                ;   Convert to String and Return
.not_dtmtk:
.not_lentk:                       ;   Else
    jp      FCERR                 ;     Function Call Error


; Convert 32 Bit Unsigned Int in FACLO..FAC to Floating Point Number
FLOAT_UINT32:
    ret

