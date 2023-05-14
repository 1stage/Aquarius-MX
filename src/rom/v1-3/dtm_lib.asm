;RTC Date and Time Module for Z80
;DateTime validation, modification and String Conversion Routines 

;DateTime Data Structure (Each 1 byte field is 2 BCD digits)
;+0 vld Is Valid     $FF if Valid, else 0
;+1 cc  Centiseconds
;+2 ss  Seconds
;+3 mm  Minutes
;+4 HH  Hour          Needs to be in 24 Hour Format
;+5 DD  Day
;+6 MM  Month 
;+7 YY  Year

;Date String Structure: 19 bytes formatted, 14 unformatted
;      Raw: YYMMDDHHmmsscc.  
;Formatted: YYYY-MM-DD HH:mm:ss.
;   Offset: 01234567890123456789
;* period denotes null terminator

;Convert BCD Date to Formatted Date String
;Args: HL = Address of DTM Buffer
;      DE = Address of String Buffer
;Returns: A=$FF, Z if Successful, A=0, NZ if not
;         BC, DE, HL unchanged

dtm_to_fmt:
    call  dtm_to_str          ;Convert RTC Date to Unformatted Date String
                                  ;then Fall into Formatting Routine
;Format Date String
;Converts Date String from YYMMDDHHmmsscc to YYYY-MM-DD HH:mm:ss
;Args: DE = Address of String Buffer
;Returns: A=$FF, Z if Successful, A=0, NZ if not
;         BC, DE, HL unchanged
dtm_fmt_str: 
    ld      a,(de)            ;If Date is Empty String
    or      a                 ;  just Return 
    ret     z                 
    push    hl                ;Save Registers
    push    de
    push    bc
    ld      h,d               ;DE = Start Position in Raw String
    ld      l,e
    ld      bc,11              ;(Second Digit of Minutes)
    add     hl,bc
    ld      d,h
    ld      e,l
    ld      bc,8              ;HL = Start Position in Formatted String
    add     hl,bc             ;(Terminator Ending String)
    ld      c,0
    call    dtm_str_mov       ;Move Seconds + ASCII NUL
    ld      c,':'
    call    dtm_str_mov       ;Move Minutes + Colon
    ld      c,':'
    call    dtm_str_mov       ;Move Hours + Colon
    ld      c,' '
    call    dtm_str_mov       ;Move Day + Space
    ld      c,'-'
    call    dtm_str_mov       ;Move Month + Dash
    call    dtm_str_mov       ;Move Year + Dash
    ld      bc,$3230          ;Add Century to Beginning
    ld      (hl),c
    dec     hl
    ld      (hl),b
    dec     hl
    pop     bc                ;Restore Registers  
    pop     de                
    pop     hl                
    or      $FF               ;Return Success
    ret
    
;Move Characters from Raw to Formatted (Moving Backwards)
;C = Character to Insert, DE = Raw String Position, HL = Formatted String Position
dtm_str_mov:
    ld    (hl),c        ;Store Insertion Character
    dec   hl            ;and Move Backward
    ld    a,(de)        ;Copy Right Digit
    ld    (hl),a
    dec   de            ;and Move Backward
    dec   hl            
    ld    a,(de)        ;Copy Left Digit
    ld    (hl),a
    dec   de            ;and Move Backward
    dec   hl            
    ret

;Convert DateTime to Unformatted Date String
;Args: HL = Address of DTM Buffer
;      DE = Address of String Buffer
;Returns: A=$FF, Z if Successful, A=0, NZ if not
;         BC, DE, HL unchanged
dtm_to_str:
    ld      a,(hl)            ;+0 - RTC Found
    or      a                 ;Set Flags
    jr      nz,dtm_str_do     ;If Not Found
    ld      (de),a            ;  Return a Null String
    ret                   
dtm_str_do:
    push    hl                ;Save Registers
    push    de
    push    bc
    ld      bc,7              ;Start at RTC Field 7 (Year)
    add     hl,bc             
    ld      b,c               ;and Process 7 Fields
dtm_str_loop:        
    ld      a,(hl)            ;Get RTC Field 
    ld      c,a               ;and Save it
    srl     a                 ;Shift Tens Digit to Low Nybble
    srl     a
    srl     a
    srl     a
    or      '0'               
    ld      (de),a            
    inc     de                
    ld      a,c               ;Get Back RTC Field
    and     $0F               ;Isolate Ones Digit
    or      '0'               ;Convert it to ASCII
    ld      (de),a            ;Put it in the String
    inc     de                ;  and Move to Next Character Position
    dec     hl                ;Move to Previous RTC Field
    djnz    dtm_str_loop      ;  and Convert It
    xor     a
    ld      (de),a            ;Terminate String
    pop     bc                ;Restore Registers  
    pop     de                
    pop     hl
    ret

;Convert Raw Date String to DateTime
;Args: HL = Address of DTM Buffer
;      DE = Address of String Buffer
;           Must be in format YYMMDDHHmmss (any following characters are ignored)
;Returns: A=$7F, NZ if Successful, A=0, Z if not
;         BC, DE, HL unchanged
str_to_dtm:
    push    hl                ;Save Arguments
    push    de
    push    bc
    ld      bc,7              ;Start at RTC Field 7 (Year)
    add     hl,bc             
    ld      b,6               ;and Process 6 Fields
str_dtm_loop: 
    call    str_dtm_digit     ;Get Tens Digit
    sla     a                 ;Shift to High Nybble
    sla     a  
    sla     a  
    sla     a  
    ld      c,a               ;and save it
    call    str_dtm_digit     ;Get Ones Digit
    or      c                 ;Combine with Tens Digit
    ld      (hl),a            ;Store in dtm_bcd
    dec     hl                ;and Move Backwards
    djnz    str_dtm_loop      ;Do Next Two Digits
    xor     a                 ;Set centiseconds to 0
    ld      (hl),a            
    pop     bc                ;Restore Registers  
    pop     de                
    pop     hl
    jp      dtm_validate      ;then Execute Validation Routine

;Return Binary Value of ASCII Digit at DE, Error Out if Not Digit
str_dtm_digit:
    ld      a,(de)            ;Get ASCII Digit
    sub     '0'               ;Convert to Binary Value
    jr      c,str_dtm_err     ;Error if Less than '0'
    cp      ':'
    jr      nc,str_dtm_err    ;Error if Greater than '9'
    inc     de                ;Move to Next Digit
    ret
        
str_dtm_err:
    pop     bc                ;Discard str_dtm_digit return address
    ld      a,$FF             ;Date Format Error
    or      a
    pop     bc                ;Discard Subroutine Return Address
    pop     de                ;Restore Arguments
    pop     hl
    ret                       ;All Done

;Validate DTM fields 
;Args: HL = Address of DTM Buffer
;Destroys: BC
;Returns: A=$7F, NZ if Successful, A=0, Z if not
;         BC, DE, HL unchanged
dtm_validate:
    push    hl                ;Save Arguments
    push    de
    push    bc
    inc     hl                
    inc     hl
    ld      d,h               ;DE = Address of RTC Field 2 (Seconds)
    ld      e,l
    ld      hl,dtm_bounds     ;Field Min/Max Values
    ld      b,5
dtm_val_loop:
    ld      a,(de)            ;Get RTC Byte
    cp      (hl)              ;If < Than Lower Bound
    jr      c,dtm_ret_err     ;  Error Out
    inc     hl
    cp      (hl)              ;If >= Upper Bound
    jr      nc,dtm_ret_err    ;  Error Out
    inc     hl                ;
    inc     de                ;Move to Next RTC Byte
    djnz    dtm_val_loop      ;and Check It
    pop     bc                ;Restore Registers  
    pop     de                
    pop     hl
    ld      a,$7F
    ld      (hl),a            ;Set to Valid Conversion
    or      a                 ;and Return with Flags set accordingly
    ret                       

dtm_ret_err:
    pop     bc                ;Restore Registers  
    pop     de                
    pop     hl
    xor     a                 ;Set to Invalid DateTime
    ld      (hl),a            ;and Return with Flags set accordingly
    ret                       

dtm_bounds: ;seconds minutes    hour     day     month
    .byte   $00,$60, $00,$60, $00,$24, $01,$32, $01,$13

; FAT Time Stamp Format
; Bytes  Bits   Contents
;  0,1   15-11  Hours, valid value range 0-23
;        10-5   Minutes, valid value range 0-59
;         4-0   2-second count, valid value range 0–29 (0-58 seconds)
;  2,3   15-9   Count of years from 1980, valid value range 0-127
;         8-5   Month of year, 1 = January, valid value range 1-12
;         4-0   Day of month, valid value range 1-31

;Convert DateTime to FAT TimeStamp
;Args: HL = Address of DTM Buffer
;      DE = Address of Time Stamp
;Destroys: AF
;Returns: 
;         BC, DE, HL unchanged
dtm_to_fts:
    push    hl                ;Save Arguments
    push    de
    push    bc
    ex      de,hl             ;Swap DateTime, TimeStamp pointers
    inc     de                ;Bump DTM pointer to Centiseconds
    call    dtm_get_byte      ;Get DTM Seconds 
    srl     a                 ;Divide by 2
    call    dtm_get_shift     ;Get, Shift And Combine Minutes 
    call    dtm_get_byte      ;Get DTM Hours
    sla     a                 ;Shift Left 3
    sla     a                 ;2
    call    dtm_shift_put     ;1, Combine and Write
    call    dtm_get_byte      ;Get DTM Day 
    call    dtm_get_shift     ;Get, Shift And Combine Month
    call    dtm_get_byte      ;Get DTM Year
    add     a,2000-1980       ;Add Year Offset
    call    dtm_shift_put     ;Shift 1, Combine and Write
    pop     bc                ;Restore Registers  
    pop     de                
    pop     hl
    ret

dtm_get_shift:
    ld      c,a               ;Put in Seconds or Day into Bits 4-0
    ld      b,0               ;and Clear Bits 15-5
    call    dtm_get_byte      ;Get DTM Minutes or Month
    sla     a                 ;Shift Left 5
    rl      b                 
    sla     a                 ;4
    rl      b                 
    sla     a                 ;3
    rl      b                 
    sla     a                 ;2
    rl      b                 
    sla     a                 ;1
    rl      b                 
    or      c                 ;Combine with Seconds/Day
    ld      c,a               
    ret

dtm_shift_put
    sla     a                 ;Shift Hours or Years left
    or      b                 ;Combine with Minutes or Months
    ld      (hl),c            ;Store LSB
    inc     hl
    ld      (hl),a            ;Store MSB
    inc     hl                ;Bump Pointer for Next Put
    ret

    
dtm_get_byte:
    inc     de                ;Point to next DTM byte
    ld      a,(de)            ;Read it
    jp      bcd_to_bin        ;Convert it and Return

;Convert FAT TimeStamp to DateTime
;Args: HL = Address of DTM Buffer
;      DE = Address of Time Stamp
;Destroys: AF
;Returns: BC, DE, HL unchanged
fts_to_dtm:
    push    hl                ;Save Arguments
    push    de
    push    bc
    ex      de,hl             ;Swap DateTime, TimeStamp pointers
    inc     de
    xor     a
    ld      (de),a            ;Set DTM Centiseconds to 0
    call    fts_get_word      ;Read Time and Isolate Seconds
    sla     a                 ;Multiply Seconds by 2
    call    fts_to_bcd        ;Convert and Save
    srl     b                 ;Shift Bits 15-5 to 14-4
    rr      c
    srl     b                 ;Shift Bits 14-4 to 13-3
    rr      c
    srl     b                 ;Shift Bits 13-3 to 12-2
    rr      c                 ;leaving Hours in B 
    srl     c                 ;Shift Bits 7-2 to 5-0
    srl     c                 ;leaving Minutes in C
    ld      a,c
    call    fts_to_bcd        ;Convert and Save Minutes
    ld      a,b
    call    fts_to_bcd        ;Convert and Save Hours
    call    fts_get_word      ;Read Date and Isolate Day
    call    fts_to_bcd        ;Convert and Save
    srl     b                 ;Shift Bits 15-5 to 14-4
    rr      c                 ;leaving Year in B
    srl     c                 ;Shift Bits 8-3 to 5-0
    srl     c                 ;leaving Month in C
    srl     c                 
    srl     c                 
    ld      a,c
    call    fts_to_bcd        ;Convert and Save Month
    ld      a,b
    sub     2000-1980         ;Subtract Year Offset
    call    fts_to_bcd        ;Convert and Save 
    pop     bc                ;Restore Registers  
    pop     de                
    pop     hl
    jp      dtm_validate      ;Validate DateTime and return

fts_get_word:
    ld      c,(hl)            ;Get FTS Date/Time LSB into C
    inc     hl
    ld      b,(hl)            ;Get FTS Date/Time MSB into B
    inc     hl                ;Bump Pointer for Next Get
    ld      a,c               ;Get LSB and Mask High Bits to
    and     $3F               ;Return Day/Seconds
    ret                       

fts_to_bcd:
    inc     de                ;Point to Next Byte in DTM Buffer
    call    bin_to_bcd        ;Convert Byte to BCD
    ld      (de),a            ;Save it
    ret

;Convert Binary to BCD
;Args: A = Binary Byte
;Returns: A = BCD Byte
bin_to_bcd:
    push    bc
    ld      c,a
    ld      b,8
    xor     a
bin_bcd_loop:
    sla     c
    adc     a,a
    daa
    djnz    bin_bcd_loop
    pop     bc
    ret

;Convert BCD to Binary
;Args: A = BCD Byte
;Destroys: BC
;Returns: A = Binary Byte
bcd_to_bin:
    push    bc
    ld      c,a
    and     $F0
    srl     a
    ld      b,a
    srl     a
    srl     a
    add     a,b
    ld      b,a
    ld      a,c
    and     $0F
    add     a,b
    pop     bc
    ret
