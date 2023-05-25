; Enhanced BASIC Statements and Commands

;----------------------------------------------------------------------------
;;; ---
;;; ## COPY (Extended)
;;; Copy Memory (overloads legacy COPY command which lineprints screen output)
;;; ### FORMAT:
;;;   - COPY < source >, < dest >, < count >
;;; ### EXAMPLES:
;;; ` COPY 12368,12328,920 `
;;; > Scroll Screen Up One Line
;;;
;;; ` COPY 12288,12328,920 `
;;; > Scroll Screen Down One Line
;;;
;;; ` COPY 12329,12328,39 `
;;; > Scroll Row 1 right 1 char
;;;
;;; ` COPY $3000,$2000,2048 `
;;; > Copy Screen and Colors to Low RAM
;;;
;;; ` COPY $2000,$3000,2048 `
;;; > Restore Screen and Colors
;----------------------------------------------------------------------------
ST_COPY:   
    pop      af             ; Discard Saved Token, Flags
    rst      CHRGET         ; Skip COPY Token
    jp      z,COPY          ; No Parameters? Do Standard COPY
    call    GETADR          ; 
    push    de              ; Stack = <source>
    SYNCHK  ','             ; 
    call    GETADR          ; 
    push    de              ; Stack = <dest>, <source>
    SYNCHK  ','             ; 
    call    GETADR          ; Get <count> 
    ld      b,d             ; BC = <count>
    ld      c,e
    ld      a,b             ; FC Error if <count> = 0
    or      c
    jp      z,FCERR
    pop      de             ; DE = <dest>, Stack = <source>
    ex      (sp),hl         ; HL = <source>, Stack = Text Pointer
    rst      COMPAR         ; If <source> < <dest>
    jr      c,.copy_down    ;    Do Reverse Copy Instead
    ldir                    ; Do the Copy
    pop      hl             ; Restore Text Pointer
    ret
 
.copy_down
    push    de              ; Stack = <dest>, Text Pointer
    ex      (sp),hl         ; HL = <dest>, Stack = <source>, Text pointer
    add      hl,bc          
    dec      hl             
    ld      d,h             
    ld      e,l             ; DE = <dest> + <count> - 1
    pop      hl             ; HL = <source>, Stack = Text Pointer
    add      hl,bc          
    dec      hl             ; HL = <source> + <count> - 1
    lddr                    ; Do the Copy
    pop      hl             ; Restore Text Pointer
    ret

;----------------------------------------------------------------------------
;;; ---
;;; ## PEEK (Extended)
;;; Read from Memory
;;; ### FORMAT:
;;;  - PEEK(< address >)
;;;    - Action: Reads a byte from memory location < address >.
;;; ### EXAMPLES:
;;; ` PRINT CHR$(PEEK(12288)) `
;;; > Print the current border character
;;;
;;; ` PRINT PEEK($3400) `
;;; > Print the current border color value
;----------------------------------------------------------------------------

FN_PEEK:
    call    PARCHK
    push    hl
    ld      bc,LABBCK
    push    bc
    call    FRCADR            ; Convert to Arg to Address
    ld      a,(de)            ; Read byte at Address
    jp      SNGFLT            ; and Float it
    
;----------------------------------------------------------------------------
;;; ---
;;; ## POKE (Extended)
;;; Writes byte(s) to memory location(s)
;;; ### FORMAT:
;;;  - POKE < address >, [ < byte or string >, < byte or string >... ] [,STEP count, < byte or string >...]
;;;    - Action: Writes < byte or string > to < address >, followed by < address > STEP counts away...
;;;  - POKE < address > TO < address >, < byte >
;;;    - Action: Writes < byte > to memory from < address > TO < address >.
;;; ### EXAMPLES:
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
    call    FRESTR          ; Free up Temp String
    ld      c,(hl)          ; Get length in BC
    ld      b,0
    inc     hl              ; Skip String Descriptor length byte
    inc     hl              ; Set Address of String Text into HL
    ld      a,(hl)          ;
    inc     hl
    ld      h,(hl)
    ld      l,a
    ld      a,c             ; Put length in A
    or      a               ; and Set Flags
    ret
