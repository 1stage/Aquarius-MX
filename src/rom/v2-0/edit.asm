;====================================================================
; Mattel Aquarius:   Enhanced Line Editing Routines
;====================================================================
;
; changes:-
; 2015-11-13 STROUT after CTRL-C to ensure that cursor goes to next line.
;            Could not type into last char position in buffer - fixed.
; 2015-11-14 Cursor now restores original character color when removed.
; 2016-02-06 Return to BABASIC immediate mode loop.
; 2017-04-18 CTRL-R = retype previous line entered
; 2017-04-29 bugfix: EDIT retreiving another line if line not found
; 2017-05-06 using equates BUF and BUFLEN
;            retype clears old line before recalling history buffer
; 2023-05-22 Changed to use new 127 character line buffer LineBuf
; 2023-06-04 Changed back to BUF to fix literal strings in immediate mode

;---------------------------------------------------------------------
;;; ---
;;; ## EDIT
;;; Edit BASIC Line
;;; ### FORMAT:
;;;  - EDIT *line number*
;;;    - Action: Displays BASIC line *line number* on screen and enters edit mode. While editing a line, the following control keys are available:
;;; ```
;;;   CTL - P   Move cursor left
;;;   CTL - /   Move cursor right
;;;     <--     Delete character to left
;;;   CTL - \   Delete character to right
;;;     RTN     Save changes and exit edit mode
;;;   CTL - C   Discard changes and exit edit mode
;;;   CTL - R   Retype previously entered IMMEDIATE MODE command
;;; ```
;;;
;;;    - Note: The above control keys are also available when entering a new line or direct mode command.
;------------------------------------------------------------------------------


ST_EDIT:
    call  SCNLIN          ; DE = line number
    ld    a,d
    or    e
    jr    nz,.prtline
    ld    de,(ERRLIN)
    ld    a,d
    or    e
    jr    nz,.prtline
    ld    e,ERRMO         ; if no line number then MO error
    JP    ERROR
.prtline:
    ex    de,hl           ; HL = line number
    push  hl
    call  LINPRT          ; Print line number (also puts number string in $38ea)
    pop   de
    call  FNDLIN          ; find line in BASIC program
    push  af              ; push flags (c = found line in BASIC program)
    ld    de,BUF          ; DE = buffer
    ld    hl,FBUFFR+2     ; HL = floating point decimal number (line number)
    call  getinteger      ; copy decimal number string to edit buffer
    pop   af              ; pop flags
    push  de              ; push buffer pointer
    jr    nc,.gotline     ; if no line found then start with empty line
    ld    hl,4            ; skip line number, next line pointer
    add   hl,bc           ; HL = address of text in BASIC line
.getline:
    ld    a,(hl)          ; get next byte in BASIC line
    or    a
    jr    z,.gotline      ; if byte = 0 then end of line
    call  expand_token    ; copy char to buffer, expanding tokens
    inc   hl              ; next byte
    jr    .getline
.gotline:
    xor   a
    ld    (de),a          ; terminate string in buffer
    pop   hl              ; pop buffer pointer into HL
    ld    a,l
    sub   low(BUF)
    cpl
    inc   a
    add   BUFLEN          ; A = length of buffer - length of line number
    ld    b,a
.editline:
    call  EDITLINE        ; edit string in buffer
.done:
    inc   sp
    inc   sp              ; clean up stack
    jp    ENTERLINE       ; back to BABASIC immediate mode ($041d)

;----------------------------------
; Copy Decimal Number String
;----------------------------------
; copies digits until non-numeric
; character found.
;
;  in: HL = source string
;      DE = dest
;
; out: HL = first non-numeric char
;      DE = end of number string in dest (null-terminated)
;
getinteger:
    ld    a,(hl)
    inc   hl
    cp    '0'
    jr    c,.done
    cp    '9'+1
    jr    nc,.done
    ld    (de),a
    inc   de
    jr    getinteger
.done:
    xor   a
    ld    (de),a     ; null-terminate destination string
    ret


;-----------------------------
;   Expand token to string
;-----------------------------
; in: A  = char or token
;     DE = dest string address
;
expand_token:
    push  hl
    bit   7,a           ; if byte is less than $80 then just copy it
    jr    z,.exp_char
    cp    $95           ; if token for PRINT then expand to '?'
    jr    z,.exp_print
    ld    hl,$0245      ; HL = system BASIC keyword table
    sub   $7f           ; keyword table number number 1~xx
    cp    BTOKEN-1-$7f
    jr    c,.exp_count  ; if > $D3 then it must be a BABASIC keyword, so...
    ld    hl,TBLCMDS    ;    HL = BABASIC keyword table
    sub   BTOKEN-1-$7f  ;    BABASIC keyword table entry number 1~xx
.exp_count:
    ld    c,a           ; C = keyword counter
.exp_find:
    ld    a,(hl)        ; get char of current keyword in table
    inc   hl
    or    a
    jp    p,.exp_find   ; loop back until end of keyword
    dec   c             ; Word counter - 1
    jr    nz,.exp_find  ; Keep looping until we get to the correct keyword
.exp_token:
    and   $7f           ; remove marker bit from 1st character
    ld    (de),a        ; copy character of keyword
    inc   de
    ld    a,(hl)        ; get next char of keyword
    inc   hl
    bit   7,a
    jr    z,.exp_token  ; loop until end of keyword
    jr    .exp_end
.exp_print:
    ld    a,'?'         ; show '?' shortcut for PRINT
.exp_char:
    ld    (de),a
    inc   de
.exp_end:
    pop   hl
    ret


;--------------------------------------------------
;        Edit Line of Text in a Buffer
;--------------------------------------------------
;  in: HL = buffer address
;       B = buffer size
; out: Carry set if pressed CTRL-C
;      buffer holds text entered by user
;
EDITLINE:
    ld    a,(CURCHR)
    ld    de,(CURRAM)     ; hide system cursor
    ld    (de),a
    call  _showstr         ; show buffer on screen
    push  hl
    ld    d,-1
.strlen:
    ld    a,(hl)
    inc   hl
    inc   d               ; D = number of chars in string
    or    a
    jr    nz,.strlen
    pop   hl
    ld    e,0             ; E = cursor position in string
.waitkey:
    call  _show_cursor
    call  _clr_key_wait   ; wait for keypress
    call  _hide_cursor
    ld    c,a             ; C = key
    cp    ' '             ; If not a Control Key
    jr    nc,.ascii       ;   Type it
    cp    $1c             ; If CTL-LeftArrow (^\)
    jp    z,.delete       ;   Delete character to right
    cp    $03             ; If CTL-C (^C)
    jp    z,.quit         ;   Quit with Carry set
    cp    $0d             ; If RTN or CTL-M (^M)
    jp    z,.retn         ;   Return with typed line in buffwe
    cp    $08             ; If LeftArrow or CTL-H (^H)
    jp    z,.backspace    ;   Delete character to left
    cp    $10             ; If CTL-P (^P)
    jp    z,.left         ;   Move cursor left
    cp    $1e             ; If CTL-/ (^^)
    jp    z,.right        ;   Move cursor right
    cp    $12             ; If CTL-R (^R)
    jp    z,.retype       ;   Retype Line
    cp    $09             ; If CTL-I (^I)
    jr    z,.cntli         ;   Remap to '['
    cp    $0f             ; If CTL-I (^O)
    jr    z,.cntlo         ;   Remap to ']'    
    cp    $11             ; If CTL-Q (^Q)
    jp    z,.cntlq         ;   Remap to '`'
    cp    $19             ; If CTL-Y (^Y)
    jp    z,.cntly        ;   Remap to '`'
    cp    $07             ; If CTL-G (^G)
    jp    z,.cntlg        ;   Remap to '|'
    cp    $15             ; If CTL-U (^U)
    jp    z,.cntlu        ;   Remap to '}'
    cp    $18             ; If CTL-X
    jp    z,.cntlx        ;   Remap to '~'
.cntls:                   ; Remap CTL-S to 'S'
    sub   a,'X'-'S'+1
.cntlx:                    
    sub   a,'X'-'U'-1
.cntlu:
    sub   a,'U'-'G'-1
.cntlg:
    add   a,'Y'-'G'+1
.cntly:
    sub   a,'Y'-'Q'-27
.cntlq:
    sub   a,'Q'-'O'-3
.cntlo:
    sub   a,'O'-'I'-2
.cntli:
    add   '['-$09
    ld    c,a             ; Copy into c
; insert key into line
.ascii:
    ld    a,d             ; A = string length (not including null terminator)
    inc   a               ; add 1 for NULL
    cp    b               ; compare to buffer length
    jr    nc,.waitkey     ; if buffer full then don't insert
    jr    z,.insert       ; if already at end of buffer then don't open gap
; open gap in line to insert key into
    push  hl
    push  de
    push  bc
    ld    b,0
    ld    a,d             ; A = string length
    sub   e               ; subtract cursor position in string
    jr    c,.gapped       ; must not be less than zero!
    ld    c,a             ; C = distance from cursor to end of string
    add   hl,bc           ; HL = end of string
    ld    d,h
    ld    e,l
    inc   de              ; DE = end of string + 1
    inc   c               ; BC = number of chars to move
    lddr                  ; stretch right side of string to make room for key
.gapped:
    pop   bc
    pop   de
    pop   hl
; insert key into gap
.insert:
    ld    (hl),c          ; store character in buffer
    call  _showstr        ; update screen text
    call  _cursor_right
    inc   hl              ; cursor address in buffer + 1
    inc   e               ; cursor position in buffer + 1
    ld    a,d
    inc   a
    cp    b               ; if not at end of buffer
    jp    nc,.waitkey
    inc   d               ;    then end of string + 1
    jp    .waitkey

; pressed <RTN>, clean up and return with HL = buffer-1
.retn:
    call  STROUT          ; move screen cursor to end of string
    call  CRDO            ; print CR+LF
    xor   a               ; Carry clear = line edited
    ret

; BACKSPACE
.backspace:
    dec   e
    inc   e
    jp    z,.waitkey      ; if already at start of buffer then done
    dec   hl
    dec   e               ; move cursor left
    call  _cursor_left
; DELETE
.delete:
    ld    a,d             ; a = number of chars in string
    sub   e               ; subract cursor position in string
    jp    z,.waitkey      ; if no bytes to move then done
    ld    c,a             ; C = number of bytes to move
    dec   d               ; number of chars -1
    push  bc
    push  de
    push  hl
    ld    d,h             ; DE = address of char at cursor
    ld    e,l
    inc   hl              ; HL = address of next char
    ld    b,0             ; BC = number of bytes to move
    ldir                  ; pull right side of string left over cursor
    dec   de              ; de = new end of string (NULL)
    pop   hl              ; hl = cursor address in string
    ld    a,' '
    ld   (de),a           ; add SPACE to rub out previous last char
    call  _showstr        ; print right side of string
    xor   a
    ld    (de),a          ; remove SPACE from end of string
    pop   de
    pop   bc
    jp    .waitkey

; cursor left
.left:
    xor   a
    cp    e
    jp    z,.waitkey      ; if already at start then stay there
    call  _cursor_left
    dec   hl
    dec   e
    jp    .waitkey

; cursor right
.right:
    ld    a,e
    cp    d
    jp    nc,.waitkey       ; limit movement to inside string
    call  _cursor_right
    inc   e
    inc   hl
    jp    .waitkey


; CTRL-R = retype
.retype:
    ld    a,(SYSFLAGS)    ; if CTRL-R inactive then ignore it
    BIT   SF_RETYP,a
    JP    z,.waitkey
    inc   e
.rt_home:
   dec   e
   jr    z,.gethistory
   dec   hl
   call  _cursor_left    ; cursor left to start of buffer
   jr    .rt_home
.gethistory:
   push  hl              ; push buffer address
.clearline:
    ld    a,(hl)
    or    a
    jr    z,.line_cleared
    ld   (hl),' '         ; spaces up to end of string
    inc   hl
    jr    .clearline
.line_cleared:
    pop   hl
    call  _showstr        ; show spaces over previous string
    push  hl
    ld    c,-1
    ld    de,ReTypBuf     ; DE = history buffer
.rt_copy:
    ld    a,(de)          ; get char from history buffer
    inc   de
    ld    (hl),a          ; copy char to line buffer
    inc   hl
    inc   c               ; C = number of chars copied
    or    a
    jr    nz,.rt_copy     ; copy until done NULL
    pop   hl              ; pop buffer address
    call  _showstr        ; show string
    ld    d,c             ; D = end of string in buffer
    ld    e,0             ; E = start of buffer
.rt_end:
    jp    .waitkey

; CTRL-C
.quit:
    call  STROUT          ; move screen cursor to end of string
    call  CRDO            ; CR+LF
    scf                   ; set Carry flag = edit aborted
    ret


;--------------------------------------------------------------------
;         Clear Keyboard Buffer and Wait for Key
;--------------------------------------------------------------------
;
; out: A = key
;
_clr_key_wait:
    xor     a
    ld      (CHARC),a             ; clear last key pressed
_key_wait:
    call    $1e7e                 ; get last key pressed
    jr      z,_key_wait           ; loop until key pressed
    push    hl                    
    push    af         
    ld      a,(KeyFlags)          ; Get Key Flags
    bit     KF_CLICK,a            ; If Key Click Enabled
    jr      z,.no_click
    ld      hl,(RESPTR)           ;   Check For Keyword Expansion
    ld      a,h
    or      a
    jr      z,.click              ;   If Expanding
    ld      a,(hl)                ;     If Character Doesn't Have High Bit Set
    or      a                     ;       Not at Beginning of Word
    jp      p,.no_click           ;       So Don't Click
    ld      a,l
    cp      $AE                   ;     If CLOAD
    jr      z,.fix_it            
    cp      $B3                   ;     or CSAVE
    jr      nz,.no_fix
.fix_it
    inc     hl                    ;       Bump RESPTR to Second Character
    ld      (RESPTR),hl           ;       and Save it
    pop     af                    ;         Replace Saved Key 
    ld      a,(hl)                ;         with Second Character of Reserved Word
    push    af
.no_fix    
.click  
    call    key_click             ;     DoKey Click
.no_click
    pop     af
    pop     hl
    ret



key_click:
    ld   a,$FF                    ;   speaker ON
    out  ($fc),a                      
.click_wait:                          
    push af                           
    pop  af                       ;   delay 6 cycles * 256
    dec  a                            
    jr   nz,.click_wait               
    out  ($fc),a                  ;   speaker OFF
    ret
    
;--------------------------------------------------------------------
;         Print String to screen without moving cursor
;--------------------------------------------------------------------
;  in: HL = string (null-terminated)
;
_showstr:
    push  hl
    push  de
    push  bc
    ld    de,(CURRAM)   ; DE = cursor address in character RAM
    ld    a,(TTYPOS)
    ld    c,a           ; C = cursor column
    jr    .prt_next     ; start printing
.prt_loop:
    ld    a,c
    cp    38            ; if at column 38 then...
    jr    nz,.prt_char
    ld    c,0           ;    C = column 0
    inc   de
    inc   de            ;    skip over border to next line
    push  hl
    ld    hl,$33e7
    rst   $20           ;    compare cursor address to end of screen
    pop   hl
    jr    nc,.prt_char  ;    if end of screen then...
    push  hl
    push  bc
    call  SCROLL        ;       scroll screen up
    ld    bc,-40
    ld    hl,(CURRAM)
    add   hl,bc         ;       move cursor up 1 line
    ld    (CURRAM),hl
    pop   bc
    pop   hl
    ld    de,$33c1      ;       set address to start of bottom line
.prt_char:
    ld    a,(hl)
    ld    (de),a        ; put character into screen RAM
    inc   hl            ; next char in string
    inc   de            ; next screen address
    inc   c             ; next column
.prt_next:
    ld    a,(hl)        ; get next character from string
    or    a             ; NULL?
    jr    nz,.prt_loop  ; no, print it
    pop   bc
    pop   de
    pop   hl
    ret

;--------------------------------------------------------------------
; Move cursor to the previous character position on screen. If at
; column 0 then go up to colomn 37 on the previous line.
;
; Only updates TTYPOS and CURRAM (no affect on cursor display).
; Cursor should be turned off to avoid leaving colored blocks behind!
;
; NOTE: does not test for wrap at start of screen, so don't call
; this function if cursor is at position 0,0!
;
_cursor_left:
    push  hl
    ld    hl,TTYPOS
    ld    a,(hl)
    or    a
    jp    nz,.column
    ld    (hl),38      ; if at column 0 then goto column 38
.column:
    dec   (hl)         ; column - 1
    ld    hl,(CURRAM)
    or    a
    jr    nz,.ram
    dec   hl           ; if going up 1 line then skip over border
    dec   hl
.ram:
    dec   hl           ; character RAM address - 1
    ld    (CURRAM),hl
    pop   hl
    ret

;--------------------------------------------------------------------
; Move cursor location to the next character position. If at end of
; screen then scroll up and put cursor on the 1st column of the last
; line.
;
; Only updates TTYPOS and CURRAM (no affect on cursor display).
; Cursor should be turned off to avoid leaving colored blocks behind!
;
_cursor_right:
    push  hl
    ld    hl,TTYPOS
    ld    a,(HL)
    inc   a           ; cursor column + 1
    cp    38
    jr    c,.column   ; if end of line then
    ld    a,0         ;   set column to start of (next) line
.column:
    ld    (hl),a      ; update cursor column
    ld    hl,(CURRAM)
    inc   hl          ; cursor address + 1
    jr    c,.ram      ; if past end of line then
    inc   hl
    inc   hl          ;    skip over border to start of next line
    push  de
    ld    de,$33e8
    rst   $20         ;    compare cursor address to end of screen
    jr    c,.scr      ;    if past end of screen then
    push  bc
    call  SCROLL      ;       scroll up
    pop   bc
    ld    hl,$33c1    ;       set cursor address to start of bottom line
.scr:
    pop   de
.ram:
    ld    (CURRAM),hl ; update cursor address
    pop   hl
    ret

;--------------------------------------------------------------------
;                      Show Colored Cursor
;--------------------------------------------------------------------
; Uses color atrribute RAM to show a colored block at the cursor
; location. With appropriate colors the character 'under' the cursor
; shows through, and does not have to be restored after the cursor is
; removed.
;
_show_cursor:
    push  af
    push  hl
    ld    hl,(CURRAM)
    set   2,h             ; HL = cursor address in color RAM
    ld    a,(hl)          ; get original character color
    ld    (RUBSW),a       ; save it
    and   $0f
    cp    $04
    ld    a,$74           ; A = cursor forground/background color
    jr    nz,.show        ; if background same as cursor color
    ld    a,$47           ;     then use a different color
.show:
    ld    (hl),a          ; character color = cursor color
    pop   hl
    pop   af
    ret

;--------------------------------------------------------------------
;                     Remove Colored Cursor
;--------------------------------------------------------------------
; Use to restore normal character color when moving cursor to another
; location
_hide_cursor:
    push  af
    push  hl
    ld    hl,(CURRAM)
    set   2,h             ; HL = character position in color RAM
    ld    a,(RUBSW)
    ld    (hl),a          ; restore original character color
    pop   hl
    pop   af
    ret


