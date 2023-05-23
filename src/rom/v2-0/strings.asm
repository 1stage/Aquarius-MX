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
;       Do it with LD (DE),A after calling strcpy.
;
_strcpy_loop:
       LD    (DE),A
       INC   DE
strcpy:
       LD    A,(HL)
       INC   HL
       OR    A
       JR    NZ,_strcpy_loop
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


