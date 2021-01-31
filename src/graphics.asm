VGA:                equ     0xa000
VIDEO_MODE:         equ     13h

; Function: init_graphics
; Inputs:   None
; Returns:  None
; Clobbers: None
init_graphics:      mov     ax, VIDEO_MODE      ; Turn on graphics mode (320x200)
                    int     10h
                    ret

; Function: set_palette
; Inputs:   SP + 2: near pointer to palette with 256 * 3 bytes with R,G,B colors
; Returns:  None
; Clobbers: None
set_palette:        push    bp
                    mov     bp, sp
                    pusha

                    ;; http://www.techhelpmanual.com/144-int_10h_1010h__set_one_dac_color_register.html
                    ;; INT 10H 1010H: Set One DAC Color Register
                    ;; Expects: AX    1010H
                    ;;          BX    color register to set (0-255)
                    ;;          DH    red value   (00H-3fH)
                    ;;          CH    green value (00H-3fH)
                    ;;          CL    blue value  (00H-3fH)
                    mov     ax, [bp + 4]
                    mov     di, ax
                    xor     bx, bx

.loop:              mov     dh,  [di]
                    inc     di
                    mov     ch,  [di]
                    inc     di
                    mov     cl,  [di]
                    inc     di
                    mov     ax, 1010h
                    int     10h

                    inc     bx
                    cmp     bx, 256
                    jl      .loop

                    popa
                    mov     sp, bp
                    pop     bp
                    ret     2

; Function: set_pixel
;           Set the color of (x,y) to the given color in a mouse-aware way.
;
; Inputs:   SP + 8   = x
;           SP + 6   = y
;           SP + 4   = color
; Returns:  None
; Clobbers: None
set_pixel:          push    bp
                    mov     bp, sp
                    push    es
                    push    di
                    pusha

                    ; check if x and y are valid coordinates
                    mov     bx, word [bp + 8]
                    cmp     bx, 320
                    jge     .ret
                    cmp     bx, 0
                    jl     .ret

                    mov     ax, word [bp + 6]
                    cmp     ax, 200
                    jge     .ret
                    cmp     ax, 0
                    jl     .ret

                    mov     cx, 320
                    mul     cx
                    add     ax, bx

                    mov     di, ax
                    mov     cx, [bp + 4]


                    ; check if x and y is in the mouse rectangle, if yes, need to update the underlying area
                    mov     ax, word [bp + 6]
                    mov     dx, [mouseY]
                    sub     ax, dx
                    mov     bx, ax

                    mov     ax, word [bp + 8]
                    mov     dx, [mouseX]
                    sub     ax, dx

                    cmp     bx, 0
                    jl      .draw
                    cmp     bx, CURSOR_HEIGHT
                    jge     .draw

                    cmp     ax, 0
                    jl      .draw
                    cmp     ax, CURSOR_WIDTH
                    jge     .draw

                    xchg    ax, bx
                    mov     dx, CURSOR_WIDTH
                    mul     dx
                    add     ax, bx
                    mov     si, ax

                    mov     byte [areaUnderCursor + si], cl

                    ; check if mouse is transparent at the given index, don't draw if not transparent
                    mov     al, [cursorShape + si]
                    cmp     al, 0
                    jnz     .ret

.draw:              push    VGA
                    pop     es
                    mov     byte [es:di], cl

.ret:               popa
                    pop     di
                    pop     es
                    pop     bp
                    retn    6

; Function: hide_cursor
;           Restores the area that was covered by the mouse
hide_cursor:        push    bp
                    mov     bp, sp
                    sub     sp, 8
                    pusha

                    push    es                  ; set es
                    push    VGA
                    pop     es

                    mov     ax, [mouseX]
                    mov     [bp - 2], ax        ; mouseX + icol
                    mov     ax, [mouseY]
                    mov     [bp - 4], ax        ; mouseY + irow
                    xor     ax, ax
                    mov     [bp - 6], ax        ; icol
                    mov     [bp - 8], ax        ; irow

.loop:              ; check that the destination is within screen limits
                    mov     ax, [bp - 2]
                    cmp     ax, 0
                    jl      .afterDraw
                    cmp     ax, 320
                    jge     .afterDraw

                    mov     ax, [bp - 4]
                   
                    cmp     ax, 0
                    jl      .afterDraw
                    cmp     ax, 200
                    jge     .afterDraw

                    ; we are good to draw, let's compute si and di
                    mov     bx, 320
                    mul     bx
                    add     ax, [bp - 2]
                    mov     di, ax              ; target

                    mov     ax, [bp - 8]
                    mov     bx, CURSOR_WIDTH
                    mul     bx
                    add     ax, [bp - 6]
                    mov     si, ax              ; src

                    ; get color and draw
                    mov     cl,  byte [areaUnderCursor + si]
                    mov     byte [es:di], cl

.afterDraw:         ; increment icol
                    mov     ax, [bp - 6]
                    inc     ax
                    cmp     ax, CURSOR_WIDTH
                    jge     .nextRow
                    
                    ;  set icol and mouse + icol
                    mov     [bp - 6], ax
                    mov     ax, [bp - 2]
                    inc     ax
                    mov     [bp - 2], ax

                    jmp     .loop

.nextRow:           ; reset icol and mouse + icol
                    xor     ax, ax      
                    mov     [bp - 6], ax
                    mov     ax, [mouseX]
                    mov     [bp - 2], ax

                    ; increment irow
                    mov     ax, [bp - 8]
                    inc     ax
                    cmp     ax, CURSOR_HEIGHT
                    jge     .endLoop

                    ;  set irow and mouse + irow
                    mov     [bp - 8], ax
                    mov     ax, [bp - 4]
                    inc     ax
                    mov     [bp - 4], ax
                    jmp     .loop

.endLoop:           pop     es
                    popa
                
                    mov     sp, bp
                    pop     bp
                    ret

; Function: draw_cursor
;           Draws the mouse cursor to the screen saving the area that 
;           is under the mouse so that we can restore it later when the
;           cursor moves or disappears.
draw_cursor:        push    bp                          ; Function prologue
                    mov     bp, sp
                    sub     sp, 8
                    pusha

                    push    es                  ; set es
                    push    VGA
                    pop     es

                    mov     ax, [mouseX]
                    mov     [bp - 2], ax        ; mouseX + icol
                    mov     ax, [mouseY]
                    mov     [bp - 4], ax        ; mouseY + irow
                    xor     ax, ax
                    mov     [bp - 6], ax        ; icol
                    mov     [bp - 8], ax        ; irow

.loop:              ; check that the destination is within screen limits
                    mov     ax, [bp - 2]
                    cmp     ax, 0
                    jl      .afterDraw
                    cmp     ax, 320
                    jge     .afterDraw

                    mov     ax, [bp - 4]
                   
                    cmp     ax, 0
                    jl      .afterDraw
                    cmp     ax, 200
                    jge     .afterDraw

                    ; we are good to draw, let's compute si and di
                    mov     bx, 320
                    mul     bx
                    add     ax, [bp - 2]
                    mov     di, ax              ; target

                    mov     ax, [bp - 8]
                    mov     bx, CURSOR_WIDTH
                    mul     bx
                    add     ax, [bp - 6]
                    mov     si, ax              ; src

                    ; save original screen color
                    mov     cl, byte [es:di]
                    mov     byte [areaUnderCursor + si], cl

                    ; get color from cursor shape
                    mov     cl, byte [cursorShape + si]

                    ; skip if transparent
                    cmp     cl, 0
                    jz      .afterDraw

                    ; draw to screen
                    mov     byte [es:di], cl

.afterDraw:         ; increment icol
                    mov     ax, [bp - 6]
                    inc     ax
                    cmp     ax, CURSOR_WIDTH
                    jge     .nextRow
                    
                    ;  set icol and mouse + icol
                    mov     [bp - 6], ax
                    mov     ax, [bp - 2]
                    inc     ax
                    mov     [bp - 2], ax

                    jmp     .loop

.nextRow:           ; reset icol and mouse + icol
                    xor     ax, ax      
                    mov     [bp - 6], ax
                    mov     ax, [mouseX]
                    mov     [bp - 2], ax

                    ; increment irow
                    mov     ax, [bp - 8]
                    inc     ax
                    cmp     ax, CURSOR_HEIGHT
                    jge     .endLoop

                    ;  set irow and mouse + irow
                    mov     [bp - 8], ax
                    mov     ax, [bp - 4]
                    inc     ax
                    mov     [bp - 4], ax
                    jmp     .loop

.endLoop:           pop     es
                    popa
                
                    mov     sp, bp
                    pop     bp
                    ret

;;;;;;;;;;;;;;;;;;;;;;;
; DATA
;;;;;;;;;;;;;;;;;;;;;;;
cursorShape:        db      254,   0,   0,   0,   0,
.r2:                db      254, 254,   0,   0,   0,
                    db      254, 255, 254,   0,   0,
                    db      254, 255, 255, 254,   0,
                    db      254, 255, 255, 254, 254,
                    db      254, 254, 254,   0,   0,
                    db      254,   0, 254, 254,   0,
                    db        0,   0, 254, 254,   0,

CURSOR_WIDTH        equ     (.r2 - cursorShape)
CURSOR_HEIGHT       equ     ($ - cursorShape) / CURSOR_WIDTH

areaUnderCursor:
times CURSOR_HEIGHT * CURSOR_WIDTH db 0
