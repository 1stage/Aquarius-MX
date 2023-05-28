;===============================================================================
;  Statement/Function Dispatch and Keyword Tables and Related Routines
;===============================================================================

TBLJMPS:
    dw      ST_PUT
    dw      ST_GET
    dw      ST_DRAW
    dw      ST_CIRCLE
    dw      ST_LINE
    dw      ST_SWAP
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
    dw      FN_STRING
    dw      FN_XOR
TBLFEND:

FCOUNT equ (TBLFEND-TBLFNJP)/2    ; number of functions

firstf equ BTOKEN+BCOUNT          ; token number of first function in table
lastf  equ firstf+FCOUNT-1        ; token number of last function in table

; Our Commands and Functions
;
; - New commands get added to the TOP of the commands list,
;   and the BTOKEN value DECREMENTS as commands are added.
;   They also get added at the TOP of the TBLJMPS list.
;
BTOKEN       equ $cc                ; our first token number
TBLCMDS:
; Commands list
    
;other keywords
    db      $80 + 'P', "UT"         ; $cc - Put Pixels
    db      $80 + 'G', "ET"         ; $cd - Get Pixels
    db      $80 + 'D', "RAW"        ; $ce - Graphic Macro Language
    db      $80 + 'C', "IRCLE"      ; $cf - Draw Circle
    db      $80 + 'L', "INE"        ; $d0 - Draw Line
    db      $80 + 'S', "WAP"        ; $d1 - Double Poke
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
    db      $80 + 'S', "TRING"      ; $ea - Create String function
    db      $80 + 'X', "OR"         ; $eb - Bitwise XOR
    db      $80                     ; End of table marker
ERRTK     = $E9
STRINGTK  = $EA
XORTK     = $EB

;-------------------------------------
;            NEXTSTMT
;-------------------------------------
; Called from $064b by RST 30
; with parameter $17


NEXTSTMT:
    jr      nc,BASTMT           ; if NC then process BASIC statement
    push    af                  ; Save Flags
    cp      POKETK-$80          ; If POKE Token
    jp      z,ST_POKE           ;   Do Extended POKE
    cp      COPYTK-$80          ; If COPY Token
    jp      z,ST_COPY           ;   Do Extended POKE
    cp      PSETTK-$80          ; If PSET
    jp      z,ST_PSET           ;   Do Extended BASIC PSET
    cp      PRESTK-$80          ; If PRESET
    jp      z,ST_PRESET         ;   Do Extended BASIC PRESET
    pop     af                  ; Else
    jp      HOOK23+1

BASTMT:
    sub     (BTOKEN)-$80
    jp      c,SNERR             ; SN error if < our 1st BASIC command token
    cp      BCOUNT              ; Count number of commands
    jp      nc,SNERR            ; SN error if > our last BASIC command token
    rlca                        ; A*2 indexing WORDs
    ld      c,a
    ld      b,$00               ; BC = index
    ex      de,hl
    ld      hl,TBLJMPS          ; HL = our command jump table
    jp      GONE5               ; Continue with NEXTSTMT

;-------------------------------------
;         Replace Command
;-------------------------------------
; Called from $0536 by RST $30,$0a
; Replaces keyword with token.

REPLCMD:
    ld      a,b                ; A = current index
    cp      $cb                ; if < $CB then keyword was found in BASIC table
    ld      IX,HOOK10+1        ;   CRUNCX will also return here when done
    push    IX
    ret     nz                 ;   so return
;     pop     bc                 ; get return address from stack
;     pop     af                 ; restore AF
;     pop     hl                 ; restore HL
;     push    bc                 ; put return address back onto stack
    ex      de,hl              ; HL = Line buffer
    ld      de,TBLCMDS-1       ; DE = our keyword table
    ld      b,BTOKEN-1         ; B = our first token
    jp      CRUNCX             ; continue searching using our keyword table

;-------------------------------------
;             PEXPAND
;-------------------------------------
; Called from $0598 by RST $30,$16
; Expand token to keyword

PEXPAND:
    cp      BTOKEN              ; is it one of our tokens?
    jr      nc,PEXPBAB          ; yes, expand it
    jp      HOOK22+1

PEXPBAB:
    sub     BTOKEN - 1
    ld      c,a                 ; C = offset to AquBASIC command
    ld      de,TBLCMDS          ; DE = table of AquBASIC command names
    jp      $05a8               ; Print keyword indexed by C

