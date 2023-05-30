; show splash screen (Boot menu)
SPLASH:
    push    bc                 ; Save Ctrl-C flag
    call    usb__root          ; root directory
    ld      a,CYAN
    call    clearscreen
    ld      b,40
    ld      hl,$3000
TOPLINE: 
    ld      (hl),' '
    set     2,h
    ld      (hl),WHITE*16+BLACK ; black border, white on black chars in top line
    res     2,h
    inc     hl
    djnz    TOPLINE
REDRAW:
    ld      ix,BootbdrWindow
    call    OpenWindow
    ld      ix,bootwindow
    call    OpenWindow
    pop     bc                ; Get Ctrl-C Flag
    push    bc
    call    BootMenuPrint
    
; outer loop for boot option key so date time display gets updated
SPLLOOP:
    call    SPL_DATETIME       ; Print DateTime at the bottom of the screen
; wait for Boot option key
    ld      b,0                ; Call the clock update every 256 loops
SPLKEY:                        ;
    call    Key_Check          ;
    jr      nz,SPLGOTKEY       ; We got a key pressed
    djnz    SPLKEY             ; loop until c=0
    jr      SPLLOOP
SPLGOTKEY:
  ifndef softrom
    cp      "1"                ; '1' = load ROM
    jr      z,LoadROM
  endif
    cp      "2"                ; '2' = debugger
    jr      z, DEBUG
    cp      $0d                ; RTN = cold boot
    jp      z, COLDBOOT
    and     $DF                ; Convert letters to upper-case
    cp      "A"                ; 'A' = About screen
    jr      z, AboutSCR        
    pop     bc                 ; Get Ctrl-C Flag
    push    bc
    and     c                  ;  Make A=0 if Ctrl-C disabled
    cp      $03                ;  ^C = warm boot
    jp      z, WARMBOOT
    jr      SPLLOOP

DEBUG:
    ld      a,(SysFlags)
    bit     SF_DEBUG,a
    jr      z,SPLLOOP
    call    ST_DEBUG           ; invoke Debugger
    JR      SPLASH

LoadROM:
    call    Load_ROM           ; ROM loader
    JR      SPLASH

; About/Credits window

AboutSCR:
    ld      ix,AboutBdrWindow           ; Draw outer window
    call    OpenWindow
    ld      ix,AboutWindow              ; Draw smaller inset window
    call    OpenWindow
    ld      hl,AboutText
    ;call    OpenWindow
    call    WinPrtStr
    call    Wait_key
    JP      REDRAW

AboutBdrWindow:
    db   (1<<WA_BORDER)|(1<<WA_TITLE)|(1<<WA_CENTER) ; attributes
    db   (BLUE*16)+CYAN               ; text colors,   (FG * 16) + BG
    db   (DKBLUE*16)+CYAN             ; border colors, (FG * 16) + BG
    db   2,3,36,20                    ; x,y,w,h
    dw   AboutBdrTitle                ; title

AboutWindow:
    db   0                            ; attributes
    db   (BLUE*16)+CYAN               ; text colors,   (FG * 16) + BG
    db   (DKBLUE*16)+CYAN             ; border colors, (FG * 16) + BG
    db   4,4,32,18                    ; x,y,w,h
    dw   0                            ; title

AboutBdrTitle:
    db     " About MX BASIC ",0

AboutText:
    db     CR,CR,CR
    db     "      Version - ",VERSION+'0','.',REVISION+'0',CR,CR
    db     " Release Date - Alpha 2023-05-29",CR,CR                       ; Can we parameterize this later?
    db     " ROM Dev Team - Curtis F Kaylor",CR
    db     "                Mack Wharton",CR
    db     "                Sean Harrington",CR
    db     CR
    db     "Original Code - Bruce Abbott",CR
    db     CR
    db     "     AquaLite - Richard Chandler",CR
    db     CR
    db     "Aquarius Draw - Matt Pilz",CR
    db     CR
    db     " github.com/1stage/Aquarius-MX",CR
    db     0

; boot outer window with border
BootBdrWindow:
    db      (1<<WA_BORDER)|(1<<WA_TITLE)|(1<<WA_CENTER) ; attributes
    db      CYAN                   ; text colors
    db      CYAN                   ; border colors
    db      2,3,36,20              ; x,y,w,h
    dw      bootWinTitle           ; Titlebar text

; boot window text inside border
BootWindow:
    db     0
    db     CYAN
    db     CYAN
    db     9,5,26,18
    dw     0

BootWinTitle:
    db     " Aquarius MX "
StrBasicVersion:
    db     "BASIC "
    db     "v",VERSION+'0','.',REVISION+'0',' ',0

BootMenuPrint:
    call    WinPrtMsg
    db      CR,CR
    db      "      1. "
  ifdef softrom
    db      "(disabled)"
  else  
    db      "Load ROM"
  endif 
    db      CR,CR,CR,0
    ld      a,(SysFlags)
    bit     SF_DEBUG,a
    jr      z,.nodebug
    call    WinPrtMsg
    db      "      2. Debug"
.nodebug    
    call    WinPrtMsg
    db      CR,CR,CR,CR,CR                      ; Move down a few rows
    db      "    <RTN> USB BASIC"
    db      CR,0
    or      c                             ; If Ctrl-C Flag is 0
    jr      z,.about                      ;   Skip Ctrl-C Message
    call    WinPrtMsg
    db      CR," <CTRL-C> Warm Start",CR,0
.about
    call    WinPrtMsg
    db      CR
    db      "      <A> About...",CR
    db      CR,CR,0
    ret

;------------------------------------------------------------------------------
;     Redraw DateTime at bottom of SPLASH screen
;------------------------------------------------------------------------------
;
SPL_DATETIME:
    ld      bc,RTC_SHADOW
    ld      hl,DTM_BUFFER
    call    rtc_read
    ld      de,DTM_STRING
    call    dtm_to_fmt    ;Convert to Formatted String   
    ld      d,2                
    ld      e,16              
    call    WinSetCursor
    ld      hl,DTM_STRING
    call    WinPrtStr
    ret    
    
