;RTC Software Clock
;

;Software Clock Data Structure
;+0 enl Enabled         $FF if enabled, else 0
;+1 cc  Centiseconds
;+2 ss  Seconds
;+3 mm  Minutes
;+4 HH  Hour            24 Hour Format
;+5 DD  Day
;+6 MM  Month 
;+7 YY  Year
;+8 cd0 Countdown       Set to 0 after RTC Read/Write
;+9 cd1 Countdown       

ds1244addr: EQU $4000

;Initialize Real Time Clock
;  Fills date-time buffer with zeros
;  causing following reads to return RTC Not Found
;Args: BC = Address of Software Clock 
;Destroys: BC
;Returns: A = 0 if Successful, otherwise $FF
;         BC, DE, HL unchanged
rtc_init:
    push    hl            ;Save Registers
    push    bc 
    ld      h,b           
    ld      l,c
    xor     a
    dec     a
    ld      b,10          ;Set all SoftClock fields to 0
rtc_init_loop:
    ld      (hl),a        ;Clear field
    inc     hl            ;Move to Next One
    djnz    rtc_init_loop ;and clear it
    xor a                 ;Return A=0 - Success
    pop     bc            ;Restore Registers
    pop     hl
    ret                 

;Read Real Time Clock
;Args: HL = Address of DTM Buffer
;      BC = Address of Software Clock 
;Returns: A=0, Z=1 if Successful, A=$FF, Z=0 if not
;         BC, DE, HL unchanged
rtc_read:
    ld      a,(bc)            ;Check RTC Found flag
    or      a                 ;If 0 (Not Found)
    jr      nz,do_rtc_read    ;  return Failure
    ld      (hl),a            ;DTM is Invalid
    dec     a
    ret
;Read Real Time Clock
;Args: HL = Address of DTM Buffer
;      BC = Address of Software Clock 
;Returns: A=0, Z=1 if Successful, A=$FF, Z=0 if not
;         BC, DE, HL unchanged
do_rtc_read:
 
    ld      a,(ds1244addr)  ; save byte at control address
    push    af              ;Save Registers
    push    de
    push    hl      
    push    bc              ; Registers saved as AF,DE,HL,BC
    LD      hl,rtc_Ident
    inc     bc              ; want to write to softclock +1
    ld      d,b             ; Save BC for later use (remember no Stack usage here)
    ld      e,c                 
    ld      c,8             ; Going to loop round 8 times here
    ld      a,(ds1244addr)  ; start read sequence (needs a Read cycle before the 64 writes)
ds_ident:
    ld      a,(hl)          ; A
    ld      b,8
ds_ident_inner:
    ld      (ds1244addr),a
    rra
    djnz    ds_ident_inner
    inc     hl
    dec     c
    jr      nz,ds_ident
    ; okay we should be talking to the clock now....
    ld      h,d  ; restore HL to = original BC passed in
    ld      l,e
    LD      c,8
ds_read_time:
    LD      D,0 ; this is the byte
    ld      B,8
ds_read_byte
    LD      A,(ds1244addr)
    AND     $01
    RRCA
    AND     $80
    OR      D
    RRA
    LD      D,A
    DJNZ    ds_read_byte
    ld      a,d
    rla
    ld      (hl),a
    inc     hl
    dec     c
    jr      nz,ds_read_time       
    pop     bc  
    pop     hl
    push    hl
    push    bc
    ld      d,h           ;Copying to DTM Buffer
    ld      e,l
    ld      h,b           ;Copying from SoftClock
    ld      l,c
    ld      bc,8           ;Copying 8 Bytes
    ldir                    ; Do Copy                    
    pop     bc            ;Restore Registers
    pop     hl
    pop     de
    pop     af
    ld      (ds1244addr),a    ; restore original memory
    xor     a
    dec     a
    ld      (bc),a       ; write FF into (Softclock) to indicate clock present 
    xor     a
    ret                 

rtc_Ident: defb $C5, $3A, $A3, $5C, $C5, $3A, $A3, $5C

;Write Real Time Clock
;Args: HL = Address of DTM Buffer 
;      BC = Address of Software Clock 
;Returns: A=0, Z=1 if Successful, A=$FF, Z=0 if not
;         DE and HL unchanged
rtc_write:
    push    hl            ;Save Registers
    push    de            
    push    bc 
    ld      d,b           ;Copying from SoftClock
    ld      e,c           ;Copying to DTM Buffer
    ld      bc,8          ;Copying 8 Bytes
    ldir                  ;Do Copy
    xor     a             ;Clear Countdown 
    ld      (de),a
    inc     de
    ld      (de),a
    pop     bc            ;Restore Registers
    pop     de
    pop     hl
    ret                 

