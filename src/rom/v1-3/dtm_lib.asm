;RTC Date and Time Module for Z80
;DateTime validation, modification and String Conversion Routines 

;To assemble
;  tasm -80 -b -s dtm_lib.asm


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
;Destroys: AF, BC
;Returns: DE and HL unchanged

dtm_to_fmt:
        call  dtm_to_str          ;Convert RTC Date to Unformatted Date String
                                  ;then Fall into Formatting Routine
;Format Date String
;Converts Date String from YYMMDDHHmmsscc to YYYY-MM-DD HH:mm:ss
;Args: DE = Address of String Buffer
;Returns: A = 0 if Successful, $FF if Date String is Invalid
;         DE and HL unchanged
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
        xor     a                 ;Return Success
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

;Convert RTC Date to Unformatted Date String
;Args: HL = Address of RTC Buffer
;      DE = Address of String Buffer
;Destroys: AF, BC
;Returns: DE and HL unchanged
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

;Convert Raw Date String to RTC Date
;Args: HL = Address of DTM Buffer
;      DE = Address of String Buffer
;           Must be in format YYMMDDHHmmss (any following characters are ignored)
;Returns: A=0, Z=1 if Successful, A=$FF, Z=0 if not
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

;
;Validate RTC fields 
;Args: HL = Address of DTM Buffer
;Destroys: BC
;Returns: A=0, Z=1 if Successful, A=$FF, Z=0 if not
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

dtm_bounds:     ;seconds minutes    hour     day     month
        .byte   $00,$60, $00,$60, $00,$24, $01,$32, $01,$13

