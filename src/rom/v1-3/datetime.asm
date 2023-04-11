;******************************************************************************
;                      Dallas DS1244 Real Time Clock Driver
;******************************************************************************
; Original code by:
;        Curtis Kaylor                                      revcurtisp@gmail.com
;        Mack Wharton                              Mack@Aquarius.je, aquarius.je
;        Sean P. Harrington                  sph@1stage.com, aquarius.1stage.com
;
; Date       Ver    Changes                         
; 2023-04-11 V0.00  Started
;


; Curtis notes:
; -----------------------
; Two Digit BCD Numbers
;
;DS 1244 Time Shadow Registers
;FACLO   $38E4  0 Centiseconds    
;
;
;FACMO   $38E5  1 Seconds         
;FACHO   $38E6  2 Minutes         
;FAC     $38E7  3 Hour            
;
;TI$
;FBUFFR  $38E8   Y  
;        $38E9   Y
;        $38EA   M
;        $38EB   M
;        $38EC   D
;        $38ED   D
;        $38EE   H
;        $38EF   H
;        $38F0   M
;        $38F1   M
;        $38F2   S
;        $38F3   S
;        $38F4   C
;        $38F5   C
;
;DS 1244 Date Shadow Registers
;RESHO   $38F6  5 Day             
;RESMO   $38F7  6 Month           
;RESLO   $38F8  7 Year            

;------------------------------------------------------------------------------
;     DateTime Command - SET DateTime
;------------------------------------------------------------------------------
;
;  The DTM command allows users to SET the DateTime in the Dallas RTC by
;  using the following format:
;
;    DTM "230411101500" (where string is in "YYMMDDHHMMSS" format) - Sets DateTime to 11 APR 2023 10:15:00 (24 hour format)
;
;  - Improperly formatted string can result in unpredicable results
;  - DateTime is set by default to 24 hour mode, with cc (hundredths of seconds) set to 0
;

ST_DTM:
        RET


;------------------------------------------------------------------------------
;     DateTime Function - GET DateTime
;------------------------------------------------------------------------------
;
;  The DTM$() function allows users to GET the DateTime from the Dallas RTC
;  by using the following format and parameters:
;
;    PRINT DTM$(0) - Returns DateTime as a string in "YYMMDDHHMMSSCC" format
;
;    PRINT DTM$(1) - Returns DateTime as a string in "YYYY-MM-DD HH:MM:SS" format
;  
;  - Use of other parameter values will return the same result as DTM$(1)
;  - Additional parameters may be added for discreet results
;

FN_DTM:
        RET

;------------------------------------------------------------------------------
;     Redraw DateTime at bottom of SPLASH screen
;------------------------------------------------------------------------------
;

DTMSPL_STRTLOC = $3379    ; DateTime text should begin at $3379 / 13177 (9,22) - SPH

SPL_DATETIME:
        RET