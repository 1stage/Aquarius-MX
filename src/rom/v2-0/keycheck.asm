;======================================================================
;  KEY_CHECK: See if a key has been pressed and return ASCII value
;======================================================================
; differences from Stock Aquarius KEYCHK:-
; - does not expand control codes to BASIC keywords
; - does not use IX, HL', DE',BC'
; 
; Control Keys remapped to cover entire standard ASCII character set
;
; note: DEBOUNCE is still a constant. If there is a large delay between
;       keyscans you can reduce debounce time with the following code:-
;
;       LD   A,(KCOUNT)
;       CP   6                 ; starting key-up debounce?
;       JR   NZ,.check_key
;       LD   A,DEBOUNCE-x      ; x = number of scans to go
;       LD   (KCOUNT),A       ; adjust debounce count
;  .check_key:
;       call Key_Check         ; Get ASCII of last key pressed
;
;  in:
; out: A = ASCII code of key pressed (0 = no key)
;
DEBOUNCE = 70   ; number of key-up scans before believing key is up

Key_Check:
        push    hl
        push    bc
        ld      bc,$00ff        ; Scan all columns at once
        in      a,(c)           ; Read the results
        cpl                     ; invert - (a key down now gives 1)
        and     $3f             ; check all rows
        ld      hl,LSTX         ; HL = &LSTX (scan code of last key pressed)
        jr      z,.nokeys
        ld      b,$7f           ; 01111111 - scanning column 8
        in      a,(c)
        cpl                     ; invert bits
        and     $0f             ; check lower 4 bits
        jr      nz,.keydown     ; if any keys in column 8 pressed then do KEYDOWN
.scncols:
        ld      b,$bf           ; 10111111 - start with column 7
.keycolumn:
        in      a,(c)
        cpl                     ; invert bits
        and     $3f             ; is any key down?
        jr      nz,.keydown     ; yes,
        rrc     b               ; no, try next column
        jr      c,.keycolumn    ; until all columns scanned

; key up debouncer
.nokeys:                        ; no keys are down.
        inc     hl              ; HL = &KCOUNT, counts how many times the same
        ld      a,DEBOUNCE      ;                code has been scanned in a row.
        cp      (hl)            ; compare scan count to debounce value
        jr      c,.nokey        ; if scanned more than DEBOUNCE times then done
        jr      z,.keyup        ; if scanned DEBOUNCE times then do KEY UP
        inc     (hl)            ; else increment KCOUNT
        jr      .nokey

; HL = &LSTX
; B  = bit pattern of column being scanned.
; A  = row bits
; KROWCNT converts the BIT number of the row and column into
; actual numbers. So if bit 7 was set, a would hold 7.
; the column is multiplied by 6 so it can be added to the row number
; to give a unique scan code for each key.
; There are 8 columns of 6 keys giving a total of 48 keys.
;
.keydown:
       ld      c,0             ; C = column count
.krowcnt:
       inc     c               ; column count + 1
       rra
       jr      nc,.krowcnt     ; Count how many rotations to get the bit into Carry.
       ld      a,c             ; A = number of bit which was set
.kcolcnt:
       rr      b
       jr      nc,.krowcol     ; jump when 0 bit gets to CARRY
       add     a,6             ; add 6 for each rotate, to give the column number.
       jr      .kcolcnt
; A = (column*6)+row
.krowcol:
       cp      (hl)            ; is scancode same as last time?
       ld      (hl),a          ; (LSTX) = scancode
       inc     hl              ; HL = &SCANCOUNT
       jr      nz,.newkey      ; no,
       ld      a,4             ; yes, has it been down for 4 scans? (debounce)
       cp      (hl)
       jr      c,.scan6        ; if more than 4 counts then we are already handling it
       jr      z,.kdecode      ; if key has been down for exactly 4 scans then decode it
       inc     (hl)            ; otherwise increment SCANCOUNT
       jr      .nokey          ; exit with no key
.scan6:
       ld      (hl),6          ; SCANCOUNT = 6
       jr      .nokey          ; exit with no key

; The same key has now been down for 4 scans.
; so it's time to find out what it is.
;  in: HL = &SCANCOUNT
.kdecode:
       inc     (hl)           ; increment the scan count
       ld      bc,$7fff       ; read column 8 ($7f = 01111111)
       in      a,(c)
       ld      hl,CTLTBL-1    ; point to start of CTRL key lookup table
       bit     5,a            ; CTRL key down?
       jr      z,.klookup     ; yes,
       ld      hl,SHFTBL-1    ; point to start of SHIFT key lookup table
       bit     4,a            ; SHIFT key down?
       jr      z,.klookup     ; yes,
       ld      hl,KEYTBL-1    ; else point to start of normal key lookup table.
.klookup:
       ld      b,0
       ld      a,(LSTX)    ; get scancode
       ld      c,a
       add     hl,bc          ; offset into table
       ld      a,(hl)         ; A = ASCII key
       or      a
       jr      .exit          ; return nz with ASCII key in A
.keyup:
       inc     (hl)           ; increment KCOUNT
       dec     hl             ; HL = &LSTX
.newkey:
       ld      (hl),0         ; set KCOUNT/LSTX to 0
.nokey:
       xor     a              ; return z, A = no key
.exit:
       pop     bc
       pop     hl
       ret

;-------------------------------------------------------
;                     KEY TABLES
;-------------------------------------------------------
; note: minimum offset is 1 not 0.

;Vanilla key table - no shift or control keys pressed:
KEYTBL:
    db    '=',$08,':',$0D,';','.' ;Backspace, Return
    db    '-','/','0','p','l',',' 
    db    '9','o','k','m','n','j' 
    db    '8','i','7','u','h','b' 
    db    '6','y','g','v','c','f' 
    db    '5','t','4','r','d','x' 
    db    '3','e','s','z',' ','a' 
    db    '2','w','1','q'         

; SHIFT key table
SHFTBL:
    db    '+',$5C,'*',$86,'@','>' ;Backslash, Checkerboard
    db    '_','^','?','P','L','<' 
    db    ')','O','K','M','N','J' 
    db    '(','I',$27,'U','H','B' ;Apostrophe	
    db    '&','Y','G','V','C','F' 
    db    '%','T','$','R','D','X' 
    db    '#','E','S','Z',$A0,'A' ;Blank
    db    $22,'W','!','Q'         ;Quotation Mark

; CTL key table
;      code  key#  symbol   ctrl-name      operation
;       ---  ----  ------   ---------   ----------------
CTLTBL:
    db    $1B,$7F,$1D,$FF,$80,$7D ;ESC DEL GS  blk NUL  }   
    db    $1F,$1E,$1C,$10,$0C,$7B ;GS  RS  FS  DLE FF   {   
    db    $5D,$0F,$0B,$0D,$0E,$0A ; ]  SI  VT  CR  SO  LF   
    db    $5B,$09,$60,$15,$08,$02 ; [  tab  `  NAK BS  SOH  
    db    $8E,$19,$07,$16,$03,$06 ;rt  EM  BEL SYN ETX ACK  
    db    $9F,$14,$8F,$12,$04,$18 ;dn  DC4 up  DC2 EOT CAN  
    db    $9E,$05,$13,$1A,$C6,$01 ;lft ENC DC3 SUB dot SOH  
    db    $7E,$17,$7C,$11         ; ~  ETB  |  DC1

KEYTBL_END
