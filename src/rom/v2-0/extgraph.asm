;----------------------------------------------------------------------------
; Extended BASIC Graphics Routines
;----------------------------------------------------------------------------

SGBASE  equ     $A0     ; Base Semigraphics Character

;Set Up Extended BASIC System Variables
XSTART: ld      hl,$0704         ; Default = White, Current = Blue 
        ld      (FORCLR),hl      ; Set Foreground Colors
        ld      a,$C3            ; JP Instruction
        ld      (MAXUPD),a       ;{GWB} Major Axis Move Update
        ld      (MINUPD),a       ;{GWB} Minor Axis Move Update
        ld      (OPCJMP),a       ; Draw Operator Routine
        xor     a                ; Store 0 in
        ld      (DRWSCL),a       
        ld      (DRWFLG),a       
        ld      (DRWANG),a       
        ret

;----------------------------------------------------------------------------
;;; ---
;;; ## PSET / PRESET
;;; Draw or Erase a pixel
;;; ### FORMAT:
;;;   - PSET | PRESET [STEP] (*x-coord*,*y-coord*) [ , *color* ]
;;;     - Action: PSET draws a pixel on the screen. PRESET erases a pixel from the screen.
;;; ### EXAMPLES:
;;; `  `
;;; > 
;----------------------------------------------------------------------------
; E1F0
; Extended PSET or PRESET
; Reads Coordinates and saves them for subsequent LINE -(X,Y) or LINE -STEP(X,Y) statement then executes standard basic PSET/PRESET code
ST_PRESET: 
        call    SCANDX            ; Scan Coordinates as [STEP] (X,Y)
        xor     a                 ; PRESET FLAG
PPRSEX: ex      af,af'            ; Put it in AF'
        jp      PPRSDO            ; Go Do PSET/PRESET
        
ST_PSET:                          
        call    SCANDX            ; Scan Coordinates as [STEP] (X,Y)
        call    CHRGT2            ; Get Character at Text Pointer
        jr      nz,PPSETC         ; If End of Statement
        ld      a,1               ; PSET Flag
        jr      PPRSEX            ; Go Do Standard PSET
PPSETC: SYNCHK  ','               ; Else Require Comma
        call    ATRGET            ; Read Attribute Byte
        call    SCLXYX            ; SEE IF POINT OFF SCREEN
        jp      nc,FCERR          ; NC IF POINT OFF SCREEN - FC Error
        call    MAPXYP  
        jp      SETC              ; PLOT THE POINT

        
ATRGET: push    bc                ; Save Current Point
        push    de                
        jp      ATRSCB            ; Jump Into ATRSCN`

; E38F
;;Convert FAC to Integer and Return in [H,L]
FRCINX: rst     FSIGN             ;[M80] GET THE SIGN OF THE FAC IN A
        jp      m,FRCINM          ; If Positive
        ex      de,hl             ;   Save DE in HL
        call    FRCINT            ;   Convert FAC into Integer in DE
        ex      de,hl             ;   Put Result into HL, Restore DE
        ret                       ; Else
FRCINM: push    de                ;   Save DE
        call    NEG               ;   Negate FAC
        call    FRCINT            ;   Convert FAC into Integer in DE
        call    NEG               ;   Un-Negate FAC
        ld      hl,0
        or      a
        sbc     hl,de             ;   Put 0 - Integer into HL
        pop     de                ;   and Restore DE
        ret
; E3AB
MAKINT: push    hl                ; Save Registers
        push    de
        push    bc
        ld      a,h
        ld      d,l
        call    FLOATD            ; Put HL into FAC
        pop     bc                ; Restore Registers
        pop     de
        pop     hl
        ret

;E3F6
;----------------------------------------------------------------------------
;;; ---
;;; ## GET Statement
;;; Copy a rectangle of screen data to a numeric array.
;;; ### FORMAT:
;;;  - GET (*x1*,*y1*)-(*x2*,*y2*),*arrayname*
;;;    - Action: Copies a rectangle of screen characters and colors to numeric array *arrayname*.
;;;      - The rectangle's upper left corner is at column *x1* on line *y1* and lower right corner is at column *x2* on line *y2*
;;;      - *arrayname* must already be DIMensioned to a size large enough to hold the data.
;;;        - To calculate the size of an array needed to store the elements in a rectangle:
;;;          - Multply the width of the rectangle in rows by the height in LINES
;;;          - Round up to an even number
;;;          - Divide by two
;;;      - Can also be combined with LOAD array* and SAVE array* to import/export "sprite" graphics from/to USB drive.
;;;      - See PUT statement for copying from array to screen.
;;;  - Advanced: The screen data (CHRRAM and COLRAM) is stored in the array as binary data.
;;; ### EXAMPLE:
;;; ```
;;; 10 DIM A(8)
;;; 20 GET (1,1)-(4,4),A
;;; 30 SAVE "CURSOR.SPR",*A
;;; ```
;;; > Saves the contents of a 4x4 character/color grid at the upper left of the screen to file CURSOR.SPR.
;----------------------------------------------------------------------------
ST_PUT: ld      a,1               ;;Mode = GET
        jr      GGPUTG
;E3FA
;----------------------------------------------------------------------------
;;; ---
;;; ## PUT Statement
;;; Copy data from a numeric array into a rectangle of screen data.
;;; ### FORMAT:
;;;  - PUT (*x1*,*y1*)-(*x2*,*y2*),*arrayname*
;;;    - Action: Copies bytes from *arrayname* into a a rectangle of screen characters and colors.
;;;      - The rectangle's upper left corner is at column *x1* on line *y1* and lower right corner is at column *x2* on line *y2*
;;;      - *arrayname* must already be DIMensioned to a size large enough to hold the data, and populated with data.
;;;        - To calculate the size of an array needed to store the elements in a rectangle:
;;;          - Multply the width of the rectangle in rows by the height in LINES
;;;          - Round up to an even number
;;;          - Divide by two
;;;      - Can also be combined with LOAD array* and SAVE array* to import/export "sprite" graphics from/to USB drive.
;;;      - See GET statement for copying from screen to array.
;;;  - Advanced: The screen data (CHRRAM and COLRAM) is stored in the array as binary data.
;;; ### EXAMPLE:
;;; ```
;;; 10 DIM A(8)
;;; 20 LOAD "CURSOR,SPR",*A
;;; 30 PUT (1,1)-(4,4),A
;;; ```
;;; > Loads a file into array A, then displays the contents of in a 4x4 character/color grid at the upper left of the screen.
;----------------------------------------------------------------------------
ST_GET: xor     a                 ;;Mode = PUT
GGPUTG: jp      GPUTG

; E3FE
; Parse Intger
GETIN2: call    FRMEVL            ; EVALUATE A FORMULA
INTFR2: push    hl                ; SAVE THE TEXT POINTER
        call    CHKNUM            ; MUST BE NUMBER
        call    FRCINT            ; COERCE THE ARGUMENT TO INTEGER
        pop     hl                ; RESTORE THE TEXT POINTER
        ret

; ALLOW A COORDINATE OF THE FORM (X,Y) OR STEP(X,Y)
; THE LATTER IS RELATIVE TO THE GRAPHICS AC.
; THE GRAPHICS AC IS UPDATED WITH THE NEW VALUE
; RESULT IS RETURNED WITH [B,C]=X AND [D,E]=Y
; CALL SCAN1 TO GET FIRST IN A SET OF TWO PAIRS SINCE IT ALLOWS
; A NULL ARGUMENT TO IMPLY THE CURRENT AC VALUE AND
; IT WILL SKIP A "@" IF ONE IS PRESENT
; E5D2
SCAN1:  ld      a,(hl)            ; GET THE CURRENT CHARACTER
        cp      '@'               ; ALLOW MEANINGLESS "@"
        call    z,CHRGTR          ; BY SKIPPING OVER IT
        ld      bc,0              ; ASSUME NO COODINATES AT ALL (-SECOND)
        ld      d,b               
        ld      e,c               
        cp      MINUTK            ; SEE IF ITS SAME AS PREVIOUS            
        jr      z,SCANN           ; USE GRAPHICS ACCUMULATOR
; THE STANDARD ENTRY POINT  
SCANDX: ld      a,(hl)            ; GET THE CURRENT CHARACTER
        cp      STEPTK            ; IS IT RELATIVE?
        push    af                ; REMEMBER
        call    z,CHRGTR          ; SKIP OVER $STEP TOKEN
        SYNCHK  '('               ; SKIP OVER OPEN PAREN
        call    GETIN2            ; SCAN X INTO [D,E]
        push    de                ; SAVE WHILE SCANNING Y
        SYNCHK  ','               ; SCAN COMMA               
        call    GETIN2            ; GET Y INTO [D,E]
        SYNCHK  ')'               
        pop     bc                ; GET BACK X INTO [B,C]             
        pop     af                ; RECALL IF RELATIVE OR NOT
SCANN:  push    hl                ; SAVE TEXT POINTER
        ld      hl,(GRPACX)       ; GET OLD POSITION
        jr      z,SCXREL          ; IF ZERO,RELATIVE SO USE OLD BASE
        ld      hl,0              ; IN ABSOLUTE CASE, JUST Y USE ARGEUMENT
SCXREL: add     hl,bc             ; ADD NEW VALUE
        ld      (GRPACX),hl       ; UPDATE GRAPHICS ACCUMLATOR
        ld      (GXPOS),hl        ; STORE SECOND COORDINTE FOR CALLER
        ld      b,h               ; RETURN X IN BC
        ld      c,l                
        ld      hl,(GRPACY)       ; GET OLDY POSITION
        jr      z,SCYREL          ; IF ZERO, RELATIVE SO USE OLD BASE
        ld      hl,0              ; ABSOLUTE SO OFFSET BY 0
SCYREL: add     hl,de             
        ld      (GRPACY),hl       ; UPDATE Y PART OF ACCUMULATOR
        ld      (GYPOS),hl        ; STORE Y FOR CALLER
        ex      de,hl             ; RETURN Y IN [D,E]
        pop     hl                ; GET BACK THE TEXT POINTER
        ret
; E61B
; ATTRIBUTE SCAN
; LOOK AT THE CURRENT POSITION AND IF THERE IS AN ARGUMENT READ IT AS
; THE 8-BIT ATTRIBUTE VALUE TO SEND TO SETATR. IF STATEMENT HAS ENDED
; OR THERE IS A NULL ARGUMENT, SEND FORCLR  TO SETATR
; 
; Entry point ATRENT will leave [A] unchanged if there is a null agrument
ATRSCN: ld      a,(FORCLR)        ; Get Default foreground color
ATRENT: push    bc                ; SAVE THE CURRENT POINT
        push    de                  
        ld      e,a               ; Preload Attribute with Default Value
        dec     hl                ; SEE IF STATEMENT ENDED
        rst     CHRGET              
        jr      z,ATRFIN          ; USE DEFAULT
        SYNCHK  ','               ;  INSIST ON COMMA
        cp      ','               ; ANOTHER COMMA FOLLOWS?
        jr      z,ATRFIN          ; IF SO, NULL ARGUMENT SO USE DEFAULT
ATRSCB: call    GETBYT            ; GET THE BYTE
ATRFIN: ld      a,e               ; GET ATTRIBUTE INTO [A]
        push    hl                ; SAVE THE TEXT POINTER
        call    SETATR            ; SET THE ATTRIBUTE AS THE CURRENT ONE
        jp      c,FCERR           ; ILLEGAL ATTRIBUTES GIVE FUNCTION CALL
        pop     hl                  
        pop     de                ; GET BACK CURRENT POINT
        pop     bc              
        jp      CHRGT2          

; XDELT SETS [H,L]=ABS(GXPOS-[B,C]) AND SETS CARRY IF [B,C].GT.GXPOS
; ALL REGISTERS EXCEPT [H,L] AND [A,PSW] ARE PRESERVED
; NOTE: [H,L] WILL BE A DELTA BETWEEN GXPOS AND [B,C] - ADD 1 FOR AN X "COUNT"
XDELT:  ld      hl,(GXPOS)        ; GET ACCUMULATOR POSITION
        or      a
        sbc     hl,bc             ; DO SUBTRACT INTO [H,L]
CNEGHL: ret     nc              

NEGHL:  xor       a             ; STANDARD [H,L] NEGATE
        sub       l
        ld        l,a
        sbc       a,h
        sub       l
        ld        h,a
        scf
        ret
; E64E 
; YDELT SETS [H,L]=ABS(GYPOS-[D,E]) AND SETS CARRY IF [D,E].GT.GYPOS
; ALL REGISTERS EXCEPT [H,L] AND [A,PSW] ARE PRESERVED
YDELT:  ld      hl,(GYPOS)
        or      a
        sbc     hl,de
        jr      CNEGHL
; E659 
; Register Exchange Routines
; XCHGY EXCHANGES [D,E] WITH GYPOS
; XCHGAC PERFORMS BOTH OF THE ABOVE
; NONE OF THE OTHER REGISTERS IS AFFECTED
XCHGY:  push    hl
        ld      hl,(GYPOS)
        ex      de,hl
        ld      (GYPOS),hl
        pop     hl
        ret
; E663
XCHGAC: call    XCHGY
XCHGX:  push    hl
        push    bc
        ld      hl,(GXPOS)
        ex      (sp),hl
        ld      (GXPOS),hl
        pop     bc
        pop     hl
        ret
; E672
;----------------------------------------------------------------------------
;;; ---
;;; ## LINE Statement
;;; Draw line or box on screen.
;;; ### FORMAT:
;;;   - LINE [ (*x-coord1*,*y-coord1*) ] - ( *x-coord2*,*y-coord2*) [ ,[ *color* ] [,B[F] ]
;;;     - Action: Draws line from the first specified point to the second specified point.
;;;       - If the first (*x-coord1*,*y-coord1*) is ommited (starts with a dash), the line starts at the last referenced point.
;;;       - B (box) draws a box with the specified points at opposite corners.
;;;       - BF (filled box) draws a box (as ,B) and fills in the interior with points.
;;;       - If *color* is not specified, the current screen colors are maintained and two commas must be used before B or BF
;;; ### EXAMPLES:
;;; ` LINE (0,36)-(79,36) `
;;; > Draws a horizontal line which divides the screen in half from top to bottom.
;;; 
;;; ` LINE (40,0)-(40,71) `
;;; > Draws a vertical line which divides the screen in half from left to right.
;;; 
;;; ` LINE (0,0)-(79,71) `
;;; > Draws a diagonal line from the top left to lower right corner of the screen.
;;;  
;;; ` LINE (10,10)-(20,20),2 `
;;; > Draws a line in color 2.
;;;
;;; ```
;;; 10 CLS
;;; 20 LINE -(RND*80,RND*72),RND*16
;;; 30 GOTO 20
;;; ```
;;; >  Draw lines forever using random attributes.
;----------------------------------------------------------------------------
; LINE COMMAND
; LINE [(X1,Y1)]-(X2,Y2) [,ATTRIBUTE[,B[F]]]
; DRAW A LINE FROM (X1,Y1) TO (X2,Y2) EITHER
; 1. STANDARD FORM -- JUST A LINE CONNECTING THE 2 POINTS
; 2. ,B=BOXLINE -- RECTANGLE TREATING (X1,Y1) AND (X2,Y2) AS OPPOSITE CORNERS
; 3. ,BF= BOXFILL --  FILLED RECTANGLE WITH (X1,Y1) AND (X2,Y2) AS OPPOSITE CORNERS
; ATTRIBUTE is the Foreground Color
ST_LINE:    
        call    SCAN1             ; SCAN THE FIRST COORDINATE
        push    bc                ; SAVE THE POINT
        push    de                
        rst     SYNCHR            
        db      MINUTK            ; MAKE SURE ITS PROPERLY SEPERATED
        call    SCANDX            ; SCAN THE SECOND SET
        call    ATRSCN            ; SCAN THE ATTRIBUTE
        pop     de                ; GET BACK THE FIRST POINT
        pop     bc                
        jr      z,DOLINE          ; IF STATEMENT ENDED ITS A NORMAL LINE
        SYNCHK  ','               ; OTHERWISE MUST HAVE A COMMA
        SYNCHK  'B'
        jr      z,BOXLIN          ; IF JUST "B" THE NON-FILLED BOX
        SYNCHK  'F'               ; MUST BE FILLED BOX
DOBOXF: push    hl                ; SAVE THE TEXT POINTER
        call    SCLXYX            ; SCALE FIRST POINT
        call    XCHGAC            ; SWITCH POINTS
        call    SCLXYX            ; SCALE SECOND POINT
        call    YDELT             ; SEE HOW MANY LINES AND SET CARRY
        call    c,XCHGY           ; MAKE [D,E] THE SMALLEST Y
        inc     hl                ; MAKE [H,L] INTO A COUNT
        push    hl                ; SAVE COUNT OF LINES
        call    XDELT             ; GET WIDTH AND SMALLEST X
        call    c,XCHGX           ; MAKE [B,C] THE SMALLEST X
        inc     hl                ; MAKE [H,L] INTO A WIDTH COUNT
        push    hl                ; SAVE WIDTH COUNT
        call    MAPXYP            ; MAP INTO A "C"
        pop     de                ; GET WIDTH COUNT
        pop     bc                ; GET LINE COUNT
BOXLOP: push    de                ; SAVE WIDTH
        push    bc                ; SAVE NUMBER OF LINES
        call    FETCHC            ; LOOK AT CURRENT C
        push    af                ; SAVE BIT MASK OF CURRENT "C"
        push    hl                ; SAVE Address
        ex      de,hl             ; SET UP FOR NSETCX WITH COUNT
        call    NSETCX            ; IN [H,L] OF POINTS TO SETC
        pop     hl                ; GET BACK STARTING C
        pop     af                ; Address AND BIT MASK
        call    STOREC            ; SET UP AS CURRENT "C"
        call    DOWNC             ; MOVE TO NEXT LINE DOWN IN Y
        pop     bc                ; GET BACK NUMBER OF LINES
        pop     de                ; GET BACK WIDTH
        dec     bc                ; COUNT DOWN LINES
        ld      a,b               
        or      c                 ; SEE IF ANY LEFT
        jr      nz,BOXLOP         ; KEEP DRAWING MORE LINES
        pop     hl              
        ret                     
; E6C6 
DOLINE: push    bc                ; SAVE COORDINATES
        push    de                
        push    hl                ; SAVE TEXT POINTER
        call    DOGRPH            
        ld      hl,(GRPACX)       ; RESTORE ORIGINAL SECOND COORDINATE
        ld      (GXPOS),hl        
        ld      hl,(GRPACY)       ; FOR BOXLIN CODE
        ld      (GYPOS),hl        
        pop     hl                ; RESTORE TEXT POINTER
        pop     de              
        pop     bc              
        ret                     
; E6DC 
BOXLIN: push    hl                ; SAVE TEXT POINTER
        ld      hl,(GYPOS)        
        push    hl                ; SAVE Y2
        push    de                ; SAVE Y1
        ex      de,hl             ; MOVE Y2 TO Y1
        call    DOLINE            ; DO TOP LINE
        pop     hl                ; MOVE Y1 TO Y2
        ld      (GYPOS),hl        
        ex      de,hl             ; RESTORE Y1 TO [D,E]
        call    DOLINE            
        pop     hl                ; GET BACK Y2
        ld      (GYPOS),hl        ; AND RESTORE
        ld      hl,(GXPOS)        ; GET X2
        push    bc                ; SAVE X1
        ld      b,h               ; SET X1=X2
        ld      c,l               
        call    DOLINE            
        pop     hl                
        ld      (GXPOS),hl        ; SET X2=X1
        ld      b,h               ; RESTORE X1 TO [B,C]
        ld      c,l               
        call    DOLINE            
        pop     hl                ; RESTORE THE TEXT POINTER
        ret                     
; E706 
DOGRPH: call    SCLXYX            ; CHEATY SCALING - JUST TRUNCATE FOR NOW
        call    XCHGAC            
        call    SCLXYX            
        call    YDELT             ; GET COUNT DIFFERENCE IN [H,L]
        call    c,XCHGAC          ; IF CURRENT Y IS SMALLER NO EXCHANGE
        push    de                ; SAVE Y1 COORDINATE
        push    hl                ; SAVE DELTA Y
        call    XDELT             
        ex      de,hl             ; PUT DELTA X INTO [D,E]
        ld      hl,RIGHTC         ; ASSUME X WILL GO RIGHT
        jr      nc,LINCN2        
        ld      hl,LEFTC        
LINCN2: ex      (sp),hl           ; XTHL
        rst     COMPAR            ; SEE WHICH DELTA IS BIGGER
        jr      nc,YDLTBG         ; YDELTA IS BIGGER OR EQUAL 
        ld      (MINDEL),hl       ; SAVE MINOR AXIS DELTA (Y)
        pop     hl                ; GET X ACTION ROUTINE
        ld      (MAXUPD+1),hl     ; SAVE IN MAJOR ACTION Address
        ld      hl,DOWNC          ; ALWAYS INCREMENT 
        ld      (MINUPD+1),hl     ; WHICH IS THE MINOR AXIS
        ex      de,hl             ; [H,L]=DELTA X=MAJOR DELTA
        jr      LINCN3            ; MERGE WITH YDLTBG CASE AND DO DRAW
; E737  
YDLTBG: ex      (sp),hl           ; XTHL
        ld      (MINUPD+1),hl     ; SAVE Address OF MINOR AXIS UPDATE
        ld      hl,DOWNC          ; Y IS ALWAYS INCREMENT MODE
        ld      (MAXUPD+1),hl     ; SAVE AS MAJOR AXIS UPDATE
        ex      de,hl             ; [H,L]=DELTA X
        ld      (MINDEL),hl       ; SAVE MINOR DELTA
        pop     hl                ; [H,L]=DELTA Y=MAJOR DELTA
; E746 
;;Draw a Line
; MAJOR AXIS IS ONE WITH THE LARGEST DELTA
; MINOR IS THE OTHER
; READY TO DRAW NOW
; MINUPD+1=Address TO GO TO UPDATE MINOR AXIS COORDINATE
; MAXUPD+1=Address TO GO TO UPDATE MAJOR AXIS COORDINATE
; [H,L]=MAJOR AXIS DELTA=# OF POINTS-1
; MINDEL=DELTA ON MINOR AXIS
;
; IDEA IS
;  SET SUM=MAJOR DELTA/2
;  [B,C]=# OF POINTS
;  MAXDEL=-MAJOR DELTA (CONVENIENT FOR ADDING)
; LINE LOOP (LINLP3):
;       DRAW AT CURRENT POSITION
;       UPDATE MAJOR AXIS
;       SUM=SUM+MINOR DELTA
;       IF SUM.GT.MAJOR DELTA THEN UPDATE MINOR AND SUM=SUM-MAJOR DELTA
;       DECREMENT [B,C] AND TEST FOR 0 -- LOOP IF NOT
; END LOOP
LINCN3: pop     de                ; GET BACK Y1 
        push    hl                ; SAVE FOR SETTING UP COUNT
        call    NEGHL          
        ld      (MAXDEL),hl       ; SAVE MAJOR DELTA FOR SUMMING
        call    MAPXYP            ; GET POSITION INTO BITMSK AND [H,L]  
        pop     de                
        push    de                ; START SUM AT MAXDEL/2 
        call    HLFDE             
        pop     bc                ; GET COUNT IN [B,C]
        inc     bc                ; NUMBER OF POINTS IS DELTA PLUS ONE 
        jr      LINLP3           
; E75A 
LINLPR: pop     hl
        ld      a,b
        or      c
        ret     z
LINLOP: call    MAXUPD            ; UPDATE MAJOR AXIS
; Inner loop of line code.        
LINLP3: call    SETC              ; SET CURRENT POINT
        dec     bc                
        push    hl                
        ld      hl,(MINDEL)       
        add     hl,de             ; ADD SMALL DELTA TO SUM
        ex      de,hl             
        ld      hl,(MAXDEL)       ; UPDATE SUM FOR NEXT POINT
        add     hl,de             
        jr      nc,LINLPR         
        ex      de,hl             
        pop     hl                
        ld      a,b               
        or      c                 
        ret     z                 
        call    MINUPD            ; ADVANCE MINOR AXIS           
        jr      LINLOP            ; CONTINUE UNTIL COUNT EXHAUSTED

HLFDE:  srl     d                 ; DE = DE/2
        rr      e
        ret 
;Restore Text Pointer and Return
POPTRT: pop     hl
        ret
NEGDE:  ex      de,hl           ; DE = 0 - DE
        call    NEGHL
        ex      de,hl
        ret
;----------------------------------------------------------------------------
;;; ---
;;; ## CIRCLE
;;; Draw circle or ellipse on screen.
;;; ### FORMAT:
;;;   - CIRCLE(*xcenter*, *ycenter*), *radius*[,[*color*][,[*start*],[*end*][,*aspect*]]]
;;;     - Action: Draws circle, elipse, or arc with given *radius* centered at *xcenter*, *ycenter*.
;;;       - If *color* is not specified, the screen colors are maintained. 
;;;       - The *start* and *end* angle parameters are radian arguments between -2π and 2π which specify where the drawing of the ellipse is to begin and end. 
;;;         - If start or end is negative, the ellipse is connected to the center point with a line, and the angles are treated as if they are positive (note that this is different from adding 2π).
;;;         - The start angle may be less than the end angle.
;;;       - The option *aspect* describes the ratio of the x radius to the y radius (x:y). 
;;;         - The default aspect ratio gives a visual circle, assuming a standard monitor screen aspect ratio of 4:3. 
;;;         - If the aspect ratio is less than 1, then the radius is given in x-pixels. If it is greater than 1, the radius is given in y-pixels. 
;;;         - In many cases, an aspect ratio of 1 gives better ellipses. This also causes the ellipse to be drawn faster. 
;;; ### EXAMPLES:
;;; ` CIRCLE(40,36),10,8 `
;;; > Draws a grey circle in the center of the screen.
;;;
;;; ` CIRCLE(40,36),10,3,-0.75,-5.7,0.75 `
;;; > Draws a popular arcade character in the middle of the screen
; ------------------------------------------------------------
ST_CIRCLE:  
        call    SCAN1             ; GET (X,Y) OF CENTER INTO GRPACX,Y
        SYNCHK  ','               ; EAT COMMA
        call    GETIN2            ; GET THE RADIUS
        ld      a,d 
        or      a 
        jp      m,FCERR 
        push    hl                ; SAVE TXTPTR
        ex      de,hl 
        ld      (GXPOS),hl        ; SAVE HERE TILL START OF MAIN LOOP
        call    MAKINT            ; PUT INTEGER INTO FAC
        call    CHKNUM            ; MUST BE NUMBER
        ld      bc,$8035          ; LOAD REGS WITH SQR(2)/2
        ld      de,$04F3  
        call    FMULT             ; DO FLOATING PT MULTIPLY
        call    FRCINX            ; CONVERT TO INTEGER & GET INTO [HL]
        ld      (CNPNTS),hl       ; CNPNTS=RADIUS*SQR(2)/2=# PTS TO PLOT
        xor     a                 ; ZERO OUT GLINEF - NO LINES TO CENTER
        ld      (GLINEF),a  
        ld      (CSCLXY),a  
        pop     hl                ; REGET TXTPTR
        call    ATRSCN            ; SCAN POSSIBLE ATTRIBUTE
        ld      c,1               ; SET LO BIT IN GLINEF FOR LINE TO CNTR
        ld      de,0              ; DEFAULT START COUNT = 0
        call    CGTCNT  
        push    de                ; SAVE COUNT FOR LATER COMPARISON
        ld      c,128             ; SET HI BIT IN GLINEF FOR LINE TO CNTR
        ld      de,0-1            ; DEFAULT END COUNT = INFINITY
        call    CGTCNT  
        ex      (sp),hl           ; GET START COUNT, PUSH TXTPTR TILL DONE
        xor     a 
        ex      de,hl             ; REVERSE REGS TO TEST FOR .LT.
        rst     COMPAR            ; SEE IF END .GE. START
        ld      a,0 
        jp      nc,CSTPLT         ; YES, PLOT POINTS BETWEEN STRT & END
        dec     a                 ; PLOT POINTS ABOVE & BELOW
        ex      de,hl             ; SWAP START AND END SO START .LT. END
        push    af                ; Swap sense of center line flags
        ld      a,(GLINEF)  
        ld      c,a 
        rlca  
        rlca  
        or      c 
        rrca  
        ld      (GLINEF),a        ; Store swapped flags
        pop     af  
; E7E6  
CSTPLT: ld      (CPLOTF),a        ; SET UP PLOT POLARITY FLAG
        ex      de,hl 
        ld      (CSTCNT),hl       ; STORE START COUNT
        ex      de,hl 
        ld      (CENCNT),hl       ; AND END COUNT
        pop     hl                ; GET TXTPTR
        dec     hl                ; NOW SEE IF LAST CHAR WAS A COMMA
        rst     CHRGET  
        jp      nz,CIRC1          ; SOMETHING THERE
        push    hl                ; SAVE TXTPTR
        call    GTASPC            ; GET DEFAULT ASPECT RATIO INTO [HL]
        ld      a,h 
        or      a                 ; IS ASPECT RATIO GREATER THAN ONE?
        jp      z,CIRC2           ; BRIF GOOD ASPECT RATIO
        ld      a,1 
        ld      (CSCLXY),a  
        ex      de,hl             ; ASPECT RATIO IS GREATER THAN ONE, USE INVERSE
        jp      CIRC2             ; NOW GO CONVERT TO FRACTION OF 256
; E809  
CIRC1:  SYNCHK  ','               ; EAT COMMA
        call    FRMEVL            ; EVALUATE A FORMULA
        push    hl                ; SAVE TXTPTR
        call    CHKNUM            ; MUST BE NUMBER
        call    CMPONE            ; SEE IF GREATER THAN ONE
        jp      nz,CIRC11         ; LESS THAN ONE - SCALING Y
        inc     a                 ; MAKE [A] NZ
        ld      (CSCLXY),a        ; FLAG SCALING X
        call    FDIV              ; RATIO = 1/RATIO, MAKE NUMBER FRACTION OF 256
; E81F  
CIRC11: ld      hl,FAC            ; BY MULTIPLYING BY 2^8 (256)
        ld      a,(hl)  
        add     a,8               ; ADD 8 TO EXPONENT
        ld      (hl),a  
        call    FRCINX            ; MAKE IT AN INTEGER IN [HL]
CIRC2:  ld      (ASPECT),hl       ; STORE ASPECT RATIO
;       CIRCLE ALGORITHM
;
;       [HL]=X=RADIUS * 2 (ONE BIT FRACTION FOR ROUNDING)
;       [DE]=Y=0
;       SUM =0
; LOOP: IF Y IS EVEN THEN
;             REFLECT((X+1)/2,(Y+1)/2) (I.E., PLOT POINTS)
;             IF X.LT.Y THEN EXIT
;       SUM=SUM+2*Y+1
;       Y=Y+1
;       IF SUM.GGWGRP.RNO
;             SUM=SUM-2*X+1
;             X=X-1
;       ENDIF
;       GOTO LOOP
;
        ld      de,0              ; INIT Y = 0
        ex      de,hl 
        ld      (CRCSUM),hl       ; SUM = 0
        ex      de,hl 
        ld      hl,(GXPOS)        ; X = RADIUS*2
        add     hl,hl 
; E838  
CIRCLP: call    ISCNTC            ;[M80] CHECK FOR CONTROL-C
        ld      a,e               ; TEST EVENNESS OF Y
        rra                       ; TO SEE IF WE NEED TO PLOT
        jp      c,CRCLP2          ; Y IS ODD - DON'T TEST OR PLOT
        push    de                ; SAVE Y AND X
        push    hl  
        inc     hl                ; ACTUAL COORDS ARE (X+1)/2,(Y+1)/2
        ex      de,hl 
        call    HLFDE             ; (PLUS ONE BEFORE DIVIDE TO ROUND UP)
        ex      de,hl 
        inc     de  
        call    HLFDE 
        call    CPLOT8  
        pop     de                ; RESTORE X AND Y
        pop     hl                ; INTO [DE] AND [HL] (BACKWARDS FOR CMP)
        rst     COMPAR            ; QUIT IF Y .GE. X
        jp      nc,POPTRT         ; GO POP TXTPTR AND QUIT
        ex      de,hl             ; GET OFFSETS INTO PROPER REGISTERS
CRCLP2: ld      b,h               ; [BC]=X
        ld      c,l 
        ld      hl,(CRCSUM) 
        inc     hl                ; SUM = SUM+2*Y+1
        add     hl,de 
        add     hl,de 
        ld      a,h               ; NOW CHECK SIGN OF RESULT
        add     a,a 
        jp      c,CNODEX          ; DON'T ADJUST X IF WAS NEGATIVE
        push    de                ; SAVE Y
        ex      de,hl             ; [DE]=SUM
        ld      h,b               ; [HL]=X
        ld      l,c               ; [HL]=2*X-1
        add     hl,hl 
        dec     hl  
        ex      de,hl             ; PREPARE TO SUBTRACT
        ld      a,l               ; CALC SUM-2*X+1
        sub     e 
        ld      l,a 
        ld      a,h 
        sbc     a,d 
        ld      h,a 
        dec     bc                ; X=X-1
        pop     de                ; GET Y BACK
CNODEX: ld      (CRCSUM),hl       ; UPDATE CIRCLE SUM
        ld      h,b               ; GET X BACK TO [HL]
        ld      l,c 
        inc     de                ; Y=Y+1
        jp      CIRCLP  
; E87B  
CPLSCX: push    de  
        call    SCALEY  
        pop     hl                ; GET UNSCALED INTO [HL]
        ld      a,(CSCLXY)        ; SEE WHETHER ASPECT WAS .GT. 1
        or      a 
        ret     z                 ; DON'T SWAP IF ZERO
        ex      de,hl 
        ret 
; E887  
CPLOT8: ex      de,hl 
        ld      (CPCNT),hl        ; POINT COUNT IS ALWAYS = Y
        ex      de,hl 
        push    hl                ; SAVE X
        ld      hl,0              ; START CPCNT8 OUT AT 0
        ld      (CPCNT8),hl 
        call    CPLSCX            ; SCALE Y AS APPROPRIATE
        ld      (CXOFF),hl        ; SAVE CXOFF
        pop     hl                ; GET BACK X
        ex      de,hl 
        push    hl                ; SAVE INITIAL [DE]
        call    CPLSCX            ; SCALE X AS APPROPRIATE
        ex      de,hl 
        ld      (CYOFF),hl  
        ex      de,hl 
        pop     de                ; GET BACK INITIAL [DE]
        call    NEGDE             ; START: [DE]=-Y,[HL]=X,CXOFF=Y,CY=X
        call    CPLOT4            ; PLOT +X,-SY -Y,-SX -X,+SY +Y,-SX
        push    hl  
        push    de  
        ld      hl,(CNPNTS)       ; GET # PNTS PER OCTANT
        ld      (CPCNT8),hl       ; AND SET FOR DOING ODD OCTANTS
        ex      de,hl 
        ld      hl,(CPCNT)        ; GET POINT COUNT
        ex      de,hl
        ld      a,l               ; ODD OCTANTS ARE BACKWARDS SO
        sub     e                 ; PNTCNT = PNTS/OCT - PNTCN
        ld      l,a 
        ld      a,h 
        sbc     a,d 
        ld      h,a 
        ld      (CPCNT),hl        ; PNTCNT = PNTS/OCT - PNTCNT
        ld      hl,(CXOFF)        ; NEED TO NEGATE CXOFF TO START OUT RIGHT
        call    NEGHL 
        ld      (CXOFF),hl  
        pop     de  
        pop     hl  
        call    NEGDE             ; ALSO NEED TO MAKE [DE]=-SX=-[DE],
                                  ;[GBB] PLOT +Y,-SX -X,-SY -Y,+SX +X,+SY
                                  ; (FALL THRU TO CPLOT4)
CPLOT4: ld      a,4               ; LOOP FOUR TIMES
CPLOT:  push    af                ; SAVE LOOP COUNT
        push    hl                ; SAVE BOTH X & Y OFFSETS
        push    de  
        push    hl                ; SAVE TWICE
        push    de  
        ex      de,hl 
        ld      hl,(CPCNT8)       ; GET NP*OCTANT*8
        ex      de,hl 
        ld      hl,(CNPNTS)       ; ADD SQR(2)*RADIUS FOR NEXT OCTANT
        add     hl,hl 
        add     hl,de 
        ld      (CPCNT8),hl       ; UPDATE FOR NEXT TIME
        ld      hl,(CPCNT)        ; CALC THIS POINT'S POINT COUNT
        add     hl,de             ; ADD IN PNTCNT*OCTANT*NP
        ex      de,hl             ; SAVE THIS POINT'S COUNT IN [DE]
        ld      hl,(CSTCNT)       ; GET START COUNT
        rst     COMPAR  
        jp      z,CLINSC          ; SEE IF LINE TO CENTER REQUIRED
        jp      nc,CNBTWN         ; IF SC .GT. PC, THEN NOT BETWEEN
        ld      hl,(CENCNT)       ; GET END COUNT
        rst     COMPAR  
        jp      z,GLINEC          ; GO SEE IF LINE FROM CENTER NEEDED
        jp      nc,CBTWEN         ; IF EC .GT. PC, THEN BETWEEN
  
CNBTWN: ld      a,(CPLOTF)        ; SEE WHETHER TO PLOT OR NOT
        or      a                 ; IF NZ, PLOT POINTS NOT IN BETWEEN
        jp      nz,CPLTIT         ; NEED TO PLOT NOT-BETWEEN POINTS
        jp      GCPLFN            ; DON'T PLOT - FIX UP STACK & RETURN
  
GLINEC: ld      a,(GLINEF)        ; GET CENTER LINE FLAG BYTE
        add     a,a               ; BIT 7=1 MEANS DRAW LINE FROM CENTER
        jp      nc,CPLTIT         ; NO LINE REQUIRED - JUST PLOT POINT
        jp      CLINE             ; LINE REQUIRED.
  
CLINSC: ld      a,(GLINEF)        ; GET CENTER LINE FLAG BYTE
        rra                       ; BIT 0=1 MEANS LINE FROM CENTER NEEDED.
        jp      nc,CPLTIT         ; NO LINE REQUIRED - JUST PLOT POINT
  
CLINE:  pop     de                ; GET X & Y OFFSETS
        pop     hl  
        call    GTABSC            ; GO CALC TRUE COORDINATE OF POINT
        call    GLINE2            ; DRAW LINE FROM [BC],[DE] TO CENTER
        jp      CPLFIN  
  
CBTWEN: ld      a,(CPLOTF)        ; SEE WHETHER PLOTTING BETWEENS OR NOT
        or      a 
        jp      z,CPLTIT          ; IF Z, THEN DOING BETWEENS
GCPLFN: pop     de                ; CLEAN UP STACK
        pop     hl  
        jp      CPLFIN  

CPLTIT: pop     de                ; GET X & Y OFFSETS
        pop     hl  
        call    GTABSC            ; CALC TRUE COORDINATE OF POINT
        call    SCLXYX            ; SEE IF POINT OFF SCREEN
        jp      nc,CPLFIN         ; NC IF POINT OFF SCREEN - NO PLOT
        call    MAPXYP  
        call    SETC              ; PLOT THE POINT
  
CPLFIN: pop     de                ; GET BACK OFFSETS
        pop     hl  
        pop     af                ; GET BACK LOOP COUNT
        dec     a 
        ret     z                 ; QUIT IF DONE.
        push    af                ;  PUSH PSW
        push    de                ; SAVE X OFFSET
        ex      de,hl 
        ld      hl,(CXOFF)        ; SWAP [HL] AND CXOFF
        ex      de,hl 
        call    NEGDE             ; NEGATE NEW [HL]
        ld      (CXOFF),hl
        ex      de,hl
        pop     de
        push    hl
        ld      hl,(CYOFF)        ; SWAP [DE] AND CYOFF
        ex      de,hl             ; NEGATE NEW [DE]
        ld      (CYOFF),hl  
        call    NEGDE 
        pop     hl  
        pop     af                ;  POP PSW
        jp      CPLOT             ; PLOT NEXT POINT
  
  
GLINE2: ld      hl,(GRPACX)       ; DRAW LINE FROM [BC],[DE]
        ld      (GXPOS),hl        ; TO GRPACX,Y
        ld      hl,(GRPACY) 
        ld      (GYPOS),hl  
        jp      DOGRPH            ; GO DRAW THE LINE
  
; GTABSC - GET ABSOLUTE COORDS  
GTABSC: push    de                ; SAVE Y OFFSET FROM CENTER
        ex      de,hl 
        ld      hl,(GRPACX)       ; GET CENTER POS
        ex      de,hl 
        add     hl,de             ; ADD TO DX
        ld      b,h               ; [BC]=X CENTER + [HL]
        ld      c,l 
        pop     de  
        ld      hl,(GRPACY)       ; GET CENTER Y
        add     hl,de 
        ex      de,hl             ; [DE]=Y CENTER + [DE]
        ret 
  
SCALEY: ld      hl,(ASPECT)       ; CHECK FOR *0 AND *1 CASES
        ld      a,l 
SCALE2: or      a                 ; ENTRY TO DO [A]*[DE] ([A] NON-Z)
        jp      nz,SCAL2          ; NON-ZERO
        or      h                 ; TEST HI BYTE
        ret     nz                ; IF NZ, THEN WAS *1 CASE
        ex      de,hl             ; WAS *0 CASE - PUT 0 IN [DE]
        ret

SCAL2:  ld      c,d
        ld      d,0
        push    af
        call    SCAL2M
        ld      e,128
        add     hl,de             ;  ADDI AX,128  - ROUND UP
        ld      e,c
        ld      c,h
        pop     af
        call    SCAL2M
        ld      e,c
        add     hl,de
        ex      de,hl
        ret

;;
SCAL2M: ld      b,8               ; Going to Loop 8 Times
        ld      hl,0              ; Clear [HL] First
SCAL2L: add     hl,hl             ; [HL] = [HL] * 2
        add     a,a               ; [A] = [A] * 2
        jp      nc,NOCARY         ; If Carry
        add     hl,de             ;   [HL] = [HL] + [DE]
NOCARY: dec     b                 ; Countdown
        jp      nz,SCAL2L         ;   and Loop
        ret
; CGTCNT
; PARSE THE BEGIN AND END ANGLES
CGTCNT: dec     hl
        rst     CHRGET            ; GET CURRENT CHAR
        ret     z                 ; IF NOTHING, RETURN DFLT IN [DE]
        SYNCHK  ','               ; EAT THE COMMA
        cp      ','               ; USE DEFAULT IF NO ARGUMENT.
        ret     z                 
        push    bc                ; SAVE FLAG BYTE IN [C]
        call    FRMEVL            ; EVALUATE THE THING
        ex      (sp),hl           ; XTHL
        push    hl                ; POP FLAG BYTE, PUSH TXTPTR
        call    CHKNUM            ; MUST BE NUMBER
        pop     bc                ; GET BACK FLAG BYTE
        ld      hl,FAC            ; NOW SEE WHETHER POSITIVE OR NOT
        ld      a,(hl)            ; GET EXPONENT BYTE
        or      a                 
        jp      z,CGTC2           ; SET TO HIGH MANTISSA BYTE
        dec     hl                
        ld      a,(hl)            
        or      a                 
        jp      p,CGTC2           
        and     127               ; MAKE IT POSITIVE
        ld      (hl),a            
        ld      hl,GLINEF         ; SET BIT IN [C] IN GLINEF
        ld      a,(hl)            
        or      c                 
        ld      (hl),a            
CGTC2:  ld      bc,$7E22          ; LOAD REGS WITH 1/2*PI
        ld      de,$F983          
        call    FMULT             ; MULTIPLY BY 1/(2*PI) TO GET FRACTION
        call    CMPONE            ; SEE IF RESULT IS GREATER THAN ONE
        jp      z,FCERR           ; FC ERROR IF SO
        call    PUSHF             ; SAVE FAC ON STAC
        ld      hl,(CNPNTS)       ; GET NO. OF POINTS PER OCTANT
        add     hl,hl             ; TIMES 8 FOR TRUE CIRCUMFERENCE
        add     hl,hl             
        add     hl,hl             
        call    MAKINT            ; STICK IT IN FAC
        call    CHKNUM            ; MUST BE NUMBER
        pop     bc                ; GET BACK ANG/2*PI IN REGS
        pop     de                
        call    FMULT             ; DO THE MULTIPLY
        call    FRCINX            ; CONVERT TO INTEGER IN [HL]
        pop     de                ; GET BACK TXTPTR
        ex      de,hl             
        ret                       
; EA04                                  
CMPONE: ld      bc,$8100          ; Compare FAC with 1.0
        ld      de,$0000
        call    FCOMP
        dec     a
        ret
; EA0F
; GET & PUT - READ & WRITE GRAPHICS BIT ARRAY
GPUTG:  ld      (PUTFLG),a        ; STORE WHETHER PUTTING OR NOT
        push    af                ; SAVE THIS FLAG A SEC
        SYNCHK  '('               ; SKIP OVER OPEN PAREN
        dec     hl
        call    SCAN1             ; GET FIRST COORD
        call    CHKRNG
        pop     af                ; REGET PUT FLAG
        or      a                 ; If Not 0
        jr      nz,PUT1           ;   Do PUT
        rst     SYNCHR  
        db      MINUTK            ; EAT "-"
        push    bc                ; SAVE X1
        push    de                ; SAVE Y1
        call    SCANDX            ; GET SECOND COORD FOR 'GET' ONLY
        call    CHKRNG
        pop     de                ; GET Y1 BACK
        pop     bc                ; AND X1
        push    hl                ; SAVE TXTPTR
        call    YDELT             ; CALC DELTA Y
        call    c,XCHGY           ; MAKE DE=MIN(GXPOS,DE)
        inc     hl                ; MAKE DELTA A COUNT
        ld      (MINDEL),hl       ; SAVE DELTA Y IN MIDEL
        call    XDELT
        call    c,XCHGX           ; BC = MIN(GXPOS,DE)
        inc     hl                ; MAKE DELTA A COUNT
        ld      (MAXDEL),hl       ; SAVE DX IN MAXDEL
        call    MAPXYC
        pop     hl
        call    GTARRY
        push    hl
        push    de              ;;Save Pointer to Array Data
        push    bc              ;;Save End of Array Data
        push    de              ;;Save Number of Bytes to be Used
        ex      de,hl
        ld      hl,(MAXDEL)
        ld      c,l
        ld      b,h
        ex      de,hl
        sla     e
        rl      d
        ld      hl,(MINDEL)       ; GET DELTA Y
        push    bc                ; SAVE DX*BITS/PIX
        ld      b,h               ; INTO [BC] FOR UMULT
        ld      c,l
        call    UMULT             ; [DE]=DX*DY*BITS/PIX
        pop     bc                ; GET BACK DX*BITS/PIX
        ld      de,4              ; ADD 4 BYTES FOR DX,DY STORAGE
        add     hl,de           ;[HL] HAS NO. OF BYTES TO BE USED
        pop     de              ;ADD NO. OF BYTES TO BE USED
        add     hl,de
        ex      de,hl             ; [DE] = CALCULATED END OF DATA
        pop     hl                ; END OF ARRAY DATA TO [HL]
        rst     COMPAR
        jp      c,FCERR           ; ARRAY START+LENGTH .GT. 64K
                                  ; BEG OF DATA PTR IS ON STK HERE
        pop     hl                ; GET POINTER TO ARRAY DATA
        rst     COMPAR
        jp      nc,FCERR          ; ARRAY START+LENGTH .GT. 64K
        ld      (hl),c            ; SAVE DX*BITS/PIX IN 1ST 2 BYTES OF ARY
        inc     hl
        ld      (hl),b            ; PASS NO. OF BITS DESIRED IN [BC]
        inc     hl
        ex      de,hl
        ld      hl,(MINDEL)       ; GET LINE (Y) COUNT
        ex      de,hl
        ld      (hl),e
        inc     hl
        ld      (hl),d
        inc     hl                ; SAVE DY IN 2ND 2 BYTES
        or      a                 ; CLEAR CARRY FOR GET INIT.
        jr      GOPGIN            ; GIVE LOW LEVEL ADDR OF ARRAY & GO
; EA8C
PUT1:   push    hl                ; SAVE TXTPTR
        call    MAPXYC            ; MAP THE POINT
        pop     hl
        call    GTARRY            ; SCAN ARRAY NAME & GET PTR TO IT
        push    de                ; SAVE PTR TO DELTAS IN ARRAY
        dec     hl                ; NOW SCAN POSSIBLE PUT OPTION
        rst     CHRGET
        ld      b,5               ; DEFAULT OPTION IS XOR
        jr      z,PUT2            ; IF NO CHAR, USE DEFAULT
        SYNCHK  ','               ; MUST BE A COMMA
        ex      de,hl             ; PUT TXTPTR IN [DE]
        ld      hl,GFUNTB+4     ;;From End of Table to Start if Table
PFUNLP: cp      (hl)              ; IS THIS AN OPTION?
        jr      z,PUT20           ; YES, HAND IT TO PGINIT.
        dec     hl                ; POINT TO NEXT
        dec     b
        jr      nz,PFUNLP
        ex      de,hl             ; GET TXTPTR BACK TO [HL]
        pop     de                ; CLEAN UP STACK
        ret                       ; LET NEWSTT GIVE SYNTAX ERROR
; EAAB
PUT20:  ex      de,hl             ; GET TXTPTR BACK TO [HL]
        rst     CHRGET            ; EAT THE TOKEN
PUT2:   dec     b                 ; 1..5 TO 0..4
        ld      a,b               ; INTO [A] FOR PGINIT
        ex      (sp),hl           ; XTHL
        push    af                ; SAVE PUT ACTION MODE
        ld      e,(hl)            ; [DE]=NO. OF BITS IN X
        inc     hl
        ld      d,(hl)
        inc     hl
        push    de                ; SAVE BIT COUNT
        push    hl                ; SAVE ARRAY POINTER
        dec     de                ; DECREMENT DX SINCE IT'S A COUNTER
        ld      hl,(GXPOS)        ; NOW CALC TRUE X
        ex      de,hl
        add     hl,de
        jr      c,PRNGER          ; ERROR IF CARRY
        ld      b,h               ; TO [BC] FOR SCLXYX
        ld      c,l
        pop     hl                ; GET BACK ARRAY POINTER
        ld      e,(hl)            ; [DE] = DELTA Y ([HL] POINTS TO DATA)
        inc     hl
        ld      d,(hl)
        inc     hl
        push    de                ; SAVE DELTA Y ON STACK
        push    hl                ; SAVE PTR ON STACK AGAIN
        ld      hl,(GYPOS)
        dec     de                ; DECREMENT DY SINCE IT'S A COUNTER
        add     hl,de
PRNGER: jp      c,FCERR           ; ERROR IF CARRY
        ex      de,hl             ; [DE]=Y + DELTA Y
        pop     hl                ; GET BACK ARRAY POINTER
        call    CHKRNG            ; MAKE SURE [BC],[HL] ARE ON THE SCREEN
        pop     de                ; POP DY
        pop     bc                ; POP DX*BITS/PIX
        pop     af                ; GET BACK ACTION MODE
        scf                       ; SET CARRY TO FLAG PUT INIT
; 2A4E
GOPGIN: push    de                ; RESAVE DY
        call    PGINIT            ; Set Operation Routine Address
        pop     de                ; GET Y COUNT
PGLOOP: push    de                ; SAVE LINE COUNT
        call    FETCHC
        push    hl
        push    af
        ld      a,(PUTFLG)        ; SEE IF PUTTING OR GETTING
        or      a
        jr      nz,PGLOO2
        call    NREAD
        jr      PGLOO3
PGLOO2: call    NWRITE
PGLOO3: pop     af                ; GET BACK STARTING C
        pop     hl                ; Address AND BIT MASK
        call    STOREC            ; SET UP AS CURRENT "C"
        call    DOWNL             ; NOW MOVE DOWN A LINE
        pop     de
        dec     de
        ld      a,d
        or      e
        jr      nz,PGLOOP         ; CONTINUE IF NOT ZERO
        pop     hl                ; GET BACK TXTPTR
        ret                       ; AND RETURN
; EB02
GTARRY: SYNCHK  ','               ; EAT COMMA
        ld      a,1               ; SEARCH ARRAYS ONLY
        ld      (SUBFLG),a
        call    PTRGET            ; GET PTR TO ARRAY
        jp      nz,FCERR          ; NOT THERE - ERROR
        ld      (SUBFLG),a        ; CLEAR THIS
        push    hl                ; SAVE TXTPTR
        ld      h,b               ; HL = PTR TO ARRAY
        ld      l,c
        ex      de,hl             ; HL = LENGTH
        add     hl,de             ; HL = LAST BYTE OF ARRAY
        push    hl                ; SAVE
        ld      a,(bc)            ; GET NO. OF DIMS
        add     a,a               ; DOUBLE SINCE 2 BYTE ENTRIES
        ld      l,a
        ld      h,0
        inc     bc                ; SKIP NO. OF DIMS
        add     hl,bc
        ex      de,hl             ; DE = PTR TO FIRST BYTE OF DATA
        pop     bc                ; BC = PTR TO LAST BYTE OF DATA
        pop     hl                ; GET TXTPTR
        ret
; EB23
GFUNTB: db      ORTK, ANDTK      ;;PUT Action Tokens Table
        db      PRESTK, PSETTK
        db      XORTK
; EB28
;----------------------------------------------------------------------------
;;; ---
;;; ## DRAW
;;; Draws a figure.
;;; ### FORMAT:
;;;   - DRAW *string expression*
;;;     - Action: The DRAW statement combines most of the capabilities of the other graphics statements into an object definition language called Graphics Macro Language (GML). A GML command is a single character within a string, optionally followed by one or more arguments.
;;; #### Commands:
;;; Each of the movement commands begins movement from the current graphics position. 
;;;  - This is usually the coordinate of the last graphics point plotted with another GML command, LINE, or PSET. 
;;;  - The current position defaults to upper right hand corner of the screen (0,0) when a program is run. 
;;;  - Movement commands move for a distance of scale factor *n, where the default for n is 1; thus, they move one point if n is omitted and the default scale factor is used.
;;; | Command  | Action
;;; |    Un    | Move up
;;; |    Dn    | Move down
;;; |    Ln    | Move left
;;; |    Rn    | Move right
;;; |    En    | Move diagonally up and right
;;; |    Fn    | Move diagonally down and right
;;; |    Gn    | Move diagonally down and left
;;; |    Hn    | Move diagonally up and left
;;; This command moves as specified by the following argument:
;;; ` Mx, y ` Move absolute or relative. 
;;;   - If x is preceded by a + or -, x and y are added to the current graphics position, and connected to the current position by a line. 
;;;   - Otherwise, a line is drawn to point x, y from the current position.
;;; The following prefix commands may precede any of the above movement commands:
;;; ` B`  Move, but plot no points.
;;; ` N`  Move, but return to original position when done.
;;; The following commands are also available:
;;; ` An  ` Set angle n. 
;;; - n may range from 0 to 3, where 0 is 0°, 1 is 90°, 2 is 180°, and 3 is 270°. 
;;; - Figures rotated 90° or 270° are scaled so that they will appear the same size as with 0° or 180° on a monitor screen with the standard aspect ratio of 4:3.
;;; ` TAn `  Turn angle n. 
;;; - n can be any value from negative 360 to positive 360. 
;;; - If the value specified by n is positive, it turns the angle counter-clockwise. 
;;; - If the value specified by n is negative, it turns clockwise.
;;; ` Cn  ` Set color n. 
;;; ` Sn  ` Set scale factor n. 
;;; - n may range from 1 to 255. n is divided by 4 to derive the scale factor. 
;;; - The scale factor is multiplied by the distances given with U, D, L, R, E, F, G, H, or relative M commands to get the actual distance traveled. 
;;; - The default for S is 4.
;;; `x*string* ` Execute substring. 
;;; - This command executes a second substring from a string, much like GOSUB. One string executes another, which executes a third, and so on.
;;; - *string* is a variable assigned to a string of movement commands.
;;; #### Numeric Arguments:
;;; - Numeric arguments can be constants like "123" or "=variable;", where variable is the name of a variable.
;;; - When you use the second syntax, "=variable;", the semicolon must be used. Otherwise, the semicolon is optional between commands.
;;; ### EXAMPLES:
;;; ```
;;;   10 DRAW "BM 40,36"
;;;   20 A=20: DRAW "R=A; D=A; L=A; U=A;" 
;;; ```
;;; > Moves to the center of the screen without drawing, then draws a box 11 pixels wide by 11 pixles high.
;;; ```
;;;   30 PSET (10, 20)
;;;   40 DRAW "E20; F20; L39"
;;; ```
;;; > Draws a 42 pixel wide triangle with it's top vertex at x-coordinate 10 and y-coordinate 20.
ST_DRAW:    
        ld      de,DRWTAB         ; DISPATCH TABLE FOR GML
        xor     a                 ; CLEAR OUT DRAW FLAGS
        ld      (DRWFLG),a  
        jp      MACLNG  
; EB32  
DRWTAB: db      'U'+128           ; UP
        dw      DRUP  
        db      'D'+128           ; DOWN
        dw      DRDOWN  
        db      'L'+128           ; LEFT
        dw      DRLEFT  
        db      'R'+128           ; RIGHT
        dw      DRIGHT  
        db      'M'               ; MOVE
        dw      DMOVE 
        db      'E'+128           ; -,-
        dw      DRWEEE  
        db      'F'+128           ; +,-
        dw      DRWFFF  
        db      'G'+128           ; +,+
        dw      DRWGGG  
        db      'H'+128           ; -,+
        dw      DRWHHH  
        db      'A'+128           ; ANGLE COMMAND
        dw      DANGLE  
        db      'B'               ; MOVE WITHOUT PLOTTING
        dw      DNOPLT  
        db      'N'               ; DON'T CHANGE CURRENT COORDS
        dw      DNOMOV  
        db      'X'               ; EXECUTE STRING
        dw      MCLXEQ  
        db      'C'+128           ; COLOR
        dw      DCOLR 
        db      'S'+128           ; SCALE
        dw      DSCALE  
        db      0                 ; END OF TABLE
  
DRUP:   call    NEGDE             ; MOVE +0,-Y
DRDOWN: ld      bc,0              ; MOVE +0,+Y, DX=0
        jp      DOMOVR            ; TREAT AS RELATIVE MOVE
;   
DRLEFT: call    NEGDE             ; MOVE -X,+0
DRIGHT: ld      b,d               ; MOVE +X,+0
        ld      c,e               ; [BC]=VALUE
        ld      de,0              ; DY=0
        jp      DOMOVR            ; TREAT AS RELATIVE MOVE
  
DRWHHH: call    NEGDE             ; MOVE -X,-Y
DRWFFF: ld      b,d               ; MOVE +X,+Y
        ld      c,e 
        jp      DOMOVR  
  
DRWEEE: ld      b,d               ; MOVE +X,-Y
        ld      c,e 
DRWHHC: call    NEGDE 
        jp      DOMOVR  
  
DRWGGG: call    NEGDE             ; MOVE -X,+Y
        ld      b,d 
        ld      c,e 
        jp      DRWHHC            ; MAKE DY POSITIVE & GO
  
DMOVE:  call    FETCHZ            ; GET NEXT CHAR AFTER COMMA
        ld      b,0               ; ASSUME RELATIVE
        cp      '+'               ; IF "+" OR "-" THEN RELATIVE
        jp      z,MOVREL  
        cp      '-' 
        jp      z,MOVREL  
        inc     b                 ; NON-Z TO FLAG ABSOLUTE
MOVREL: ld      a,b 
        push    af                ; SAVE ABS/REL FLAG ON STACK
        call    DECFET            ; BACK UP SO VALSCN WILL SEE "-"
        call    VALSCN            ; GET X VALUE
        push    de                ; SAVE IT
        call    FETCHZ            ; NOW CHECK FOR COMMA
        cp      ','               ; COMMA?
        jp      nz,FCERR  
        call    VALSCN            ; GET Y VALUE IN D
        pop     bc                ; GET BACK X VALUE
        pop     af                ; GET ABS/REL FLAG
        or      a 
        jp      nz,DRWABS         ; NZ - ABSOLUTE
  
DOMOVR: call    DSCLDE            ; ADJUST Y OFFSET BY SCALE
        push    de                ; SAVE Y OFFSET
        ld      d,b               ; GET X INTO [DE]
        ld      e,c 
        call    DSCLDE            ; GO SCALE IT.
        ex      de,hl             ; GET ADJUSTED X INTO [HL]
        pop     de                ; GET ADJUSTED Y INTO [DE]
        xor     a 
        ld      (CSCLXY),a  
        ld      a,(DRWANG)        ; GET ANGLE BYTE
        rra                       ; LOW BIT TO CARRY
        jr      nc,ANGEVN         ; ANGLE IS EVEN - DON'T SWAP X AND Y
        push    af                ; SAVE THIS BYTE
        push    de                ; SAVE DY
        push    hl                ; SAVE DX
        call    GTASPC            ; GO GET SCREEN ASPECT RATIO
        ld      a,h 
        or      a                 ; IS ASPECT RATIO GREATER THAN ONE?
        jr      z,ASPLS0          ; BRIF GOOD ASPECT RATIO
        ld      a,1 
        ld      (CSCLXY),a  
ASPLS0: ex      de,hl             ; GET ASPECT RATIO INTO [C] FOR GOSCAL
        ld      c,l 
        pop     hl                ; GET BACK DX
        ld      a,(CSCLXY)  
        or      a 
        jr      z,ASPLS1          ;branch if aspect ratio less 1.0
        ex      (sp),hl           ; XTHL
ASPLS1: ex      de,hl             ; [HL]=DY, save DX
        push    hl                ; SAVE 1/ASPECT
        call    GOSCAL            ; SCALE DELTA X BY ASPECT RATIO
        pop     bc                ; GET BACK 1/ASPECT RATIO
        pop     hl                ; GET DY
        push    de                ; SAVE SCALED DX
        ex      de,hl             ; DY TO [DE] FOR GOSCAL
        ld      hl,0  
DMULP:  add     hl,de             ; MULTIPLY [DE] BY HI BYTE OF 1/ASPECT
        djnz    DMULP 
        push    hl                ; SAVE PARTIAL RESULT
        call    GOSCAL            ; MULTIPLY [DE] BY LOW BYTE
        pop     hl                ; GET BACK PARTIAL RESULT
        add     hl,de             ; [HL]=Y * 1/ASPECT
        pop     de                ; GET BACK SCALED Y
        ld      a,(CSCLXY)  
        or      a 
        jr      z,ASLSS1          ; branch if aspect ratio less than 1
        ex      de,hl 
ASLSS1: call    NEGDE             ; ALWAYS NEGATE NEW DY
        pop     af                ; GET BACK SHIFTED ANGLE
ANGEVN: rra                       ; TEST SECOND BIT
        jp      nc,ANGPOS         ; DON'T NEGATE COORDS IF NOT SET
        call    NEGHL 
        call    NEGDE             ; NEGATE BOTH DELTAS
ANGPOS: call    GTABSC            ; GO CALC TRUE COORDINATES

DRWABS: ld      a,(DRWFLG)        ; SEE WHETHER WE PLOT OR NOT
        add     a,a               ; CHECK HI BIT
        jp      c,DSTPOS          ; JUST SET POSITION.
        push    af                ; SAVE THIS FLAG
        push    bc                ; SAVE X,Y COORDS
        push    de                ; BEFORE SCALE SO REFLECT DISTANCE OFF
        call    SCLXYX            ; SCALE IN CASE COORDS OFF SCREEN
        call    GLINE2            
        pop     de                
        pop     bc                ; GET THEM BACK
        pop     af                ; GET BACK FLAG
DSTPOS: add     a,a               ; SEE WHETHER TO STORE COORDS
        jp      c,DNSTOR          ; DON'T UPDATE IF B6=1
        ex      de,hl             
        ld      (GRPACY),hl       ; UPDATE GRAPHICS AC
        ex      de,hl             
        ld      h,b               
        ld      l,c               
        ld      (GRPACX),hl       
DNSTOR: xor     a                 ; CLEAR SPECIAL FUNCTION FLAGS
        ld      (DRWFLG),a        
        ret                       
                                  
DNOMOV: ld      a,64              ; SET BIT SIX IN FLAG BYTE
        jp      DSTFLG            
                                  
DNOPLT: ld      a,128             ; SET BIT 7
DSTFLG: ld      hl,DRWFLG         
        or      (hl)              
        ld      (hl),a            ; STORE UPDATED BYTE
        ret                       
                                  
DANGLE: jp      nc,NCFCER         ; ERROR IF NO ARG
        ld      a,e               ; MAKE SURE LESS THAN 4
        cp      4                 
        jp      nc,NCFCER         ; ERROR IF NOT
        ld      (DRWANG),a        
        ret                       
NCFCER:                           
DSCALE: jp      nc,FCERR          ; FC ERROR IF NO ARG
        ld      a,d               ; MAKE SURE LESS THAN 256
        or      a                 
        jp      nz,FCERR          
        ld      a,e               
        ld      (DRWSCL),a        ; STORE SCALE FACTOR
        ret                       
                                  
DSCLDE: ld      a,(DRWSCL)        ; GET SCALE FACTOR
        or      a                 ; ZERO MEANS NO SCALING
        ret     z                 
        ld      hl,0              
                                  
DSCLP:  add     hl,de             ; ADD IN [DE] SCALE TIMES
        dec     a                 
        jp      nz,DSCLP          
        ex      de,hl             ; PUT IT BACK IN [DE]
        ld      a,d               ; SEE IF VALUE IS NEGATIVE
        add     a,a               
        push    af                ; SAVE RESULTS OF TEST
        jp      nc,DSCPOS         
        dec     de                ; MAKE IT TRUNCATE DOWN
DSCPOS: call    HLFDE             ; DIVIDE BY FOUR
        call    HLFDE             
        pop     af                ; SEE IF WAS NEGATIVE
        ret     nc                
        ld      a,d               
        or      0C0H              
        ld      d,a               
        inc     de                
        ret                       ; ALL DONE IF WAS POSITIVE
                                  
GOSCAL: ld      a,d               ; SEE IF NEGATIVE
        add     a,a               
        jp      nc,GOSC2          ; NO, MULTIPLY AS-IS
        ld      hl,NEGD           ; NEGATE BEFORE RETURNING
        push    hl                
        call    NEGDE             ; MAKE POSITIVE FOR MULTIPLY
GOSC2:  ld      a,c               ; GET SCALE FACTOR
        jp      SCALE2            ; GET SCALE FACTOR
                                  
DCOLR:  jp      nc,NCFCER         ; FC ERROR IF NO ARG
        ld      a,e               ; GO SET ATTRIBUTE
        call    SETATR            
        jp      c,FCERR           ; ERROR IF ILLEGAL ATTRIBUTE
        ret

;;Issue FC Error if Point is Not on Screen
CHKRNG: push    hl                ; SAVE TXTPTR
        call    CHKRXY            
        jp      nc,FCERR          ; OUT OF BOUNDS - ERROR
        pop     hl                
        ret                       
                                  
MACLNG: ex      de,hl             
        ld      (MCLTAB),hl       ; SAVE POINTER TO COMMAND TABLE
        ex      de,hl             
        call    FRMEVL            ; EVALUATE STRING ARGUMENT
        push    hl                ; SAVE TXTPTR TILL DONE
        ld      de,0              ; PUSH DUMMY ENTRY TO MARK END OF STK
        push    de                ; DUMMY ADDR
        push    af                ; DUMMY LENGTH
                                  
MCLNEW: call    FRESTR            
        call    MOVRM             ; GET LENGTH & POINTER
        ld      a,b               
        or      c                 
        jr      z,MCLOOP          ; Don't Push if addr is 0
        ld      a,e               
        or      a                 
        jr      z,MCLOOP          ;  or if Len is 0...
        push    bc                ; PUSH ADDR OF STRING
        push    af                
                                  
MCLOOP: pop     af                ; GET LENGTH OFF STACK
        ld      (MCLLEN),a        
        pop     hl                ; GET ADDR
        ld      a,h               
        or      l                 ; SEE IF LAST ENTRY
        jr      z,POPHRX          ; ALL FINISHED IF ZERO
        ld      (MCLPTR),hl       ; SET UP POINTER
MCLSCN: call    FETCHR            ; GET A CHAR FROM STRING
        jr      z,MCLOOP          ; END OF STRING - SEE IF MORE ON STK
        add     a,a               ; PUT CHAR * 2 INTO [C]
        ld      c,a               
        ld      hl,(MCLTAB)       ; POINT TO COMMAND TABLE
                                  
MSCNLP: ld      a,(hl)            ; GET CHAR FROM COMMAND TABLE
        add     a,a               ; CHAR = CHAR * 2 (CLR HI BIT FOR CMP)
                                  
GOFCER: call    z,FCERR           ; END OF TABLE.
        cp      c                 ; HAVE WE GOT IT?
        jr      z,MISCMD          ; YES.
        inc     hl                ; MOVE TO NEXT ENTRY
        inc     hl                
        inc     hl                
        jr      MSCNLP            
                                  
MISCMD: ld      bc,MCLSCN         ; RETURN TO TOP OF LOOP WHEN DONE
        push    bc                
        ld      a,(hl)            ; SEE IF A VALUE NEEDED
        ld      c,a               ; PASS GOTTEN CHAR IN [C]
        add     a,a               
        jr      nc,MNOARG         ; COMMAND DOESN'T REQUIRE ARGUMENT
        or      a                 ; CLEAR CARRY
        rra                       ; MAKE IT A CHAR AGAIN
        ld      c,a               ; PUT IN [C]
        push    bc                
        push    hl                ; SAVE PTR INTO CMD TABLE
        call    FETCHR            ; GET A CHAR
        ld      de,1              ; DEFAULT ARG=1
        jr      z,VSNAR0          
        call    ISLETC            
        jr      nc,VSNARG         ; NO ARG IF END OF STRING
        call    ISLET2            ; SEE IF POSSIBLE LETTER
        scf                       
        jr      ISCMD3            
                                  
VSNARG: call    DECFET            ; PUT CHAR BACK INTO STRING
VSNAR0: or      a                 ; CLEAR CARRY
ISCMD3: pop     hl                
        pop     bc                ; GET BACK COMMAND CHAR
MNOARG: inc     hl                ; POINT TO DISPATCH ADDR
        ld      a,(hl)            ; GET Address INTO HL
        inc     hl                
        ld      h,(hl)            
        ld      l,a               
        jp      (hl)              ; DISPATCH
                                  
FETCHZ: call    FETCHR            ; GET A CHAR FROM STRING
        jr      z,GOFCER          ; GIVE ERROR IF END OF LINE
        ret                       
                                  
FETCHR: push    hl                
FETCH2: ld      hl,MCLLEN         ; POINT TO STRING LENGTH
        ld      a,(hl)            
        or      a                 
        jr      z,POPHRX          ; RETURN Z=0 IF END OF STRING
        dec     (hl)              ; UPDATE COUNT FOR NEXT TIME
        ld      hl,(MCLPTR)       ; GET PTR TO STRING
        ld      a,(hl)            ; GET CHARACTER FROM STRING
        inc     hl                ; UPDATE PTR FOR NEXT TIME
        ld      (MCLPTR),hl       
        cp      ' '               ;  SKIP SPACES
        jr      z,FETCH2          
        cp      96                ; CONVERT LOWER CASE TO UPPER
        jr      c,POPHRX          
        sub     32                ; DO CONVERSION
POPHRX: pop     hl                
        ret                       
; ED40                            
DECFET: push    hl                
        ld      hl,MCLLEN         ; INCREMENT LENGTH
        inc     (hl)              
        ld      hl,(MCLPTR)       ; BACK UP POINTER
        dec     hl
        ld      (MCLPTR),hl
        pop     hl
        ret
; ED4E
VALSCN: call    FETCHZ            ; GET FIRST CHAR OF ARGUMENT
ISLET2: cp      '='               ; NUMERIC?
        jr      z,VARGET          ; No, Evaluate Variable
        cp      '+'               ; PLUS SIGN?
        jr      z,VALSCN          ; THEN SKIP IT
        cp      '-'               ; NEGATIVE VALUE?
        jr      nz,VALSC2         
        ld      de,NEGD           ; IF SO, NEGATE BEFORE RETURNING
        push    de                
        jr      VALSCN            ; EAT THE "-"
VALSC2: ld      de,0              
        ld      b,4               
; ED68                            
NUMLOP: cp      ','               ; COMMA
        jr      z,DECFET          ; YES, BACK UP AND RETURN
        cp      ';'               ; SEMICOLON?
        ret     z                 ; YES, JUST RETURN
        cp      '9'+1             ; NOW SEE IF ITS A DIGIT
        jr      nc,DECFET         ; IF NOT, BACK UP AND RETURN
        cp      '0'               
        jr      c,DECFET          
        ld      l,e               
        ld      h,d               
        add     hl,hl             
        add     hl,hl             
        add     hl,de             
        add     hl,hl             
        sub     '0'               ; ADD IN THE DIGIT
        ld      e,a               
        ld      d,0               
        add     hl,de             ; VALUE SHOULD BE IN [DE]
        ex      de,hl             ; GET NEXT CHAR
        call    FETCHR  
        ret     z 
        dec     b 
        jr      nz,NUMLOP 
        cp      '0' 
        jr      c,NUMLOP  
        cp      '9'+1 
        jr      nc,NUMLOP 
        jr      SCNFC 
; ED95  
SCNVAR: call    FETCHZ            ; MAKE SURE FIRST CHAR IS LETTER
        ld      de,BUF            ; PLACE TO COPY NAME FOR PTRGET
        push    de                ; SAVE ADDR OF BUF FOR "ISVAR"
        ld      b,32              ; COPY MAX OF 32 CHARACTERS
        call    ISLETC            ; MAKE SURE IT'S A LETTER
        jr      c,SCNFC           ; FC ERROR IF NOT LETTER
SCNVLP: ld      (de),a            ; STORE CHAR IN BUF
        inc     de  
        cp      ';'               ; A SEMICOLON?
        jr      z,SCNV2           ; YES - END OF VARIABLE NAME
        call    FETCHZ            ; GET NEXT CHAR
        dec     b 
        jr      nz,SCNVLP 
SCNFC:  call    FCERR             ; ERROR - VARIABLE TOO LONG
SCNV2:  pop     hl                ; GET PTR TO BUF
        jp      ISVAR             ; GO GET ITS VALUE
; EDB6                              
VARGET: call    SCNVAR            ; SCAN & EVALUATE VARIABLE
        call    FRCINX            ; MAKE IT AN INTEGER
        ex      de,hl             ; IN [DE]
        ret 
; EDBE  
MCLXEQ: call    SCNVAR            ; SCAN VARIABLE NAME
        ld      a,(MCLLEN)        ; SAVE CURRENT STRING POS & LENGTH
        ld      hl,(MCLPTR) 
        ex      (sp),hl           ;PUSH MCLPTR
        push    af  
        ld      c,2               ;MAKE SURE OF ROOM ON STACK
        call    GETSTK  
        jp      MCLNEW  
; EDD1  
NEGD:   xor     a                 ;;[DE] = -[DE]
        sub     e
        ld      e,a
        sbc     a,d
        sub     e
        ld      d,a
        ret
; EDD8
;;Move Cursor to Column [H], Row [L]
MOVEIT: push    af
        push    hl              ;;Save Location
        exx
        ld      hl,(CURRAM)     ;;Get Current Cursor Address
        ld      a,(CURCHR)      ;;Get Character Under Cursor
        ld      (hl),a          ;;and Put Back into Screen Location
        pop     hl              ;;Restore Location
        ld      a,l             ;;Address Offset = Row * 5
        add     a,a
        add     a,a
        add     a,l
        ex      de,hl
        ld      e,d             ;;[DE] = Column
        ld      d,0
        ld      h,d             ;;[HL] = Offset
        ld      l,a
        ld      a,e             ;;[A] = Column - 1
        dec     a
        add     hl,hl           ;;Offset = Offset * 8 (Row * 40)
        add     hl,hl
        add     hl,hl
        add     hl,de           ;;Offset = Offset + Column
        ld      de,CHRRAM       ;;Get Screen Address
        add     hl,de           ;;and Add Offset
        jp      TTYFIS          ;;Save Position and Finish
;EDFA
GTASPC: ld      de,204          ; Aspect Ration = 318:204 (6.25:4)
        ld      hl,318
        ret
; EE01 
STOREC: ld      (PINDEX),a        ; Store Point Position
        ld      (CURLOC),hl       ; and Semigraphics Character Address
        ret                     
; EE08 
FETCHC: ld      a,(PINDEX)        ; Load Bit Index 
        ld      hl,(CURLOC)       ; Load Current Point Address
        ret                     
; EE0F                                                  
; Set Graphics Attribute (Foreground Color) 
SETATR: cp      16                ; Is Color > 16
        ccf                       ; If Yes
        ret     c                 ;   Return Error
        ld      (ATRBYT),a        ; Store Color
        ret                     
; EE17
; Get Bit Mask for Bit Position PINDEX
GETMSK:  ld      de,BITTAB       
         ld      a,(PINDEX)
         add     a,e
         ld      e,a
         jr      nc,GETMSS
         inc     d
GETMSS:  ld      a,(de)
         ret
; EE24       
; SET CURRENT POINT
; Sets Current Point to Foreground Color ATRBYT
; Background Color is not changed
; Current point is at Current Point Index PINDEX in 
; Semigraphics Character at Current Address CURLOC
SETC:   push    hl                ; Save [HL]
        push    de                ; and [DE]
        ld      hl,(CURLOC)       ; Get Current Screen Address
        ld      a,(hl)            ; Get Character at Address
        or      SGBASE            ; Verify it's in the range of              
        xor     (hl)              ; Semigraphics Characters
        jr      z,SETC2           ; If Not
        ld      (hl),SGBASE       ;   Store Base Semigraphic Character
SETC2:  call    GETMSK            ; Get Bit Mask for Pixel to set
        or      (hl)              ; Set it
        ld      (hl),a            ; Write Character back to Screen Matrix
SETCLR: ld      de,COLRAM-CHRRAM  ; Add Offset into Color Matrix to
        add     hl,de             ; Screen Address to Get Color Address
        ld      a,(ATRBYT)        ; Get Color Byte
        add     a,a               ; Now multiply by 16,
        add     a,a               ; moving it to the high nybble (Foreground Color)
        add     a,a               ; leaving 0 (Black) in thr low nybblr (Background Color)
        add     a,a                 
        ld      d,a               ; Save New Color Byte
        ld      e,(hl)            ; Get Old Color Byte
        ld      a,15              ; Override Old Background Color ($0F would keep it)
        and     e                 ; Clear Old Foreground Color
        or      d                 ; Put in the New Foreground Color
        ld      (hl),a            ; Writeback Attribute back to Color Matrix
        pop     de                
        pop     hl              
        ret
; EE4B 
; Draw Horizontal Line [HL] Pixels Long 
NSETCX: ld      a,l               ; Looping HL Times
        or      h                 ; If HL is 0
        ret     z                 ;   Return
        call    SETC              ; Set Pixel at Current Location
        call    RIGHTC            ; Move 1 Pixel Right
        dec     hl                ; Count Down
        jr      NSETCX            ; and Loop


; EE78
;;Get Screen Address and and Pixel Index from Character X, Character Y
MAPXYC: push    hl              ;;Save [H,L]
        push    de              ;;Save [D,E] (YPOS)
        ld      hl,CHRRAM+40    ;;Address = Column 0, Line 1
        ld      a,e             ;;
        ld      de,40           ;;Screen Width
        inc     a               ;;Mask = YPOS +1
MAPCLP: dec     a               ;;Mask = Mask - 1
        jr      z,MAPXYA        ;;iF Zero, Add XPOS and FInish Up
        add     hl,de           ;;Else Add Screen Width to Address
        jr      MAPCLP          ;;and Loop
; EE88 
; Get Screen Address and and Pixel Index from Character X, Character Y
; Uses: [B,C] = Character X Position 
;       [D,E] = Pixel Y Position 
; Sets: PINDEX = [A] = 0, 1, or 2
;       CURLOC = [H,L] = Screen Address
MAPXYP: push    hl                ; Save [H,L] 
        push    de                ; Save [D,E] (YPOS)
        ld      hl,CHRRAM+40      ; Address = Column 0, Line 1
        ld      a,e               ; Mask = YPOS
        ld      de,40             ; Screen Width
MAPPLP: sub     3                 ; Mask = Mask - 3
        jr      c,MAPPAD          ; If Positive
        add     hl,de             ;   Add Screen Width to Screen Address
        jr      MAPPLP            ;   and Loop
MAPPAD: add     a,3               ; Mask = Mask + 3
        add     a,a               ; 
        sra     c                 ; 
        jr      nc,MAPXYA         ; If Mask is Even
        inc     a                 ;   Mask = Mask + 1
MAPXYA: add     hl,bc             ; Add XPOS to Screen Address
        ld      (PINDEX),a        ; Store Mask
        ld      (CURLOC),hl       ; Store Address
        pop     de                ; Get YPOS back into DE
        pop     hl                ; Restore HL
        ret                       
; EC9D
; SEE IF LOCATION OFF SCREEN
CHKRXY: ld       a,23
        ld       (GYMAX),a       ;;Mex Y = 23 Rows
        ld       a,39
        ld       (GXMAX),a       ;;Mac X = 39 Coumns
        jr       CMPGMY
; EEB6  
; SEE IF POINT OFF SCREEN 
SCLXYX: ld      a,71              
        ld      (GYMAX),a         ; Max Y = 71 Pixels
        ld      a,79              
        ld      (GXMAX),a         ; Max X = 79 Pixels
CMPGMY: push    hl                ;Save Registers
        push    bc                
        push    de                
        ld      a,(GYMAX)         
        ld      h,0               ; [H,L] = GYMAX
        ld      l,a               
        bit     7,d               ; If [D,E] is Negative
        jr      nz,SETGYZ         ;   [H,L] = 0 and Set Carry
        rst     COMPAR            ; Else Compare [D,E] and [H,L]
SCLXY2: ld      d,b               ; [D,E] = [B,C]
        ld      e,c               
        ld      b,0               
        jr      nc,CMPGMX         
        ex      (sp),hl           
        inc     b                 
CMPGMX: ld      a,(GXMAX)         
        ld      h,0               ; [H,L] = GXMAX
        ld      l,a               
        bit     7,d               ; If [D,E] is Negative
        jr      nz,SETGXZ         ;   [H,L] = 0 and Set Carry
        rst     COMPAR            ; Else Compare [D,E] and [H,L]
SCLXY3: pop     de                
        jr      c,SCLXY4           
        rr      b                 
        db      $06               ; LD B, over EX
SCLXY4: ex      (sp),hl              
        pop     bc                
        ccf                       
        pop     hl                
        ret                       
; EEEC  
SETGYZ: ld      l,0               ; [L] = 0
        scf                       ; Set Carry Flag
        jr      SCLXY2            ; and Continue
  
SETGXZ: ld      l,0                    ; [L] = 0
        scf                       ; Set Carry Flag
        jr      SCLXY3                 ; and Continue

; EF1A 
;Down 1 Pixel: Calculate New Screen Address and Bit Index
DOWNP:  inc     a               
        inc     a                 ; [A] = Bit Index * 2
        cp      6                 
        ccf                       
        ret     nc                
        sub     6                 ; [A] = [A] - 6 
        push    de                
        ld      de,40         
        add     hl,de             ; [HL] = curloc + 40
        pop     de                
        or      a                 ; Set Flags
        ret                       
; EF2A 
; Left 1 Pixel: Calculate New Screen Address and Bit Index
LEFTP:  dec     a                 ; Decrement Bit Index
        bit     0,a               
        ret     z                 ; If Bit Index is Even
        inc     a                 ;   Add 2
        inc     a                 
        dec     hl                ;   Decremement Address
        or      a                 ;   Set Flags from Bit Index
        ret                     
; EF33
; Right 1 Pixel: Calculate New Screen Address and Bit Index
RIGHTP: inc     a                 ; Increment Bit Index
        bit     0,a               ; 
        ret     nz                ; If Bit Index is Odd
        dec     a                 ;   Add 2
        dec     a                 ; 
        inc     hl                ;   Incremement Address
        or      a                 ;   Set Flags from Bit Index
        ret                     
; EF3C
; Move Text Cursor Down One Line
DOWNL:  push    af                ; SAVE BIT MASK OF CURRENT "C" Address
        push    hl                ; SAVE Address
        call    FETCHC            ; GET CURRENT LOCATION
        ld      de,40             ; Line Width = 40 characters
        add     hl,de             ; Move Down One Line
        jp      POPSTC            ; Store Current, Restore Saved and Return
; EF48
; Move Pixel Cursor Down One Line   
DOWNC:  push    af                ; SAVE BIT MASK OF CURRENT "C" Address
        push    hl                ; SAVE Address    
        call    FETCHC            ; GET CURRENT LOCATION
        call    DOWNP             ; Calculate New Screen Address, Bit Index
        jr      POPSTC            ; Store Current, Restore Saved and Return

; EF5C                                              
LEFTC:  push    af                ; SAVE BIT MASK OF CURRENT "C" Address
        push    hl                ; SAVE Address    
        call    FETCHC            ; GET CURRENT LOCATION
        call    LEFTP             ; Calculate New Screen Address, Bit Index
        jr      POPSTC            ; Store Current, Restore Saved and Return
; EF66 
RIGHTC: push    af                ; SAVE BIT MASK OF CURRENT "C" Address
        push    hl                ; SAVE Address    
        call    FETCHC            ; GET CURRENT LOCATION
        call    RIGHTP           
; EF7A
POPSTC: ld      (PINDEX),a        ; Store Bit Position 
        ld      (CURLOC),hl       ; Store Current Point Address
        pop     hl                ; Restore Saved Address
        pop     af                ; Restore Saved Bit Index
        ret                       ; Return from Subroutine
; EF8B
PGINIT: ld      (ARYPNT),hl     ;;Save Pointer into Array
        ld      h,b
        ld      l,c
        ld      (MAXDEL),hl     ;;Save Bit Counr?
        add     a,a             ;;Index = Operation ID * 2
        ld      c,a             ;;Copy to BC
        ld      b,0
        ld      hl,OPCTAB       ;;Get Operation Table Address
        add     hl,bc           ;;Add Index
        ld      a,(hl)          ;;Get Address from Table
        inc     hl
        ld      h,(hl)
        ld      l,a
        ld      (OPCADR),hl      ;;Store It
        ret
; EFA3
OPCTAB: dw      ORC             ;;A = A | C     OR
        dw      ANDC            ;;A = A & C     AND
        dw      CPLA            ;;A = !A        PRESET
        dw      NOOP            ;;No Operation  PSET
        dw      XORC            ;;A = A ^ C     XOR (Default)
; EFAD
;;Read One Line of Characters from Colors to Screen
NREAD:  call    NSETUP            ; [H,L] = Screen Address, [A] = Counter
NREADL: ld      b,(hl)            ; [B] = Character at Address
        ld      de,COLRAM-CHRRAM  ; [D,E] = Offset into Color Matrix
        ex      de,hl             ; [D,E] = Screen Address, [H,L] = Offset
        add     hl,de             ; [H,L] = Color Address
        ld      c,(hl)            ; [C] = Color Attribute
        pop     hl                ; Pop Array Pointer into [H,L]
        ld      (hl),b            ; Copy Character into Array
        inc     hl                ; Bump Array Pointer
        ld      (hl),c            ; Copy Colors into Array
        inc     hl                ; Bump Array Pointer
        push    hl                ; Push Array Pointer back onto Stack
        ex      de,hl             ; [H,L} = Screen Address, Discard Offset
        inc     hl                ; Bump Screen Address
        dec     a                 ; Decrement Counter
        jr      nz,NREADL         ; If Not Done, Do Next Position
        jr      NDONE             ; Else Save Array Pointer and Return
; EFC4
;;Write One Line of Characters and Colors to Screen
NWRITE: call    NSETUP            ; [H,L] = Screen Address, [A] = Counter
NWRITL: ex      de,hl             ; [D,E] = Screen Address
        ld      hl,COLRAM-CHRRAM  ; [H,L] = Offset into Color Matrix
        add     hl,de             ; [H,L] = Color Address
        ld      c,(hl)            ; [C] = Color Attribute
        pop     hl                ; Pop Array Pointer into [H,L]
        ld      b,(hl)            ; Read Character from Array into [B]
        inc     hl                ; Bump Array Pointer
        ex      af,af'            ; Save Counter
        ld      a,(hl)            ; Read Color Attribute from into [A]
        inc     hl                ; Bump Array Pointer
        call    OPCJMP            ; Do Operation on Color Attribute
        push    hl                ; Push Array Pointer onto Stack
        ex      de,hl             ; [H,L} = Screen Address, Discard Offset
        ld      (hl),b            ; Write Character to Character
        ld      de,COLRAM-CHRRAM  ; [H,L] = Offset into Color Matrix
        ex      de,hl             ; [D,E] = Screen Address, [H,L] = Offse
        add     hl,de             ; [H,L] = Color Address
        ld      (hl),a            ; Write Attribute to Color Matrix
        ex      de,hl             ; [H,L] = Screen Address
        inc     hl                ; Next Screen Address
        ex      af,af'            ; Restore Counter
        dec     a                 ; Decremement it
        jr      nz,NWRITL         ; If Not Done, Do Next Position
NDONE:  pop     hl                ; Pop Array Pointer off Stack
        ld      (ARYPNT),hl       ; and Store in ARYPNT
        ret
; EFEA
;;Get CURLOC and MAXDEL for NREAD and NWRITE
NSETUP: ld      hl,(MAXDEL)
        ld      a,l               ; [A] = Byte Count
        ld      hl,(ARYPNT)       ; 
        ex      (sp),hl           ; Push Array Pointer under Return Address
        push    hl                ; 
        ld      hl,(CURLOC)       ; [H,L] = Screen Address
        ret
; EFF7
;;PUT Action Subroutines
ORC:    or      c               ;;OR
        ret                     ;;
ANDC:   and     c               ;;AND
        ret                     ;;
XORC:   xor     c               ;;XOR (Default)
        ret                     ;;
CPLA:   cpl                     ;;PRSET
NOOP:   ret                     ;;PSET (Use Color from Array)
