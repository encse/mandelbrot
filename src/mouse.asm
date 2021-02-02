;; https://stackoverflow.com/questions/54280828/making-a-mouse-handler-in-x86-assembly

;; PS/2 mouse installed?
%assign Mouse.hwEquipPs2  4

;; Number of bytes in mouse packet
%assign Mouse.packetBytes 3

;; Mouse resolution 8 counts/mm
%assign Mouse.resolution  2

;; Function: Initialize and enable mouse
Mouse.start:
    call    Mouse.initialize
    ; If not successful assume no mouse
    jc  .ret
    call    Mouse.enable
.ret
    ret

;; Function: Initialize the mouse if present
;; Returns:  CF = 1 if error, CF=0 success
;; Clobbers: AX
Mouse.initialize:
    push es
    push bx

    ; Get equipment list
    int 0x11
    ; Is a PS/2 mouse installed?
    test ax, Mouse.hwEquipPs2
    ; if not print error and end
    jz .no_mouse

    ; Initialize mouse
    mov ax, 0xC205
    mov bh, Mouse.packetBytes
    int 0x15
    ; If not successful assume no mouse
    jc .no_mouse

    ; Set resolution
    mov ax, 0xC203
    mov bh, Mouse.resolution
    int 0x15
    ; If not successful assume no mouse
    jc .no_mouse

    ; Set mouse callback function (ES:BX)
    push cs
    pop es
    mov bx, Mouse.callbackDummy
    mov ax, 0xC207
    int 0x15
    ; If not successful assume no mouse
    jc .no_mouse

    ; cf = 0 -> success
    clc
    jmp .finished

.no_mouse:
    ; cf = 1 -> error
    stc

.finished:
    pop bx
    pop es
    ret

;; Function: Enable the mouse
Mouse.enable:
    push es
    push bx
    push ax

    ; Disable mouse before enabling
    call Mouse.disable

    ; Set mouse callback function (ES:BX)
    push cs
    pop es
    mov bx, Mouse.callback
    mov ax, 0xC207
    int 0x15

    ; Enable/Disable mouse
    mov ax, 0xC200
    ; BH = Enable = 1
    mov bh, 1 
    int 0x15

    pop ax
    pop bx
    pop es
    ret

;; Function: Disable the mouse
Mouse.disable:
    push es
    push bx
    push ax

    ; Enable/Disable mouse
    mov ax, 0xC200
    ; BH = Disable = 0
    xor bx, bx 
    int 0x15

    ; Clear callback function (ES:BX=0:0)
    mov es, bx
    mov ax, 0xC207
    int 0x15

    pop ax
    pop bx
    pop es
    ret

;; Function: mouseCallback (FAR)
;;           called by the interrupt handler to process a mouse data packet
;;           All registers that are modified must be saved and restored
;;           Since we are polling manually this handler does nothing
;;
;; Parameters:
;;      * wUnused       0
;;      * wDy           movement y
;;      * wDx           movement x
;;      * byStatus      mouse status byte
Mouse.callback:
    push bp
    mov bp, sp

    %define byStatus    bp + 12
    %define wDx         bp + 10
    %define wDy         bp + 8

    pusha
    push ds
    push es

    ; DS = CS, CS = where our variables are stored
    push cs
    pop ds

    call Graphics.hideCursor

    mov al, [byStatus]
    ; bl = copy of status byte
    mov bl, al
    ; Shift signY (bit 5) left 3 bits
    mov cl, 3
    ; CF = signY; Sign bit of AL = SignX
    shl al, cl

    ; dh = SignY value set in all bits
    ; ah = SignX value set in all bits
    sbb dh, dh 
    cbw 
    ; dl = movementY
    ; al = movementX
    mov dl, [wDy]
    mov al, [wDx]

    ; new mouse X_coord = X_Coord + movementX
    ; new mouse Y_coord = Y_Coord + (-movementY)
    neg dx
    mov cx, [Mouse.wMouseY]
    ; dx = new mouse Y_coord
    add dx, cx

    mov cx, [Mouse.wMouseX]
    ; ax = new mouse X_coord
    add ax, cx

    ; Status
    ; Keep two lowest bits (left and rigth button clicked)
    and bl, 3
    ; Update the current status with the new bits
    mov [Mouse.byButtonStatus], bl

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
    ; Update current mouseX coord
    mov [Mouse.wMouseX], ax
    ; Update current mouseY coord
    mov [Mouse.wMouseY], dx

    call Graphics.drawCursor

.ret:
    pop es
    pop ds
    popa
    mov sp, bp
    pop bp


Mouse.callbackDummy:
    ; This routine was reached via FAR CALL. Need a FAR RET
    retf

;; Current mouse X coordinate
Mouse.wMouseX: dw 0

;; Current mouse Y coordinate
Mouse.wMouseY: dw 0

;; Current button status:
;; 1: left pushed
;; 2: right pushed
;; 3: both pushed
Mouse.byButtonStatus: db 0

