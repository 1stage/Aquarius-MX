LDRR    MACRO rr,aa
    call  addr_rel
    dw    aa
    call  word_ind
    pop   rr
        ENDM

; Usage: CALL addr_rel
;        DW   target-*
;        POP  rr
addr_rel:
    exx                         ; Save Registers
    pop     hl                  ; Get Return Address
    ld      c,(hl)              ; Get Offset LSB
    inc     hl
    ld      b,(hl)              ; Get Offset MSB
    inc     hl
    push    hl                  ; Push New Return Address on Stack
    dec     hl
    dec     hl                  ; Back to Original Address
    ex      af,af'
    add     hl,bc               ; Add Offset to get Target Address
    ex      af,af'
    ex      (sp),hl             ; Swap with Return Address
    push    hl                  ; Puah Return Address on to Stack
    exx                         ; Restore the Registers
    ret                         ; Return to following instruction

; Usage: CALL byte_rel
;        DW   target-*
; Returns: A       
word_ind:
    ex      af,af'
    exx                         ; Save Registers
    pop     hl                  ; Get Return Address
    ld      c,(hl)              ; Get Offset LSB
    inc     hl
    ld      b,(hl)              ; Get Offset MSB
    inc     hl
    push    hl                  ; Push New Return Address on Stack
    dec     hl
    dec     hl                  ; Back to Original Address
    add     hl,bc               ; Add Offset to get Target Address
    ex      (sp),hl             ; Swap with Return Address
    ld      a,(hl)              ; Get Byte at ADDR intoA
    exx                         ; Restore the Registers
    ret                         ; Return to following instruction

; Get Address off Stack
; Read Word at Address
; Put Word on Stack
ld_hl_ind:
    exx                         ; Save Registers
    pop     hl                  ; Get Return Address off Stack
    ex      (sp),hl             ; Swap with Target Address
    ld      e,(hl)              ; Save LSB
    inc     hl                  ;
    ld      h,(hl)              ; Get MSB
    ld      l,e                 ; Get LSB
    ex      (sp),hl             ; Swap with Return Address
    push    hl                  ; Put it Return Address on Stack
    exx                         ; Restore the Registers
    ret                         ; Return to following instruction
    
; Usage: CALL routine
;        dw   target-*

;+00
jump_rel:  
    exx                         ; Save Registers
    pop     hl                  ; Get Return Address
_jump_rel:
    ld      c,(hl)              ; Get Offset LSB
    inc     hl
    ld      b,(hl)              ; Get Offset MSB
    dec     hl                  ; Back to Original Address
    ex      af,af'
    add     hl,bc               ; Add Offset to get Target Address
    ex      af,af'
_jump_ret:
    push    hl                  ; Put it on the Stack
    exx                         ; Restore the Registers
    ret                         ; Jump to the Subroutine

;+10
jump_rel_z
    exx                         
    pop     hl                  
    jr      nz,_jump_rel        
    inc     hl
    inc     hl
    jr      _jump_ret

;+18
jump_rel_nz
    exx                         
    pop     hl                  
    jr      z,_jump_rel        
    inc     hl
    inc     hl
    jr      _jump_ret

;+20
jump_rel_c
    exx                         
    pop     hl                  
    jr      nc,_jump_rel        
    inc     hl
    inc     hl
    jr      _jump_ret

;+28
jump_rel_nc
    exx                         
    pop     hl                  
    jr      c,_jump_rel        
    inc     hl
    inc     hl
    jr      _jump_ret

;+30
jump_rel_m
    exx                         
    pop     hl                  
    jr      p,_jump_rel        
    inc     hl
    inc     hl
    jr      _jump_ret

;+38
jump_rel_p
    exx                         
    pop     hl                  
    jr      m,_jump_rel        
    inc     hl
    inc     hl
    jr      _jump_ret


;+40 Relative CALL 
call_rel:     
    exx                         ; Save Registers
    pop     hl                  ; Get Return Address
_call_rel:
    ld      c,(hl)              ; Get Offset LSB
    inc     hl
    ld      b,(hl)              ; Get Offset MSB  
    inc     hl
    push    hl                  ; Push New Return Address on Stack
    dec     hl                  
    dec     hl                  ; Back to Original Address
    ex      af,af'
    add     hl,bc               ; Add Offset to get Target Address
    ex      af,af'
_call_ret:
    push    hl                  ; Put it on the Stack
    exx                         ; Restore the Registers
    ret                         ; Jump to the Subroutine

;+50
call_rel_z
    exx                         
    pop     hl                  
    jr      nz,_call_rel        
    inc     hl
    inc     hl
    jr      _call_ret

;+58
call_rel_nz
    exx                         
    pop     hl                  
    jr      z,_call_rel        
    inc     hl
    inc     hl
    jr      _call_ret

;+60
call_rel_c
    exx                         
    pop     hl                  
    jr      nc,_call_rel        
    inc     hl
    inc     hl
    jr      _call_ret

;+68
call_rel_nc
    exx                         
    pop     hl                  
    jr      c,_call_rel        
    inc     hl
    inc     hl
    jr      _call_ret

;+70
call_rel_m
    exx                         
    pop     hl                  
    jr      p,_call_rel        
    inc     hl
    inc     hl
    jr      _call_ret

;+58
call_rel_p
    exx                         
    pop     hl                  
    jr      m,_call_rel        
    inc     hl
    inc     hl
    jr      _call_ret
