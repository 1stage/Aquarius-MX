;-----------------------------------------
; Enhanced BASIC Statements and Functions
;-----------------------------------------

;----------------------------------------------------------------------------
;;; ---
;;; ## AND
;;; Bitwise AND
;;; ### FORMAT:
;;;  - AND( *number1*, *number2* )
;;;    - Action: Returns the bitwise AND of two numbers.
;;;      - Both *number1* and *number2* must be between -32768 and 65535.
;;;      - Can be used instead of AND operator which only allows operands between -32768 and 32767.
;;; ### EXAMPLE:
;;; ` PRINT AND(-1,$FFFF) `
;;; > Prints 65535
;----------------------------------------------------------------------------
FN_AND:
    call    PARADR          ; Read First Argument
    push    de              ; Save It
    SYNCHK  ','             ; Require Comma
    call    GETADR          ; Read Second Address into DE
    SYNCHK  ')'             ; Require Parenthesis
    ex      (sp),hl         ; First Argument into HL, Text Pointer on Stack
    ld      bc,LABBCK       ; Return Address for FLOAT_DE
    push    bc
    ld      a,d             ; D = D | H
    and     h
    ld      d,a
    ld      a,e             ; E = E | L
    and     l 
    ld      e,a
    jp      FLOAT_DE


;----------------------------------------------------------------------------
;;; ---
;;; ## ASC$ Function
;;; Convert Hexadecimal String to ASCII String
;;; ### FORMAT:
;;;  - ASC$ ("*string*")
;;;    - Action: Returns string whose characters ASCII values match the series of two digit hexadecimal numbers in *string*.
;;;      - See the HEX$ function for string-to-hex conversion.
;;; ### EXAMPLE:
;;; ` PRINT ASC$("414243") `
;;; > Prints the string "ABC".
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------

FN_ASC:
    inc     hl              ; Check character directly after ASC Token
    ld      a,(hl)          ; (don't skip spaces)
    cp      '$'             ; If it's not a dollar sign
    jr      nz,ABORT_FN     ;   Return to do normal ASC
    rst     CHRGET          ; Eat $ and Skip Spaces
    call    PARCHK          ; Parse Argument in Parentheses
    push    hl              ; Save Text Pointer
    call    CHKSTR          ; TM Error if Not a String
hex_to_asc:
    ld      de,(FACLO)      ; Get String Descriptor Address
    ld      h,d
    ld      l,e             ; Put String Descriptor Address in HL
    call    str_len_adr     ; Get Arg Length in A, Address in HL
    sra     a               ; Divide Length by 2
    jp      c,FCERR         ;   Error if Length was Odd
    jr      z,null_string   ;   If 0, Return Null String
    push    af              ; Save New String Length
    push    hl              ; Save Argument String Address
    push    de              ; Save Argument String Descriptor
    call    STRINI          ; Create Result String returning HL=Descriptor, DE=Text Address
    pop     de              ; Get Back Argument Descriptor
    call    FRESTR          ; and Free It
    ld      de,(DSCTMP+2)   ; Get Result String Text Address
    pop     hl              ; Get Argument String Address
    pop     af              ; Get New String Length
    ld      b,a             ; Loop Count = Result String Length
.asc_loop:
    call    get_hex         ; Get Hex Digit from Argument
    sla     a               ; Shift to High Nybble
    sla     a
    sla     a
    sla     a
    ld      c,a             ; and Save in C
    call    get_hex         ; Get Next Hex Digit from Argument
    or      c               ; Combine with High Nybble
    ld      (de),a          ; Store in Result String
    inc     de              ; Bump Result Pointer
    djnz    .asc_loop
    jp      PUTNEW          ; Return Result String

get_hex:
    ld      a,(hl)          ; Get Hex Digit 
    inc     hl              ; Bump Pointer
cvt_hex:
    cp      ':'             ; Test for Digit 
    jr      nc,.not_digit   ; If A <= '9'
    sub     '0'             ;   Convert Digit to Binary
    jr      c,.fcerr        ;   If it was less than '0', Error
    ret                     ;   Else Return 
.not_digit:
    and     $5F             ; Convert to Upper Case
    sub     'A'-10          ; Make 'A' = 10
    jr      c,.fcerr        ; Error if it was less than 'A'
    cp      16              ; If less than 16
    ret     c               ;   Return
.fcerr                      ; Else 
    jp      FCERR           ;   Error

null_string
    ld      hl,REDDY-1      ; Point at ASCII 0 
    push    bc              ; Put Dummy Return Address on Stack
    jp      TIMSTR          ; Literalize and Return It

ABORT_FN:
    dec     hl              ; Back up to Function Token
    ld      a,(hl)          ; Re-Read Token
    sub     ONEFUN          ; Convert to Offset
    jp      HOOK27+1        ; Continue with Standard Function Code

;----------------------------------------------------------------------------
;;; ---
;;; ## COPY (Extended)
;;; Copy screen to Line Printer / Copy memory
;;; ### FORMAT:
;;;   - COPY
;;;     - Action: Sends screen contents to line printer (legacy command)
;;;   - COPY *source*, *dest*, *count*
;;; ### EXAMPLES:
;;; ` COPY ` (no parameters)
;;; > Send contents of screen to line printer
;;;
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
    ld       d,h             
    ld       e,l            ; DE = <dest> + <count> - 1
    pop      hl             ; HL = <source>, Stack = Text Pointer
    add      hl,bc          
    dec      hl             ; HL = <source> + <count> - 1
    lddr                    ; Do the Copy
    pop      hl             ; Restore Text Pointer
    ret

;----------------------------------------------------------------------------
;;; ---
;;; ## FRE (Extended)
;;; Show available Memory / Show memory details
;;; ### FORMAT:
;;;  - FRE ( 0 )
;;;    - Action: Returns the number of bytes in memory not being used by BASlC.
;;;  - FRE ( 1 )
;;;    - Action: Returns the total size of string space (as set by the first argument of CLEAR).
;;;  - FRE ( 2 ) 
;;;    - Action: Returns the top of BASIC memory (as set by the second argument of CLEAR).
;;;  - FRE ( 3 ) 
;;;    - Action: Returns the top of user memory (the highest value allowed for CLEAR).
;;;  - FRE ( *string* )
;;;    - Action: Forces a garbage collection before returning the number of free bytes of string space. 
;;;      - BASIC will not initiate garbage collection until all free memory has been used up. 
;;;      - Therefore, using FRE("") periodically will result in shorter delays for each garbage collection.
;;;   - Any other argument returns an FC error.
;;; ### EXAMPLE:
;;; ` PRINT FRE(0) `
;;; > Displays amount of free remaining memory available to BASIC.
;;;
;;; ` PRINT HEX$(FRE(2)) `
;;; > Displays the current top address of BASIC memory as a hexadecimal format address.
;----------------------------------------------------------------------------
FN_FRE:
    rst     CHRGET
    call    PARCHK
    push    hl
    ld      bc,LABBCK       ; Return Address for FLOAT...
    push    bc
    call    GETYPR          ; If FRE(string)
    jp      z,FRE_STR       ;   Garbage Collect and Return Free String Space 
    call    CONINT          ; Convert Argument to byte in A
    ld      hl,(STREND)     ; 
    ex      de,hl           ; 
    ld      hl,0            ;
    add     hl,sp           ; 
    or      a               ; If FRE(0)
    jp      z,FLOAT_DIFF    ;   Return Free Space
    ld      hl,(MEMSIZ)     ; 
    ld      de,(TOPMEM)     ;
    dec     a               ; If FRE(1)
    jp      z,FLOAT_DIFF    ;   Return Total String Space
    dec     a               ; If FRE(2)
    jp      z,FLOAT_DE      ;   Return Top of BASIC Memory
    ex      de,hl           ; 
    dec     a               ; If FRE(3)
    jp      z,FLOAT_DE      ;   Return End of User Memory  
    jp      FCERR           ; Else FC Error

FRE_STR:
    call    FREFAC          ;[M80] FREE UP ARGUMENT AND SETUP TO GIVE FREE STRING SPACE
    call    GARBA2          ;[M80] DO GARBAGE COLLECTION
    ld      de,(TOPMEM)     ;
    ld      hl,(FRETOP)     ;[M80] TOP OF FREE AREA
FLOAT_DIFF:                 ; Return HL minus DE has a positive floating point number
    ld      a,l             ; E = L - E
    sub     e               ;
    ld      e,a             ;
    ld      a,h             ;
    sbc     a,d             ; D = H - E - carry
    ld      d,a
    jp      FLOAT_DE        ; Float It


;----------------------------------------------------------------------------
;;; ---
;;; ## PEEK Function
;;; Read Byte from Memory
;;; ### FORMAT:
;;;  - PEEK( *address* )
;;;    - Action: Returns contents of memory location *address*.
;;; ### EXAMPLES:
;;; ` PRINT CHR$(PEEK(12288)) `
;;; > Print the current border character
;;;
;;; ` PRINT PEEK($3400) `
;;; > Print the current border color value
;----------------------------------------------------------------------------

FN_PEEK:
    rst     CHRGET            ; Skip PEEK Token and Spaces
    cp      '$'               ; If followed by dollar sign
    jr      z,FN_PEEKS        ;   Do PEEK$()
    call    PARCHK
    push    hl
    ld      bc,LABBCK         ; Return Address for SGNFLT
    push    bc
    call    FRCADR            ; Convert to Arg to Address
    ld      a,(de)            ; Read byte at Address
    jp      SNGFLT            ; and Float it
    
;----------------------------------------------------------------------------
;;; ---
;;; ## PEEK$ Function
;;; Read String from Memory
;;; ### FORMAT:
;;;  - PEEK( *address*, *length* )
;;;    - Action: Returns a string containing *length* bytes from memory starting at location *address*.
;;;      - Length must be between 0 and 255, inclusive.
;;;      - If length is 0, an empty string is returned.
;;; ### EXAMPLES:
;;; ` PRINT PEEK$(12328,40) `
;;; > Print the contents of screen line 1.
;;;
;;; ` PRINT HEX$(PEEK$(&A,4)) `
;;; > Print the binary value floating point number in variable A as a hexadecimal number.

;----------------------------------------------------------------------------

FN_PEEKS:
    call    PARADR            ; Parse '(' Address
    push    de                ; Stack = Address
    SYNCHK  ','               ; Require ','
    call    GETBYT            ; Parse Length into [DE] (a)
    SYNCHK  ')'               ; Require ')'
    ex      (sp),hl           ; HL = Address, Stack = TxtPtr
    ld      a,e               ; Get *length* into A
    or      a                 ; If *length* is 0
    jp      z,null_string     ;   Return Empty String
    push    hl                ; Stack = Address, TxtPtr
    push    de                ; Stack = Length, Address, TxtPtr
    call    STRINI            ; Make String with Length [A], HL=StrDsc, DE=StrTxt
    pop     bc                ; BC = Length, Stack = Address, TxtPtr
    pop     hl                ; HL = Address, Stack = TxtPtr
    ldir                      ; Copy from Memory to String
    jp      PUTNEW            ; Return the Temporary String
    
;----------------------------------------------------------------------------
;;; ---
;;; ## POKE (Extended)
;;; Writes byte(s) to memory location(s)
;;; ### FORMAT:
;;;  - POKE *address*, [ *byte or string*, *byte or string*... ] [,STEP *count*, *byte or string*...]
;;;    - Action: Writes *byte or string* to *address*, followed by *address* STEP *count* addresses away...
;;;  - POKE *address1* TO *address2* [STEP *count*], *byte*
;;;    - Action: Writes *byte* to memory from *address1* TO *address2*.
;;;      - If optional STEP *count* is specified then then then *count* minus 1 locations are skipped between writes.
;;;        - FC Error if *count* is not between 1 and 255.
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
;;; 
;;; ` POKE 12689 TO 12699 STEP 2,64 `
;;; > Draws six @ characters on the screen, skipping one character location between each.
;;;
;;; ```
;;; POKE 12367 TO 13287 STEP 40,255
;;; POKE 13391 TO 14311 STEP 40,$16
;;; ```
;;; > Draws a red vertical bar along the right side of the screen.
;----------------------------------------------------------------------------

ST_POKE:   
    call    GETADR          ; Get <address>
    ld      a,(hl)          ; If next character 
    cp      TOTK            ; is TO Token 
    jr      z,.poke_fill    ;   Do POKE TO STEP
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
    ld      de,1            ; Default STEP to 1
    ld      a,(hl)          ; Check Next Character
    cp      STEPTK          ; 
    jr      nz,.no_step     ; If STEP Token
    rst     CHRGET          ;   Skip STEP Token
    call    GETBYT          ;   Parse Byte Value
    or      a               ;   If Zero
    jp      z,FCERR         ;     FC Error
.no_step
    push    de              ; Save STEP Value
    SYNCHK  ','             ; Require a Comma
    call    GETBYT          ; 
    ex      af,af'          ; Save <byte>
    pop     bc
    pop     de              
    inc     de              ; DE = End Address + 1
    ex      (sp),hl         ; HL = Start Address, Stack = Text Pointer
.fill_loop:
    ex      af,af'          ; Get <byte>
    ld      (hl),a          ; Store Byte
    ex      af,af'          ; Save <byte> again
    add     hl,bc           ; Add Step to Address
    rst     COMPAR          
    jr      c,.fill_loop    ; Loop if < DE
    pop     hl              ; Restore Text Pointer
    ret

STRLENADR:
    call    FRESTR          ; Free up Temp String
str_len_adr:
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


;----------------------------------------------------------------------------
;;; ---
;;; ## RUN
;;; Loads and runs BASIC programs (*.CAQ or *.BAS)
;;; ### FORMAT:
;;;  - RUN *filename*
;;;    - Action: Loads program into memory and runs it.
;;;      - If *filename* is shorter than 9 characters and does not contain a ".", the extension ".BAS" is appended.
;;;      - File on USB drive must be in CAQ format. The internal filename is ignored.
;;;  - RUN "*filename*"
;;;    - Action: Loads program named *filename* into memory and runs it.
;;;      - If executed from within another BASIC program, the original program is cleared (same as NEW command) and the new program is loaded and executed in its place.
;;;      - Wildcards and paths cannot be used.
;;; ### EXAMPLES:
;;; ` RUN "RUN-ME" `
;;; > Loads and runs the file named `RUN-ME.BAS`. Note the program must exist within the current folder path.
;;;
;;; ` 10 PRINT "Loading Program..." `
;;;
;;; ` 20 RUN "NEXTPRG.CAQ" `
;;; > Displays "Loading Program..." on screen and then immediately loads and runs the `NEXTPRG.CAQ` program.
;----------------------------------------------------------------------------

RUNPROG:
    call    CLNERR             ; Clear Error Trapping Variables
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
    call    ST_LOADFILE        ; load file from disk, name in FileName
    jp      RUNC               ; run loaded BASIC program

;----------------------------------------------------------------------------
;;; ---
;;; ## OR
;;; Bitwise OR
;;; ### FORMAT:
;;;  - OR( *number1*, *number2* > )
;;;    - Action: Returns the bitwise OR of two numbers.
;;;      - Both *number1* and *number2* must be between -32768 and 65535.
;;;      - Can be used instead of OR operator which only allows operands between -32768 and 32767.
;;; ### EXAMPLE:
;;; ` PRINT HEX$(OR($8080,$0808)) `
;;; > Prints 8888
;----------------------------------------------------------------------------
FN_OR:
    call    PARADR          ; Read First Argument
    push    de              ; Save It
    SYNCHK  ','             ; Require Comma
    call    GETADR          ; Read Second Address into DE
    SYNCHK  ')'             ; Require Parenthesis
    ex      (sp),hl         ; First Argument into HL, Text Pointer on Stack
    ld      bc,LABBCK       ; Return Address for FLOAT_DE
    push    bc
    ld      a,d             ; D = D | H
    or      h
    ld      d,a
    ld      a,e             ; E = E | L
    or      l 
    ld      e,a
    jp      FLOAT_DE

;----------------------------------------------------------------------------
;;; ---
;;; ## XOR 
;;; Bitwise Exclusive OR
;;; ### FORMAT:
;;;  - XOR( *number1*, *number2* )
;;;    - Action: Returns the bitwise Exclusive OR of two numbers.
;;;      - Both *number1* and *number2* must be between -32768 and 65535.
;;; ### EXAMPLE:
;;; ` PRINT HEX$(XOR($FFFF,$0808)) `
;;; > Prints F7F7
;----------------------------------------------------------------------------
FN_XOR:
    call    PARADR          ; Read First Argument
    push    de              ; Save It
    SYNCHK  ','             ; Require Comma
    call    GETADR          ; Read Second Address into DE
    SYNCHK  ')'             ; Require Parenthesis
    ex      (sp),hl         ; First Argument into HL, Text Pointer on Stack
    ld      bc,LABBCK       ; Return Address for FLOAT_DE
    push    bc
    ld      a,d             ; D = D ^ H
    xor     h
    ld      d,a
    ld      a,e             ; E = E ^ L
    xor     l 
    ld      e,a
    jp      FLOAT_DE

;----------------------------------------------------------------------------
;;; ---
;;; ## SWAP 
;;; Swap MSB and LSB
;;; ### FORMAT:
;;;  - SWAP(*number*)
;;;    - Action: Returns *number* with the least significant and most significant bytes swapped.
;;;      - *number* must be between -32768 and 65535.
;;; ### EXAMPLES:
;;; ` PRINT HEX$(SWAP($ABCD)) `
;;; > Prints CDAB
;----------------------------------------------------------------------------
FN_SWAP:
    call    PARADR          ; Read First Argument
    SYNCHK  ')'             ; Require Parenthesis
    push    hl              ;   Text Pointer on Stack
    ld      bc,LABBCK       ; Return Address for FLOAT_DE
    push    bc
    ld      a,d             ; Swap D and E
    ld      d,e
    ld      e,a             ; E = E ^ L
    jp      FLOAT_DE

