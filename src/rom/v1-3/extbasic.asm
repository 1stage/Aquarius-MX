;====================================================================
; Mattel Aquarius: Extended BASIC Statements and Functions
;====================================================================
;
; 2023-04-22 - Extracted from Aquarius Extended BASIC Disassembly

;SIMPLE-USER-DEFINED-FUNCTION CODE
;
; IN THE 8K VERSION (SEE LATER COMMENT FOR EXTENDED)
; NOTE ONLY SINGLE ARGUMENTS ARE ALLOWED TO FUNCTIONS
; AND FUNCTIONS MUST BE OF THE SINGLE LINE FORM:
; DEF FNA(X)=X^2+X-2
; NO STRINGS CAN BE INVOLVED WITH THESE FUNCTIONS
;
; IDEA: CREATE A FUNNY SIMPLE VARIABLE ENTRY
; WHOSE FIRST CHARACTER (SECOND WORD IN MEMORY)
; HAS THE 200 BIT SET.
; THE VALUE WILL BE:
;
;   A TXTPTR TO THE FORMULA
; THE NAME OF THE PARAMETER VARIABLE
;
; FUNCTION NAMES CAN BE LIKE "FNA4"
;
DEFX:   pop     hl              
        pop     af              
        pop     hl              
        call    GETFNM          ; GET A POINTER TO THE FUNCTION NAME

        call    IDERR          ; DEF IS "ILLEGAL DIRECT"
                                ; MEMORY, RESTORE THE TXTPTRAND GO TO "DATA" 
                                ; SKIPPING THE REST OF THE FORMULA
        ld      bc,DATA      
        push    bc              
        push    de              
        SYNCHK  '('             ;{GWB} SKIP OVER OPEN PAREN
        call    PTRGET          ; GET POINTER TO DUMMY VAR(CREATE VAR)
        push    hl              
        ex      de,hl           
        dec     hl              
        ld      d,(hl)          
        dec     hl              
        ld      e,(hl)          
        pop     hl              
        call    CHKNUM          
        SYNCHK  ')'             ;{M80} MUST BE FOLLOWED BY )
        SYNCHK  EQUATK
        ld      b,h             
        ld      c,l             
        ex      (sp),hl         
        ld      (hl),c          
        inc     hl              
        ld      (hl),b          
        jp      STRADX           

FNDOER: pop     hl              
        pop     af              
        pop     hl              
        call    GETFNM          ; GET A POINTER TO THE FUNCTION NAME

        push    de                
        call    PARCHK          ;{M80} RECURSIVELY EVALUATE THE FORMULA
        call    CHKNUM          ;{M65} MUST BE NUMBER
        ex      (sp),hl         ; SAVE THE TEXT POINTER THAT POINTS PAST THE 
                                ; FUNCTION NAME IN THE CALL
        ld      e,(hl)          ;[H,L]=VALUE OF THE FUNCTION
        inc     hl              
        ld      d,(hl)          
        inc     hl              ; WHICH IS A TEXT POINTER AT THE FORMAL
        ld      a,d             ; PARAMETER LIST IN THE DEFINITION
        or      e               ; A ZERO TEXT POINTER MEANS THE FUNCTION 
                                ; WAS NEVER DEFINED
        jp      z,UFERR         ; IF SO, GIVEN AN "UNDEFINED FUNCTION" ERROR
        ld      a,(hl)          
        inc     hl              
        ld      h,(hl)          
        ld      l,a             
        push    hl              ; SAVE THE NEW VALUE FOR PRMSTK
        ld      hl,(VARNAM)      
        ex      (sp),hl         
        ld      (VARNAM),hl      
        ld      hl,(FNPARM)      
        push    hl              
        ld      hl,(VARPNT)      
        push    hl              
        ld      hl,VARPNT        
        push    de              
        call    MOVMF           
        pop     hl              
        call    FRMNUM          ;AND EVALUATE THE DEFINITION FORMULA
        dec     hl              ;CAN HAVE RECURSION AT THIS POINT
        rst     CHRGET          ;SEE IF THE STATEMENT ENDED RIGHT
        jp      nz,SNERR        ;THIS IS A CHEAT, SINCE THE LINE 
                                ;NUMBER OF THE ERROR WILL BE THE CALLERS
                                ;LINE # INSTEAD OF THE DEFINITIONS LINE #
        pop     hl              
        ld      (VARPNT),hl      
        pop     hl              
        ld      (FNPARM),hl      
        pop     hl              
        ld      (VARNAM),hl      
        pop     hl              ;GET BACK THE TEXT POINTER
        ret                     

; SUBROUTINE TO GET A POINTER TO A FUNCTION NAME
; 
GETFNM: SYNCHK  FNTK            ;  MUST START WITH "FN"
        ld      a,128           ;  DONT ALLOW AN ARRAY
        ld      (SUBFLG),a      ;  DON'T RECOGNIZE THE "(" AS THE START OF AN ARRAY REFEREENCE
        or      (hl)            ;  PUT FUNCTION BIT ON
        ld      c,a             ;  GET FIRST CHARACTER INTO [C]
        call    PTRGT2          
        jp      CHKNUM          

; ARCTANGENT FUNCTION
; IDEA: USE IDENTITIES TO GET ARG BETWEEN 0 AND 1 AND THEN USE AN
; APPROXIMATION POLYNOMIAL TO COMPUTE ARCTAN(X)
ATN1:   pop     hl
        pop     af
        pop     hl
        rst     FSIGN           ; SEE IF ARG IS NEGATIVE
        call    m,PSHNEG        ; IF ARG IS NEGATIVE, USE:
        call    m,NEG           ;    ARCTAN(X)=-ARCTAN(-X
        ld      a,(FAC)         ; SEE IF FAC .GT. 1
        cp      129            
        jp      c,ATN2          ; GET THE CONSTANT 1

        ld      bc,129*128      ; GET THE CONSTANT 1
        ld      d,c             
        ld      e,c             ; COMPUTE RECIPROCAL TO USE THE IDENTITY:
        call    FDIV            ;   ARCTAN(X)=PI/2-ARCTAN(1/X)
        ld      hl,FSUBS        ; PUT FSUBS ON THE STACK SO WE WILL RETURN       
        push    hl              ;  TO IT AND SUBTRACT THE REULT FROM PI/2
ATN2:   ld      hl,ATNCON       ; EVALUATE APPROXIMATION POLYNOMIAL

        call    POLYX           
        ld      hl,PI2          ; GET POINTER TO PI/2 IN CASE WE HAVE TO
        ret                     ;  SUBTRACT THE RESULT FROM PI/2

;CONSTANTS FOR ATN
ATNCON: db    9               ;DEGREE
        db    $4A,$D7,$3B,$78 ; .002866226
        db    $02,$6E,$84,$7B ; -.01616574
        db    $FE,$C1,$2F,$2F ; .04290961
        db    $74,$31,$9A,$7D ; -.07528964
        db    $84,$3D,$5A,$7D ; .1065626
        db    $C8,$7F,$91,$7E ; -.142089
        db    $E4,$BB,$4C,$7E ; .1999355
        db    $6C,$AA,$AA,$7F ; -.3333315
        db    $00,$00,$00,$81 ; 1.0
