;====================================================================
; Mattel Aquarius: Extended BASIC Statements and Functions
;====================================================================
;
; 2023-04-22 - Extracted from Aquarius Extended BASIC Disassembly

;----------------------------------------------------------------------------
;;; ## DEF FN / FN ##
;;; Define User Function
;;; ### FORMAT: ###
;;;  - DEF FN < name > ( < variable > ) = < expression >
;;;    - Action: This sets up a user-defined function that can be used later in the program. The function can consist of any mathematical formula. User-defined functions save space in programs where a long formula is used in several places. The formula need only be specified once, in the definition statement, and then it is abbreviated as a function name. It must be executed once, but any subsequent executions are ignored.
;;;      - The function name is the letters FN followed by any variable name. This can be 1 or 2 characters, the first being a letter and the second a letter or digit.
;;;      - The parametern < variable > represents the argument variable or value that will be given in the function call and does not affect any program variable with the same name. For any other variable name in < expression >, the value of that program variable is used.
;;;      - A DEF FN statement must be executed before the function it defines may be called. If a function is called before it has been defined, an "Undefined user function" error occurs.
;;;      - Multiple user functions may be defined at once, each with a unique FN name. Executing a DEF with the same FN name as a previously defined user function replaces the previous definition with the new one. DEF FN is illegal in direct mode.
;;;      - The function is called later in the program by using the function name with a variable in parentheses. This function name is used like any other variable, and its value is automatically calculated.
;;; ### EXAMPLES: ###
;;; ` 10 DEF FN A(X)=X+7 `
;;;
;;; ` 20 PRINT FN A(9) `
;;; > Prints the value 16 (9 + 7)
;;;
;;; ` 10 DEF FN AA(X)=Y*Z `
;;;
;;; ` 20 R=FN AA(9) `
;;; > Assigns R the value of X * Y, and the number 9 inside the parentheses does not affect the outcome of the function, because the function definition in line 10 doesn't use the variable in the parentheses. 
;;;
;;; ` 10 DEF FN A9(Q) = INT(RND(1)*Q+1) `
;;;
;;; ` 20 G=G+FN A9(10) `
;;; > Increments the value of G the rounded value of a random number between 1 and 10.
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
;;; ## ATN ##
;;; Arctangent
;;; ### FORMAT: ###
;;;  - ATN ( < number > )
;;;    - Action: This mathematical function returns the arctangent of the number. The result is the angle (in radians) whose tangent is the number given. The result is always in the range -pi/2 to +pi/2.
;;; ### EXAMPLES: ###
;;; ` PRINT ATN(1) `
;;; > Prints the arctangent of 1, a value of `0.785398`
;;;
;;; ` X = ATN(J)*180/ {pi} `
;;; > Defines variable X as the arctangent of another variable, J, divided by pi.
;----------------------------------------------------------------------------

ATN1:   pop     hl
        pop     af
        pop     hl
        rst     FSIGN           ; SEE IF ARG IS NEGATIVE
        call    m,PSHNEG        ; IF ARG IS NEGATIVE, USE:
        call    m,NEG           ;    ARCTAN(X)=-ARCTAN(-X
        ld      a,(FAC)         ; SEE IF FAC .GT. 1
        cp      129            
        jp      c,ATN2         

        ld      bc,$8100        ; GET THE CONSTANT 1
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

;----------------------------------------------------------------------------
; ON ERROR
; Taken from CP/M MBASIC 80 - BINTRP.MAC
;----------------------------------------------------------------------------
;;; ## ON ERROR / ERROR ##
;;; BASIC error handling function and codes
;;; ### FORMAT: ###
;;;  - ON ERROR GOTO < line number >
;;;    - Action: details
;;; ### EXAMPLE: ###
;;; ` 10 ON ERROR GOTO 900 `
;;;
;;; ` 20 NEXT `
;;;
;;; ` 30 REM I get skipped `
;;;
;;; ` 100 PRINT ERROR (0) `
;;;
;;; ` 110 PRINT ERROR (1) `
;;;
;;; ` 120 PRINT ERROR (2) `
;;; > Sets line 100 as the error handler, forces an error (NEXT without FOR) in line 20, then jumps to 100 and prints `100` for the error handler line, then the error number, then the line the error occured on `20`.
;----------------------------------------------------------------------------

ONGOTX: pop     hl              ; Discard Hook Return Addres
        pop     af              ; Restore Accumulator
        pop     hl              ; Restore Text Pointer
        cp      ERRTK           ; "ON...ERROR"?
        jr      nz,.noerr       ; NO. Do ON GOTO
        inc     hl              ; Check Following Byte
        ld      a,(hl)          ; Don't Skip Spaces
        cp      (ORTK)          ; Cheat: ERROR = ERR + OR
        jr      z,.onerr        ; If not ERROR
        dec     hl              ; Back up to ERR Token
        dec     hl              ; to process as Function
.noerr: jp      NTOERR          ; and do ON ... GOTO
.onerr: rst     CHRGET          ; GET NEXT THING
        rst     SYNCHR          ; MUST HAVE ...GOTO
        db      GOTOTK
        call    SCNLIN          ; GET FOLLOWING LINE #
        ld      a,d             ; IS LINE NUMBER ZERO?
        or      e               ; SEE
        jr      z,RESTRP        ; IF ON ERROR GOTO 0, RESET TRAP
        push    hl              ; SAVE [H,L] ON STACK
        call    FNDLIN          ; SEE IF LINE EXISTS
        ld      d,b             ; GET POINTER TO LINE IN [D,E]
        ld      e,c             ; (LINK FIELD OF LINE)
        pop     hl              ; RESTORE [H,L]
        jp      nc,USERR        ; ERROR IF LINE NOT FOUND
RESTRP: ld      (ONELIN),de     ; SAVE POINTER TO LINE OR ZERO IF 0.
        ret     c               ; YOU WOULDN'T BELIEVE IT IF I TOLD YOU
        ld      a,(ONEFLG)      ; ARE WE IN AN "ON...ERROR" ROUTINE?
        or      a               ; SET CONDITION CODES
        ret     z               ; IF NOT, HAVE ALREADY DISABLED TRAPPING.
        ld      a,(ERRFLG)      ; GET ERROR CODE
        ld      e,a             ; INTO E.
        jp      ERRCRD          ; FORCE THE ERROR TO HAPPEN

;----------------------------------------------------------------------------
; ERROR Hook Routine for Error Trapping
; Taken from CP/M MBASIC 80 - BINTRP.MAC
;----------------------------------------------------------------------------

ERRORX: ;call    break 
        ld      hl,(CURLIN)     ; GET CURRENT LINE NUMBER
        ld      (ERRLIN),hl     ; SAVE IT FOR ERL VARIABLE
        ld      a,e             ; Get Error Table Offset
        ld      c,e             ; ALSO SAVE IT FOR LATER RESTORE
        srl     a               ; Divide by 2 and add 1 so
        inc     a               ; [A]=ERROR NUMBER
        ld      (ERRFLG),a      ; Save it for ERR() Function
        ld      hl,(ERRLIN)     ; GET ERROR LINE #
        ld      a,h             ; TEST IF DIRECT LINE
        and     l               ; SET CC'S
        inc     a               ; SETS ZERO IF DIRECT LINE (65535)
        ld      hl,(ONELIN)     ; SEE IF WE ARE TRAPPING ERRORS.
        ld      a,h             ; BY CHECKING FOR LINE ZERO.
        ORA     l               ; IS IT?
        ex      de,hl           ; PUT LINE TO GO TO IN [D,E]
        ld      hl,ONEFLG       ; POINT TO ERROR FLAG
        jr      z,NOTRAP        ; SORRY, NO TRAPPING...
        and     (hl)            ; A IS NON-ZERO, SETZERO IF ONEFLG ZERO
        jr      nz,NOTRAP       ; IF FLAG ALREADY SET, FORCE ERROR
        dec     (hl)            ; IF ALREADY IN ERROR ROUTINE, FORCE ERROR
        ex      de,hl           ; GET LINE POINTER IN [H,L]
        jp      GONE4           ; GO DIRECTLY TO NEWSTT CODE
NOTRAP: xor     a               ; A MUST BE ZERO FOR CONTRO
        ld      (hl),a          ; RESET 3
        ld      e,c             ; GET BACK ERROR CODE
        jp      ERRCRD          ; FORCE THE ERROR TO HAPPEN

;----------------------------------------------------------------------------
; ERR Function
;----------------------------------------------------------------------------
FN_ERR: call    InitFN          ; Parse Arg and set return address
        call    CONINT          ; Convert to Byte
        or      a               ; If 0
        jr      z,.onelin       ;   Return Error Trap Line Number
        dec     a               ; If 1
        jr      z,.errno        ;   Return Error Number
        dec     a               ; If 2
        jr      z,.errlin       ;   Return Error Line Number
        dec     a               ; If 3
        jr      z,.doserr       ;   Return Error Line Number
        jp      FCERR           ; Else FC Error
.onelin:
        ld      hl,(ONELIN)     ; Get Error Line Pointer
        ld      a,h
        or      a,l             ; If 0
        jr      z,.ret_a        ;   Return 0
        inc     hl              ; Point to Line Number
        inc     hl 
        jp      FLOAT_M         ; Float Word at [HL] and Return
.errno:
        ld      a,(ERRFLG)      ; Get Error Table Offset
.ret_a  jp      SNGFLT          ; and Float it
.errlin:
        ld      de,(ERRLIN)     ; Get Error Line Number
        jp      FLOAT_DE        ; Float It
.doserr:
        ld      a,(DosError)    ; Get DOS Error Number
        jr      .ret_a

;----------------------------------------------------------------------------
;;; ## CLEAR Statement ##
;;; Clear Variables and/or Error Code
;;; ### FORMAT: ###
;;;  - CLEAR [ < number >, [ < address > ] ]
;;;    - Action: Clears all variables and arrays, last arror number and line. 
;;;      - If <number> is specified allocates string space.
;;;        - BASIC starts with 1024 bytes of string space allocated.
;;;      - If <address> is specified, sets top of BASIC memory.
;;;        - If 0, set to start of system variables minus one
;;;        - FC Error if less than end of BASIC program plus 40 bytes
;;;        - FC Error if greater than or equal to start of system variables
;;;  - CLEAR ERR
;;;    - Action: Clears last error number and line.
;;;      - Leaves variables and arrays intact.
;;; ### EXAMPLES: ###
;;; ` CLEAR xxx, yyy `
;;; > Details of this example
;;;
;;; ` CLEAR bbb
;;; > Details of this example
;----------------------------------------------------------------------------
;CLEAR statement hook

CLEARX: ld      b,4             ; Clear ERRLIN,ERRFLG,ONEFLG
        call    CLERR
        pop     af              ; Discard Hook Return Addres
        pop     af              ; Restore Accumulator
        pop     hl              ; Get Text Pointer
        jp      z,CLEARC        ; IF NO arguments JUST CLEAR
        cp      ERRTK           ; If CLEAR ERR?
        jp      nz,.args        ;   
        rst     CHRGET          ;   Skip ERR Token, Eat Spaces
        ret                     ;   and Return
.args:  call    INTID2          ; GET AN INTEGER INTO [D,E] 
        dec     hl              ;
        rst     CHRGET          ; SEE IF ITS THE END 
        push    hl              ;
        ld      hl,(MEMSIZ)     ; GET HIGHEST ADDRESS
        jp      z,CLEARS        ; SHOULD FINISH THERE
        pop     hl              ;
        SYNCHK  ','             ;
        push    de              ; Save String Size
        call    GETADR          ; Get Top of Memory
        dec     hl              ;
        rst     CHRGET          ;
        jp      nz,SNERR        ; IF NOT TERMINATOR, GOOD BYE  
        ex      (sp),hl         ; Get String Size, Save Text Pointer
        push    hl              ; Put String Size back on Stack
        ex      de,hl           ; HL = Top of Memory
        ld      de,vars         ; DE = Start of Protected Memory
        ld      a,h             ; 
        or      l               ; 
        jp      nz,.check       ; If HL = 0
        ex      de,hl           ;   Set Top of Memory
        dec     hl              ;   to One Less Start of Protected
        jr      .clear          ; Else
.check: rst     COMPAR          ;   If Top >= Protected
.fcerr: jp      nc,FCERR        ;     FC Error
.clear: pop     de              ; Get String Space into DE
        jp      CLEARS          ; Set VARTAB, TOPMEM, and MEMSIZ then return

;NEW statement hook
SCRTCX: pop     hl              ; Get Hook Return Addres
        pop     af              ; Discard Accumulator
        ex      (sp),hl         ; Discard Text Pointer, Push Return Address
CLNERR: ld      b,6             ; Clear ERRLIN,ERRFLG,ONEFLG,ONELIN
CLERR:  call    dos__clearError ; returns A = 0
        ld      hl,ERRLIN
.zloop: ld      (hl),a
        inc     hl
        djnz    .zloop
        ret
