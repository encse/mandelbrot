; https://stackoverflow.com/questions/54280828/making-a-mouse-handler-in-x86-assembly

HW_EQUIP_PS2:       equ     4          ; PS2 mouse installed?
MOUSE_PKT_BYTES:    equ     3          ; Number of bytes in mouse packet
MOUSE_RESOLUTION:   equ     2          ; Mouse resolution 8 counts/mm

mouse_start:        ; http://www.techhelpmanual.com/144-int_10h_1010h__set_one_dac_color_register.html
                    ; INT 10H 1010H: Set One DAC Color Register
                    ; Expects: AX    1010H
                    ;          BX    color register to set (0-255)
                    ;          CH    green value (00H-3fH)
                    ;          CL    blue value  (00H-3fH)
                    ;          DH    red value   (00H-3fH)

                    mov     bx, 255
                    mov     dh, 255
                    mov     ch, 255
                    mov     cl, 255

                    mov     ax, 1010h
                    int     10h

                    mov     bx, 254
                    mov     dh, 255
                    mov     ch, 255
                    mov     cl, 255

                    mov     ax, 1010h
                    int     10h


                    call    mouse_initialize
                    call    mouse_enable                ; Enable the mouse
                    ret


; Function: mouse_initialize
;           Initialize the mouse if present
;
; Inputs:   None
; Returns:  CF = 1 if error, CF=0 success
; Clobbers: AX
mouse_initialize:   push    es
                    push    bx
                
                    int     0x11                        ; Get equipment list
                    test    ax, HW_EQUIP_PS2            ; Is a PS2 mouse installed?
                    jz      .no_mouse                   ;     if not print error and end
                
                    mov     ax, 0xC205                  ; Initialize mouse
                    mov     bh, MOUSE_PKT_BYTES         ; 3 byte packets
                    int     0x15                        ; Call BIOS to initialize
                    jc      .no_mouse                   ;    If not successful assume no mouse
                
                    mov     ax, 0xC203                  ; Set resolution
                    mov     bh, MOUSE_RESOLUTION        ; 8 counts / mm
                    int     0x15                        ; Call BIOS to set resolution
                    jc      .no_mouse                   ;    If not successful assume no mouse
                
                    push    cs
                    pop     es                          ; ES = segment where code and mouse handler reside
                
                    mov     bx, mouse_callback_dummy
                    mov     ax, 0xC207                  ; Install a default null handler (ES:BX)
                    int     0x15                        ; Call BIOS to set callback
                    jc      .no_mouse                   ;    If not successful assume no mouse
                
                    clc                                 ; CF=0 is success
                    jmp     .finished

.no_mouse:          stc                                 ; CF=1 is error
.finished:          pop     bx
                    pop     es
                    ret


; Function: mouse_enable
;           Enable the mouse
;
; Inputs:   None
; Returns:  None
; Clobbers: AX
mouse_enable:       push    es
                    push    bx

                    call    mouse_disable               ; Disable mouse before enabling

                    push    cs
                    pop     es
                    mov     bx, mouse_callback
                    mov     ax, 0xC207                  ; Set mouse callback function (ES:BX)
                    int     0x15                        ; Call BIOS to set callback

                    mov     ax, 0xC200                  ; Enable/Disable mouse
                    mov     bh, 1                       ; BH = Enable = 1
                    int     0x15                        ; Call BIOS to disable mouse

                    pop     bx
                    pop     es
                    ret


; Function: mouse_disable
;           Disable the mouse
;
; Inputs:   None
; Returns:  None
; Clobbers: AX
mouse_disable:      push    es
                    push    bx

                    mov     ax, 0xC200                  ; Enable/Disable mouse
                    xor     bx, bx                      ; BH = Disable = 0
                    int     0x15                        ; Call BIOS to disable mouse

                    mov     es, bx
                    mov     ax, 0xC207                  ; Clear callback function (ES:BX=0:0)
                    int     0x15                        ; Call BIOS to set callback

                    pop     bx
                    pop     es
                    ret

; Function: mouse_callback (FAR)
;           called by the interrupt handler to process a mouse data packet
;           All registers that are modified must be saved and restored
;           Since we are polling manually this handler does nothing
;
; Inputs:   SP+4  = Unused (0)
;           SP+6  = MovementY
;           SP+8  = MovementX
;           SP+10 = Mouse Status
;
; Returns:  None
; Clobbers: None
ARG_OFFSETS:        equ     6                           ; Offset of args from BP
mouse_callback:     push    bp                          ; Function prologue
                    mov     bp, sp
                    push    ds                          ; Save registers we modify
                    push    ax
                    push    bx
                    push    cx
                    push    dx
                    push    es
                    push    di

                    push    cs
                    pop     ds                          ; DS = CS, CS = where our variables are stored

                    call    hide_cursor

                    mov     al, [bp+ARG_OFFSETS+6]
                    mov     bl, al                      ; BX = copy of status byte
                    mov     cl, 3                       ; Shift signY (bit 5) left 3 bits
                    shl     al, cl                      ; CF = signY
                                                        ; Sign bit of AL = SignX
                    sbb     dh, dh                      ; CH = SignY value set in all bits
                    cbw                                 ; AH = SignX value set in all bits
                    mov     dl, [bp+ARG_OFFSETS+2]      ; CX = movementY
                    mov     al, [bp+ARG_OFFSETS+4]      ; AX = movementX


                    ; new mouse X_coord = X_Coord + movementX
                    ; new mouse Y_coord = Y_Coord + (-movementY)
                    neg     dx
                    mov     cx, [mouseY]
                    add     dx, cx                      ; DX = new mouse Y_coord
                    mov     cx, [mouseX]
                    add     ax, cx                      ; AX = new mouse X_coord


                    ; Status
                    and     bl, 3                       ; Keep two lowest bits (left and rigth button clicked)
                    mov     [buttonStatus], bl          ; Update the current status with the new bits
                    cmp     ax, 0
                    jge     .j1
                    mov     ax, 0

.j1:                cmp     ax, 319
                    jle     .j2
                    mov     ax, 319

.j2:                cmp     dx, 0
                    jge     .j3
                    mov     dx, 0

.j3:                cmp     dx, 199
                    jle     .j4
                    mov     dx, 199

.j4:                mov     [mouseX], ax                ; Update current virtual mouseX coord
                    mov     [mouseY], dx                ; Update current virtual mouseY coord

                    call    draw_cursor

                    pop     di
                    pop     es
                    pop     dx                          ; Restore all modified registers
                    pop     cx
                    pop     bx
                    pop     ax
                    pop     ds
                    pop     bp                          ; Function epilogue


mouse_callback_dummy: 
                    retf                                ; This routine was reached via FAR CALL. Need a FAR RET


;;;;;;;;;;;;;;;;;;;;;;;
; DATA
;;;;;;;;;;;;;;;;;;;;;;;

mouseX:             dw      0              ; Current mouse X coordinate
mouseY:             dw      0              ; Current mouse Y coordinate
buttonStatus:       db      0              ; 1: left, 2: right button clicked, 3: both
noMouseMsg:         db      `Error setting up & initializing mouse\r\n`, 0

