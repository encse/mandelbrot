;; Graphics memory start address
%assign Graphics.Vga 0xa000

;; 320 x 200, 256 color mode
%assign Graphics.VideoMode 0x13

;; Function:
;;      turn on graphics mode 
proc Graphics.init
begin
    mov ax, Graphics.VideoMode
    int 0x10
endproc

;; Function:
;;      set vga palette
;; Parameters:
;;      * rgbyPalette       near pointer to palette with 256 * 3 bytes of R, G, B colors
proc Graphics.setPalette
    %arg rgbyPalette:word
begin
    pusha

    mov ax, [rgbyPalette]
    mov di, ax
    
    ; palette index
    xor bx, bx 
.loop:
    ; red
    mov dh, [di] 
    inc di
    ; green
    mov ch, [di]
    inc di
    ; blue
    mov cl, [di]
    inc di
    ; set DAC Color Register
    mov ax, 0x1010
    int 0x10

    inc bx
    cmp bx, 256
    jl .loop

.ret:
    popa
endproc

;; Function:
;;      Set the color of (x,y) to the given color in a mouse-aware way.
;; Parameters:
;;      * wX
;;      * wY
;;      * byColor
proc Graphics.setPixel
    %arg byColor:byte
    %arg wY:word
    %arg wX:word
begin
    push es
    pusha

    ; check if x and y are valid coordinates
    mov bx, word [wX]
    cmp bx, 320
    jge .ret
    cmp bx, 0
    jl .ret

    mov ax, word [wY]
    cmp ax, 200
    jge .ret
    cmp ax, 0
    jl .ret

    mov cx, 320
    mul cx
    add ax, bx

    mov di, ax
    mov cx, [byColor]

    ; check if x and y is in the mouse rectangle,
    ; if yes, need to update the underlying area
    mov ax, word [wY]
    mov dx, [Mouse.wMouseY]
    sub ax, dx
    mov bx, ax

    mov ax, word [wX]
    mov dx, [Mouse.wMouseX]
    sub ax, dx

    cmp bx, 0
    jl .draw
    cmp bx, Graphics.cursorHeight
    jge .draw

    cmp ax, 0
    jl .draw
    cmp ax, Graphics.cursorWidth
    jge .draw

    xchg ax, bx
    mov dx, Graphics.cursorWidth
    mul dx
    add ax, bx
    mov si, ax

    mov byte [Graphics.rgbyAreaUnderCursor + si], cl

    ; check if mouse is transparent at the given index, don't draw if not transparent
    mov al, [Graphics.rgbyCursorShape + si]
    cmp al, 0
    jnz .ret

.draw:
    push Graphics.Vga
    pop es
    mov byte [es:di], cl

.ret:
    popa
    pop es
endproc


;; Function:
;;      Restores the area that was covered by the mouse
proc Graphics.hideCursor
    %local wIcolScreen:word
    %local wIrowScreen:word
    %local wIcol:word
    %local wIrow:word
begin
    pusha
    push es

    ; es = Vga
    push Graphics.Vga
    pop es

    mov ax, [Mouse.wMouseX]
    mov [wIcolScreen], ax
    mov ax, [Mouse.wMouseY]
    mov [wIrowScreen], ax
    xor ax, ax
    mov [wIcol], ax
    mov [wIrow], ax

.loop:
    ; check that the destination is within screen limits
    mov ax, [wIcolScreen]
    cmp ax, 320     ; 0 <= wIcolScreen < 320
    jge .afterDraw

    mov ax, [wIrowScreen]
    cmp ax, 200     ; 0 <= wIrowScreen < 200
    jge .afterDraw

    ; we are good to draw, let's compute si and di
    mov bx, 320
    mul bx
    add ax, [wIcolScreen]
    ; di: target
    mov di, ax

    mov ax, [wIrow]
    mov bx, Graphics.cursorWidth
    mul bx
    add ax, [wIcol]
    ; si: src
    mov si, ax 

    ; get color and draw
    mov cl, byte [Graphics.rgbyAreaUnderCursor + si]
    mov byte [es:di], cl

.afterDraw:
    ; increment icol
    mov ax, [wIcol]
    inc ax
    cmp ax, Graphics.cursorWidth
    jge .nextRow

    ;  set icol and icolScreen
    mov [wIcol], ax
    mov ax, [wIcolScreen]
    inc ax
    mov [wIcolScreen], ax

    jmp .loop

.nextRow:
    ; reset icol and icolScreen
    xor ax, ax
    mov [wIcol], ax
    mov ax, [Mouse.wMouseX]
    mov [wIcolScreen], ax

    ; increment irow
    mov ax, [wIrow]
    inc ax
    cmp ax, Graphics.cursorHeight
    jge .endLoop

    ;  set irow and irowScreen
    mov [wIrow], ax
    mov ax, [wIrowScreen]
    inc ax
    mov [wIrowScreen], ax
    jmp .loop

.endLoop:
    pop es
    popa
endproc


;; Function:
;;      Draws the mouse cursor to the screen saving the area that
;;      is under the mouse so that we can restore it later when the
;;      cursor moves or disappears.
proc Graphics.drawCursor
    %arg wIcolScreen:word
    %arg wIrowScreen:word
    %arg wIcol:word
    %arg wIrow:word
begin
    pusha

    ; es = VGA
    push es
    push Graphics.Vga
    pop es

    ; wIcolScreen = Mouse.wMouseX
    mov ax, [Mouse.wMouseX]
    mov [wIcolScreen], ax

    ; wIrowScreen = Mouse.wMouseY
    mov ax, [Mouse.wMouseY]
    mov [wIrowScreen], ax

    xor ax, ax
    ; wIcol = 0
    mov [wIcol], ax
    ; wIrow = 0
    mov [wIrow], ax

.loop:
    ; check that the destination is within screen limits
    ; 0 <= wIcolScreen < 320 ?
    mov ax, [wIcolScreen]
    cmp ax, 320     ; 0 <= wIcolScreen < 320
    jge .afterDraw
    
    ; 0 <= wIrowScreen < 320 ?
    mov ax, [wIrowScreen]
    cmp ax, 200     ; 0 <= wIrowScreen < 200
    jge .afterDraw

    ; we are good to draw, let's compute si and di
    mov bx, 320
    mul bx
    add ax, [wIcolScreen]
    ; di: target
    mov di, ax

    mov ax, [wIrow]
    mov bx, Graphics.cursorWidth
    mul bx
    add ax, [wIcol]
    ; si: src
    mov si, ax

    ; save original screen color
    mov cl, byte [es:di]
    mov byte [Graphics.rgbyAreaUnderCursor + si], cl

    ; get color from cursor shape
    mov cl, byte [Graphics.rgbyCursorShape + si]

    ; skip if transparent
    cmp cl, 0
    jz .afterDraw

    ; draw to screen
    mov byte [es:di], cl

.afterDraw:
    ; increment wIcol
    mov ax, [wIcol]
    inc ax
    cmp ax, Graphics.cursorWidth
    jge .nextRow

    ;  set wIcol and wIcolScreen
    mov [wIcol], ax
    mov ax, [wIcolScreen]
    inc ax
    mov [wIcolScreen], ax

    jmp .loop

.nextRow:
    ; reset wIcol and wIcolScreen
    xor ax, ax
    mov [wIcol], ax
    mov ax, [Mouse.wMouseX]
    mov [wIcolScreen], ax

    ; increment wIrow
    mov ax, [wIrow]
    inc ax
    cmp ax, Graphics.cursorHeight
    jge .endLoop

    ;  set wIrow and wIrowScreen
    mov [wIrow], ax
    mov ax, [wIrowScreen]
    inc ax
    mov [wIrowScreen], ax
    jmp .loop

.endLoop:
    pop es
    popa
endproc

Graphics.rgbyCursorShape:
    db 255,   0,   0,   0,   0,
.w: db 255, 255,   0,   0,   0,
    db 255, 255, 255,   0,   0,
    db 255, 255, 255, 255,   0,
    db 255, 255, 255, 255, 255,
    db 255, 255, 255,   0,   0,
    db 255,   0, 255, 255,   0,
    db   0,   0, 255, 255,   0,

Graphics.cursorWidth equ .w - Graphics.rgbyCursorShape
Graphics.cursorHeight equ ($ - Graphics.rgbyCursorShape) / Graphics.cursorWidth

Graphics.rgbyAreaUnderCursor:
    times Graphics.cursorHeight * Graphics.cursorWidth db 0
