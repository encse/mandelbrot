;; https://stackoverflow.com/questions/54280828/making-a-mouse-handler-in-x86-assembly

;; PS/2 mouse installed?
%assign Mouse.hwEquipPs2  4 

;; Number of bytes in mouse packet
%assign Mouse.packetBytes 3

;; Mouse resolution 8 counts/mm
%assign Mouse.resolution  2


;; Function: mouseStart
;;
;; Inputs:   None
;; Returns:  None
Mouse.start:
    call    Mouse.initialize
    call    Mouse.enable
    ret


;; Function: mouseInitialize
;;           Initialize the mouse if present
;;
;; Inputs:   None
;; Returns:  CF = 1 if error, CF=0 success
;; Clobbers: AX
Mouse.initialize:
    push es
    push bx

    int 0x11                        ; Get equipment list
    test ax, Mouse.hwEquipPs2            ; Is a PS/2 mouse installed?
    jz .no_mouse                   ;     if not print error and end

    mov ax, 0xC205                  ; Initialize mouse
    mov bh, Mouse.packetBytes         ; 3 byte packets
    int 0x15                        ; Call BIOS to initialize
    jc .no_mouse                   ;    If not successful assume no mouse

    mov ax, 0xC203                  ; Set resolution
    mov bh, Mouse.resolution        ; 8 counts / mm
    int 0x15                        ; Call BIOS to set resolution
    jc .no_mouse                   ;    If not successful assume no mouse

    push cs
    pop es                          ; ES = segment where code and mouse handler reside

    mov bx, Mouse.callbackDummy
    mov ax, 0xC207                  ; Install a default null handler (ES:BX)
    int 0x15                        ; Call BIOS to set callback
    jc .no_mouse                   ;    If not successful assume no mouse

    clc                                 ; CF=0 is success
    jmp .finished

.no_mouse:
    stc                                 ; CF=1 is error

.finished:
    pop bx
    pop es
    ret


;; Function: mouseEnable
;;           Enable the mouse
;;
;; Inputs:   None
;; Returns:  None
Mouse.enable:
    push es
    push bx
    push ax

    call Mouse.disable                ; Disable mouse before enabling

    push cs
    pop es
    mov bx, Mouse.callback
    mov ax, 0xC207                  ; Set mouse callback function (ES:BX)
    int 0x15                        ; Call BIOS to set callback

    mov ax, 0xC200                  ; Enable/Disable mouse
    mov bh, 1                       ; BH = Enable = 1
    int 0x15                        ; Call BIOS to disable mouse

    pop ax
    pop bx
    pop es
    ret


;; Function: mouseDisable
;;           Disable the mouse
;;
;; Inputs:   None
;; Returns:  None
Mouse.disable:
    push es
    push bx
    push ax

    mov ax, 0xC200                  ; Enable/Disable mouse
    xor bx, bx                      ; BH = Disable = 0
    int 0x15                        ; Call BIOS to disable mouse

    mov es, bx
    mov ax, 0xC207                  ; Clear callback function (ES:BX=0:0)
    int 0x15                        ; Call BIOS to set callback

    pop ax
    pop bx
    pop es
    ret


;; Function: mouseCallback (FAR)
;;           called by the interrupt handler to process a mouse data packet
;;           All registers that are modified must be saved and restored
;;           Since we are polling manually this handler does nothing
;;
;; Inputs:   SP+4  = Unused (0)
;;           SP+6  = MovementY
;;           SP+8  = MovementX
;;           SP+10 = Mouse Status
;; Returns:  None

Mouse.callback:
    %define wStatus     bp + 12
    %define wDx         bp + 10
    %define wDy         bp + 8

    push bp
    mov bp, sp
    pusha
    
    push ds
    push es

    push cs
    pop ds                          ; DS = CS, CS = where our variables are stored

    call Graphics.hideCursor

    mov al, [wStatus]
    mov bl, al                      ; bl = copy of status byte
    mov cl, 3                       ; Shift signY (bit 5) left 3 bits
    shl al, cl                      ; CF = signY
                                    ; Sign bit of AL = SignX
    sbb dh, dh                      ; dh = SignY value set in all bits
    cbw                             ; ah = SignX value set in all bits
    mov dl, [wDy]               ; dl = movementY
    mov al, [wDx]               ; al = movementX

    ; new mouse X_coord = X_Coord + movementX
    ; new mouse Y_coord = Y_Coord + (-movementY)
    neg dx
    mov cx, [Mouse.wMouseY]
    add dx, cx                      ; dx = new mouse Y_coord
    mov cx, [Mouse.wMouseX]
    add ax, cx                      ; ax = new mouse X_coord

    ; Status
    and bl, 3                       ; Keep two lowest bits (left and rigth button clicked)
    mov [Mouse.byButtonStatus], bl        ; Update the current status with the new bits
    
    ; ax = max(0, ax) 
    cmp ax, 0
    jge .j1
    mov ax, 0

.j1:
    ; ax = min(ax, 319)
    cmp ax, 319
    jle .j2
    mov ax, 319

.j2:
    ; dx = max(0, dx) 
    cmp dx, 0
    jge .j3
    mov dx, 0

.j3:
    ; dx = min(dx, 199)
    cmp dx, 199
    jle .j4
    mov dx, 199

.j4:
    ; Update current virtual mouseX coord
    mov [Mouse.wMouseX], ax
    ; Update current virtual mouseY coord
    mov [Mouse.wMouseY], dx

    call Graphics.drawCursor

    pop es
    pop ds
    popa
    mov sp, bp
    pop bp


Mouse.callbackDummy: 
    ; This routine was reached via FAR CALL. Need a FAR RET
    retf

;;
;; DATA
;;

;; Current mouse X coordinate
Mouse.wMouseX: dw 0

;; Current mouse Y coordinate
Mouse.wMouseY: dw 0

;; Current button status: 
;; 1: left pushed
;; 2: right pushed
;; 3: both pushed
Mouse.byButtonStatus: db 0

