;       PAINT - FILL AN AREA WITH COLOR
; SYNTAX: PAINT (X,Y), FILLC, BORDC]]
; Code taken from MSX BASIC, Comments from GW-BASIC
;59C5
ST_PAINT:
        call    SCAN1             ;GET (X,Y) OF START
J59C8:  push    bc                ;SAVE COORDS OF START
        push    de
        call    ATRSCN            ;SET FILL ATTRIBUTE AS CURRENT
        ld      a,(ATRBYT)        ;DEFAULT BORDER COLOR IS SAME AS FILL
        ld      e,a               ;DEFAULT ATTRIBUTE TO [E] LIKE GETBYT
        dec     hl
        rst     CHRGET            
        jr      z,GOTBRD			    ;NOTHING THERE - USE DEFAULT
        SYNCHR  ","               ;MAKE SURE OF COMMA
        call    GETBYT            ;GET BORDER COLOR ARGUMENT
GOTBRD: ld      a,e               ;BORDER ATTRIBUTE TO A
        call    PNTINI            ;INIT PAINT STUFF & CHECK BORDER ATTRIB
        jp      c,FCERR           
        pop     de                ;GET BACK START COORDS
        pop     bc
        push    hl                ;SAVE TXTPTR UNTIL DONE
        call    CHKRNG            ;MAKE SURE POINT IS ON SCREEN
        call    MAPXYC
        ld      de,1              ;ENTRY COUNT IS ONE (SKIP NO BORDER)
        ld      b,0
        call    SCANR1            ;SCAN RIGHT FROM INITIAL POSITION
        jr      z,POPTRT          ;STARTED ON BORDER - GET TXTPTR & QUIT
        push    hl                ;SAVE NO. OF POINTED PAINTED TO RIGHT
        call    SCANL1            ;NOW SCAN LEFT FROM INITIAL POS.
        pop     de                ;GET RIGHT SCAN COUNT.
        add     hl,de             ;ADD TO LEFT SCAN COUNT
        ex      de,hl             ;COUNT TO [DE]
        xor     a                 
        call    ENTST1             
        ld      a,64              ;MAKE ENTRY FOR GOING DOWN             
        call    ENTST1             
        ld      b,192             ;CAUSE PAINTING UP            
        jr      STPAIN            ;START PAINTING UPWARD
;5A0A
PNTLOP: CALL    CKCNTC            ;CHECK FOR CTRL-C ABORT
        LD      A,(LOHDIR)        
        OR      A
        JR      Z,PNTLP1
        LD      HL,(LOHADR)       ;Put Entry on Queue
        PUSH    HL
        LD      HL,(LOHMSK)
        PUSH    HL
        LD      HL,(LOHCNT)
        PUSH    HL
;5A1F
PNTLP1: POP     DE                ;GET ONE ENTRY FROM QUEUE
        POP     BC
        POP     HL
        LD      A,C               ;NOW GO SET UP CURRENT LOCATION
        CALL    STOREC
;5A26
STPAIN: LD      A,B               ;GET DIRECTION
        LD      (PDIREC),A        
        ADD     A,A               ;SEE WHETHER TO GO UP, DOWN, OR QUIT
        JR      Z,POPTRT          ;IF ZERO, ALL DONE.
        PUSH    DE                ;SAVE SKPCNT IN CASE TUP&TDOWN DON'T
        JR      NC,PDOWN          ;IF POSITIVE, GO DOWN FIRST  
        CALL    TUPC              ;MOVE UP BEFORE SCANNING
        JR      PDOWN2             
;5A35
PDOWN:  CALL    TDOWNC            ;SEE IF AT BOTTOM & MOVE DOWN IF NOT
;5A38
PDOWN2: POP     DE                ;GET SKPCNT BACK
        JR      C,PNTLP1          ;OFF SCREEN - GET NEXT ENTRY
        LD      B,0             
        CALL    SCANR1            ;SCAN RIGHT & SKIP UP TO SKPCNT BORDER
        JP      Z,PNTLP1          ;IF NO POINTS PAINTED, GET NEXT ENTRY
        XOR     A                 
        LD      (LOHDIR),A        
        CALL    SCANL1             
        LD      E,L               ;[DE] = LEFT MOVCNT
        LD      D,H               
        OR      A                 ;SEE IF LINE WAS ALREADY PAINTED
        JR      Z,PNTLP3          ;IT WAS - DON'T MAKE OVERHANG ENTRY
        DEC     HL                ;IF LMVCNT.GT.1, NEED TO MAKE ENTRY
        DEC     HL                ;IN OPPOSITE DIRECTION FOR OVERHANG.
        LD      A,H               
        ADD     A,A               ;SEE IF [HL] WAS .GT. 1
        JR      C,PNTLP3           
        LD      (LOHCNT),DE       
        CALL    FETCHC            
        LD      (LOHADR),HL       
        LD      (LOHMSK),A        
        LD      A,(PDIREC)        
        CPL                       
        LD      (LOHDIR),A        
;5A69
PNTLP3: LD      HL,(MOVCNT)       ;GET COUNT PAINTED DURING RIGHT SCAN
        ADD     HL,DE             ;ADD TO LEFT MOVCNT
        EX      DE,HL             ;ENTRY COUNT TO [DE]
        CALL    ENTSLR            ;GO MAKE ENTRY.
J5A71:  LD      HL,(CSAVEA)       ;SET CURRENT LOCATION BACK TO END
        LD      A,(CSAVEM)        ;OF RIGHT SCAN.
        CALL    STOREC            
;5A7A
PNTLP4: LD      HL,(SKPCNT)       ;CALC SKPCNT - MOVCNT TO SEE IF
        LD      DE,(MOVCNT)       ;ANY MORE BORDER TO SKIP
        OR      A                 
        SBC     HL,DE             
        JR      Z,GOPLOP          ;NO MORE - END OF THIS SCAN
        JR      C,PNTLP6           
        EX      DE,HL             ;          
        LD      B,1             
        CALL    SCANR1            
        JR      Z,GOPLOP           
        OR      A                 
        JR      Z,PNTLP4           
        EX      DE,HL             
        LD      HL,(CSAVEA)       
        LD      A,(CSAVEM)        
        LD      C,A               
        LD      A,(PDIREC)        
        LD      B,A               
        CALL    C5AD3             
        JR      PNTLP4            
;5AA4
PNTLP6: CALL    NEGHL             ;MAKE NEW SKPCNT POSITIVE
        DEC     HL                ;IF SKPCNT-MOVCNT .LT. -1
        DEC     HL                ;THEN RIGHT OVERHANG ENTRY IS NEEDED.
        LD      A,H               ;SEE IF POSITIVE.
        ADD     A,A               
        JR      C,GOPLOP          ;OVERHANG TOO SMALL FOR NEW ENTRY
        INC     HL                ;NOW MOVE LEFT TO BEGINNING OF SCAN
        PUSH    HL                ;SO WE CAN ENTER A POSITIVE SKPCNT
;5AAF
RTOVH1: CALL    LEFTC             ;START IS -(SKPCNT-MOVCNT)-1 TO LEFT
        DEC     HL                
        LD      A,H               
        OR      L                 
        JR      NZ,RTOVH1          
        POP     DE                ;GET BACK ENTRY SKPCNT INTO [DE]
        LD      A,(PDIREC)        ;MAKE ENTRY IN OPPOSITE DIRECTION
        CPL                       
        CALL    ENTST1            ;MAKE ENTRY
;5ABF
GOPLOP: JP      PNTLOP            ;GO PROCESS NEXT ENTRY
;5AC2
ENTSLR: LD      A,(LFPROG)        ;DON'T STACK IF SCANNED LINE
        LD      C,A               ;WAS ALREADY PAINTED
        LD      A,(RTPROG)        
        OR      C                 
        RET     Z                 ;IF SCAN LINE ALREADY PAINTED
        LD      A,(PDIREC)        
;5ACE
ENTST1: LD      B,A               ;DIRECTION IN [B]
        CALL    FETCHC            ;LOAD REGS WITH CURRENT "C"
        LD      C,A               ;BIT MASK IN [C]
;5AD3
C5AD3:  EX      (SP),HL
        PUSH    BC
        PUSH    DE
        PUSH    HL
        LD      C,2
        JP      GETSTK             
;5ADC
SCANR1: CALL    SCANR             ;PERFORM LOW LEVEL RIGHT SCAN
        LD      (SKPCNT),DE       ;SAVE UPDATED SKPCNT
        LD      (MOVCNT),HL       ;SAVE MOVCNT
        LD      A,H               
        OR      L                 ;SET CC'S ON MOVCNT
        LD      A,C               ;GET ALREADY-PAINTED FLAG FROM [C]
        LD      (RTPROG),A        
        RET                       

;5AED
SCANL1: CALL    FETCHC             ;GET CURRENT LOCATION
        PUSH    HL                 ;AND SWAP WITH CSV
        PUSH    AF                 
        LD      HL,(CSAVEA)        
        LD      A,(CSAVEM)         
        CALL    STOREC             ;REPOS AT BEGINNING OF SCAN
        POP     AF                 ;REGET PLACE WHERE RT SCN STOPPED
        POP     HL                 
        LD      (CSAVEA),HL        ;AND SAVE IT IN TEMP LOCATION
        LD      (CSAVEM),A         
        CALL    SCANL              ;NOW DO LOW LEVEL LEFT SCAN
        LD      A,C                ;GET ALREADY-PAINTED FLAG FROM [C]
        LD      (LFPROG),A         ;WHETHER IT WAS ALREADY PAINTED
        RET                        

