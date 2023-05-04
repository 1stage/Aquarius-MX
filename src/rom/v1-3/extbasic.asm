;====================================================================
; Mattel Aquarius: Extended BASIC Statements and Functions
;====================================================================
;
; 2023-04-22 - Extracted from Aquarius Extended BASIC Disassembly

;----------------------------------------------------------------------------
;;; DEF FN Statement - Define User Function
;;;
;;; FORMAT: DEF FN <name> ( <variable> ) = <expression>
;;;
;;; Action: This sets up a user-defined function that can be used later in
;;; the program. The function can consist of any mathematical formula. 
;;; User-defined functions save space in programs where a long formula is 
;;; used in several places. The formula need only be specified once, in the
;;; definition statement, and then it is abbreviated as a function name. It
;;; must be executed once, but any subsequent executions are ignored.
;;;   The function name is the letters FN followed by any variable name. 
;;; This can be 1 or 2 characters, the first being a letter and the second a
;;; letter or digit.
;;;   The parametern <variable> represents the argument variable or value 
;;; that will be given in the function call and does not affect any program
;;; variable with the same name. For any other variable name in <expression>,
;;; the value of that program variable is used.
;;;   A DEF FN statement must be executed before the function it defines may 
;;; be called. If a function is called before it has been defined, an 
;;; "Undefined user function" error occurs. 
;;;   Multiple user functions may be defined at once, each with a unique FN 
;;; name. Executing a DEF with the same FN name as a previously defined user 
;;; function replaces the previous definition with the new one. DEF FN is 
;;; illegal in direct mode.
;;;
;;; EXAMPLES of DEF FN Statement:
;;;
;;;   10 DEF FN A(X)=X+7
;;;
;;;   20 DEF FN AA(X)=Y*Z
;;;
;;;   30 DEF FN A9(Q) = INT(RND(1)*Q+1)
;;;
;;;   The function is called later in the program by using the function name
;;; with a variable in parentheses. This function name is used like any other
;;; variable, and its value is automatically calculated,
;;;
;;; EXAMPLES of FN Use:
;;;
;;;   40 PRINT FN A(9)
;;;
;;;   50 R=FN AA(9)
;;;
;;;   60 G=G+FN A9(10)
;;;
;;;   In line 50 above, the number 9 inside the parentheses does not affect
;;; the outcome of the function, because the function definition in line 20
;;; doesn't use the variable in the parentheses. The result is Y times Z,
;;; regardless of the value of X. In the other two functions, the value in
;;; parentheses does affect the result.
;----------------------------------------------------------------------------

DEFX:   pop     hl              
        pop     af              
        pop     hl              
        call    GETFNM          ; GET A POINTER TO THE FUNCTION NAME
        call    ERRDIR          ; DEF IS "ILLEGAL DIRECT"
        ld      bc,DATA         ; MEMORY, RESTORE THE TXTPTRAND GO TO "DATA" 
        push    bc              ; SKIPPING THE REST OF THE FORMULA
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
        rst     SYNCHR
        db      EQUATK
        ld      b,h             
        ld      c,l             
        ex      (sp),hl         
        ld      (hl),c          
        inc     hl              
        ld      (hl),b          
        jp      STRADX           

FNDOEX: pop     hl              
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
GETFNM: rst     SYNCHR  
        db      FNTK            ;  MUST START WITH "FN"
        ld      a,128           ;  DONT ALLOW AN ARRAY
        ld      (SUBFLG),a      ;  DON'T RECOGNIZE THE "(" AS THE START OF AN ARRAY REFEREENCE
        or      (hl)            ;  PUT FUNCTION BIT ON
        ld      c,a             ;  GET FIRST CHARACTER INTO [C]
        call    PTRGT2          
        jp      CHKNUM          


;----------------------------------------------------------------------------
;;; ATN Function - Arctangent
;;;
;;; FORMAT: ATN ( <number> )
;;;
;;; Action: This mathematical function returns the arctangent of the
;;; number. The result is the angle (in radians) whose tangent is the number
;;; given. The result is always in the range -pi/2 to +pi/2.
;;;
;;; EXAMPLES of ATN Function:
;;;
;;;   10 PRINT ATN(0)
;;;   20 X = ATN(J)*180/ {pi} : REM CONVERT TO DEGREES
;----------------------------------------------------------------------------

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
        db    $FE,$C1,$2F,$7C ; .04290961
        db    $74,$31,$9A,$7D ; -.07528964
        db    $84,$3D,$5A,$7D ; .1065626
        db    $C8,$7F,$91,$7E ; -.142089
        db    $E4,$BB,$4C,$7E ; .1999355
        db    $6C,$AA,$AA,$7F ; -.3333315
        db    $00,$00,$00,$81 ; 1.0
