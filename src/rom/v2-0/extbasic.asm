;====================================================================
; Mattel Aquarius Extended BASIC Statements and Functions
;====================================================================
;
;----------------------------------------------------------------------------
;;; ---
;;; ## DEF FN / FN
;;; Define User Function
;;; ### FORMAT:
;;;   - DEF FN < name > ( < variable > ) = < expression >
;;;     - Action: This sets up a user-defined function that can be used later in the program. The function can consist of any mathematical formula. User-defined functions save space in programs where a long formula is used in several places. The formula need only be specified once, in the definition statement, and then it is abbreviated as a function name. It must be executed once, but any subsequent executions are ignored.
;;;       - The function name is the letters FN followed by any variable name. This can be 1 or 2 characters, the first being a letter and the second a letter or digit.
;;;       - The parametern < variable > represents the argument variable or value that will be given in the function call and does not affect any program variable with the same name. For any other variable name in < expression >, the value of that program variable is used.
;;;       - A DEF FN statement must be executed before the function it defines may be called. If a function is called before it has been defined, an "Undefined user function" error occurs.
;;;       - Multiple user functions may be defined at once, each with a unique FN name. Executing a DEF with the same FN name as a previously defined user function replaces the previous definition with the new one. DEF FN is illegal in direct mode.
;;;       - The function is called later in the program by using the function name with a variable in parentheses. This function name is used like any other variable, and its value is automatically calculated.
;;; ### EXAMPLES:
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
DEFX:   ;pop      bc             ; clean up stack              
        ;pop      af              
        ;pop      hl              
        call    GETFNM          ; GET A POINTER TO THE FUNCTION NAME
        call    ERRDIR          ; DEF IS "ILLEGAL DIRECT"
        ld      bc,DATA          ; MEMORY, RESTORE THE TXTPTRAND GO TO "DATA" 
        push    bc              ; SKIPPING THE REST OF THE FORMULA
        push    de              
        SYNCHK  '('              ;{GWB} SKIP OVER OPEN PAREN
        call    PTRGET          ; GET POINTER TO DUMMY VAR(CREATE VAR)
        push    hl              
        ex      de,hl            
        dec      hl              
        ld      d,(hl)          
        dec      hl              
        ld      e,(hl)          
        pop      hl              
        call    CHKNUM          
        SYNCHK  ')'              ;{M80} MUST BE FOLLOWED BY )
        rst      SYNCHR
        db      EQUATK
        ld      b,h              
        ld      c,l              
        ex      (sp),hl          
        ld      (hl),c          
        inc      hl              
        ld      (hl),b          
        jp      STRADX           

FNDOEX: ;pop      bc              
        ;pop      af              
        ;pop      hl              
        call    GETFNM          ; GET A POINTER TO THE FUNCTION NAME

        push    de                
        call    PARCHK          ;{M80} RECURSIVELY EVALUATE THE FORMULA
        call    CHKNUM          ;{M65} MUST BE NUMBER
        ex      (sp),hl         ; SAVE THE TEXT POINTER THAT POINTS PAST THE 
                                ; FUNCTION NAME IN THE CALL
        ld      e,(hl)          ;[H,L]=VALUE OF THE FUNCTION
        inc      hl              
        ld      d,(hl)          
        inc      hl              ; WHICH IS A TEXT POINTER AT THE FORMAL
        ld      a,d              ; PARAMETER LIST IN THE DEFINITION
        or      e                ; A ZERO TEXT POINTER MEANS THE FUNCTION 
                                 ; WAS NEVER DEFINED
        jp      z,UFERR          ; IF SO, GIVEN AN "UNDEFINED FUNCTION" ERROR
        ld      a,(hl)          
        inc      hl              
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
        pop      hl              
        call    FRMNUM          ;AND EVALUATE THE DEFINITION FORMULA
        dec      hl              ;CAN HAVE RECURSION AT THIS POINT
        rst      CHRGET          ;SEE IF THE STATEMENT ENDED RIGHT
        jp      nz,SNERR        ;THIS IS A CHEAT, SINCE THE LINE 
                                ;NUMBER OF THE ERROR WILL BE THE CALLERS
                                ;LINE # INSTEAD OF THE DEFINITIONS LINE #
        pop      hl              
        ld      (VARPNT),hl       
        pop      hl              
        ld      (FNPARM),hl       
        pop      hl              
        ld      (VARNAM),hl       
        pop      hl              ;GET BACK THE TEXT POINTER
        ret                      

; SUBROUTINE TO GET A POINTER TO A FUNCTION NAME
; 
GETFNM: rst      SYNCHR  
        db      FNTK            ;   MUST START WITH "FN"
        ld      a,128            ;   DONT ALLOW AN ARRAY
        ld      (SUBFLG),a      ;   DON'T RECOGNIZE THE "(" AS THE START OF AN ARRAY REFEREENCE
        or      (hl)            ;   PUT FUNCTION BIT ON
        ld      c,a              ;   GET FIRST CHARACTER INTO [C]
        call    PTRGT2          
        jp      CHKNUM          

;----------------------------------------------------------------------------
;;; ---
;;; ## ATN
;;; Arctangent
;;; ### FORMAT:
;;;   - ATN ( < number > )
;;;     - Action: This mathematical function returns the arctangent of the number. The result is the angle (in radians) whose tangent is the number given. The result is always in the range -pi/2 to +pi/2.
;;; ### EXAMPLES:
;;; ` PRINT ATN(1) `
;;; > Prints the arctangent of 1, a value of `0.785398`
;;;
;;; ` X = ATN(J)*180/ {pi} `
;;; > Defines variable X as the arctangent of another variable, J, divided by pi.
;----------------------------------------------------------------------------

ATN1:   ;pop      bc
        ;pop      af
        ;pop      hl
        rst      FSIGN            ; SEE IF ARG IS NEGATIVE
        call    m,PSHNEG        ; IF ARG IS NEGATIVE, USE:
        call    m,NEG            ;     ARCTAN(X)=-ARCTAN(-X
        ld      a,(FAC)          ; SEE IF FAC .GT. 1
        cp      129             
        jp      c,ATN2         

        ld      bc,$8100        ; GET THE CONSTANT 1
        ld      d,c              
        ld      e,c              ; COMPUTE RECIPROCAL TO USE THE IDENTITY:
        call    FDIV            ;    ARCTAN(X)=PI/2-ARCTAN(1/X)
        ld      hl,FSUBS        ; PUT FSUBS ON THE STACK SO WE WILL RETURN       
        push    hl              ;   TO IT AND SUBTRACT THE REULT FROM PI/2
ATN2:   ld      hl,ATNCON        ; EVALUATE APPROXIMATION POLYNOMIAL

        call    POLYX            
        ld      hl,PI2          ; GET POINTER TO PI/2 IN CASE WE HAVE TO
        ret                      ;   SUBTRACT THE RESULT FROM PI/2

;CONSTANTS FOR ATN
ATNCON: db    9                ;DEGREE
        db    $4A,$D7,$3B,$78 ; .002866226
        db    $02,$6E,$84,$7B ; -.01616574
        db    $FE,$C1,$2F,$7C ; .04290961
        db    $74,$31,$9A,$7D ; -.07528964
        db    $84,$3D,$5A,$7D ; .1065626
        db    $C8,$7F,$91,$7E ; -.142089
        db    $E4,$BB,$4C,$7E ; .1999355
        db    $6C,$AA,$AA,$7F ; -.3333315
        db    $00,$00,$00,$81 ; 1.0


;====================================================================
; Microsoft BASIC80 Extended BASIC Statements and Functions`
;====================================================================

;----------------------------------------------------------------------------
; ON ERROR
; Taken from CP/M MBASIC 80 - BINTRP.MAC
;----------------------------------------------------------------------------
;;; ---
;;; ## ON ERROR
;;; BASIC error handling function and codes
;;; ### FORMAT:
;;;   - ON ERROR GOTO < line number >
;;;     - Action: details
;;; ### EXAMPLE:
;;; ` 10 ON ERROR GOTO 100 `
;;;
;;; ` 20 NEXT `
;;;
;;; ` 30 REM I get skipped `
;;;
;;; ` 100 PRINT ERR(0) `
;;;
;;; ` 110 PRINT ERR(1) `
;;;
;;; ` 120 PRINT ERR(2) `
;;; > Sets line 100 as the error handler, forces an error (NEXT without FOR) in line 20, then jumps to 100 and prints `100` for the error handler line, then the error number, then the line the error occured on `20`.
;----------------------------------------------------------------------------

ONGOTX: ;pop      hl              ; Discard Hook Return Addres
        ;pop      af              ; Restore Accumulator
        ;pop      hl              ; Restore Text Pointer
        cp      ERRTK            ; "ON...ERROR"?
        jr      nz,.noerr        ; NO. Do ON GOTO
        inc      hl              ; Check Following Byte
        ld      a,(hl)          ; Don't Skip Spaces
        cp      (ORTK)          ; Cheat: ERROR = ERR + OR
        jr      z,.onerr        ; If not ERROR
        dec      hl              ; Back up to ERR Token
        dec      hl              ; to process as Function
.noerr: jp      NTOERR          ; and do ON ... GOTO
.onerr: rst      CHRGET          ; GET NEXT THING
        rst      SYNCHR          ; MUST HAVE ...GOTO
        db      GOTOTK
        call    SCNLIN          ; GET FOLLOWING LINE #
        ld      a,d              ; IS LINE NUMBER ZERO?
        or      e                ; SEE
        jr      z,RESTRP        ; IF ON ERROR GOTO 0, RESET TRAP
        push    hl              ; SAVE [H,L] ON STACK
        call    FNDLIN          ; SEE IF LINE EXISTS
        ld      d,b              ; GET POINTER TO LINE IN [D,E]
        ld      e,c              ; (LINK FIELD OF LINE)
        pop      hl              ; RESTORE [H,L]
        jp      nc,USERR        ; ERROR IF LINE NOT FOUND
RESTRP: ld      (ONELIN),de      ; SAVE POINTER TO LINE OR ZERO IF 0.
        ret      c                ; YOU WOULDN'T BELIEVE IT IF I TOLD YOU
        ld      a,(ONEFLG)      ; ARE WE IN AN "ON...ERROR" ROUTINE?
        or      a                ; SET CONDITION CODES
        ret      z                ; IF NOT, HAVE ALREADY DISABLED TRAPPING.
        ld      a,(ERRFLG)      ; GET ERROR CODE
        ld      e,a              ; INTO E.
        jp      ERRCRD          ; FORCE THE ERROR TO HAPPEN

;----------------------------------------------------------------------------
; ERROR Hook Routine for Error Trapping
; Taken from CP/M MBASIC 80 - BINTRP.MAC
;----------------------------------------------------------------------------

ERRORX: ld      hl,(CURLIN)      ; GET CURRENT LINE NUMBER
        ld      (ERRLIN),hl      ; SAVE IT FOR ERL VARIABLE
        ld      a,e              ; Get Error Table Offset
        ld      c,e              ; ALSO SAVE IT FOR LATER RESTORE
        srl      a                ; Divide by 2 and add 1 so
        inc      a                ; [A]=ERROR NUMBER
        ld      (ERRFLG),a      ; Save it for ERR() Function
        ld      hl,(ERRLIN)      ; GET ERROR LINE #
        ld      a,h              ; TEST IF DIRECT LINE
        and      l                ; SET CC'S
        inc      a                ; SETS ZERO IF DIRECT LINE (65535)
        ld      hl,(ONELIN)      ; SEE IF WE ARE TRAPPING ERRORS.
        ld      a,h              ; BY CHECKING FOR LINE ZERO.
        ORA      l                ; IS IT?
        ex      de,hl            ; PUT LINE TO GO TO IN [D,E]
        ld      hl,ONEFLG        ; POINT TO ERROR FLAG
        jr      z,NOTRAP        ; SORRY, NO TRAPPING...
        and      (hl)            ; A IS NON-ZERO, SETZERO IF ONEFLG ZERO
        jr      nz,NOTRAP        ; IF FLAG ALREADY SET, FORCE ERROR
        dec      (hl)            ; IF ALREADY IN ERROR ROUTINE, FORCE ERROR
        ex      de,hl            ; GET LINE POINTER IN [H,L]
        jp      GONE4            ; GO DIRECTLY TO NEWSTT CODE
NOTRAP: xor      a                ; A MUST BE ZERO FOR CONTRO
        ld      (hl),a          ; RESET 3
        ld      e,c              ; GET BACK ERROR CODE
        jp      ERRCRD          ; FORCE THE ERROR TO HAPPEN

;----------------------------------------------------------------------------
;;; ---
;;; ## ERR
;;; Error Status
;;; ### FORMAT:
;;;   - ERROR ( < number > )
;;;     - Action: Returns error status values.
;;;       - If <number> is 0, returns the line number to GOTO when an error occures.
;;;         - Returns 0 if no error trapping is disabled.
;;;       - If <number> is 1, returns the number corresponding to the last error.
;;;         - - Returns 0 if no error has occured.
;;;       - If <number> is 2, returns the line number the last error occured on.
;;;         - Returns 0 if no error has occured.
;;;         - Returns 65535 if the error occured in immediate mode.
;;;       - If <number> is 3, returns the number corresponding to the last DOS error.
;;;         - Returns 0 if the last DOS command completed successfully.
;;;
;;; ### Basic Error Numbers
;;; | Err# | Code | Description                   |
;;; |------|------|------------------------------|  
;;; |    1   |  NF  | NEXT without FOR             |
;;; |    2   |  SN  | Syntax error                 |
;;; |    3   |  RG  | RETURN without GOSUB         |
;;; |    4   |  OD  | Out of DATA                   |
;;; |    5   |  FC  | Function Call error           |
;;; |    6   |  OV  | Overflow                     |
;;; |    7   |  OM  | Out of Memory                 |
;;; |    8   |  UL  | Undefined Line number         |
;;; |    9   |  BS  | Bad Subscript                 |
;;; |   10   |  DD  | Re-DIMensioned array         |
;;; |   11   |  /0  | Division by Zero             |
;;; |   12   |  ID  | Illegal direct               |
;;; |   13   |  TM  | Type mismatch                 |
;;; |   14   |  OS  | Out of String space           |
;;; |   15   |  LS  | String too Long               |
;;; |   16   |  WT  | String formula too complex   |
;;; |   17   |  CN  | Cant CONTinue                 |
;;; |   18   |  UF  | UnDEFined FN function         |
;;; |   19   |  MO  | Missing operand               |
;;;
;;; ### DOS Error Numbers
;;; | Err# | Error Message       | Description                    |
;;; |------|---------------------|--------------------------------|
;;; |    1   | no CH376             | CH376 not responding            | 
;;; |    2   | no USB               | Not in USB mode                |
;;; |    3   | no disk             | USB Drive mount failed          |
;;; |    4   | invalid name         | Invalid DOS file name          |
;;; |    5   | file not found       | File does not exist            |
;;; |    6   | file empty           | File does not contain data      |
;;; |    7   | filetype mismatch   | File is not in CAQ format      |
;;; |    8   | remove dir error     | Unable to remove directory      |
;;; |    9   | read error           | Error while reading USB drive  |
;;; |   10   | write error         | Error while writing USB drive  |
;;; |   11   | file create error   | Unable to create file          |
;;; |   12   | directory not found | Unable to open directory        |
;;; |   13   | path too long       | Path is too long                |
;;; |   14   | disk error #xx       | Other disk error                |
;;;
;----------------------------------------------------------------------------
FN_ERR: call    PARCHK
        push    hl
        ld      bc,LABBCK
        push    bc
        call    CONINT          ; Convert to Byte
        or      a                ; If 0
        jr      z,.onelin        ;    Return Error Trap Line Number
        dec      a                ; If 1
        jr      z,.errno        ;    Return Error Number
        dec      a                ; If 2
        jr      z,.errlin        ;    Return Error Line Number
        dec      a                ; If 3
        jr      z,.doserr        ;    Return Error Line Number
        jp      FCERR            ; Else FC Error
.onelin:
        ld      hl,(ONELIN)      ; Get Error Line Pointer
        ld      a,h
        or      a,l              ; If 0
        jr      z,.ret_a        ;    Return 0
        inc      hl              ; Point to Line Number
        inc      hl 
        jp      FLOAT_M          ; Float Word at [HL] and Return
.errno:
        ld      a,(ERRFLG)      ; Get Error Table Offset
.ret_a  jp      SNGFLT          ; and Float it
.errlin:
        ld      de,(ERRLIN)      ; Get Error Line Number
        jp      FLOAT_DE        ; Float It
.doserr:
        ld      a,(DosError)    ; Get DOS Error Number
        jr      .ret_a

;----------------------------------------------------------------------------
;;; ---
;;; ## CLEAR
;;; Clear Variables and/or Error Code
;;; ### FORMAT:
;;;   - CLEAR [ < number >, [ < address > ] ]
;;;     - Action: Clears all variables and arrays, last arror number and line. 
;;;       - If <number> is specified allocates string space.
;;;         - BASIC starts with 1024 bytes of string space allocated.
;;;       - If <address> is specified, sets top of BASIC memory.
;;;         - If 0, set to start of system variables minus one
;;;         - FC Error if less than end of BASIC program plus 40 bytes
;;;         - FC Error if greater than or equal to start of system variables
;;;   - CLEAR ERR
;;;     - Action: Clears last error number and line.
;;;       - Leaves variables and arrays intact.
;;; ### EXAMPLES:
;;; ` CLEAR 2000 `
;;; > Reserves 2000 bytes of space for strings.
;;;
;;; ` CLEAR 100, $A000 `
;;; > Reserves 100 bytes for strings and sets top of BASIC memory to 40960
;;;
;;; ` CLEAR 500, 0 `
;;; > Reserves 500 bytes for strings and sets to the maximum allowed
;;;
;;; ` CLEAR ERR `
;;; > Sets last error number and line as returned by ERR(1) and ERR(2) to 0.
;----------------------------------------------------------------------------
;CLEAR statement hook

CLEARX: exx                     ; Save Registers
        ld      b,4             ; Clear ERRLIN,ERRFLG,ONEFLG
        call    CLERR           ; and Restore registers  
        jp      z,CLEARC        ; IF NO arguments JUST CLEAR
        cp      ERRTK           ; If CLEAR ERR?
        jp      nz,.args        ;    
        rst     CHRGET          ;    Skip ERR Token, Eat Spaces
        ret                     ;    and Return
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
        ex      de,hl           ;    Set Top of Memory
        dec     hl              ;    to One Less Start of Protected
        jr      .clear          ; Else
.check: rst     COMPAR          ;    If Top >= Protected
.fcerr: jp      nc,FCERR        ;      FC Error
.clear: pop     de              ; Get String Space into DE
        jp      CLEARS          ; Set VARTAB, TOPMEM, and MEMSIZ then return

;-------------------------------------------------------------------------
; NEW statement hook
SCRTCX: call    CLNERR
        jp      HOOK12+1

CLNERR: exx                     ; Save Registers
        ld      b,6             ; Clear ERRLIN,ERRFLG,ONEFLG,ONELIN
CLERR:  ex      af,af'
        call    dos__clearError ; returns A = 0
        ld      hl,ERRLIN
.zloop: ld      (hl),a
        inc      hl
        djnz    .zloop
        ex      af,af'
        exx                     ; Restore Registers                  
        ret

;----------------------------------------------------------------------------
;;; ---
;;; ## SWAP
;;; Swap variable contents.
;;; ### FORMAT:
;;;  - SWAP < variable >, < variable >
;;;    - Action: Exchanges the values of two variables.
;;;      - The variables must be of the same type or a TM error results.
;;; ### EXAMPLE:
;;; ``` 
;;;   10 A$=" ONE " : B$=" ALL ": C$="FOR"
;;;   20 PRINT A$ C$ B$
;;;   30 SWAP A$, B$
;;;   40 PRINT A$ C$ B$
;;;   RUN
;;;   ONE FOR ALL
;;;   ALL FOR ONE
;;; ```
;----------------------------------------------------------------------------
ST_SWAP:  
        call    PTRGET          ;[D,E]=POINTER AT VALUE #1
        push    de              ;SAVE THE POINTER AT VALUE #1
        push    hl              ;SAVE THE TEXT POINTER
        ld      hl,SWPTMP       ;TEMPORARY STORE LOCATION
        call    VMOVE           ;SWPTMP=VALUE #1
        ld      hl,ARYTAB       ;GET ARYTAB SO CHANGE CAN BE NOTED
        ex      (sp),hl         ;GET THE TEXT POINTER BACK AND SAVE CURRENT [ARYTAB]
        ld      a,(VALTYP)      ;Get Variable Type
        push    af              ;SAVE THE TYPE OF VALUE #1
        SYNCHK  ','             ;MAKE SURE THE VARIABLES ARE DELIMITED BY A COMMA
        call    PTRGET          ;[D,E]=POINTER AT VALUE #2
        pop     bc              ;[B]=TYPE OF VALUE #1
        ld      a,(VALTYP)      ;[A]=TYPE OF VALUE #2
        cmp     b               ;MAKE SURE THEY ARE THE SAME
        jp      nz,TMERR        ;IF NOT, "TYPE MISMATCH" ERROR
        ex      (sp),hl         ;[H,L]=OLD [ARYTAB] SAVE THE TEXT POINTER
        ex      de,hl           ;[D,E]=OLD [ARYTAB]
        push    hl              ;SAVE THE POINTER AT VALUE #2
        ld      hl,ARYTAB       ;GET NEW [ARYTAB]
        rst     COMPAR
        jp      nz,FCERR        ;IF ITS CHANGED, ERROR
        pop     de              ;[D,E]=POINTER AT VALUE #2
        pop     hl              ;[H,L]=TEXT POINTER
        ex      (sp),hl         ;SAVE THE TEXT POINTER ON THE STACK, [H,L]=POINTER AT VALUE #1
        push    de              ;SAVE THE POINTER AT VALUE #2
        call    VMOVE           ;TRANSFER VALUE #2 INTO VALUE #1'S OLD POSITION
        pop     hl              ;[H,L]=POINTER AT VALUE #2
        ld      de,SWPTMP       ;LOCATION OF VALUE #1
        call    VMOVE           ;TRANSFER SWPTMP=VALUE #1 INTO VALUE #2'S OLD POSITION
        pop     hl              ;GET THE TEXT POINTER BACK
        ret  

VMOVE:  ex      de,hl           ;MOVE VALUE FROM (DE) TO (HL). ALTERS B,C,D,E,H,L	
    			
MOVVFM: ld        bc,4          ;MOVE VALUE FROM (HL) TO (DE)
        ldir
        ret

;----------------------------------------------------------------------------
;;; ---
;;; ## ERASE
;;; Erase array.
;;; ### FORMAT:
;;;  - ERASE < array > [, < array > ...]
;;;    - Action: Eliminates array from program.
;;;      - Arrays may be redimensioned after they are ERASEd, or the previously allocated array spacein memory may be used for other purposes. 
;;;      - If an attempt is made to redimension an array without first ERASEing it, a "Redimensioned array" errors.
;;; ### EXAMPLES:
;;; ` ERASE A `
;;; > Removes array A() from memory.
;;;
;;; ` 10 DIM B$(20) `
;;;
;;; ` 20 ERASE B$ `
;;;
;;; ` 30 DIM B$(10) `
;;;
;;; > Dimensions B$ as a 20 unit string array, then ERASES it, then redimensions it as a 10 unit array.
;----------------------------------------------------------------------------
ST_ERASE:
        ld      a,1
        ld      (SUBFLG),a      ;THAT THIS IS "ERASE" CALLING PTRGET
        call    PTRGET          ;GO FIND OUT WHERE TO ERASE
        jp      nz,FCERR        ;PTRGET DID NOT FIND VARIABLE!
        push    hl              ;SAVE THE TEXT POINTER
        ld      (SUBFLG),a      ;ZERO OUT SUBFLG TO RESET "ERASE" FLAG
        ld      h,b             ;[B,C]=START OF ARRAY TO ERASE
        ld      l,c
        dec     bc              ;BACK UP TO THE FRONT
LPBKNM: ld      a,(bc)          ;GET A CHARACTER. ONLY THE COUNT HAS HIGH BIT=0
        dec     bc              ;SO LOOP UNTIL WE SKIP OVER THE COUNT
        or      a               ;SKIP ALL THE EXTRA CHARACTERS
        jp      m,LPBKNM
        dec     bc
        dec     bc
        add     hl,de           ;[H,L]=THE END OF THIS ARRAY ENTRY
        ex      de,hl           ;[D,E]=END OF THIS ARRAY
        ld      hl,(STREND)     ;[H,L]=LAST LOCATION TO MOVE UP
ERSLOP: rst     COMPAR          ;SEE IF THE LAST LOCATION IS GOING TO BE MOVED
        ld      a,(de)          ;DO THE MOVE
        ld      (bc),a
        inc     de              ;UPDATE THE POINTERS
        inc     bc
        jr      nz,ERSLOP       ;MOVE THE REST
        dec     bc
        ld      h,b             ;SETUP THE NEW STORAGE END POINTER
        ld      l,c
        ld      (STREND),hl
        pop     hl              ;GET BACK THE TEXT POINTER
        ld      a,(hl)          ;SEE IF MORE ERASURES NEEDED
        cp      ','             ;ADDITIONAL VARIABLES DELIMITED BY COMMA
        ret     nz              ;ALL DONE IF NOT
        rst     CHRGET
        jr      ST_ERASE

;----------------------------------------------------------------------------
;;; ---
;;; ## STRING$
;;; Create string of repeating characters.
;;; ### FORMAT: 
;;;  - STRING$ (< length >)
;;;    - Action: Returns a string of length < length > whose characters all spaces (ASCII code 32).
;;;  - STRING$ (< length >, < byte > )
;;;    - Action: Returns a string of length < length > whose characters all have ASCII code < byte >.
;;;  - STRING$ (< length >, < string > )
;;;    - Action: Returns a string of length < length > whose characters are all r the first character of < string >.
;;; ### EXAMPLES:
;;; ```
;;;   10 X$ = STRING$ {10 , 45) 
;;;   20 PRINT X$ "MONTHLY REPORT" X$ 
;;;   RUN
;;;   ----------MONTHLY REPORT----------
;;;   OK
;;; ```
FN_STRING: 
        rst     CHRGET          ;GET NEXT CHAR FOLLOWING "STRING$"
        SYNCHK  '('             ;MAKE SURE LEFT PAREN
        call    GETBYT          ;EVALUATE FIRST ARG (LENGTH)
        ld      a,(hl)          ;Check Next Character
        cp      ','             ;If No Comma
        jr      nz,SPACE        ;  Single Argument - Act Like SPACE$() Function
        rst     CHRGET          ;Else Skip Comma
        push    de              ;SAVE FIRST ARG (LENGTH)
        call    FRMEVL          ;GET FORMULA ARG 2
        SYNCHK  ')'             ;EXPECT RIGHT PAREN
        ex      (sp),hl         ;SAVE TEXT POINTER ON STACK, GET REP FACTOR
        push    hl              ;SAVE BACK REP FACTOR
        ld      a,(VALTYP)      ;GET TYPE OF ARG
        dec     a               ;Make 1 into 0
        jr      z,STRSTR        ;WAS A STRING
        call    CONINT          ;GET ASCII VALUE OF CHAR
        jp      CALSPA          ;NOW CALL SPACE CODE
STRSTR: call    ASC2            ;GET VALUE OF CHAR IN [A]
CALSPA: pop     de              ;GET REP FACTOR IN [E]
        CALL	SPACE2			      ;INTO SPACE CODE, PUT DUMMY ENTRY
SPACE:  SYNCHK  ')'             ;Require Right Paren after Single Argument
        push    hl              ;Save Text Pointer
        ld      a,' '           ;GET SPACE CHAR
        push    bc              ;Dummy Return Address for FINBCK to discard
SPACE2: push    af              ;SAVE CHAR
        ld      a,e             ;GET NUMBER OF CHARS IN [A]
        call    STRINI          ;GET A STRING THAT LONG
        ld      b,a             ;COUNT OF CHARS BACK IN [B]
        pop     af              ;GET BACK CHAR TO PUT IN STRING
        inc     b               ;TEST FOR NULL STRING
        dec     b
        jp      z,FINBCK        ;YES, ALL DONE
        ld      hl,(DSCTMP+2)   ;GET DESC. POINTER
SPLP:   ld      (hl),a          ;SAVE CHAR
        inc     hl              ;BUMP PTR
                                ;DECR COUNT
        djnz    SPLP            ;KEEP STORING CHAR
        jp      FINBCK          ;PUT TEMP DESC WHEN DONE
