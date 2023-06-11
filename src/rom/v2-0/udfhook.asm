;===============================================================================
;  UDF Hook Table and Dispatch Routine
;===============================================================================

;; ## UDF Dispatch Table and Routine
;;
;; The BABASIC/USB BASIC Hook Dispatch routine, which was based on the Extended
;; BASIC dispatch routine searched a table for the hook number (byte following the 
;; RST 6). This process consumed hundreds of cycles, with unimplemented hooks 
;; taking the longest (over 600 cycles) which causes BASIC to run noticeably
;; slower.
;;
;; The old hook routine also pushed registers AF, BC, and HL onto the stack and
;; the hook service routines would have to pop them off, requiring more bytes of
;; of code and consuming more cycles.
;;
;; The FASTHOOK routine executes in a flat 92 cycles and the hook service routines
;; are entered with all registers intact. This is accomplished by using the shadow
;; registers and a single table with a two byte entry for each hook number. This
;; table is placed aat a page boundary to eliminate the need for addition when
;; calculating the offset into it. The entries for unimplemented hooks are the
;; addresses immediately following the respective hook calls in BASIC.
;;
;; The design of the dispatch table makes it easy to see at a glance which hooks
;; have been implemented and which have not. The dispatch routine and table total
;; 77 bytes.

; Align to 256 Byte Boundary
if $ & $FF00
    org ($ & $FF00) + 256
endif

HOOKTABLE:                    ; ## caller   addr  performing function
    dw      ERRORX            ;  0 ERROR    03DB  Initialize Stack, Display Error, and Stop Program
    dw      ERRCRX            ;  1 ERRCRD   03E0  Print Error Message
    dw      AQMAIN            ;  2 READY    0402  BASIC command line (immediate mode)
    dw      HOOK3+1           ;  3 EDENT    0428  Tokenize Entered Line  
    dw      HOOK4+1           ;  4 FINI     0480  Finish Adding/Removing Line or Loading Program
    dw      LINKLINES         ;  5 LINKER   0485  Update BASIC Program Line Links
    dw      HOOK6+1           ;  6 PRINT    07BC  Execute PRINT Statement
    dw      HOOK7+1           ;  7 FINPRT   0866  End of PRINT Statement
    dw      HOOK8+1           ;  8 TRMNOK
    dw      EVAL_EXT          ;  9 EVAL     09FD  Evaluate Number or String
    dw      REPLCMD           ; 10 NOTGOS   0536  Converting Keyword to Token
    dw      CLEARX            ; 11 CLEAR    0CCD  Execute CLEAR Statement
    dw      SCRTCX            ; 12 SCRTCH   0BBE  Execute NEW Statement
    dw      HOOK13+1          ; 13 OUTDO    198A  Execute OUTCHR
    dw      ATN1              ; 14 ATN      1985  ATN() function
    dw      DEFX              ; 15 DEF      0B3B  DEF statement
    dw      FNDOEX            ; 16 FNDOER   0B40  FNxx() call
    dw      HOOK17+1          ; 17 LPTOUT   1AE8  Print Character to Printer
    dw      HOOK18+1          ; 18 INCHRH   1E7E  Read Character from Keyboard
    dw      HOOK19+1          ; 19 TTYCHR   1D72  Print Character to Screen
    dw      HOOK20+1          ; 20 CLOAD    1C2C  Load File from Tape
    dw      HOOK21+1          ; 21 CSAVE    1C09  Save File to Tape
    dw      PEXPAND           ; 22 LISPRT   0598  expanding a token
    dw      STATEMENT         ; 23 GONE2    064B  interpreting next BASIC statement
    dw      RUNPROG           ; 24 RUN      06BE  starting BASIC program
    dw      ONGOTX            ; 25 ONGOTO   0780  ON statement
    dw      HOOK26+1          ; 26 INPUT    0893  Execute INPUT, bypassing Direct Mode check
    dw      FUNCTION          ; 27 ISFUN    0A5F  Executing a Function
    dw      HOOK28+1          ; 28 DATBK    08F1

;------------------------------------------------------
;             UDF Hook Service Routine
;------------------------------------------------------
; This address is stored at $3806-7, and is called by
; every RST $30. It allows us to hook into the system
; ROM in several places (anywhere a RST $30 is located).
; Total execution time 92 cycles.

FASTHOOK:
    ex      af,af'              ; save AF
    exx                         ; save BC,DE,HL
    pop     hl                  ; get hook return address
    ld      a,(hl)              ; A = byte (RST $30 parameter)
    add     a,a                 ; A * 2 to index WORD size vectors
    ld      l,a
    ld      h,high(HOOKTABLE)
    ld      a,(hl)
    ld      ixl,a
    inc     hl
    ld      a,(hl)
    ld      ixh,a
    exx                         ; Restore BC,DE,HL
    ex      af,af'              ; Restore AF
    jp      (ix)


