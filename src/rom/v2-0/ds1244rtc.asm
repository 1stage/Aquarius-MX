;RTC DS1244 Phantom Clock
;

;DS1244 Clock Data Structure
;+0 enl Enabled         $FF if enabled, else 0
;+1 cc  Centiseconds
;+2 ss  Seconds
;+3 mm  Minutes
;+4 HH  Hour            24 Hour Format
;+5 D   Day of Week
;+6 DD  Day of Month
;+7 MM  Month 
;+8 YY  Year
;+9 cd0 Countdown       Set to 0 after RTC Read/Write
;+10 cd1 Countdown       

ds1244addr: EQU $4000

;Initialize Real Time Clock
;  Fills date-time buffer with zeros
;  causing following reads to return RTC Not Found
;Args: BC = Address of RTC Shadow Registers
;      HL = Address of Normalized DateTime 
;Returns: A=$FF, Z=0 if Successful, A=$00, Z=1 if not
;         BC, DE, HL unchanged
rtc_init:
    xor     a
    dec     a
    ld      (bc),a
    call    rtc_read  ; since this will error out the clock if needs be
    ret                 

;Read Real Time Clock
;Args: BC = Address of RTC Shadow Registers
;      HL = Address of Normalized DateTime 
;Returns: A=0, Z=1 if Successful, A=$FF, Z=0 if not
;         BC, DE, HL unchanged
rtc_read:
    ld      a,(bc)            ;Check RTC Found flag
    or      a                 ;If 0 (Not Found)
    ;call    nz,do_rtc_read  ;  If Clock Was Found, Call Read
    call    do_rtc_read
    ret

;Read Real Time Clock
;Args: BC = Address of RTC Shadow Registers
;      HL = Address of Normalized DateTime 
;Returns: A=$FF, Z=0 if Successful, A=$00, Z=1 if not
;         BC, DE, HL unchanged
do_rtc_read:
    ld      a,(ds1244addr)  ; save byte at control address
    push    af              ;Save Registers
    push    de
    push    hl      
    push    bc              ; Registers saved as AF,DE,HL,BC
    LD      hl,rtc_Ident
    inc     bc              ; want to write to shadow +1
    ld      d,b             ; Save BC for later use (remember no Stack usage here)
    ld      e,c                 
    ld      c,8             ; Going to loop round 8 times here
    xor     a
    ld      (ds1244addr),a  ; store a 0 here, so if no RTC, then it will just read all zero's
    ld      a,(ds1244addr)  ; start read sequence (needs a Read cycle before the 64 writes)
ds_ident:
    ld      a,(hl)          ; this works by writing the pattern $C5, $3A, $A3, $5C, $C5, $3A, $A3, $5C
    ld      b,8             ; to an address within the clock
ds_identInner:
    ld      (ds1244addr),a  ; it is all written by 64 single bit D0, so 
    rra                     ; rotating A right 8 times for each byte and writing to the control address
    djnz    ds_identInner
    inc     hl
    dec     c
    jr      nz,ds_ident
                            ; okay we should be talking to the clock now....
    ld      h,d             ; restore HL to = original BC passed in
    ld      l,e
    LD      c,8
ds_readTime:
    LD      D,0             ; this is the byte we are going to read
    ld      B,8             ; Have to read in 64 times, as the 8 bytes (64 bits) 
ds_readByte:                ; all come in in D0
    LD      A,(ds1244addr)  ; So read a bit
    AND     $01             ; mask anything else off
    RRCA                    ; Rotate Right into D7
    AND     $80             ; mask of anything else (shouldn't be needed but hey ho)
    OR      D               ; Merge D in
    RRA                     ; Rotate Right (D0 ->C flag)
    LD      D,A             ; Save back into D
    DJNZ    ds_readByte     ; Loop for the byte
    ld      a,d             ; Need to Correct D for the last Rotate
    rla                     ; Rotate Left D0 <- C Flag
    ld      (hl),a          ; Save value in shadow
    inc     hl              
    dec     c               
    jr      nz,ds_readTime ; Loop round for the 8 bytes      
    pop     bc              ; recover HL & BC
    pop     hl
    push    hl              ; Resave them for exit
    push    bc              ; BC = shadow ATM
    ex      de,hl           ; de= DTM Buffer
    inc     bc              ; shadow+1    
    ld      h,b
    ld      l,c
    ld      b,8
    xor     a
ds_checkvalues:
    or      (hl)            ; loop through checking for all zeros
    inc     hl              ; this means no RTC found
    djnz    ds_checkValues
    pop     hl              ; copy original BC off stack
    push    hl
    jr      z,ds_NoClockFound
    ld      a,$ff
ds_NoClockFound:    
    ld      (hl),a          ; Copying to DTM Buffer (already in DE)
                            ; Copying from shadow     
    ld      bc,5            ; Copying 5 Bytes (Valid + 4 bytes)
    ldir                    ; Do Copy  (HH:MM:SS.CC)
    inc     hl              ; skip DAY
    ld      bc,3
    ldir                    ; Do Copy (YY-MM-DD)
    pop     bc              ; Restore Registers
    pop     hl    
    pop     de
    pop     af
    ld      (ds1244addr),a  ; restore original memory into control address
    ld      a,(hl)          ; return (dtm_buffer+0)
    or      a               
    ret                   
rtc_Ident: defb $C5, $3A, $A3, $5C, $C5, $3A, $A3, $5C

;Write Real Time Clock
;Args: BC = Address of RTC Shadow Registers
;      HL = Address of Normalized DateTime 
;Returns: Output as per RTC_Read (which is called on exit)
;         DE and HL unchanged
rtc_write:
    ld      a,(ds1244addr)  ; save byte at control address
    push    af              ;Save Registers
    push    de          
    push    hl              ; Registers saved as AF,DE,HL,BC
    push    bc
    ld      d,b             ; DE = RTC_SHADOW
    ld      e,c
    ld      bc,5
    ldir    
    ld      a,$11
    ld      (de),a          ; Clock enable No Reset and Day 1    
    inc     de
    ld      bc,3
    ldir
    pop     de              ; copy original BC off stack
    push    de
    LD      hl,rtc_Ident
    ld      c,8             ; Going to loop round 8 times here
    xor     a
    ld      (ds1244addr),a  ; store a 0 here, so if no RTC, then it will just read all zero's
    ld      a,(ds1244addr)  ; start read sequence (needs a Read cycle before the 64 writes)
ds_wrIdent:
    ld      a,(hl)          ; this works by writing the pattern $C5, $3A, $A3, $5C, $C5, $3A, $A3, $5C
    ld      b,8             ; to an address within the clock
ds_wrIdentInner:
    ld      (ds1244addr),a  ; it is all written by 64 single bit D0, so 
    rra                     ; rotating A right 8 times for each byte and writing to the control address
    djnz    ds_wrIdentInner 
    inc     hl
    dec     c
    jr      nz,ds_wrIdent
                            ; okay we should be talking to the clock now....
    ;call    Break
    ld      h,d             ; restore HL to = original BC passed in
    ld      l,e       
    inc     hl              ; read from shadow starting at +1
    LD      c,8
ds_wrData:
    ld      a,(hl)          ; this works by writing the pattern RTC_SHADOW 
    ld      b,8             ; to an address within the clock
ds_wrDataInner:
    ld      (ds1244addr),a  ; it is all written by 64 single bit D0, so 
    rra                     ; rotating A right 8 times for each byte and writing to the control address
    djnz    ds_wrDataInner
    inc     hl
    dec     c
    jr      nz,ds_wrData
    pop     bc
    pop     hl              ; Restore Registers        
    pop     de
    pop     af
    ld      (ds1244addr),a  ; restore original memory into control address
    jp      rtc_read        ; Sets buffers up correctly
