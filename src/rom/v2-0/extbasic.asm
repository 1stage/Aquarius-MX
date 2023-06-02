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
DEFX:   call    GETFNM          ; GET A POINTER TO THE FUNCTION NAME
        call    ERRDIR          ; DEF IS "ILLEGAL DIRECT"
        ld      bc,DATA         ; MEMORY, RESTORE THE TXTPTRAND GO TO "DATA" 
        push    bc              ; SKIPPING THE REST OF THE FORMULA
        push    de              
        SYNCHK  '('             ; SKIP OVER OPEN PAREN
        call    PTRGET          ; GET POINTER TO DUMMY VAR(CREATE VAR)
        push    hl              
        ex      de,hl            
        dec     hl              
        ld      d,(hl)          
        dec     hl              
        ld      e,(hl)          
        pop     hl              
        call    CHKNUM          
        SYNCHK  ')'               ;{M80} MUST BE FOLLOWED BY )
        rst      SYNCHR
        db      EQUATK
        ld      b,h              
        ld      c,l              
        ex      (sp),hl          
        ld      (hl),c          
        inc     hl              
        ld      (hl),b          
        jp      STRADX           

FNDOEX: call    GETFNM            ; GET A POINTER TO THE FUNCTION NAME
        push    de                  
        call    PARCHK            ; RECURSIVELY EVALUATE THE FORMULA
        call    CHKNUM            ; MUST BE NUMBER
        ex      (sp),hl           ; SAVE THE TEXT POINTER THAT POINTS PAST THE 
                                  ; FUNCTION NAME IN THE CALL
        ld      e,(hl)            ; [H,L]=VALUE OF THE FUNCTION
        inc     hl                
        ld      d,(hl)            
        inc     hl                ; WHICH IS A TEXT POINTER AT THE FORMAL
        ld      a,d               ; PARAMETER LIST IN THE DEFINITION
        or      e                 ; A ZERO TEXT POINTER MEANS THE FUNCTION 
                                  ; WAS NEVER DEFINED
        jp      z,UFERR           ; IF SO, GIVEN AN "UNDEFINED FUNCTION" ERROR
        ld      a,(hl)          
        inc     hl              
        ld      h,(hl)          
        ld      l,a              
        push    hl                ; SAVE THE NEW VALUE FOR PRMSTK
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
        call    FRMNUM            ; AND EVALUATE THE DEFINITION FORMULA
        dec     hl                ; CAN HAVE RECURSION AT THIS POINT
        rst     CHRGET            ; SEE IF THE STATEMENT ENDED RIGHT
        jp      nz,SNERR          ; THIS IS A CHEAT, SINCE THE LINE 
                                  ; NUMBER OF THE ERROR WILL BE THE CALLERS
                                  ; LINE # INSTEAD OF THE DEFINITIONS LINE #
        pop     hl              
        ld      (VARPNT),hl       
        pop     hl              
        ld      (FNPARM),hl       
        pop     hl              
        ld      (VARNAM),hl       
        pop     hl                ; GET BACK THE TEXT POINTER
        ret                      

; SUBROUTINE TO GET A POINTER TO A FUNCTION NAME
; 
GETFNM: rst     SYNCHR  
        db      FNTK              ; MUST START WITH "FN"
        ld      a,128             ; DONT ALLOW AN ARRAY
        ld      (SUBFLG),a        ; DON'T RECOGNIZE THE "(" AS THE START OF AN ARRAY REFEREENCE
        or      (hl)              ; PUT FUNCTION BIT ON
        ld      c,a               ; GET FIRST CHARACTER INTO [C]
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
        rst     FSIGN             ; SEE IF ARG IS NEGATIVE
        call    m,PSHNEG          ; IF ARG IS NEGATIVE, USE:
        call    m,NEG             ;     ARCTAN(X)=-ARCTAN(-X
        ld      a,(FAC)           ; SEE IF FAC .GT. 1
        cp      129               
        jp      c,ATN2          
  
        ld      bc,$8100          ; GET THE CONSTANT 1
        ld      d,c                
        ld      e,c               ; COMPUTE RECIPROCAL TO USE THE IDENTITY:
        call    FDIV              ;    ARCTAN(X)=PI/2-ARCTAN(1/X)
        ld      hl,FSUBS          ; PUT FSUBS ON THE STACK SO WE WILL RETURN       
        push    hl                ;   TO IT AND SUBTRACT THE REULT FROM PI/2
ATN2:   ld      hl,ATNCON         ; EVALUATE APPROXIMATION POLYNOMIAL
  
        call    POLYX              
        ld      hl,PI2            ; GET POINTER TO PI/2 IN CASE WE HAVE TO
        ret                       ;   SUBTRACT THE RESULT FROM PI/2
  
;CONSTANTS FOR ATN  
ATNCON: db    9                   ;DEGREE
        db    $4A,$D7,$3B,$78     ; .002866226
        db    $02,$6E,$84,$7B     ; -.01616574
        db    $FE,$C1,$2F,$7C     ; .04290961
        db    $74,$31,$9A,$7D     ; -.07528964
        db    $84,$3D,$5A,$7D     ; .1065626
        db    $C8,$7F,$91,$7E     ; -.142089
        db    $E4,$BB,$4C,$7E     ; .1999355
        db    $6C,$AA,$AA,$7F     ; -.3333315
        db    $00,$00,$00,$81     ; 1.0


;----------------------------------------------------------------------------
;;; ---
;;; ## MENU
;;; Display and execute menu.
;;; ### FORMAT:
;;;   - MENU ( < xpos >,< ypos >) [, < spacing >;] < string > [,< string >,...] GOTO < line >, [,< line >...]
;;;     - Action: This mathematical function returns the arctangent of the number. The result is the angle (in radians) whose tangent is the number given. The result is always in the range -pi/2 to +pi/2.
;;; ### EXAMPLES:
;----------------------------------------------------------------------------
; This Statement appears to be unique to the Aquarius
ST_MENU:
        cp      '@'               ; ALLOW MEANINGLESS "@"
        call    z,CHRGTR          ; BY SKIPPING OVER IT
        call    SCANX             ; Scan Coordinates into [D,E]
        push    de                ; Push Coordinates onto Stack
        ld      e,1               ; Default Spacing (1) into [E]
        ld      a,(hl)            ; 
        cp      ','               ; If Next Character is a Comma
        jr      nz,MENU2          ;   Scan Optional Spacing Parameter
        rst     CHRGET            ;   Eat Comma
        call    GETBYT            ;   Scan Spacing in [E]
        push    de                ;   Push Options onto Stack
        SYNCHK  ';'               ;   Require a Semicolon
        pop     de                ;   Pop Options into [D,E]
MENU2:  ld      c,e               ; Copy Spacing into [C]
        ld      b,1               ; Init Counter to 1 ino B
        pop     de                ; Pop Coordinates into [D,E]
        push    de                ; Push Coordinates back onto Stack
        push    bc                ; Push Options onto Stack
        ; Evaluate and Print String
MENUS:  push    hl                ; Push Text Pointer onto Stack
        ex      de,hl             ; Swap Coordinates into [H,L]
        push    hl                ; Push Coordinates onto Stack
        call    MOVEIT            ; Move Cursor to Coordinates [H,L]
        ld      a,'.'
        rst     OUTCHR            ; Print a Period
        pop     hl                ; HL = Coords, Stack = Text Pointer, Options. Coords
        ex      (sp),hl           ; HL = Text Pointer, Stack = Coordinates
        call    FRMEVL            ; Evaluate a String
        push    hl                ; Stack = Text Pointer, Coords, Options. Coords
        call    FRESTR            ;[M80] FREE UP TEMP POINTED TO BY FACLO
        call    STRPRT            ; Print the String
        pop     hl                ; HL = Text Pointer, Stack =  Coords, Options. Coords
        pop     de                ; DE = Coords, Stack = Options. Coords
        pop     bc                ; BC = Options, Stack = Coords
        ld      a,(hl)
        cp      ','               ; Is Next Character a Comma?
        jr      nz,MENU3          ; If So
        ex      de,hl             ;   HL = Coords, DE = Text Pointer
        inc     b                 ;   Increment Option Counter
        call    ADDLC             ;   Add Spacing to Y
        push    bc                ;   Stack = Options, Coords
        push    hl                ;   Stack = Coords, Options, Coords
        ex      de,hl             ;   HL = Text Pointer, DE = Coords
        rst     CHRGET            ;   Eat Comma
        pop     de                ;   Get Back Coordinates
        jr      MENUS             ;   Scane Next String

;;BC = Options, DE = Coords, HL = Text Pointer, Stack = Coords
MENU3:  cp      GOTOTK            ; If Not GOTO
        jp      nz,SNERR          ; Syntax Error
        ex      (sp),hl           ; HL = Coords, Stack = Text Pointer
MENUT:  push    hl                ; Stack = Coords, Text Pointer
        push    bc                ; Stack = Options, Coorda, Text Pointer
        ld      e,0               ; Option Number = 0
MENUN:  call    MENUK             ; Get C/R or Space from Keyboard
        inc     e                 ; Increment Option Number
        jr      c,MENUG           ; If Space
        call    ADDLC             ;   Y = Y + Spacing
        dec     b                 ;   Decrement Option Count
        jr      nz,MENUN          ;   If Not Zero, Move to Next Optionb
        pop     bc                ;     BC = Options, HL = Coords
        pop     hl                ;     Stack = Text Pointer
        jr      MENUT             ;     Start Iver ar Top
MENUG:  pop     hl                ; Discard Options
        pop     hl                ; Discard Coords
        pop     hl                ; Restore Text Pointer
        jp      OMGOTO            ; Do ON [E] GOTO

;;Wait for C/R or Space, Return Carry Set if Return
MENUK:  push    bc                ; Save BC
        call    MOVEIT            ; Move Cursor to H,L
MENUL:  call    TRYIN             ; Get Character from Keyboard
        cp      13                ; If Carriage Return
        scf                       ;   Return Carry Set
        jr      z,MENUR             
        cp      ' '               ; If Not Space
        jr      nz,MENUL          ;   Loop
MENUR:  pop     bc                ; Restore BC
        ret

;;Get Coordinates for MENU Statement
;;Syntax: Coords
SCANX:  SYNCHK  '('               ; SKIP OVER OPEN PAREN
        call    GETBYT            ; SCAN X INTO [A]
        cp      38                ; If X > 38
        jr      nc,SCANX2         ;   Function Call Error`
        inc     a                 ; Bump X Past First Column
        push    af                ; SAVE WHILE SCANNING Y
        SYNCHK  ','               ; SCAN COMMA
        call    GETBYT            ; GET Y INTO [A]
        cp      37                ; If Y > 37
SCANX2: jp      nc,FCERR          ;   Function Call Error`
        pop     de                ; Get X into D
        inc     a                 ; Bump Y Past First Line
        ld      e,a               ; Put Y into E
        SYNCHK  ')'               ; SKIP OVER CLOSE PAREN
        ret

ADDLC:  ld      a,l               ; L = L + C
        add     a,c
        ld      l,a
        cp      24
        ret     c                 ; If L >= 24
        ld      l,23              ; L = 23
        ret

;====================================================================
; Microsoft BASIC80 Extended BASIC Statements and Functions
;====================================================================

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
; ON ERROR
; Taken from CP/M MBASIC 80 - BINTRP.MACm
ONGOTX: cp      ERRTK             ; "ON...ERROR"?
        jr      nz,.noerr         ; NO. Do ON GOTO
        inc      hl               ; Check Following Byte
        ld      a,(hl)            ; Don't Skip Spaces
        cp      (ORTK)            ; Cheat: ERROR = ERR + OR
        jr      z,.onerr          ; If not ERROR
        dec      hl               ; Back up to ERR Token
        dec      hl               ; to process as Function
.noerr: jp      NTOERR            ; and do ON ... GOTO
.onerr: rst     CHRGET            ; GET NEXT THING
        rst     SYNCHR            ; MUST HAVE ...GOTO
        db      GOTOTK  
        call    SCNLIN            ; GET FOLLOWING LINE #
        ld      a,d               ; IS LINE NUMBER ZERO?
        or      e                 ; SEE
        jr      z,RESTRP          ; IF ON ERROR GOTO 0, RESET TRAP
        push    hl                ; SAVE [H,L] ON STACK
        call    FNDLIN            ; SEE IF LINE EXISTS
        ld      d,b               ; GET POINTER TO LINE IN [D,E]
        ld      e,c               ; (LINK FIELD OF LINE)
        pop      hl               ; RESTORE [H,L]
        jp      nc,USERR          ; ERROR IF LINE NOT FOUND
RESTRP: ld      (ONELIN),de       ; SAVE POINTER TO LINE OR ZERO IF 0.
        ret      c                ; YOU WOULDN'T BELIEVE IT IF I TOLD YOU
        ld      a,(ONEFLG)        ; ARE WE IN AN "ON...ERROR" ROUTINE?
        or      a                 ; SET CONDITION CODES
        ret      z                ; IF NOT, HAVE ALREADY DISABLED TRAPPING.
        ld      a,(ERRFLG)        ; GET ERROR CODE
        ld      e,a               ; INTO E.
        jp      ERRCRD            ; FORCE THE ERROR TO HAPPEN

;----------------------------------------------------------------------------
; ERROR Hook Routine for Error Trapping
; Taken from CP/M MBASIC 80 - BINTRP.MAC
;----------------------------------------------------------------------------

ERRORX: ld      hl,(CURLIN)       ; GET CURRENT LINE NUMBER
        ld      (ERRLIN),hl       ; SAVE IT FOR ERL VARIABLE
        ld      a,e               ; Get Error Table Offset
        ld      c,e               ; ALSO SAVE IT FOR LATER RESTORE
        srl     a                 ; Divide by 2 and add 1 so
        inc     a                 ; [A]=ERROR NUMBER
        ld      (ERRFLG),a        ; Save it for ERR() Function
        ld      hl,(ERRLIN)       ; GET ERROR LINE #
        ld      a,h               ; TEST IF DIRECT LINE
        and     l                 ; SET CC'S
        inc     a                 ; SETS ZERO IF DIRECT LINE (65535)
        ld      hl,(ONELIN)       ; SEE IF WE ARE TRAPPING ERRORS.
        ld      a,h               ; BY CHECKING FOR LINE ZERO.
        or      l                 ; IS IT?
        ex      de,hl             ; PUT LINE TO GO TO IN [D,E]
        ld      hl,ONEFLG         ; POINT TO ERROR FLAG
        jr      z,NOTRAP          ; SORRY, NO TRAPPING...
        and     (hl)              ; A IS NON-ZERO, SETZERO IF ONEFLG ZERO
        jr      nz,NOTRAP         ; IF FLAG ALREADY SET, FORCE ERRO R
        dec     (hl)              ; IF ALREADY IN ERROR ROUTINE, FORCE ERROR
        ex      de,hl             ; GET LINE POINTER IN [H,L]
        jp      GONE4             ; GO DIRECTLY TO NEWSTT CODE
NOTRAP: xor     a                 ; A MUST BE ZERO FOR CONTRO
        ld      (hl),a            ; RESET 3
        ld      e,c               ; GET BACK ERROR CODE
        jp      ERRCRD            ; FORCE THE ERROR TO HAPPEN

;----------------------------------------------------------------------------
; Print Error Message Hook Routine
;----------------------------------------------------------------------------

ERRCRX: call    get_errcode_ptr   ; Get Pointer into Error Table
        jp      ERRPRT            ; Display Error and Return to Immediate Mode

;----------------------------------------------------------------------------
;;; ---
;;; ## ERR
;;; Error Status
;;; ### FORMAT:
;;;   - ERR ( < number > )
;;;     - Action: Returns error status values.
;;;       - If < number > is -1, returns the line number to GOTO when an error occures.
;;;         - Returns 0 if no error trapping is disabled.
;;;       - If < number > is 0, returns the number corresponding to the last error.
;;;         - - Returns 0 if no error has occured.
;;;       - If < number > is 1, returns the line number the last error occured on.
;;;         - Returns 0 if no error has occured.
;;;         - Returns 65535 if the error occured in immediate mode.
;;;       - If < number > is 2, returns the number corresponding to the last DOS error.
;;;         - Returns 0 if the last DOS command completed successfully.
;;;       - If < number > is 3, returns the status code of the last CH376 operation.
;;;         - This may not be directly related to the DOS error number.
;;;       - Returns FC Error if < number > is none of the above
;;;
;;; ### Basic Error Numbers
;;; | Err# | Code | Description                  |
;;; |------|------|------------------------------|  
;;; |   1  |  NF  | NEXT without FOR             |
;;; |   2  |  SN  | Syntax error                 |
;;; |   3  |  RG  | RETURN without GOSUB         |
;;; |   4  |  OD  | Out of DATA                  |
;;; |   5  |  FC  | Function Call error          |
;;; |   6  |  OV  | Overflow                     |
;;; |   7  |  OM  | Out of Memory                |
;;; |   8  |  UL  | Undefined Line number        |
;;; |   9  |  BS  | Bad Subscript                |
;;; |  10  |  DD  | Re-DIMensioned array         |
;;; |  11  |  /0  | Division by Zero             |
;;; |  12  |  ID  | Illegal direct               |
;;; |  13  |  TM  | Type mismatch                |
;;; |  14  |  OS  | Out of String space          |
;;; |  15  |  LS  | String too Long              |
;;; |  16  |  ST  | String formula too complex   |
;;; |  17  |  CN  | Cant CONTinue                |
;;; |  18  |  UF  | UnDEFined FN function        |
;;; |  19  |  MO  | Missing operand              |
;;; |  20  |  IO` | Disk I/O error               |
;;; |  21  |  UE  | Unprintable error            |
;;;
;;; ### DOS Error Numbers
;;; | Err# | Error Message       | Description                    |
;;; |------|---------------------|--------------------------------|
;;; |   1  | no CH376            | CH376 not responding           | 
;;; |   2  | no USB              | Not in USB mode                |
;;; |   3  | no disk             | USB Drive mount failed         |
;;; |   4  | invalid name        | Invalid DOS file name          |
;;; |   5  | file not found      | File does not exist            |
;;; |   6  | file empty          | File does not contain data     |
;;; |   7  | filetype mismatch   | File is not in CAQ format      |
;;; |   8  | remove dir error    | Unable to remove directory     |
;;; |   9  | read error          | Error while reading USB drive  |
;;; |  10  | write error         | Error while writing USB drive  |
;;; |  11  | file create error   | Unable to create file          |
;;; |  12  | directory not found | Unable to open directory       |
;;; |  13  | path too long       | Path is too long               |
;;; |  14  | disk error #xx      | Other disk error               |
;;;
;----------------------------------------------------------------------------
FN_ERR: rst     CHRGET            ; Skip ERR Token
        cp      '$'               ; If Next Character is $
        jr      z,FN_ERRS      ;   Do ERR$() instead
        call    PARCHK            ; Evaluate Argument
        push    hl                ; Save Test Pointer
        ld      bc,LABBCK         ; Put Return Address for FLOAT routine
        push    bc                ;   on Stack
        call    FRCINT            ; Convert to Signed Integer
        ld      a,e               ; Get LSB into A
        or      a                 ; If Negative
        jp      m,.onelin         ;    Return Error Trap Line Number
        cp      1                 ; Else If 1
        jr      z,.errlin         ;    Return Error Line Number
        call    get_errno         ; Else get the correspoding Error Number
.ret_a:
        jp      SNGFLT            ; and Float it
.onelin:
        ld      hl,(ONELIN)       ; Get Error Line Pointer
        ld      a,h 
        or      a,l               ; If 0
        jr      z,.ret_a          ;    Return 0
        inc     hl                ; Point to Line Number
        inc     hl   
        jp      FLOAT_M           ; Float Word at [HL] and Return
.errlin:
        ld      de,(ERRLIN)       ; Get Error Line Number
        jp      FLOAT_DE          ; Float It
; Get Error # corresponding to ERR() or ERR$() argument
get_errno:     
        or      a                 ; Test Error Index
        ld      c,a               ; and copy into C
        ld      a,(ERRFLG)        ; Return Error Number
        ret     z                 ; if Index is 0
        dec     c                 ; or Index is 1
        ret     z                 ; 
        ld      a,(DosError)      ; Return DOS Error Number
        dec     c                 ; or Index is 2
        ret     z                 ; 
        ld      a,(ChStatus)      ; Get DOS Error Number
        dec     c                 ; or Index is 3
        ret     z                 ; 
        jp      FCERR             ; FCERR if none of the above
        
;----------------------------------------------------------------------------
;;; ---
;;; ## ERR$
;;; Error Status
;;; ### FORMAT:
;;;   - ERR$ ( < number > [, *error*] )
;;;     - Action: Returns string containing description of error
;;;       - If < number > is 0, returns a two character BASIC error code.
;;;       - If < number > is 1, returns a BASIC error description
;;;       - If < number > is 2, returns a DOS error description
;;;     - If second argument *error* is included, prints the description for that error number.
;;;       - Otherwise, prints the description corresponding to the value returned by ERR(< number >).
;;;       - Returns an empty string if *error* or ERR(< number >) is 0.
;;;       - Returns FC Error if *error* or ERR(< number >) is less than 0.
;----------------------------------------------------------------------------
FN_ERRS:
        rst     CHRGET            ; Skip $
        call    FRMPRN            ; Evaluate formula after left parenthesis
        push    hl                ; Stack = Text Pointer
        call    CONINT            ; Convert Argument to Byte
        pop     hl                ; HL = Text Pointer`
        push    af                ; Stack = First Arg
        ld      b,a               ; B = First Arg
        ld      a,(hl)            ; Get Next Character
        cp      ','               ; Check It
        jr      nz,.notcomma      ; If it's a commaa
        call    GTBYTC            ;   Skip it and Evaluate Formula into A
        jr      .err_offset       ;
.notcomma                         ; Else
        ld      a,b               ;   Get First Arg Back
        call    get_errno         ;   Get Error Number correspoding to Argument
.err_offset
        pop     bc                ; B = First Arg
        ld      c,a               ; E = Error #
        rst     SYNCHR            ; Require Right Parenthesis
        db      ')'               
        push    hl                ; Stack = Text Pointer
        push    bc                ; Stack = Dummy Return Address, Text Pointer
        ld      a,c               ; Get Error Number
        or      a                 ; If 0
        jp      z,null_string     ;   Return Null String
        dec     a                 ; Change Error Number to Byte Offset
        add     a,a               ; Turn Byte Offset Into Word Offset
        ld      e,a               ; Save Offset in E
        ld      d,0               
        ld      a,b               ; Get First Arg
        or      a                 ; If 0
        jr      z,.err_code       ;   Return Error Code
        dec     a                 ; If 1
        jr      z,.err_message    ;   Return Error Message
        dec     a                 ; If 2
        jr      z,.dos_error      ;   Return Dos Error Message
        jp      FCERR             ; Else FC Error
.err_code
        ld      (FBUFFR+2),a      ; Preload String Terminator into Buffer
        call    get_errcode_ptr   ; Get Pointer to Error Code for E
        ld      a,(hl)            ; Copy First Character
        ld      (FBUFFR),a        ; to Buffer
        inc     hl
        ld      a,(hl)            ; Copy Second Character
        ld      (FBUFFR+1),a      ; to Buffer
        ld      hl,FBUFFR         ; Get Buffer Address for TIMSTR
        jp      TIMSTR            ; Return It
.err_message
        call    get_errmsg_ptr    ; Get Pointer to Error Message String
        jp      TIMSTR            ; Return Error Message String
.dos_error:
        ld      a,c               ; Get Back Error Number
        call    dos__lookup_error ; Get DOS Error Message
        jp      TIMSTR            ; Return as String
        
        
;----------------------------------------------------------------------------
;;; ---
;;; ## ERROR
;;; Trigger a BASIC Error
;;; ### FORMAT:
;;;  - ERROR *error*
;;;    - Action: Triggers a BASIC Error.
;;;      - *error* is the error number of the error to trigger (see ERR function)
;;;      - FC Error results if *error* is not between 0 and 255, inclusive
;;;      - if *error* is 0, no error is triggered
;;; ### EXAMPLES:
;----------------------------------------------------------------------------

ST_ERR:
    rst     SYNCHR                ; Require OR Tokem
    db      ORTK                  ;   for ERROR
    call    GETBYT                ; Parse error number
    or      a                     ; If it's zero
    ret     z                     ;   Proceed with next statement
    dec     a                     ; Else 
    add     a                     ;   convert to error OFFSET
    ld      e,a                   ;   Put it in E
    jp      ERROR                 ;   and trigger error

;----------------------------------------------------------------------------
;;; ---
;;; ## CLEAR
;;; Clear Variables and/or Error Code
;;; ### FORMAT:
;;;   - CLEAR [ < number >, [ < address > ] ]
;;;     - Action: Clears all variables and arrays, last arror number and line. 
;;;       - If < number > is specified allocates string space.
;;;         - BASIC starts with 1024 bytes of string space allocated.
;;;       - If < address > is specified, sets top of BASIC memory.
;;;         - If 0, set to start of system variables minus one
;;;         - FC Error if less than end of BASIC program plus 40 bytes
;;;         - FC Error if greater than or equal to start of system variables
;;;   - CLEAR ERR
;;;     - Action: Clears last error number and line.
;;;       - Leaves variables and arrays intact.
;;;   - CLEAR DIM < array > [, < array > ...]
;;;    - Action: Eliminates array from program.
;;;      - Arrays may be redimensioned after they are ERASEd, or the previously allocated array spacein memory may be used for other purposes. 
;;;      - If an attempt is made to redimension an array without first ERASEing it, a "Redimensioned array" errors.
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
;;;
;;; ` CLEAR DIM A `
;;; > Removes array A() from memory.
;;;
;;; ` 10 DIM B$(20) `
;;; ` 20 CLEAR DIM B$ `
;;; ` 30 DIM B$(10) `
;;; > Dimensions B$ as a 20 unit string array, then ERASES it, then redimensions it as a 10 unit array.
;----------------------------------------------------------------------------
;CLEAR statement hook

CLEARX: cp      DIMTK             ; If CLEAR DIM
        jp      z,ST_ERASE        ;   Do BASIC80 ERASE
        exx                       ; Save Registers
        ld      b,4               ; Clear ERRLIN,ERRFLG,ONEFLG
        call    CLERR             ; and Restore registers  
        or      a 
        jp      z,CLEARC          ; IF NO arguments JUST CLEAR
        cp      ERRTK             ; If CLEAR ERR?
        jp      nz,.args          ;    
        rst     CHRGET            ;    Skip ERR Token, Eat Spaces
        ret                       ;    and Return
.args:  call    INTID2            ; GET AN INTEGER INTO [D,E] 
        dec     hl                ;
        rst     CHRGET            ; SEE IF ITS THE END 
        push    hl                ;
        ld      hl,(MEMSIZ)       ; GET HIGHEST ADDRESS
        jp      z,CLEARS          ; SHOULD FINISH THERE
        pop     hl                ;
        SYNCHK  ','               ;
        push    de                ; Save String Size
        call    GETADR            ; Get Top of Memory
        dec     hl                ;
        rst     CHRGET            ;
        jp      nz,SNERR          ; IF NOT TERMINATOR, GOOD BYE   
        ex      (sp),hl           ; Get String Size, Save Text Pointer
        push    hl                ; Put String Size back on Stack
        ex      de,hl             ; HL = Top of Memory
        ld      de,vars           ; DE = Start of Protected Memory
        ld      a,h               ; 
        or      l                 ; 
        jp      nz,.check         ; If HL = 0
        ex      de,hl             ;    Set Top of Memory
        dec     hl                ;    to One Less Start of Protected
        jr      .clear            ; Else
.check: rst     COMPAR            ;    If Top >= Protected
.fcerr: jp      nc,FCERR          ;      FC Error
.clear: pop     de                ; Get String Space into DE
        jp      CLEARS            ; Set VARTAB, TOPMEM, and MEMSIZ then return


;-------------------------------------------------------------------------
; NEW statement hook
SCRTCX: call    CLNERR
        jp      HOOK12+1

CLNERR: exx                       ; Save Registers
        ld      b,6               ; Clear ERRLIN,ERRFLG,ONEFLG,ONELIN
CLERR:  ex      af,af'  
        xor     a
        ld      (DosError),a
        ld      hl,ERRLIN 
.zloop: ld      (hl),a  
        inc      hl 
        djnz    .zloop  
        ex      af,af'  
        exx                       ; Restore Registers                  
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
        call    PTRGET            ;[D,E]=POINTER AT VALUE #1
        push    de                ;SAVE THE POINTER AT VALUE #1
        push    hl                ;SAVE THE TEXT POINTER
        ld      hl,SWPTMP         ;TEMPORARY STORE LOCATION
        call    VMOVE             ;SWPTMP=VALUE #1
        ld      hl,ARYTAB         ;GET ARYTAB SO CHANGE CAN BE NOTED
        ex      (sp),hl           ;GET THE TEXT POINTER BACK AND SAVE CURRENT [ARYTAB]
        ld      a,(VALTYP)        ;Get Variable Type
        push    af                ;SAVE THE TYPE OF VALUE #1
        SYNCHK  ','               ;MAKE SURE THE VARIABLES ARE DELIMITED BY A COMMA
        call    PTRGET            ;[D,E]=POINTER AT VALUE #2
        pop     bc                ;[B]=TYPE OF VALUE #1
        ld      a,(VALTYP)        ;[A]=TYPE OF VALUE #2
        cmp     b                 ;MAKE SURE THEY ARE THE SAME
        jp      nz,TMERR          ;IF NOT, "TYPE MISMATCH" ERROR
        ex      (sp),hl           ;[H,L]=OLD [ARYTAB] SAVE THE TEXT POINTER
        ex      de,hl             ;[D,E]=OLD [ARYTAB]
        push    hl                ;SAVE THE POINTER AT VALUE #2
        ld      hl,ARYTAB         ;GET NEW [ARYTAB]
        rst     COMPAR  
        jp      nz,FCERR          ;IF ITS CHANGED, ERROR
        pop     de                ;[D,E]=POINTER AT VALUE #2
        pop     hl                ;[H,L]=TEXT POINTER
        ex      (sp),hl           ;SAVE THE TEXT POINTER ON THE STACK, [H,L]=POINTER AT VALUE #1
        push    de                ;SAVE THE POINTER AT VALUE #2
        call    VMOVE             ;TRANSFER VALUE #2 INTO VALUE #1'S OLD POSITION
        pop     hl                ;[H,L]=POINTER AT VALUE #2
        ld      de,SWPTMP         ;LOCATION OF VALUE #1
        call    VMOVE             ;TRANSFER SWPTMP=VALUE #1 INTO VALUE #2'S OLD POSITION
        pop     hl                ;GET THE TEXT POINTER BACK
        ret   
  
VMOVE:  ex      de,hl             ;MOVE VALUE FROM (DE) TO (HL). ALTERS B,C,D,E,H,L  
            
MOVVFM: ld        bc,4            ;MOVE VALUE FROM (HL) TO (DE)
        ldir
        ret

ST_ERASE:
        rst     CHRGET            ;Skip DIM Token from CLEAR DIM
        ld      a,1 
        ld      (SUBFLG),a        ;THAT THIS IS "ERASE" CALLING PTRGET
        call    PTRGET            ;GO FIND OUT WHERE TO ERASE
        jp      nz,FCERR          ;PTRGET DID NOT FIND VARIABLE!
        push    hl                ;SAVE THE TEXT POINTER
        ld      (SUBFLG),a        ;ZERO OUT SUBFLG TO RESET "ERASE" FLAG
        ld      h,b               ;[B,C]=START OF ARRAY TO ERASE
        ld      l,c 
        dec     bc                ;BACK UP TO THE FRONT
LPBKNM: ld      a,(bc)            ;GET A CHARACTER. ONLY THE COUNT HAS HIGH BIT=0
        dec     bc                ;SO LOOP UNTIL WE SKIP OVER THE COUNT
        or      a                 ;SKIP ALL THE EXTRA CHARACTERS
        jp      m,LPBKNM  
        dec     bc  
        dec     bc  
        add     hl,de             ;[H,L]=THE END OF THIS ARRAY ENTRY
        ex      de,hl             ;[D,E]=END OF THIS ARRAY
        ld      hl,(STREND)       ;[H,L]=LAST LOCATION TO MOVE UP
ERSLOP: rst     COMPAR            ;SEE IF THE LAST LOCATION IS GOING TO BE MOVED
        ld      a,(de)            ;DO THE MOVE
        ld      (bc),a  
        inc     de                ;UPDATE THE POINTERS
        inc     bc  
        jr      nz,ERSLOP         ;MOVE THE REST
        dec     bc  
        ld      h,b               ;SETUP THE NEW STORAGE END POINTER
        ld      l,c 
        ld      (STREND),hl 
        pop     hl                ;GET BACK THE TEXT POINTER
        ld      a,(hl)            ;SEE IF MORE ERASURES NEEDED
        cp      ','               ;ADDITIONAL VARIABLES DELIMITED BY COMMA
        ret     nz                ;ALL DONE IF NOT
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
;;;   10 X$ = STRING$ (10 , 45) 
;;;   20 PRINT X$ "MONTHLY REPORT" X$ 
;;;   RUN
;;;   ----------MONTHLY REPORT----------
;;;   OK
;;; ```
FN_STRING: 
        rst     CHRGET
        SYNCHK  '('               ;MAKE SURE LEFT PAREN
        call    GETBYT            ;EVALUATE FIRST ARG (LENGTH)
        ld      a,(hl)            ;Check Next Character
        cp      ','               ;If No Comma
        jr      nz,SPACE          ;  Single Argument - Act Like SPACE$() Function
        rst     CHRGET            ;Else Skip Comma
        push    de                ;SAVE FIRST ARG (LENGTH)
        call    FRMEVL            ;GET FORMULA ARG 2
        SYNCHK  ')'               ;EXPECT RIGHT PAREN
        ex      (sp),hl           ;SAVE TEXT POINTER ON STACK, GET REP FACTOR
        push    hl                ;SAVE BACK REP FACTOR
        ld      a,(VALTYP)        ;GET TYPE OF ARG
        dec     a                 ;Make 1 into 0
        jr      z,STRSTR          ;WAS A STRING
        call    CONINT            ;GET ASCII VALUE OF CHAR
        jp      CALSPA            ;NOW CALL SPACE CODE
STRSTR: call    ASC2              ;GET VALUE OF CHAR IN [A]
CALSPA: pop     de                ;GET REP FACTOR IN [E]
        CALL  SPACE2              ;INTO SPACE CODE, PUT DUMMY ENTRY
SPACE:  SYNCHK  ')'               ;Require Right Paren after Single Argument
        push    hl                ;Save Text Pointer
        ld      a,' '             ;GET SPACE CHAR
        push    bc                ;Dummy Return Address for FINBCK to discard
SPACE2: push    af                ;SAVE CHAR
        ld      a,e               ;GET NUMBER OF CHARS IN [A]
        call    STRINI            ;GET A STRING THAT LONG
        ld      b,a               ;COUNT OF CHARS BACK IN [B]
        pop     af                ;GET BACK CHAR TO PUT IN STRING
        inc     b                 ;TEST FOR NULL STRING
        dec     b 
        jp      z,FINBCK          ;YES, ALL DONE
        ld      hl,(DSCTMP+2)     ;GET DESC. POINTER
SPLP:   ld      (hl),a            ;SAVE CHAR
        inc     hl                ;BUMP PTR
                                  ;DECR COUNT
        djnz    SPLP              ;KEEP STORING CHAR
        jp      FINBCK            ;PUT TEMP DESC WHEN DONE

;----------------------------------------------------------------------------
;;; ---
;;; ## INSTR Function
;;; Search for string in another string
;;; ### FORMAT: 
;;;  - INSTR ( [ *offset* , ] *string1* , *string2* )
;;;    - Action: Searches for the first occurrence of *string2* in *string1* and returns the position at which the match is found. 
;;;      - Optional *offset* sets the position for starting the search.
;;;        - Must be in the range 1 to 255 or an FC Error results.
;;;      - If *offset* > LEN(*string1*) or if *string1* is null or if *string2* cannot be found, INSTR returns 0.
;;;      - If *string2* is null, INSTR returns *offset* or 1.
;;;      - *string1* and *string2* may be string variables, string expressions or string literals.
;;; ### EXAMPLES:
;;; ```
;;;   10 X$ = "ABCDEB"
;;;   20 Y$ = "B"
;;;   30 PRINT INSTR(X$,Y$) ;INSTR(4,X$,y$)
;;; ```
;;; > Prints the numbers 2 and 6.
;----------------------------------------------------------------------------
; THIS IS THE INSTR FUCNTION. IT TAKES ONE OF TWO FORMS: INSTR(I%,S1$,S2$) OR INSTR(S1$,S2$)
; IN THE FIRST FORM THE STRING S1$ IS SEARCHED FOR THE CHARACTER S2$ STARTING AT CHARACTER POSITION I%.
; THE SECOND FORM IS IDENTICAL, EXCEPT THAT THE SEARCH STARTS AT POSITION 1. INSTR RETURNS THE CHARACTER
; POSITION OF THE FIRST OCCURANCE OF S2$ IN S1$. IF S1$ IS NULL, 0 IS RETURNED. IF S2$ IS NULL, THEN
; I% IS RETURNED, UNLESS I% .GT. LEN(S1$) IN WHICH CASE 0 IS RETURNED.
FN_INSTR:  
        rst     CHRGET            ;EAT FIRST CHAR
        call    FRMPRN            ;EVALUATE FIRST ARG
        call    GETYPR            ;SET ZERO IF ARG A STRING.                    AF     BC     DE     HL     Stack
        ld      a,1               ;IF SO, ASSUME, SEARCH STARTS AT FIRST CHAR   1                    TxtPtr 
        push    af                ;SAVE OFFSET IN CASE STRING                                               Offset
        jp      z,WUZSTR          ;WAS A STRING                                                             
        pop     af                ;GET RID OF SAVED OFFSET                      1                           --
        call    CONINT            ;FORCE ARG1 (I%) TO BE INTEGER                Offset               --            
        or      a                 ;DONT ALLOW ZERO OFFSET                                                   
        jp      z,FCERR           ;KILL HIM.                                                                
        push    af                ;SAVE FOR LATER                                                           Offset
        SYNCHK  ','               ;EAT THE COMMA                                --                            
        call    FRMEVL            ;EAT FIRST STRING ARG                                                     
        call    CHKSTR            ;BLOW UP IF NOT STRING                                                    
WUZSTR: SYNCHK  ','               ;EAT COMMA AFTER ARG                                                      
        push    hl                ;SAVE THE TEXT POINTER                                                    TxtPtr,Offset
        ld      hl,(FACLO)        ;GET DESCRIPTOR POINTER                                             Dsc1  
        ex      (sp),hl           ;PUT ON STACK & GET BACK TEXT PNT.                                 TxtPtr  Dsc1, Offset
        call    FRMEVL            ;GET LAST ARG                                                       ----       
        SYNCHK  ')'               ;EAT RIGHT PAREN                                                          
        push    hl                ;SAVE TEXT POINTER                                                        TxtPtr,Dsc1, Offset
        call    FRESTR            ;FREE UP TEMP & CHECK STRING                   ----   ----   ----   Dsc2       
        ex      de,hl             ;SAVE 2ND DESC. POINTER IN [D,E]                             Dsc2   ----              
        pop     bc                ;GET TEXT POINTER IN B                               TxtPtr                Dsc1, Offset
        pop     hl                ;DESC. POINTER FOR S1$                                              Dsc1  Offset
        pop     af                ;OFFSET                                       Offset                      --
        push    bc                ;PUT TEXT POINTER ON BOTTOM                                               TxtPtr
        ld      bc,POPHRT         ;PUT ADDRESS OF POP H, RET ON                        POPHRT                     
        push    bc                ;PUSH IT                                                                  POPHRT, TxtPtr
        ld      bc,SNGFLT         ;NOW ADDRESS OF [A] RETURNER                         SNGGLT                     
        push    bc                ;ONTO STACK                                                               SNGFLT, POPHRT. TxtPtr
        push    af                ;SAVE OFFSET BACK                                                         Offset, SNGFLT, POPHRT. TxtPtr
        push    de                ;SAVE DESC. OF S2                                                          Dsc2, Offset, SNGFLT, POPHRT. TxtPtr
        call    FRETM2            ;FREE UP S1 DESC.                              ----   ----   ----   Dsc1
        pop     de                ;RESTORE DESC. S2                                            Dsc2
        pop     af                ;GET BACK OFFSET                              Offset
        ld      b,a               ;SAVE UNMODIFIED OFFSET                              Of,O-1
        dec     a                 ;MAKE OFFSET OK                               
        ld      c,a               ;SAVE IN C                                    
        cp      (hl)              ;IS IT BEYOND LENGTH OF S1?                   
        ld      a,0               ;IF SO, RETURN ZERO. (ERROR)                    0
        ret     nc                                                              
        ld      a,(de)            ;GET LENGTH OF S2$                            Len_D2
        or      a                 ;NULL??                                       
        ld      a,b               ;GET OFFSET BACK                              Offset
        ret     z                 ;ALL IF S2 NULL, RETURN OFFSET                
        ld      a,(hl)            ;GET LENGTH OF S1$                            
        inc     hl                ;BUMP POINTER                                 
        inc     hl                ;BUMP POINTER                                 
        ld      b,(hl)            ;GET 1ST BYTE OF ADDRESS                      
        inc     hl                                                              
        ld      h,(hl)            ;GET 2ND BYTE                                 
        ld      l,b               ;GET 1ST BYTE SET UP                          
        ld      b,0               ;GET READY FOR DAD                            
        add     hl,bc             ;NOW INDEXING INTO STRING                     
        sub     c                 ;MAKE LENGTH OF STRING S1$ RIGHT              
        ld      b,a               ;SAVE LENGTH OF 1ST STRING IN [B]             
        push    bc                ;SAVE COUNTER, OFFSET                         
        push    de                ;PUT 2ND DESC (S2$) ON STACK                  
        ex      (sp),hl           ;GET 2ND DESC. POINTER                        
        ld      c,(hl)            ;SET UP LENGTH                                
        inc     hl                ;BUMP POINTER
        inc     hl                
        ld      e,(hl)            ;GET FIRST BYTE OF ADDRESS
        inc     hl                ;BUMP POINTER AGAIN
        ld      d,(hl)            ;GET 2ND BYTE
        pop     hl                ;RESTORE POINTER FOR 1ST STRING
          
CHK1:   push    hl                ;SAVE POSITION IN SEARCH STRING
        push    de                ;SAVE START OF SUBSTRING
        push    bc                ;SAVE WHERE WE STARTED SEARCH
CHK:    ld      a,(de)            ;GET CHAR FROM SUBSTRING
        cp      (hl)              ; = CHAR POINTER TO BY [H,L]
        jp      nz,OHWELL         ;NO
        inc     de                ;BUMP COMPARE POINTER
        dec     c                 ;END OF SEARCH STRING?
        jp      z,GOTSTR          ;WE FOUND IT!
        inc     hl                ;BUMP POINTER INTO STRING BEING SEARCHED
                                  ;DECREMENT LENGTH OF SEARCH STRING
        dec     b 
        jp      nz,CHK            ;END OF STRING, YOU LOSE
RETZER: pop     de                ;GET RID OF POINTERS
        pop     de                ;GET RID OF GARB
        pop     bc                ;LIKE SO
RETZR1: pop     de                
        xor     a                 ;GO TO SNGFLT.
        ret                       ;RETURN
  
GOTSTR: pop     hl  
        pop     de                ;GET RID OF GARB
        pop     de                ;GET RID OF EXCESS STACK
        pop     bc                ;GET COUNTER, OFFSET
        ld      a,b               ;GET ORIGINAL SOURCE COUNTER
        sub     h                 ;SUBTRACT FINAL COUNTER
        add     c                 ;ADD ORIGINAL OFFSET (N1%)
        inc     a                 ;MAKE OFFSET OF ZERO = POSIT 1
        ret                       ;DONE

OHWELL: pop     bc
        pop     de                ;POINT TO START OF SUBSTRING
        pop     hl                ;GET BACK WHERE WE STARTED TO COMPARE
        inc     hl                ;AND POINT TO NEXT CHAR
                                  ;DECR. # CHAR LEFT IN SOURCE STRING
        dec     b         
        jp      nz,CHK1           ;TRY SEARCHING SOME MORE
        jr      RETZR1            ;END OF STRING, RETURN 0
  
GETYPR: ld      a,(VALTYP)        ;REPLACEMENT FOR "GETYPE" RST
        dec     a               
        ret
        
        
        
;----------------------------------------------------------------------------
;;; ---
;;; ## MID$ Statement
;;;   Replace a portion of one string with another string.
;;; ### FORMAT:
;;;  - MID$ ( *var$* , *pos* [ , *len*] ) = *string*
;;;    - Action: The contents of string variable *var$*, beginning at position *pos*, are replaced by the characters in *string*
;;;      - if *pos* is less than 1 or more than 255, an FC error results
;;;      - The optional *len* refers to the number of characters from *string* that will be used in the replacement
;;;      - If *len* is omitted, all of *string* is used. 
;;;      - Regardless of whether *len* is omitted or included, the replacement of characters never goes beyond the original length of *var$*.
;;; ### EXAMPLES:
;;; ```
;;; 10 A$="KANSAS CITY, MO"
;;; 20 MID$(A$,14) ="KS"
;;; 30 PRINT A$
;;; ```
;;; > Prints ` KANSAS CITY, KS `
;----------------------------------------------------------------------------
; STRING FUNCTIONS - LEFT HAND SIDE MID$
ST_MID: SYNCHK  '('               ; MUST HAVE (                                      AF     BC     DE     HL   Stack
        call    PTRGET            ; GET A STRING VAR                               ------ ------  Dsc1  TxtPtr 
        call    CHKSTR            ; MAKE SURE IT WAS A STRING                         
        push    hl                ; SAVE TEXT POINTER                                                          TxtPtr
        push    de                ; SAVE DESC. POINTER                                                          Dsc1,TxtPtr
        ex      de,hl             ; PUT DESC. POINTER IN [H,L]                                   TxtPtr  Dsc1
        inc     hl                ; MOVE TO ADDRESS FIELD                                                 ++
        inc     hl                ; MOVE TO ADDRESS FIELD                                                 ++
        ld      e,(hl)            ; GET ADDRESS OF LHS IN [D,E]                                           
        inc     hl                ; BUMP DESC. POINTER                                                    ++
        ld      d,(hl)            ; PICK UP HIGH BYTE OF ADDRESS                                 Addr1
        ld      hl,(STREND)       ; SEE IF LHS STRING IS IN STRING SPACE                               (STREND)
        rst     COMPAR            ; BY COMPARING IT WITH STKTOP                     
        jr      c,NCPMID          ; IF ALREADY IN STRING SPACE DONT COPY.           
        pop     hl                ; GET BACK DESC. POINTER                                               Dsc1  TxtPtr
        push    hl                ; SAVE BACK ON STACK                                                          Dsc1,TxtPtr
        call    STRCPY            ; COPY THE STRING LITERAL INTO STRING SPACE                    DSCTMP  ~~
        pop     hl                ; GET BACK DESC. POINTER                                               Dsc1  TxtPtr
        push    hl                ; BACK ON STACK AGAIN                                                         Dsc1,TxtPtr
        call    VMOVE             ; MOVE NEW DESC. INTO OLD SLOT.                                  ~~    ~~
NCPMID: pop     hl                ; GET DESC. POINTER                                                    Dsc1  TxtPtr
        ex      (sp),hl           ; GET TEXT POINTER TO [H,L] DESC. TO STACK                            TxtPtr  Dsc1
        SYNCHK  ','               ; MUST HAVE COMMA
        call    GETBYT            ; GET ARG#2 (OFFSET INTO STRING)                 Arg2
        or      a                 ; MAKE SURE NOT ZERO
        jp      z,FCERR           ; BLOW HIM UP IF ZERO
        push    af                ; SAVE ARG#2 ON STACK                                                        Arg2,Dsc1
        ld      a,(hl)            ; RESTORE CURRENT CHAR                         (TxtPtr)
        ld      e,255             ; IF TWO ARG GUY, TRUNCATE.                                     255
        cp      ')'               ; [E] SAYS USE ALL CHARS 
        jp      z,.MID2           ; IF ONE ARGUMENT THIS IS CORRECT
        SYNCHK ','  
        call    GETBYT            ; GET ARGUMENT  IN  [E]                          Arg3           Arg3
.MID2:  SYNCHK  ')'               ; MUST BE FOLLOWED BY )                           ~~                         Arg3,Arg2,Dsc1
        push    de                ; SAVE THIRD ARG ([E]) ON STACK                 
                                  ; MUST HAVE = SIGN
        call    FRMEQL            ; EVALUATE RHS OF THING.
        push    hl                ; SAVE TEXT POINTER.                                                         TxtPtr,Arg3,Arg2,Dsc1
        call    FRESTR            ; FREE UP TEMP RHS IF ANY.                        ~~             ~~    Dsc2
        ex      de,hl             ; PUT RHS DESC. POINTER IN [D,E]                                Dsc2    ~~
        pop     hl                ; TEXT POINTER TO [H,L]                                               TxtPtr Arg3,Arg2,Dsc1
        pop     bc                ; ARG #3 TO C.                                           Arg3                Arg2,Dsc1
        pop     af                ; ARG #2 TO A.                                    Arg2                       Dsc1
        ld      b,a               ; AND [B]                                               A2  A3
        ex      (sp),hl           ; GET LHS DESC. POINTER TO [H,L]                                       Dsc1  TxtPtr    
                                  ; TEXT POINTER TO STACK                                 
        push    hl                ;                                                                            Dsc1,TxtPtr
        ld      hl,POPHRT         ; GET ADDR TO RETURN TO                                               POPHRT 
        ex      (sp),hl           ; SAVE ON STACK & GET BACK TXT PTR.                                    Dsc1  POPHRT,TxtPtr
        ld      a,c               ; GET ARG #3                                      Arg3
        or      a                 ; SET CC'S
        ret     z                 ; IF ZERO, DO NOTHING
        ld      a,(hl)            ; GET LENGTH OF LHS                              (Dsc1)
        sub     b                 ; SEE HOW MANY CHARS IN REMAINDER OF STRING
        jp      c,FCERR           ; CANT ASSIGN PAST LEN(LHS)!
        inc     a                 ; MAKE PROPER COUNT
        cp      c                 ; SEE IF # OF CHARS IS .GT. THIRD ARG
        jr      c,BIGLEN          ; IF SO, DONT TRUNCATE
        ld      a,c               ; TRUNCATE BY USING 3RD ARG.                      Arg3
BIGLEN: ld      c,b               ; GET OFFSET OF STRING IN [C]
        dec     c                 ; MAKE PROPER OFFSET                                    Arg2
        ld      b,0               ; SET UP [B,C] FOR LATER DAD B.
        push    de                ; SAVE [D,E]                                                                 Dsc2,POPHRT,TxtPtr
        inc     hl                                                                              
        inc     hl                ; POINTER TO ADDRESS FIELD.                                                      
        ld      e,(hl)            ; GET LOW BYTE IN [E]
        inc     hl                ; BUMP POINTER
        ld      h,(hl)            ; GET HIGH BYTE IN [H]
        ld      l,e               ; NOW COPY LOW BYTE BACK TO [L]                                        Txt1
        add     hl,bc             ; ADD OFFSET                                                          + Arg2
        ld      b,a               ; SET COUNT OF LHS IN [B]
        pop     de                ; RESTORE [D,E]                                                 Dsc2        POPHRT,TxtPtr  
        ex      de,hl             ; MOVE RHS. DESC. POINTER TO [H,L]
        ld      c,(hl)            ; GET LEN(RHS) IN [C]
        inc     hl                ; MOVE POINTER
        inc     hl                ; MOVE POINTER
        ld      a,(hl)            ; GET LOW BYTE OF ADDRESS IN [A]
        inc     hl                ; BUMP POINTER.
        ld      h,(hl)            ; GET HIGH BYTE OF ADDRESS IN [H]
        ld      l,a               ; COPY LOW BYTE TO [L]
        ex      de,hl             ; ADDRESS OF RHS NOW IN [D,E]
        ld      a,c               ; IS RHS NULL?
        or      a                 ; TEST
        ret     z                 ; THEN ALL DONE.
; NOW ALL SET UP FOR ASSIGNMENT.
; [H,L] = LHS POINTER
; [D,E] = RHS POINTER
; C = LEN(RHS)
; B = LEN(LHS)
.MIDLP: ld      a,(de)            ; GET BYTE FROM RHS.
        ld      (hl),a            ; STORE IN LHS
        inc     de                ; BUMP RHS POINTER
        inc     hl                ; BUMP LHS POINTER.
        dec     c                 ; BUMP DOWN COUNT OF RHS.
        ret     z                 ; IF ZERO, ALL DONE. IF LHS ENDED, ALSO DONE.
        djnz    .MIDLP            ; IF NOT DONE, MORE COPYING.
        ret                       ; BACK TO NEWSTT
  
;----------------------------------------------------------------------------
;;; ---
;;; ## EVAL
;;; Evaluate a formula in a string.
;;; ### FORMAT: 
;;;  - EVAL(< formula >)
;;;    - Action: Outputs the formula as a string
;;; ### EXAMPLES:
;;; ` PRINT EVAL("7 + 4") `
;;; > Prints "11"
;;;
;----------------------------------------------------------------------------
FN_EVAL:
        call    ERRDIR            ; Issue Error if in Direct Mode
        rst     CHRGET
        call    PARCHK            ; Get Argument
        push    hl                ; Save Text Pointer
        call    STRLENADR         ; Get Argument String Length in BC, Address in HL
        jp      m,LSERR           ; Error if longer than 127 bytes
        ld      de,LineBuf        ;
        ldir                      ; Copy String to Line Buffer
        xor     a
        ld      (de),a            ; Terminate String
        ld      hl,LineBuf        ; Reading Line Buffer
        ld      d,h               ; Writing Line Buffers
        ld      e,l 
        xor     a                 ; Tokenize String
        ld      (DORES),a         ; 
        ld      c,5               ; 
        call    KLOOP             ; 
        ld      hl,LineBuf        ; Point to Line Buffer
        call    FRMEVL            ; Evaluate Formula
        pop     hl                ; Restore Text Pointer
        ret


;----------------------------------------------------------------------------
;;; ---
;;; ## OUT
;;; Write to Z80 I/O Port
;;; ### FORMAT:
;;;  - OUT < address >,< byte >
;;;    - Action: Writes < byte > to the I/O port specified by LSB of < address >.
;;;    - Advanced: During the write, < address > is put on the Z80 address bus.
;;; ### EXAMPLES:
;;; ` OUT 246, 12 `
;;; > Send a value of 12 to the SOUND chip
;;;
;;; ` 10 X=14:OUT $FC, X `
;;; > Send a value of 14 to the Cassette sound port
;----------------------------------------------------------------------------

ST_OUT:
    call    GETADR                ; get/evaluate port
    push    de                    ; stored to be used in BC
    SYNCHK  ','                   ; Compare RAM byte with following byte
    call    GETBYT                ; get/evaluate data
    pop     bc                    ; BC = port
    out     (c),a                 ; out data to port
    ret


;----------------------------------------------------------------------------
;;; ---
;;; ## IN
;;; Read Z80 I/O Port
;;; ### FORMAT:
;;;  - IN(< address >)
;;;    - Action: Reads a byte from the I/O port specified by LSB of < address >.
;;;    - Advanced: During the read, < address > is put on the Z80 address bus.
;;; ### EXAMPLES:
;;; ` PRINT IN(252) `
;;; > Prints cassette port input status
;;;
;;; ` S=IN($FE) `
;;; > Set variable S to Printer Ready status
;----------------------------------------------------------------------------
; This is INP() in BASIC80
FN_IN:
    rst     CHRGET                ; Skip Token and Eat Spaces
    call    PARCHK
    push    hl
    ld      bc,LABBCK
    push    bc
    call    FRCADR                ; convert argument to 16 bit integer in DE
    ld      b,d
    ld      c,e                   ; bc = port
    in      a,(c)                 ; a = in(port)
    jp      SNGFLT                ; return with 8 bit input value in variable var

;----------------------------------------------------------------------------
;;; ---
;;; ## WAIT
;;; Suspend program execution while inonitoring the status of a Z80 input port.
;;; ### FORMAT:
;;;  - WAIT *address*, *byte1* [, *byte2*]
;;;    - Action: Causes execution to be suspended until a Z80 port develops a specified bit pattern. 
;;;      - The I/O port to read is specified by the LSB of *address*
;;;      - The data read at the port is Exclusive OR'ed with *byte2*, then AND'ed with *byte1*. 
;;;      - If the result is zero, MX BASIC loops back and reads the data at the port again. 
;;;      - If the result is nonzero, execution continues with the next statement.
;;;      - If J is omitted, it is assumed to be zero
;;;    - Advanced: During the read, < address > is put on the Z80 address bus.
;;;    - Caution: WAIT is not interrupted by Control-C. The RST key must be used to exit a WAIT that is in an infinite loop.
;;; ### EXAMPLES:
;;; ` WAIT $FF,$3F,$FF `
;;; > Wait for any key to be pressed.
;----------------------------------------------------------------------------
; THE WAIT CHANNEL#,MASK,MASK2 WAITS UNTIL THE STATUS
; RETURNED BY CHANNEL# IS NON ZERO WHEN XORED WITH MASK2
; AND THEN ANDED WITH MASK. IF MASK2 IS NOT PRESENT IT IS ASSUMED
; TO BE ZERO.
ST_WAIT:  
        call    GETADR            ; get/evaluate port
        push    de                ; stored to be used in BC
        SYNCHK  ','               ; Compare RAM byte with following byte
        call    GETBYT            ; get/evaluate data
        push    af                ; SAVE THE MASK
        call    CHRGT2            ; SEE IF THE STATEMENT ENDED
        jr      z,NOTTHR          ; IF NO THIRD ARGUMENT SKIP THIS
        SYNCHK  ','               ; MAKE SURE THERE IS A ","
        CALL    GETBYT            ; Get XOR mask into E
NOTTHR: pop     de                ; REGET THE "AND" MASK in D
        ld      e,a               ; Put the XOR mask in E
        pop     bc                ; Get back the Port #
LOPINP: in      a,(c)             ; THE INPUT INSTR
        xor     e                 ; XOR WITH MASK2
        and     d                 ; AND WITH MASK
        jr      z,LOPINP          ; LOOP UNTIL RESULT IS NON-ZERO
                                  ; NOTE: THIS LOOP CANNOT BE CONTROL-C'ED
                                  ; HOWEVER A RESTART AT 0 IS OK.
        ret  
