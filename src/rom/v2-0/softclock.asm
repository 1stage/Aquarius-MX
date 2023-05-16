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
;+8 cdl Countdown LSB   Set to 0 after RTC Read/Write
;+9 cdh Countdown MSB      

;Initialize Real Time Clock
;  Sets SoftClock fields as specified
;Args: BC = Address Software Clock Registers
;      DE = Address of Initial RTC Data
;      HL = Address of DateTime Buffer
;Returns: A=0, Z=1 if Successful, A=$FF, Z=0 if not
;         BC, DE, HL unchanged
rtc_init:
    push    hl            ;Save Registers
    push    de
    push    bc 
    ld      h,d           ;Copying from Init Data
    ld      l,e
    ld      d,b           ;to Clock Registers
    ld      e,c
    ld      bc,10         ;Copy 10 Bytes
    ldir                    
    pop     bc            ;Restore Registers
    pop     de
    pop     hl
    ret                 

;Read Real Time Clock
;Args: BC = Address Software Clock Registers
;      HL = Address of DateTime Buffer
;Returns: A=0, Z=1 if Successful, A=$FF, Z=0 if not
;         BC, DE, HL unchanged
rtc_read:
    ld      a,(bc)            ;Check RTC Found flag
    or      a                 ;If 0 (Not Found)
    jr      nz,do_rtc_read    ;  return Failure
    ld      (hl),a            ;DTM is Invalid
    dec     a
    ret
do_rtc_read:
    push    hl            ;Save Registers
    push    de
    push    bc 
    ld      d,h           ;Copying to DTM Buffer
    ld      e,l
    ld      h,b           ;Copying from SoftClock
    ld      l,c
    ld      bc,8          ;Copying 8 Bytes
    ldir                  ;Do Copy
    pop     bc            ;Restore Registers
    pop     de
    pop     hl
    ret                 


;Write Real Time Clock
;Args: BC = Address Software Clock Registers
;      HL = Address of DateTime Buffer
;Returns: A=0, Z=1 if Successful, A=$FF, Z=0 if not
;         BC, DE, HL unchanged
rtc_write:
    push    hl            ;Save Registers
    push    de            
    push    bc 
    ld      d,b           ;Copying DTM Buffer
    ld      e,c           ;Copying to Software
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

