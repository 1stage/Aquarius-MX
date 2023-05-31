;===============================================================================
;  Statement/Function Dispatch and Keyword Tables and Related Routines
;===============================================================================

if $ & $FF00
    org ($ & $FF00) + 256
endif

; Combined Statement Jump Table
; Standard BASIC Routines left as HEX
STJUMPS:
    dw      $0C21                 ;$80 END              
    dw      $05BC                 ;$81 FOR               
    dw      $0D13                 ;$82 NEXT              
    dw      $071C                 ;$83 DATA              
    dw      $0893                 ;$84 INPUT             
    dw      $10CC                 ;$85 DIM               
    dw      $08BE                 ;$86 READ              
    dw      $0731                 ;$87 LET               
    dw      $06DC                 ;$88 GOTO              
    dw      $06BE                 ;$89 RUN               
    dw      $079C                 ;$8A IFS               
    dw      $0C05                 ;$8B RESTOR            
    dw      $06CB                 ;$8C GOSUB             
    dw      $06F8                 ;$8D RETURN            
    dw      $071E                 ;$8E REM               
    dw      $0C1F                 ;$8F STOP              
    dw      $0780                 ;$90 ONGOTO            
    dw      $07B5                 ;$91 LPRINT            
    dw      ST_COPY               ;$92 COPY              
    dw      $0B3B                 ;$93 DEF               
    dw      ST_POKE               ;$94 POKE              
    dw      $07BC                 ;$95 PRINT             
    dw      $0C4B                 ;$96 CONT              
    dw      $056C                 ;$97 LIST              
    dw      $0567                 ;$98 LLIST             
    dw      $0CCD                 ;$99 CLEAR             
    dw      $1C2C                 ;$9A CLOAD             
    dw      $1C08                 ;$9B CSAVE             
    dw      ST_PSET               ;$9C PSET              
    dw      ST_PRESET             ;$9D PRESET            
    dw      $1AD6                 ;$9E SOUND             
    dw      $0BBD                 ;$9F NEW
;Miscellaneous Functions
    dw      SNERR                 ;$A0 TAB(   
    dw      SNERR                 ;$A1 TO     
    dw      SNERR                 ;$A2 FN     
    dw      SNERR                 ;$A3 SPC(   
    dw      SNERR                 ;$A4 INKEY$ 
    dw      SNERR                 ;$A5 THEN   
    dw      SNERR                 ;$A6 NOT    
    dw      SNERR                 ;$A7 STEP   
;Operators
    dw      SNERR                 ;$A8 +      
    dw      SNERR                 ;$A9 -      
    dw      SNERR                 ;$AA *      
    dw      SNERR                 ;$AB /      
    dw      SNERR                 ;$AC ^      
    dw      SNERR                 ;$AD AND    
    dw      SNERR                 ;$AE OR     
    dw      SNERR                 ;$AF >      
    dw      SNERR                 ;$B0 =      
    dw      SNERR                 ;$B1 <      
;Standard BASIC Functions
    dw      SNERR                 ;$B2 SGN     
    dw      SNERR                 ;$B3 INT     
    dw      SNERR                 ;$B4 ABS     
    dw      SNERR                 ;$B5 USR  
    dw      SNERR                 ;$B6 FRE     
    dw      SNERR                 ;$B7 LPOS    
    dw      SNERR                 ;$B8 POS     
    dw      SNERR                 ;$B9 SQR     
    dw      SNERR                 ;$BA RND     
    dw      SNERR                 ;$BB LOG     
    dw      SNERR                 ;$BC EXP     
    dw      SNERR                 ;$BD COS     
    dw      SNERR                 ;$BE SIN     
    dw      SNERR                 ;$BF TAN     
    dw      SNERR                 ;$C0 ATN     
    dw      SNERR                 ;$C1 PEEK    
    dw      SNERR                 ;$C2 LEN     
    dw      SNERR                 ;$C3 STR$     
    dw      SNERR                 ;$C4 VAL     
    dw      SNERR                 ;$C5 ASC     
    dw      SNERR                 ;$C6 CHR$     
    dw      SNERR                 ;$C7 LEFT$    
    dw      SNERR                 ;$C8 RIGHT$   
    dw      ST_MID                 ;$C9 MID$     
    dw      SNERR                 ;$CA POINT
;MX BASIC Statements and Functions
    dw      SNERR                 ;$CB INSTR
    dw      ST_PUT                ;$CC PUT    
    dw      ST_GET                ;$CD GET    
    dw      ST_DRAW               ;$CE DRAW   
    dw      ST_CIRCLE             ;$CF CIRCLE 
    dw      ST_LINE               ;$D0 LINE   
    dw      ST_SWAP               ;$D1 SWAP   
    dw      ST_DOKE               ;$D2 DOKE   
    dw      ST_SDTM               ;$D3 SDTM   
    dw      ST_EDIT               ;$D4 EDIT   
    dw      ST_CLS                ;$D5 CLS    
    dw      ST_LOCATE             ;$D6 LOCATE 
    dw      ST_OUT                ;$D7 OUT    
    dw      ST_PSG                ;$D8 PSG    
    dw      ST_DEBUG              ;$D9 DEBUG  
    dw      ST_CALL               ;$DA CALL   
    dw      ST_LOAD               ;$DB LOAD   
    dw      ST_SAVE               ;$DC SAVE   
    dw      ST_DIR                ;$DD DIR    
    dw      ST_CAT                ;$DE CAT    
    dw      ST_DEL                ;$DF DEL    
    dw      ST_CD                 ;$E0 CD     
    dw      SNERR                 ;$E1 IN
    dw      SNERR                 ;$E2 JOY
    dw      SNERR                 ;$E3 HEX
    dw      SNERR                 ;$E4 VER
    dw      SNERR                 ;$E5 DTM
    dw      SNERR                 ;$E6 DEC
    dw      ST_KEY                ;$E7 KEY
    dw      SNERR                 ;$E8 DEEK
    dw      ST_ERR                ;$E9 ERR OR
    dw      SNERR                 ;$EA STRING
    dw      SNERR                 ;$EB XOR
    dw      ST_MENU               ;$EC MENU
    dw      SNERR                 ;$ED EVAL
    dw      ST_SLEEP              ;$EE SLEEP
    dw      ST_MKDIR              ;$EF MKDIR
    dw      SNERR                 ;$F0 RMDIR
    dw      SNERR                 ;$F1 OFF
    dw      ST_WAIT               ;$F2 WAIT
    dw      SNERR                 ;$F3
    dw      SNERR                 ;$F4
    dw      SNERR                 ;$F5
    dw      SNERR                 ;$F6
    dw      SNERR                 ;$F7
    dw      SNERR                 ;$F8
    dw      SNERR                 ;$F9
    dw      SNERR                 ;$FA
    dw      SNERR                 ;$FB
    dw      SNERR                 ;$FC
    dw      SNERR                 ;$FD
    dw      SNERR                 ;$FE
    dw      SNERR                 ;$FF

; Combined Function Jump Table
FNJUMPS:
;Standard BASIC Functions
    dw      HOOK27+1              ;$B2 SGN     
    dw      HOOK27+1              ;$B3 INT     
    dw      HOOK27+1              ;$B4 ABS     
    dw      HOOK27+1              ;$B5 USR  
    dw      FN_FRE                ;$B6 FRE     
    dw      HOOK27+1              ;$B7 LPOS    
    dw      HOOK27+1              ;$B8 POS     
    dw      HOOK27+1              ;$B9 SQR     
    dw      HOOK27+1              ;$BA RND     
    dw      HOOK27+1              ;$BB LOG     
    dw      HOOK27+1              ;$BC EXP     
    dw      HOOK27+1              ;$BD COS     
    dw      HOOK27+1              ;$BE SIN     
    dw      HOOK27+1              ;$BF TAN     
    dw      HOOK27+1              ;$C0 ATN     
    dw      FN_PEEK               ;$C1 PEEK    
    dw      HOOK27+1              ;$C2 LEN     
    dw      HOOK27+1              ;$C3 STR$     
    dw      HOOK27+1              ;$C4 VAL     
    dw      FN_ASC                ;$C5 ASC     
    dw      HOOK27+1              ;$C6 CHR$     
    dw      HOOK27+1              ;$C7 LEFT$    
    dw      HOOK27+1              ;$C8 RIGHT$   
    dw      HOOK27+1              ;$C9 MID$     
    dw      HOOK27+1              ;$CA POINT
;MX BASIC Statements and Functions
    dw      FN_INSTR              ;$CB INSTR
    dw      SNERR                 ;$CC PUT    
    dw      SNERR                 ;$CD GET    
    dw      SNERR                 ;$CE DRAW   
    dw      SNERR                 ;$CF CIRCLE 
    dw      SNERR                 ;$D0 LINE   
    dw      FN_SWAP               ;$D1 SWAP   
    dw      SNERR                 ;$D2 DOKE   
    dw      SNERR                 ;$D3 SDTM   
    dw      SNERR                 ;$D4 EDIT   
    dw      SNERR                 ;$D5 CLS    
    dw      SNERR                 ;$D6 LOCATE 
    dw      SNERR                 ;$D7 OUT    
    dw      SNERR                 ;$D8 PSG    
    dw      SNERR                 ;$D9 DEBUG  
    dw      SNERR                 ;$DA CALL   
    dw      SNERR                 ;$DB LOAD   
    dw      SNERR                 ;$DC SAVE   
    dw      SNERR                 ;$DD DIR    
    dw      SNERR                 ;$DE CAT    
    dw      SNERR                 ;$DF DEL    
    dw      FN_CD                 ;$E0 CD     
    dw      FN_IN                 ;$E1 IN
    dw      FN_JOY                ;$E2 JOY
    dw      FN_HEX                ;$E3 HEX
    dw      FN_VER                ;$E4 VER
    dw      FN_DTM                ;$E5 DTM
    dw      FN_DEC                ;$E6 DEC
    dw      FN_KEY                ;$E7 KEY
    dw      FN_DEEK               ;$E8 DEEK
    dw      FN_ERR                ;$E9 ERR
    dw      FN_STRING             ;$EA STRING
    dw      FN_XOR                ;$EB XOR
    dw      SNERR                 ;$EC MENU
    dw      FN_EVAL               ;$ED EVAL
    dw      SNERR                 ;$EE SLEEP
    dw      SNERR                 ;$EF MKDIR
    dw      SNERR                 ;$F0 RMDIR
    dw      SNERR                 ;$F1 OFF
    dw      SNERR                 ;$F2 WAIT
    dw      SNERR                 ;$F3
    dw      SNERR                 ;$F4
    dw      SNERR                 ;$F5
    dw      SNERR                 ;$F6
    dw      SNERR                 ;$F7
    dw      SNERR                 ;$F8
    dw      SNERR                 ;$F9
    dw      SNERR                 ;$FA
    dw      SNERR                 ;$FB
    dw      SNERR                 ;$FC
    dw      SNERR                 ;$FD
    dw      SNERR                 ;$FE
    dw      SNERR                 ;$FF


; These are here so they don't cross a page boundary
; Extended Error Code List
ERR_CODES: 
        db     "NF"               ; NEXT without FOR
        db     "SN"               ; Syntax error
        db     "RG"               ; RETURN without GOSUB
        db     "OD"               ; Out of DATA
        db     "FC"               ; Illegal function call
        db     "OV"               ; Overflow
        db     "OM"               ; Out of memory
        db     "UL"               ; Undefined line number
        db     "BS"               ; Subscript out of range
        db     "DD"               ; Duplicate Definit  ion
        db     "/0"               ; Division by zero
        db     "ID"               ; Illegal direct
        db     "TM"               ; Type mismatch
        db     "OS"               ; Out of string space
        db     "LS"               ; String too long
        db     "ST"               ; String formula too complex
        db     "CN"               ; Can't continue
        db     "UF"               ; Undefined user function
        db     "MO"               ; Missing operand
        db     "IO"               ; Disk I/O Error
        db     "UE"               ; Unprintable Error

; Pointers into err_table
ERRMSG: dw      MSGNF             ; 0
        dw      MSGSN             ; 2
        dw      MSGRG             ; 4
        dw      MSGOD             ; 6
        dw      MSGFC             ; 8
        dw      MSGOV             ; 10
        dw      MSGOM             ; 12
        dw      MSGUS             ; 14
        dw      MSGBS             ; 16
        dw      MSGDD             ; 18
        dw      MSGDV0            ; 20
        dw      MSGID             ; 22
        dw      MSGTM             ; 24
        dw      MSGSO             ; 26
        dw      MSGLS             ; 28
        dw      MSGST             ; 30
        dw      MSGCN             ; 32
        dw      MSGUF             ; 34
        dw      MSGMO             ; 36
        dw      MSGIO             ; 38
        dw      MSGUE             ; 40

STATEMENT:
    exx                         ; save BC,DE,HL
    sub     $80                 ; Convert from Token to Table Position
    add     a,a                 ; A * 2 to index WORD size vectors
    ld      l,a
    ld      h,high(STJUMPS)
    ld      a,(hl)
    ld      iyl,a
    inc     hl
    ld      a,(hl)
    ld      iyh,a
    exx                         ; Restore BC,DE,HL
    rst     CHRGET              ; Skip Token and Eat Spaces
    jp      (iy)                ; Go Do It

FUNCTION:
    push    af
    exx                         ; save BC,DE,HL
    add     a,a                 ; A * 2 to index WORD size vectors
    ld      l,a
    ld      h,high(FNJUMPS)
    ld      a,(hl)
    ld      iyl,a
    inc     hl
    ld      a,(hl)
    ld      iyh,a
    exx                         ; Restore BC,DE,HL
    pop     af
    jp      (iy)                ; Go Do It

; Our Commands and Functions
;
; - Any more commands will need to be added after the functions
;
BTOKEN       equ $cb                ; our first token number
TBLCMDS:
; Squeezed in before IN funcvtion
    db      $80 + 'IN', "STR"       ; $cb - String Position Function    
; MX BASIC Commands
    db      $80 + 'P', "UT"         ; $cc - Put Pixels
    db      $80 + 'G', "ET"         ; $cd - Get Pixels
    db      $80 + 'D', "RAW"        ; $ce - Graphic Macro Language
    db      $80 + 'C', "IRCLE"      ; $cf - Draw Circle
    db      $80 + 'L', "INE"        ; $d0 - Draw Line
    db      $80 + 'S', "WAP"        ; $d1 - Double Poke
    db      $80 + 'D', "OKE"        ; $d2 - Double Poke
    db      $80 + 'S', "DTM"        ; $d3 - Set DateTime
    db      $80 + 'E', "DIT"        ; $d4 - Edit BASIC line (advanced editor)
    db      $80 + 'C', "LS"         ; $d5 - Clear screen
    db      $80 + 'L', "OCATE"      ; $d6 - Move cursor to position on screen
    db      $80 + 'O', "UT"         ; $d7 - Read data from serial device
    db      $80 + 'P', "SG"         ; $d8 - Send data to Programmable Sound Generator
    db      $80 + 'D', "EBUG"       ; $d9 - Run debugger
    db      $80 + 'C', "ALL"        ; $da - Call routine in memory
    db      $80 + 'L', "OAD"        ; $db - Load file
    db      $80 + 'S', "AVE"        ; $dc - Save file
    db      $80 + 'D', "IR"         ; $dd - Directory, full listing
    db      $80 + 'C', "AT"         ; $de - Catalog, brief directory listing
    db      $80 + 'D', "EL"         ; $df - Delete file/folder (previously KILL)
    db      $80 + 'C', "D"          ; $e0 - Change directory
SDTMTK  = $D3
CDTK    = $E0

; - New functions get added to the END of the functions list.
;   They also get added at the END of the TBLFNJP list.
;
; MX BASIC Functions Functions list

    db      $80 + 'I', "N"          ; $e1 - Input function
    db      $80 + 'J', "OY"         ; $e2 - Joystick function
    db      $80 + 'H', "EX$"        ; $e3 - Hex value function
    db      $80 + 'V', "ER"         ; $e4 - USB BASIC ROM Version function
    db      $80 + 'D', "TM$"        ; $e5 - GET/SET DateTime function
    db      $80 + 'D', "EC"         ; $e6 - Decimal value function
    db      $80 + 'K', "EY"         ; $e7 - Key function
    db      $80 + 'D', "EEK"        ; $e8 - Double Peek function
    db      $80 + 'E', "RR"         ; $e9 - Error Number (and Line?)
    db      $80 + 'S', "TRING$"     ; $ea - Create String function
    db      $80 + 'X', "OR"         ; $eb - PUT Operator and Bitwise XOR 
    db      $80 + 'M', "ENU"        ; $ec - Display and Execute Menu
    db      $80 + 'E', "VAL"        ; $ed - Display and Execute Menu
    db      $80 + 'S', "LEEP"       ; $ee - Display and Execute Menu
    db      $80 + 'M', "KDIR"       ; $ef - Create Directory
    db      $80 + 'R', "MDIR"       ; $f0 - Delete Directory
    db      $80 + 'O', "FF"         ; $f1 - Special Keyword OFF
    db      $80 + 'W', "AIT"        ; $f1 - Special Keyword OFF
    db      $80                     ; End of table marker
ERRTK     = $E9
STRINGTK  = $EA
XORTK     = $EB
OFFTK     = $F1

;-------------------------------------
;         Replace Command
;-------------------------------------
; Called from $0536 by RST $30,$0a
; Replaces keyword with token.

REPLCMD:
    ld      a,b                ; A = current index
    cp      $cb                ; if < $CB then keyword was found in BASIC table
    ld      IX,HOOK10+1        ;   CRUNCX will also return here when done
    push    IX
    ret     nz                 ;   so return
;     pop     bc                 ; get return address from stack
;     pop     af                 ; restore AF
;     pop     hl                 ; restore HL
;     push    bc                 ; put return address back onto stack
    ex      de,hl              ; HL = Line buffer
    ld      de,TBLCMDS-1       ; DE = our keyword table
    ld      b,BTOKEN-1         ; B = our first token
    jp      CRUNCX             ; continue searching using our keyword table

;-------------------------------------
;             PEXPAND
;-------------------------------------
; Called from $0598 by RST $30,$16
; Expand token to keyword

PEXPAND:
    cp      BTOKEN              ; is it one of our tokens?
    jr      nc,PEXPBAB          ; yes, expand it
    jp      HOOK22+1

PEXPBAB:
    sub     BTOKEN - 1
    ld      c,a                 ; C = offset to AquBASIC command
    ld      de,TBLCMDS          ; DE = table of AquBASIC command names
    jp      $05a8               ; Print keyword indexed by C

; Long Error Descriptions
ERR_TABLE:
MSGNF:  db      "NEXT without FOR",0
MSGSN:  db      "Syntax error",0
MSGRG:  db      "RETURN without GOSUB",0
MSGOD:  db      "Out of DATA",0
MSGFC:  db      "Illegal function call",0
MSGOV:  db      "Overflow",0
MSGOM:  db      "Out of memory",0
MSGUS:  db      "Undefined line number",0
MSGBS:  db      "Subscript out of range",0
MSGDD:  db      "Duplicate Definition",0
MSGDV0: db      "Division by zero",0
MSGID:  db      "Illegal direct",0
MSGTM:  db      "Type mismatch",0
MSGSO:  db      "Out of string space",0
MSGLS:  db      "String too long",0
MSGST:  db      "String formula too complex",0
MSGCN:  db      "Can't continue",0
MSGUF:  db      "Undefined user function",0
MSGMO:  db      "Missing operand",0
MSGIO:  db      "Disk I/O error",0
MSGUE:  db      "Unprintable error",0
