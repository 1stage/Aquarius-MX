;----------------------------------------------------------------------------
;;; ---
;;; ## PRINT USING
;----------------------------------------------------------------------------

CSTRNG	=     	$5C               ; Field Terminator '\'
CURNCY  =       '$'               ; Currency Symbol - USE DOLLAR SIGN AS DEFAULT
USFLG   =       FLGINP            ; Flag - Values printed last scan

; PRINT USING DRIVER
; COME HERE AFTER THE "USING" CLAUSE IN A PRINT STATEMENT
; IS RECOGNIZED. THE IDEA IS TO SCAN THE USING STRING UNTIL
; THE VALUE LIST IS EXHAUSTED, FINDING STRING AND NUMERIC
; FIELDS TO PRINT VALUES OUT OF THE LIST IN,
; AND JUST OUTPUTING ANY CHARACTERS THAT AREN'T PART OF
; A PRINT FIELD.
PRINUS: CALL    FRMCHK            ; EVALUATE THE "USING" STRING
        CALL    CHKSTR            ; MAKE SURE IT IS A STRINGmov
        SYNCHK  ';'               ; MUST BE DELIMITED BY A SEMI-COLON
        ex      de,hl             ; [D,E]=TEXT POINTER
        ld      hl,(FACLO)        ; GET POINTER TO "USING" STRING DESCRIPTOR
        jr      INIUS             ; DONT POP OFF OR LOOK AT USFLG
REUSST: ld      a,(USFLG)         ; DID WE PRINT OUT A VALUE LAST SCAN?
        or      a                 ; SET CC'S
        jr      z,FCERR3          ; NO, GIVE ERROR
        pop     de                ; [D,E]=POINTER TO "USING" STRING DESCRIPTOR
        ex      de,hl             ; [D,E]=TEXT POINTER
INIUS:  push    hl                ; SAVE THE POINTER TO "USING" STRING DESCRIPTOR
        xor     a                 ; INITIALLY INDICATE THERE ARE MORE VALUES IN THE VALUE LIST
        ld      (USFLG),a         ; RESET THE FLAG THAT SAYS VALUES PRINTED
        cp      d                 ; TURN THE ZERO FLAG OFF TO INDICATE THE VALUE LIST HASN'T ENDED
        push    af                ; SAVE FLAG INDICATING WHETHER THE VALUE LIST HAS ENDED
        push    de                ; SAVE THE TEXT POINTER INTO THE VALUE LIST
        ld      b,(hl)            ; [B]=LENGTH OF THE "USING" STRING
        or      B                 ; SEE IF ITS ZERO
FCERR3: jp      z,FCERR           ; IF SO, "ILLEGAL FUNCTION CALL"
        inc     hl                ; [H,L]=POINTER AT THE "USING" STRING'S
        ld      c,(hl)            ; DATA
        inc     hl                
        ld      h,(hl)            
        ld      l,c                 
        jr      PRCCHR            ; GO INTO THE LOOP TO SCAN THE "USING" STRING

BGSTRF: ld      e,b               ; SAVE THE "USING" STRING CHARACTER COUNT
        push    hl                ; SAVE THE POINTER INTO THE "USING" STRING
        ld      c,2               ; THE \\ STRING FIELD HAS 2 PLUS
                                  ; NUMBER OF ENCLOSED SPACES WIDTH
LPSTRF: ld      a,(hl)            ; GET THE NEXT CHARACTER
        inc     hl                ; ADVANCE THE POINTER AT THE "USING" STRING DATA
        cp      CSTRNG            ; THE FIELD TERMINATOR?
        jp      z,ISSTRF          ; GO EVALUATE A STRING AND PRINT
        cp      ' '               ; A FIELD EXTENDER?
        jr      nz,NOSTRF         ; IF NOT, ITS NOT A STRING FIELD
        inc     c                 ; INCREMENT THE FIELD WIDTH SEE IF THERE ARE MORE CHARACTERS
        djnz    LPSTRF            ; KEEP SCANNING FOR THE FIELD TERMINATOR

; SINCE STRING FIELD WASN'T FOUND, THE "USING" STRING CHARACTER COUNT AND THE POINTER INTO IT'S DATA MUST BE RESTORED AND THE "\" PRINTED
NOSTRF: pop     hl                ; RESTORE THE POINTER INTO "USING" STRING'S DATA
        ld      b,e               ; RESTORE THE "USING" STRING CHARACTER COUNT
        ld      a,CSTRNG          ; RESTORE THE CHARACTER

; HERE TO PRINT THE CHARACTER IN [A] SINCE IT WASN'T PART OF ANY FIELD
NEWUCH: call    PLSPRT            ; IF A "+" CAME BEFORE THIS CHARACTER MAKE SURE IT GETS PRINTED
        rst     OUTCHR            ; PRINT THE CHARACTER THAT WASN'T PART OF A FIELD
PRCCHR: xor     a                 ; SET [D,E]=0 SO IF WE DISPATCH
        ld      e,a               ; SOME FLAGS ARE ALREADY ZEROED
        ld      d,a               ; DON'T PRINT "+" TWICE
PLSFIN: call    PLSPRT            ; ALLOW FOR MULTIPLE PLUSES IN A ROW
        ld      d,a               ; SET "+" FLAG
        ld      a,(hl)            ; GET A NEW CHARACTER
        inc     hl                  
        cp      '!'               ; CHECK FOR A SINGLE CHARACTER
        jp      z,SMSTRF          ; STRING FIELD
        cp      '#'               ; CHECK FOR THE START OF A NUMERIC FIELD 
        jr      z,NUMNUM          ; GO SCAN IT
        cp      '&'               ; SEE IF ITS A VARIABLE LENGTH STRING FIELD
        jp      z,VARSTR          ; GO PRINT ENTIRE STRING
        dec     b                 ; ALL THE OTHER POSSIBILITIES REQUIRE AT LEAST 2 CHARACTERS
        jp      z,REUSIN          ; IF THE VALUE LIST IS NOT EXHAUSTED GO REUSE "USING" STRING
        cp      '+'               ; A LEADING "+" ?
        ld      a,8               ; SETUP [D] WITH THE PLUS-FLAG ON IN
        jr      z,PLSFIN          ; CASE A NUMERIC FIELD STARTS
        dec     hl                ; POINTER HAS ALREADY BEEN INCREMENTED
        ld      a,(hl)            ; GET BACK THE CURRENT CHARACTER
        inc     hl                ; REINCREMENT THE POINTER
        cp      '.'               ; NUMERIC FIELD WITH TRAILING DIGITS
        jr      z,DOTNUM          ; IF SO GO SCAN WITH [E]=NUMBER OF DIGITS BEFORE THE "."=0
        cp      '_'               ; CHECK FOR LITERAL CHARACTER DECLARATION
        jp      z,LITCHR            
        cp      CSTRNG            ; CHECK FOR A BIG STRING FIELD STARTER
        jr      z,BGSTRF          ; GO SEE IF IT REALLY IS A STRING FIELD
        cp      (hl)              ; SEE IF THE NEXT CHARACTER MATCHES THE CURRENT ONE
        jr      nz,NEWUCH         ; IF NOT, CAN'T HAVE $$ OR ** SO ALL THE POSSIBILITIES ARE EXHAUSTED
        cp      CURNCY            ; IS IT $$ ?
        jr      z,DOLRNM          ; GO SET UP THE FLAG BIT
        cp      '*'               ; IS IT ** ?
        jr      nz,NEWUCH         ; IF NOT, ITS NOT PART OF A FIELD SINCE ALL THE POSSIBILITIES HAVE BEEN TRIED
        ld      a,b               ; SEE IF THE "USING" STRING IS LONG
        inc     hl                ; CHECK FOR $
        cp      2                 ; ENOUGH FOR THE SPECIAL CASE OF
        jr      c,NOTSPC          ;  **$
        ld      a,(hl)              
        cp      CURNCY            ; IS THE NEXT CHARACTER $ ?
NOTSPC: ld      a,32              ; SET THE ASTERISK BIT
        jr      nz,SPCNUM         ; IF IT NOT THE SPECIAL CASE, DON'T SET THE DOLLAR SIGN FLAG
        dec     b                 ; DECREMENT THE "USING" STRING CHARACTER COUNT TO TAKE THE $ INTO CONSIDERATION
        inc     e                 ; INCREMENT THE FIELD WIDTH FOR THE FLOATING DOLLAR SIGN
        db      $10               ; "CPI" OVER THE NEXT BYTE
DOLRNM: xor     a                 ; CLEAR [A]
        add     a,16              ; SET BIT FOR FLOATING DOLLAR SIGN FLAG
        inc     hl                ; POINT BEYOND THE SPECIAL CHARACTERS
SPCNUM: inc     e                 ; SINCE TWO CHARACTERS SPECIFY THE FIELD SIZE, INITIALIZE [E]=1
        add     a,d               ; PUT NEW FLAG BITS IN [A]
        ld      d,a               ; INTO [D]. THE PLUS FLAG MAY HAVE ALREADY BEEN SET
NUMNUM: inc     e                 ; INCREMENT THE NUMBER OF DIGITS BEFORE THE DECIMAL POINT
        ld      c,0               ; SET THE NUMBER OF DIGITS AFTER THE DECIMAL POINT = 0
        dec     b                 ; SEE IF THERE ARE MORE CHARACTERS
        jr      z,ENDNUS          ; IF NOT, WE ARE DONE SCANNING THIS NUMERIC FIELD
        ld      a,(hl)            ; GET THE NEW CHARACTER
        inc     hl                ; ADVANCE THE POINTER AT THE "USING" STRING DATA
        cp      '.'               ; DO WE HAVE TRAILING DIGITS?
        jr      z,AFTDOT          ; IF SO, USE SPECIAL SCAN LOOP
        cp      '#'               ; MORE LEADING DIGITS ?
        jr      z,NUMNUM          ; INCREMENT THE COUNT AND KEEP SCANNING
        cp      54O               ; DOES HE WANT A COMMA EVERY THREE DIGITS?
        jr      nz,FINNUM         ; NO MORE LEADING DIGITS, CHECK FOR ^^^
        ld      a,d               ; TURN ON THE COMMA BIT
        or      64
        ld      d,a
        jr      NUMNUM            ; GO SCAN SOME MORE

; HERE WHEN A "." IS SEEN IN THE "USING" STRING IT STARTS A NUMERIC FIELD IF AND ONLY IF IT IS FOLLOWED BY A "#"
DOTNUM: ld      a,(hl)            ; GET THE CHARACTER THAT FOLLOWS
        cp      '#'               ; IS THIS A NUMERIC FIELD?
        ld      a,'.'             ; IF NOT, GO BACK AND PRINT "."
        jr      nz,NEWUCH           
        ld      c,1               ; INITIALIZE THE NUMBER OF DIGITS AFTER THE DECIMAL POINT
        inc     hl                  
AFTDOT: inc     c                 ; INCREMENT THE NUMBER OF DIGITS AFTER THE DECIMAL POINT
        dec     b                 ; SEE IF THE "USING" STRING HAS MORE
        jr      z,ENDNUS          ; CHARACTERS, AND IF NOT, STOP SCANNING
        ld      a,(hl)            ; GET THE NEXT CHARACTER
        inc     hl                  
        cp      '#'               ; MORE DIGITS AFTER THE DECIMAL POINT?
        jr      z,AFTDOT          ; IF SO, INCREMENT THE COUNT AND KEEP SCANNING

; CHECK FOR THE "^^^^" THAT INDICATES SCIENTIFIC NOTATION
FINNUM: push    de                ; SAVE [D]=FLAGS AND [E]=LEADING DIGITS
        ld      de,NOTSCI         ; PLACE TO GO IF ITS NOT SCIENTIFIC
        push    de                ; NOTATION
        ld      d,h               ; REMEMBER [H,L] IN CASE
        ld      e,l               ; ITS NOT SCIENTIFIC NOTATION
        cp      '^'               ; IS THE FIRST CHARACTER "^" ?
        ret     nz                  
        cp      (hl)              ; IS THE SECOND CHARACTER "^" ?
        ret     nz                  
        inc     hl                  
        cp      (hl)              ; IS THE THIRD CHARACTER "^" ?
        ret     nz                  
        inc     hl                  
        cp      (hl)              ; IS THE FOURTH CHARACTER "^" ?
        ret     nz                  
        inc     hl                  
        ld      a,b               ; WERE THERE ENOUGH CHARACTERS FOR "^^^^"
        sub     4                 ; IT TAKES FOUR
        ret     c                   
        pop     de                ; POP OFF THE NOTSCI RETURN ADDRESS
        pop     de                ; GET BACK [D]=FLAGS [E]=LEADING DIGITS
        ld      b,a               ; MAKE [B]=NEW CHARACTER COUNT
        inc     d                 ; TURN ON THE SCIENTIFIC NOTATION FLAG
        inc     hl                  
        db      $CA               ; SKIP THE NEXT TWO BYTES WITH "JZ"
NOTSCI: ex      de,hl             ; RESTORE THE OLD [H,L]
        pop     de                ; GET BACK [D]=FLAGS [E]=LEADING DIGITS
ENDNUS: ld      a,d               ; IF THE LEADING PLUS FLAG IS ON
        dec     hl
        inc     e                 ; INCLUDE LEADING "+" IN NUMBER OF DIGITS
        and     8                 ; DON'T CHECK FOR A TRAILING SIGN
        jr      nz,ENDNUM         ; ALL DONE WITH THE FIELD IF SO IF THERE IS A LEADING PLUS
        dec     e                 ; NO LEADING PLUS SO DON'T INCREMENT THE NUMBER OF DIGITS BEFORE THE DECIMAL POINT
        ld      a,b                 
        or      a                 ; SEE IF THERE ARE MORE CHARACTERS
        jr      z,ENDNUM          ; IF NOT, STOP SCANNING
        ld      a,(hl)            ; GET THE CURRENT CHARACTER
        sub     '-'               ; TRAIL MINUS?
        jr      z,SGNTRL          ; SET THE TRAILING SIGN FLAG
        cp      '+' - '-'         ; A TRAILING PLUS?
        jr      nz,ENDNUM         ; IF NOT, WE ARE DONE SCANNING
        ld      a,8               ; TURN ON THE POSITIVE="+" FLAG
SGNTRL: add     a,4               ; TURN ON THE TRAILING SIGN FLAG
        add     a,d               ; INCLUDE WITH OLD FLAGS
        ld      d,a                 
        dec     b                 ; DECREMENT THE "USING" STRING CHARACTER COUNT TO ACCOUNT FOR THE TRAILING SIGN
ENDNUM: pop     hl                ; [H,L]=THE OLD TEXT POINTER
        pop     af                ; POP OFF FLAG THAT SAYS WHETHER THERE ARE MORE VALUES IN THE VALUE LIST
        jr      z,FLDFIN          ; IF NOT, WE ARE DONE WITH THE "PRINT"
        push    bc                ; SAVE [B]=# OF CHARACTERS REMAINING IN USING" STRING AND [C]=TRAILING DIGITS
        push    de                ; SAVE [D]=FLAGS AND [E]=LEADING DIGITS
        call    FRMEVL            ; READ A VALUE FROM THE VALUE LIST
        pop     de                ; [D]=FLAGS & [E]=# OF LEADING DIGITS
        pop     bc                ; [B]=# CHARACTER LEFT IN "USING" STRING C]=NUMBER OF TRAILING DIGITS
        push    bc                ; SAVE [B] FOR ENTERING SCAN AGAIN
        push    hl                ; SAVE THE TEXT POINTER
        ld      b,e               ; [B]=# OF LEADING DIGITS
        ld      a,b               ; MAKE SURE THE TOTAL NUMBER OF DIGITS
        add     a,c               ; DOES NOT EXCEED TWENTY-FOUR
        cp      25                  
        jp      nc,FCERR          ; IF SO, "ILLEGAL FUNCTION CALL"
        ld      a,d               ; [A]=FLAG BITS
        or      128               ; TURN ON THE "USING" BIT
        call    PUFOUT            ; PRINT THE VALUE
        call    STROUT            ; ACTUALLY PRINT IT
FNSTRF: pop     hl                ; GET BACK THE TEXT POINTER
        dec     hl                ; SEE WHAT THE TERMINATOR WAS
        call    CHRGTR              
        scf                       ; SET FLAG THAT CRLF IS DESIRED
        jr      z,CRDNUS          ; IF IT WAS A END-OF-STATEMENT FLAG THAT THE VALUE LIST ENDED AND THAT CRLF SHOULD BE PRINTED
        ld      (USFLG),a         ; FLAG THAT VALUE HAS BEEN PRINTED. DOESNT MATTER IF ZERO SET, [A] MUST BE NON-ZERO OTHERWISE
        cp      ';'               ; A SEMI-COLON?
        jr      z,SEMUSN          ; A LEGAL DELIMITER
        cp      ','               ; A COMMA ?
        jp      nz,SNERR          ; THE DELIMETER WAS ILLEGAL
SEMUSN: call    CHRGTR            ; IS THERE ANOTHER VALUE?
CRDNUS: pop     bc                ; [B]=CHARACTERS REMAINING IN "USING" STRING
        ex      de,hl             ; [D,E]=TEXT POINTER
        pop     hl                ; [H,L]=POINT AT THE "USING" STRING
        push    hl                ; DESCRIPTOR. RESAVE IT.
        push    af                ; SAVE THE FLAG THAT INDICATES WHETHER OR NOT THE VALUE LIST TERMINATED
        push    de                ; SAVE THE TEXT POINTER

; SINCE FRMEVL MAY HAVE FORCED GARBAGE COLLECTION WE HAVE TO USE THE NUMBER OF CHARACTERS ALREADY SCANNED AS AN 
; OFFSET TO THE POINTER TO THE "USING" STRING'S DATA TO GET A NEW POINTER TO THE REST OF THE CHARACTERS TO BE SCANNED
        ld      a,(hl)            ; GET THE "USING" STRING'S LENGTH
        sub     b                 ; SUBTRACT THE NUMBER OF CHARACTERS ALREADY SCANNED
        inc     hl                ; [H,L]=POINTER AT
        ld      c,(hl)            ; THE "USING" STRING'S
        inc     hl                ; STRING DATA
        ld      h,(hl)              
        ld      l,c                 
        ld      d,0               ; SETUP [D,E] AS A DOUBLE BYTE OFFSET
        ld      e,a                 
        add     hl,de             ; ADD ON THE OFFSET TO GET THE NEW POINTER
CHKUSI: ld      a,b               ; [A]=THE NUMBER OF CHARACTERS LEFT TO SCAN
        or      a                 ; SEE IF THERE ARE ANY LEFT
        jp      nz,PRCCHR         ; IF SO, KEEP SCANNING
        jr      FINUSI            ; SEE IF THERE ARE MORE VALUES
REUSIN: call    PLSPRT            ; PRINT A "+" IF NECESSARY
        rst     OUTCHR            ; PRINT THE FINAL CHARACTER
FINUSI: pop     hl                ; POP OFF THE TEXT POINTER
        pop     af                ; POP OFF THE INDICATOR OF WHETHER OR NOT THE VALUE LIST HAS ENDED
        jp      nz,REUSST         ; IF NOT, REUSE THE "USING" STRING
FLDFIN: call    c,CRDO            ; IF NOT COMMA OR SEMI-COLON ENDED THE VALUE LIST PRINT A CRLF
        ex      (sp),hl           ; SAVE THE TEXT POINTER H,L]=POINT AT THE "USING" STRING'S DESCRIPTOR
        call    FRETM2            ; FINALLY FREE IT UP
        pop     hl                ; GET BACK THE TEXT POINTER
        jp      FINPRT            ; ZERO [PTRFIL]

; HERE TO HANDLE A LITERAL CHARACTER IN THE USING STRING PRECEDED BY "_"
LITCHR: call    PLSPRT            ; PRINT PREVIOUS "+" IF ANY
        dec     b                 ; DECREMENT COUNT FOR ACTUAL CHARACTER
        ld      a,(hl)            ; FETCH LITERAL CHARACTER
        inc     hl                  
        rst     OUTCHR            ; OUTPUT LITERAL CHARACTER
        jr      CHKUSI            ; GO SEE IF USING STRING ENDED

; HERE TO HANDLE VARIABLE LENGTH STRING FIELD SPECIFIED WITH "&"
VARSTR: ld      c,255             ; SET LENGTH TO MAXIMUM POSSIBLE
        jr      ISSTR1

; HERE WHEN THE "!" INDICATING A SINGLE CHARACTER STRING FIELD HAS BEEN SCANNED
SMSTRF: ld      c,1               ; SET THE FIELD WIDTH TO 1
        db      $3E               ; SKIP NEXT BYTE WITH A "MVI A,"
ISSTRF: pop     af                ; GET RID OF THE [H,L] THAT WAS BEING SAVED IN CASE THIS WASN'T A STRING FIELD
ISSTR1: dec     b                 ; DECREMENT THE "USING" STRING CHARACTER COUNT
        call    PLSPRT            ; PRINT A "+" IF ONE CAME BEFORE THE FIELD
        pop     hl                ; TAKE OFF THE TEXT POINTER
        pop     af                ; TAKE OF THE FLAG WHICH SAYS WHETHER THERE ARE MORE VALUES IN THE VALUE LIST
        jr      z,FLDFIN          ; IF THERE ARE NO MORE VALUES THEN WE ARE DONE
        push    bc                ; SAVE [B]=NUMBER OF CHARACTERS YET TO BE SCANNED IN "USING" STRING
        call    FRMEVL            ; READ A VALUE
        call    CHKSTR            ; MAKE SURE ITS A STRING
        pop     bc                ; [C]=FIELD WIDTH
        push    bc                ; RESAVE [B]
        push    hl                ; SAVE THE TEXT POINTER
        ld      hl,(FACLO)        ; GET A POINTER TO THE DESCRIPTOR
        ld      b,c               ; [B]=FIELD WIDTH
        ld      c,0               ; SET UP FOR "LEFT$"
        push    bc                ; SAVE THE FIELD WIDTH FOR SPACE PADDING
        call    LEFTUS            ; TRUNCATE THE STRING TO [B] CHARACTERS
        call    STRPRT            ; PRINT THE STRING
        ld      hl,(FACLO)        ; SEE IF IT NEEDS TO BE PADDED
        pop     af                ; [A]=FIELD WIDTH
        inc     a                 ; IF FIELD LENGTH IS 255 MUST BE "&" SO
        jr      z,FNSTRF          ; DONT PRINT ANY TRAILING SPACES
        dec     a                   
        sub     (hl)              ; [A]=AMOUNT OF PADDING NEEDED
        ld      b,a                 
        ld      a,' '             ; SETUP THE PRINT CHARACTER
        inc     b                 ; DUMMY INCREMENT OF NUMBER OF SPACES
UPRTSP: dec     b                 ; SEE IF MORE SPACES
        jp      z,FNSTRF          ; NO, GO SEE IF THE VALUE LIST ENDED AND RESUME SCANNING
        rst     OUTCHR            ; PRINT A SPACE
        jr      UPRTSP            ; AND LOOP PRINTING THEM

; WHEN A "+" IS DETECTED IN THE "USING" STRING IF A NUMERIC FIELD FOLLOWS A BIT IN [D] SHOULD BE SET, OTHERWISE "+" SHOULD BE PRINTED.
; SINCE DECIDING WHETHER A NUMERIC FIELD FOLLOWS IS VERY DIFFICULT, THE BIT IS ALWAYS SET IN [D]. AT THE POINT IT IS DECIDED 
; A CHARACTER IS NOT PART OF A NUMERIC FIELD, THIS ROUTINE IS CALLED TO SEE IF THE BIT IN [D] IS SET, WHICH MEANS A PLUS PRECEDED THE 
; CHARACTER AND SHOULD BE PRINTED.
PLSPRT: push    af                ; SAVE THE CURRENT CHARACTER
        ld      a,d               ; CHECK THE PLUS BIT
        or      a                 ; SINCE IT IS THE ONLY THING THAT COULD BE TURNED ON
        ld      a,'+'             ; SETUP TO PRINT THE PLUS
        call    nz,OUTDO          ; PRINT IT IF THE BIT WAS SET
        pop     af                ; GET BACK THE CURRENT CHARACTER
        ret        

; THIS IS PRINT USINGS ENTRY POINT INTO LEFT$
LEFTUS:	push	  hl			          ; THIS IS A DUMMY PUSH TO OFFSET THE EXTRA POP IN PUTNEW
        jp      LEFT2             ; Jump into LEFT$

; HERE TO INITIALLY SET UP THE FORMAT SPECS AND PUT IN A SPACE FOR THE ;SIGN OF A POSITIVE NUMBER
FOUINI: ld      (TEMP3),a        ; SAVE THE FORMAT SPECIFICATION
        ld      hl,FBUFFR+1      ; GET A POINTER INTO FBUFFR WE START AT FBUFFR+1 IN CASE THE NUMBER WILL OVERFLOW ITS FIELD, THEN THERE IS ROOM IN  FBUFFR FOR THE PERCENT SIGN.
        ld      (hl),' '         ; PUT IN A SPACE
        ret                      ; ALL DONE

; PRINT THE FAC USING THE FORMAT SPECIFICATIONS IN A, B AND C
PUFOUT: call    FOUINI           ; SAVE THE FORMAT SPECIFICATION IN A AND PUT A SPACE FOR POSITIVE NUMBERS IN THE BUFFER
        and     8                ; CHECK IF POSITIVE NUMBERS GET A PLUS SIGN
        jr      z,FOUT1          ; THEY DON'T
        ld      (hl),'+'         ; THEY DO, PUT IN A PLUS SIGN
FOUT1:  ex      de,hl            ; SAVE BUFFER POINTER
        rst     FSIGN            ; GET THE SIGN OF THE FAC
        ex      de,hl            ; PUT THE BUFFER POINTER BACK IN (HL)
        jp      FOUT2            ; IF WE HAVE A NEGATIVE NUMBER, NEGATE IT
        ld      (hl),'-'         ;   AND PUT A MINUS SIGN IN THE BUFFER
        push    bc               ; SAVE THE FIELD LENGTH SPECIFICATION
        push    hl               ; SAVE THE BUFFER POINTER
        call    NEG              ; NEGATE THE NUMBER
        pop     hl               ; GET THE BUFFER POINTER BACK
        pop     bc               ; GET THE FIELD LENGTH SPECIFICATIONS BACK
        or      h                ; TURN OFF THE ZERO FLAG, THIS DEPENDS ON THE FACT THAT FBUFFR IS NEVER ON PAGE 0.
        inc     hl               ; POINT TO WHERE THE NEXT CHARACTER GOES
        ld     (hl),'0'          ; PUT A ZERO IN THE BUFFER IN CASE THE NUMBER IS ZERO (IN FREE FORMAT) OR TO RESERVE SPACE FOR A FLOATING DOLLAR SIGN (FIXED FORMAT)
        ld      a,(TEMP3)        ; GET THE FORMAT SPECIFICATION
        ld      d,a              ; SAVE IT FOR LATER
        rla                      ; PUT THE FREE FORMAT OR NOT rla IN THE CARRY
        ld      a,(VALTYP)       ; GET THE VALTYP, VNEG COULD HAVE CHANGED THIS  SINCE -32768 IS INT AND 32768 IS SNG.
        jr      c,FOUTFX         ; THE MAN WANTS FIXED FORMATED OUTPUT HERE TO PRINT NUMBERS IN FREE FORMAT
        jr      z,FOUTZR         ; IF THE NUMBER IS ZERO, FINISH IT UP
        cp      4                ; DECIDE WHAT KIND OF A VALUE WE HAVE
        jr      nc,FOUFRV        ; WE HAVE A SNG OR DBL HERE TO PRINT AN INTEGER IN FREE FORMAT
        ld      bc,0             ; SET THE DECIMAL POINT COUNT AND COMMA COUNT  TO ZERO
        call    FOUTCI           ; CONVERT THE INTEGER TO DECIMAL FALL INTO FOUTZS AND ZERO SUPPRESS THE THING

;ZERO SUPPRESS THE DIGITS IN FBUFFR. ASTERISK FILL AND ZERO SUPPRESS IF NECESSARY. SET UP B AND CONDITION CODES IF WE HAVE A TRAILING SIGN
FOUTZS: ld      hl,FBUFFR+1      ; GET POINTER TO THE SIGN
        ld      b,(hl)           ; SAVE THE SIGN IN B
        ld      c,' '            ; DEFAULT FILL CHARACTER TO A SPACE
        ld      a,(TEMP3)        ; GET FORMAT SPECS TO SEE IF WE HAVE TO
        ld      e,a              ;   ASTERISK FILL.  SAVE IT
        and     ' '                
        jr      z,FOTZS1         ; WE DON'T
        ld      a,b              ; WE DO, SEE IF THE SIGN WAS A SPACE
        cp      C                ; ZERO FLAG IS SET IF IT WAS
        ld      c,'*'            ; SET FILL CHARACTER TO AN ASTERISK
        jr      nz,FOTZS1        ; SET THE SIGN TO AN ASTERISK IF IT WAS A SPACE
        ld      a,e              ; GET FORMAT SPECS AGAIN
        and     4                ; SEE IF SIGN IS TRAILING
        jr      nz,FOTZS1        ; IF SO DON'T ASTERISK FILL
        ld      b,c              ; B HAS THE SIGN, C THE FILL CHARACTER
FOTZS1: ld      (hl),c           ; FILL IN THE ZERO OR THE SIGN
        rst     CHRGET           ; GET THE NEXT CHARACTER IN THE BUFFER SINCE THERE ARE NO SPACES, "CHRGET" IS  EQUIVALENT TO "INC HL"/"MOV A,M"
        jr      z,FOTZS4         ; IF WE SEE A REAL ZERO, IT IS THE END OF THE NUMBER, AND WE MUST BACK UP AND PUT IN A ZERO.
                                 ; CHRGET SETS THE ZERO FLAG ON REAL ZEROS OR COLONS, BUT WE WON'T SEE ANY COLONS IN THIS BUFFER.
        cp      'E'              ; BACK UP AND PUT IN A ZERO IF WE SEE
        jr      z,FOTZS4         ; AN "E" OR A "D" SO WE CAN PRINT 0 IN
        cp      'D'              ; FLOATING POINT NOTATION WITH THE C FORMAT ZERO
        jr      z,FOTZS4           
        cp      '0'              ; DO WE HAVE A ZERO?
        jr      z,FOTZS1         ; YES, SUPPRESS IT
        cp      54O              ; 54=","  DO WE HAVE A COMMA?
        jr      z,FOTZS1         ; YES, SUPPRESS IT
        cp      '.'              ; ARE WE AT THE DECIMAL POINT?
        jr      nz,FOTZS2        ; NO, I GUESS NOT
FOTZS4: dec     hl               ; YES, BACK UP AND PUT A ZERO BEFORE IT
        ld      (hl),'0'           
FOTZS2: ld      a,e              ; GET THE FORMAT SPECS TO CHECK FOR A FLOATING
        and     $10              ;  DOLLAR SIGN
        jr      z,FOTZS3         ; WE DON'T HAVE ONE
        dec     hl               ; WE HAVE ONE, BACK UP AND PUT IN THE DOLLAR
        ld      (hl),CURNCY      ;  SIGN
FOTZS3: ld      a,e              ; DO WE HAVE A TRAILING SIGN?
        and     4                  
        ret     nz               ; YES, RETURN; NOTE THE NON-ZERO FLAG IS SET
        dec     hl               ; NO, BACK UP ONE AND PUT THE SIGN BACK IN
        ld      (hl),b           ; PUT IN THE SIGN
        ret                      ; ALL DONE

;THE FOLLOWING CODE DOWN TO FOUFRF: IS ADDED TO ADDRESS THE ANSI STANDARD OF PRINTING NUMBERS IN FIXED FORMAT RATHER THAN
;SCIENTIFIC NOTATION IF THEY CAN BE AS ACCURATELY RPRESENTED IN FIXED FORMAT
FOUFRV: call    PUSHF             ; SAVE IN CASE NEEDED FOR 2ED PASS
        ex      de,hl             ; SAVE BUFFER POINTER IN (HL)
        ld      hl,(FACLO)         
        push    hl                ; SAVE FOR D.P.
        ld      hl,(FACLO+2)      ; 
        push    hl                ; 
        ex      de,hl             ; BUFFER POINTER BACK TO (HL)
        push    af                ; SAVE IN CASE NEEDED FOR SECOND PASS
        xor     a                 ; (A)=0
        ld      (FANSII),a        ; INITIALIZE FANSII FLAG
        pop     af                ; GET PSW RIGHT
        push    af                ; SAVE PSW
        call    FOUFRF            ; FORMAT NUMBER
        ld      b,'E'             ; WILL SEARCH FOR SCIENTIFIC NOTN.
        ld      c,0               ; DIGIT COUNTER
FU1:    push    hl                ; SAVE ORIGINAL FBUFFER POINTER IN CASE WE NEED TO LOOK FOR "D"
        ld      a,(hl)            ; FETCH UP FIRST CHARACTER
FU2:    cp      b                 ; SCIENTIFIC NOTATION?
        jr      z,FU4             ; IF SO, JUMP
        cp      ':'               ; IF CARRY NOT SET NOT A DIGIT
        jr      nc,FU2A             
        cp      '0'               ; IF CARRY SET NOT A DIGIT
        jr      c,FU2A              
        inc     c                 ; INCREMENTED DIGITS TO PRINT
FU2A:   inc     hl                ; POINT TO NEXT BUFFER CHARACTER
        ld      a,(hl)            ; FETCH NEXT CHARACTER
        or      a                 ; 0(BINARY) AT THE END OF CHARACTERS
        jr      nz,FU2            ; CONTINUE SEARCH IF NOT AT END
        ld      a,'D'             ; NOW TO CHECK TO SEE IF SEARCHED FOR D
        cp      b                   
        ld      b,a               ; IN CASE NOT YET SEARCHED FOR
        pop     hl                ; NOW TO CHECK FOR "D"
        ld      c,0               ; ZERO DIGIT COUNT
        jr      nz,FU1            ; GO SEARCH FOR "D" IF NOT DONE SO
FU3:    pop     af                ; POP ORIGINAL PSW
        pop     bc                  
        pop     de                ; GET DFACLO-DFACLO+3
        ex      de,hl             ; (DE)=BUF PTR,(HL)=DFACLO
        ld      (FACLO),hl
        ld      h,b
        ld      l,c
        ld      (FACLO+2),hl
        ex      de,hl        
        pop     bc
        pop     de                
        ret                       

; PRINT IS IN SCIENTIFIC NOTATION , IS THIS BEST?
FU4:    push    bc                        ;SAVE TYPE,DIGIT COUNT
        ld      b,0                        ;EXPONENT VALUE (IN BINARY)
        inc     hl                        ;POINT TO NEXT CHARACTER OF EXP.
        ld      a,(hl)                        ;FETCH NEXT CHARACTER OF EXPONENT
FU5:    cp      '+'                        ;IS EXPONENT POSITIVE?
        jr      z,FU8                        ;IF SO NO BETTER PRINTOUT
        cp      '-'                        ;MUST BE NEGATIVE!
        jr      z,FU5A                        ;MUST PROCESS THE DIGITS
        sub     '0'                        ;SUBTRACT OUT ASCII BIAS
        ld      c,a                        ;DIGIT TO C
        ld      a,b                        ;FETCH OLD DIGIT
        add     a                        ;*2
        add     a                        ;*4
        add     b                        ;*5
        add     a                        ;*10
        add     c                        ;ADD IN NEW DIGIT
        ld      b,a                        ;BACK OUT TO EXPONENT ACCUMULATOR
        cp      8                        ;8 S.P. DIGITS FOR MICROSOFT FORMAT
        jr      nc,FU8                        ;IF SO STOP TRYING
FU5A:   inc     hl                ; POINT TO NEXT CHARACTER
        ld      a,(hl)            ; FETCH UP
        or      a                 ; BINARY ZERO AT END
        jr      nz,FU5            ; CONTINUE IF NOT AT END
        ld      h,b               ; SAVE EXPONENT
        pop     bc                ; FETCH TYPE, DIGIT COUNT
        ld      a,b               ; DETERMINE TYPE
        cp      'E'               ; SINGLE PRECISION?
        jr      nz,FU7            ; NO -GO PROCESS AS DOUBLE PRECISION
        ld      a,c               ; DIGIT COUNT
        add     h                 ; ADD EXPONENT VALUE
        cp      9                   
        pop     hl                ; POP        OLD BUFFER POINTER
        jr      nc,FU3            ; CAN'T DO BETTER
FU6:    ld      a,128             ; 
        ld      (FANSII),a        ; 
        jr      FU9               ; DO FIXED POINT PRINTOUT
FU7:    ld      a,h               ; SAVE EXPONENT
        add     c                 ; TOTAL DIGITS NECESSARY
        cp      18                ; MUST PRODUCE CARRY TO USE FIXED POINT
        pop     hl                ; GET STACK RIGHT
        jr      nc,FU3              
        jr      FU6               ; GO  RINT IN FIXED POINT
FU8:    pop     bc                ; 
        pop     hl                ; GET ORIGINAL BUFFER PTR BACK
        jr      FU3               ; 
FU9:    pop     af                ; GET ORIGINAL PSW OFF STACK
        pop     bc
        pop     de
