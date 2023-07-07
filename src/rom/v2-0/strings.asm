;-------------------------------------------------
;          Lowercase->Uppercase
;-------------------------------------------------
; in-out; A = char
;
UpperCase:
       CP  'a'     ; >='a'?
       RET  C
       CP   'z'+1  ; <='z'?
       RET  NC
       SUB  $20    ; a-z -> A-Z
       RET

;--------------------------------------------------
;                 String Copy
;--------------------------------------------------
;
;  in: HL-> string (null-terminated)
;      DE-> dest
;
; out: HL-> past end of string
;      DE-> at end of dest
;
; NOTE: does NOT null-terminate the destination string!
;       Do it with LD (DE),A after calling strcopy.
;
_strcopy_loop:
       LD    (DE),A
       INC   DE
strcopy:
       LD    A,(HL)
       INC   HL
       OR    A
       JR    NZ,_strcopy_loop
       RET

;------------------------------------------------
;               String Length
;------------------------------------------------
;
;  in: HL-> string (null-terminated)
;
; out: A = number of characters in string
;
strlen:
       PUSH  DE
       LD    D,H
       LD    E,L
       XOR   A
       DEC   HL
_strlen_loop:
       INC   HL
       CP    (HL)
       JR    NZ,_strlen_loop
       SBC   HL,DE
       LD    A,L
       EX    DE,HL
       POP   DE
       RET

;----------------------------------------------
;           String Concatenate
;----------------------------------------------
;
; in: hl = string being added to (must have sufficient space at end!)
;     de = string to add
;
strcat:
    xor  a
_strcat_find_end:
    cp   (hl)               ; end of string?
    jr   z,_strcat_append
    inc  hl                 ; no, continue looking for it
    jr   _strcat_find_end
_strcat_append:             ; yes, append string
    ld   a,(de)
    inc  de
    ld   (hl),a
    inc  hl
    or   a
    jr   nz,_strcat_append
    ret


;-----------------------------------------------------------------
;               Print Null-terminated String
;-----------------------------------------------------------------
;  in: HL = text ending with NULL
;
prtstr:
   ld   a,(hl)
   inc  hl
   or   a
   ret  z
   call TTYOUT
   jr   prtstr


; DateTime Routines

; in A = Formatted String Flag
; out: DE = DTM_STRING
get_rtc:
    or      a
    jr      nz,format_rtc
string_rtc:
    call    read_rtc
; in: HL = DTM Buffer
; out: DE = DTM_STRING
string_dtm: 
    jp      dtm_to_str       ; Convert to String

format_rtc:
    call    read_rtc
; in: HL = DTM Buffer
; out: DE = DTM_STRING
format_dtm:
    jp      dtm_to_fmt    ;Convert to Formatted String   

; Read the Real Time Clock
read_rtc:
    ld      bc,RTC_SHADOW
    ld      de,DTM_STRING
    ld      hl,DTM_BUFFER
    jp      rtc_read

; in: HL = Pointer to FTS
; out: DE = DTM_STRING, HL unchangeds
format_fts:
    push    hl                      ; Save Pointer to FTS
    ex      de,hl                   ; DE = Pointer to FTS
    ld      hl,dtm_buffer
    call    fts_to_dtm              ; Convert TimeStamp to DateTime
    call    format_dtm
    pop     hl                      ; Restore Pointer to FTS
    ret


;--------------------------
;   print hex word
;--------------------------
; in: DE = word
;
print_word:
    ld      a,d
    call    print_hex
    ld      a,a

;--------------------------
;   print hex byte
;--------------------------
; in: A = byte

print_hex:
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

;--------------------------------------------------------
;  Print Integer as Decimal with leading spaces
;--------------------------------------------------------
;   in: HL = 16 bit Integer
;        A = number of chars to print
;
print_integer:
       PUSH     BC
       PUSH     AF
       CALL     LINOUT
       LD       HL,FBUFFR+2
       CALL     strlen
       POP      BC
       LD       C,A
       LD       A,B
       SUB      C
       JR       Z,.prtnum
       LD       B,A
.lead_space:
       LD       A," "
       CALL     TTYOUT        ; print leading space
       DJNZ     .lead_space
.prtnum:
       LD       A,(HL)        ; get next digit
       INC      HL
       OR       A             ; return when NULL reached
       JR       Z,.done
       CALL     TTYOUT        ; print digit
       JR       .prtnum
.done:
       POP      BC
       RET
