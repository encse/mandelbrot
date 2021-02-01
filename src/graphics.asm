;; Function: initGraphics
;; Inputs:   None
;; Returns:  None
;; Locals:   None
initGraphics:
        mov     ax, VIDEO_MODE      ; Turn on graphics mode (320x200)
        int     0x10
        ret


;; Function: setPalette
;; Inputs:
;;      near pointer to palette with 256 * 3 bytes of R, G, B colors
%define var_rgbyPalette     bp + 4
;; Returns:  None
;; Locals:   None
setPalette:
        push    bp
        mov     bp, sp
        pusha

        ;; http://www.techhelpmanual.com/144-int_10h_1010h__set_one_dac_color_register.html
        ;; INT 0x10 0x1010: Set One DAC Color Register
        ;; Expects: AX    0x1010
        ;;          BX    color register to set (0-255)
        ;;          DH    red value   (0-255)
        ;;          CH    green value (0-255)
        ;;          CL    blue value  (0-255)
        mov     ax, [var_rgbyPalette]
        mov     di, ax
        xor     bx, bx

    .loop:
        mov     dh,  [di]
        inc     di
        mov     ch,  [di]
        inc     di
        mov     cl,  [di]
        inc     di
        mov     ax, 0x1010
        int     0x10

        inc     bx
        cmp     bx, 256
        jl      .loop

        popa
        mov     sp, bp
        pop     bp
        ret     2


;; Function: setPixel
;;           Set the color of (x,y) to the given color in a mouse-aware way.
;; Inputs:
%define var_wX              bp + 8
%define var_wY              bp + 6
%define var_byColor         bp + 4
;; Returns:  None
;; Locals:   None
setPixel:
        push    bp
        mov     bp, sp
        push    es
        pusha

        ; check if x and y are valid coordinates
        mov     bx, word [var_wX]
        cmp     bx, 320
        jge     .ret
        cmp     bx, 0
        jl     .ret

        mov     ax, word [var_wY]
        cmp     ax, 200
        jge     .ret
        cmp     ax, 0
        jl     .ret

        mov     cx, 320
        mul     cx
        add     ax, bx

        mov     di, ax
        mov     cx, [var_byColor]


        ; check if x and y is in the mouse rectangle, if yes, need to update the underlying area
        mov     ax, word [var_wY]
        mov     dx, [wMouseY]
        sub     ax, dx
        mov     bx, ax

        mov     ax, word [var_wX]
        mov     dx, [wMouseX]
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

        mov     byte [rgbyAreaUnderCursor + si], cl

        ; check if mouse is transparent at the given index, don't draw if not transparent
        mov     al, [rgbyCursorShape + si]
        cmp     al, 0
        jnz     .ret

    .draw:
        push    VGA
        pop     es
        mov     byte [es:di], cl

    .ret:
        popa
        pop     es
        pop     bp
        retn    6


;; Function: hideCursor
;;           Restores the area that was covered by the mouse
;; Inputs:   None
;; Returns:  None
;; Locals:
%define var_wIcolScreen     bp - 2
%define var_wIrowScreen     bp - 4
%define var_wIcol           bp - 6
%define var_wIrow           bp - 8
hideCursor:
        push    bp
        mov     bp, sp
        sub     sp, 8
        pusha
        push    es                  ; set es

        push    VGA
        pop     es

        mov     ax, [wMouseX]
        mov     [var_wIcolScreen], ax
        mov     ax, [wMouseY]
        mov     [var_wIrowScreen], ax
        xor     ax, ax
        mov     [var_wIcol], ax
        mov     [var_wIrow], ax

    .loop:
        ; check that the destination is within screen limits
        mov     ax, [var_wIcolScreen]
        cmp     ax, 0
        jl      .afterDraw
        cmp     ax, 320
        jge     .afterDraw

        mov     ax, [var_wIrowScreen]

        cmp     ax, 0
        jl      .afterDraw
        cmp     ax, 200
        jge     .afterDraw

        ; we are good to draw, let's compute si and di
        mov     bx, 320
        mul     bx
        add     ax, [var_wIcolScreen]
        mov     di, ax              ; target

        mov     ax, [var_wIrow]
        mov     bx, CURSOR_WIDTH
        mul     bx
        add     ax, [var_wIcol]
        mov     si, ax              ; src

        ; get color and draw
        mov     cl,  byte [rgbyAreaUnderCursor + si]
        mov     byte [es:di], cl

    .afterDraw:
        ; increment varIcol
        mov     ax, [var_wIcol]
        inc     ax
        cmp     ax, CURSOR_WIDTH
        jge     .nextRow

        ;  set varIcol and mouse + varIcol
        mov     [var_wIcol], ax
        mov     ax, [var_wIcolScreen]
        inc     ax
        mov     [var_wIcolScreen], ax

        jmp     .loop

    .nextRow:
        ; reset varIcol and mouse + varIcol
        xor     ax, ax
        mov     [var_wIcol], ax
        mov     ax, [wMouseX]
        mov     [var_wIcolScreen], ax

        ; increment varIrow
        mov     ax, [var_wIrow]
        inc     ax
        cmp     ax, CURSOR_HEIGHT
        jge     .endLoop

        ;  set varIrow and screenRrow
        mov     [var_wIrow], ax
        mov     ax, [var_wIrowScreen]
        inc     ax
        mov     [var_wIrowScreen], ax
        jmp     .loop

    .endLoop:
        pop     es
        popa
        mov     sp, bp
        pop     bp
        ret


;; Function: drawCursor
;;           Draws the mouse cursor to the screen saving the area that
;;           is under the mouse so that we can restore it later when the
;;           cursor moves or disappears.
;; Inputs:   None
;; Returns:  None
;; Locals:
%define var_wIcolScreen     bp - 2
%define var_wIrowScreen     bp - 4
%define var_wIcol           bp - 6
%define var_wIrow           bp - 8
drawCursor:
        push    bp
        mov     bp, sp
        sub     sp, 8
        pusha

        ; es = VGA
        push    es
        push    VGA
        pop     es

        ; var_wIcolScreen = wMouseX
        mov     ax, [wMouseX]
        mov     [var_wIcolScreen], ax

        ; var_wIrowScreen = wMouseY
        mov     ax, [wMouseY]
        mov     [var_wIrowScreen], ax

        xor     ax, ax
        ; var_wIcol = 0
        mov     [var_wIcol], ax
        ; var_wIrow = 0
        mov     [var_wIrow], ax

    .loop:
        ; check that the destination is within screen limits
        ; 0 <= var_wIcolScreen < 320 ?
        mov     ax, [var_wIcolScreen]
        cmp     ax, 0
        jl      .afterDraw
        cmp     ax, 320
        jge     .afterDraw

            ; 0 <= var_wIrowScreen < 320 ?
        mov     ax, [var_wIrowScreen]
        cmp     ax, 0
        jl      .afterDraw
        cmp     ax, 200
        jge     .afterDraw

        ; we are good to draw, let's compute si and di
        mov     bx, 320
        mul     bx
        add     ax, [var_wIcolScreen]
        mov     di, ax              ; target

        mov     ax, [var_wIrow]
        mov     bx, CURSOR_WIDTH
        mul     bx
        add     ax, [var_wIcol]
        mov     si, ax              ; src

        ; save original screen color
        mov     cl, byte [es:di]
        mov     byte [rgbyAreaUnderCursor + si], cl

        ; get color from cursor shape
        mov     cl, byte [rgbyCursorShape + si]

        ; skip if transparent
        cmp     cl, 0
        jz      .afterDraw

        ; draw to screen
        mov     byte [es:di], cl

    .afterDraw:
        ; increment var_wIcol
        mov     ax, [var_wIcol]
        inc     ax
        cmp     ax, CURSOR_WIDTH
        jge     .nextRow

        ;  set var_wIcol and var_wIcolScreen
        mov     [var_wIcol], ax
        mov     ax, [var_wIcolScreen]
        inc     ax
        mov     [var_wIcolScreen], ax

        jmp     .loop

    .nextRow:
        ; reset var_wIcol and var_wIcolScreen
        xor     ax, ax
        mov     [var_wIcol], ax
        mov     ax, [wMouseX]
        mov     [var_wIcolScreen], ax

        ; increment var_wIrow
        mov     ax, [var_wIrow]
        inc     ax
        cmp     ax, CURSOR_HEIGHT
        jge     .endLoop

        ;  set var_wIrow and var_wIrowScreen
        mov     [var_wIrow], ax
        mov     ax, [var_wIrowScreen]
        inc     ax
        mov     [var_wIrowScreen], ax
        jmp     .loop

    .endLoop:
        pop     es
        popa
        mov     sp, bp
        pop     bp
        ret


;;
;; DATA
;;
VGA:                equ     0xa000
VIDEO_MODE:         equ     0x13

rgbyCursorShape:
        db      255,   0,   0,   0,   0,
.r2:    db      255, 255,   0,   0,   0,
        db      255, 255, 255,   0,   0,
        db      255, 255, 255, 255,   0,
        db      255, 255, 255, 255, 255,
        db      255, 255, 255,   0,   0,
        db      255,   0, 255, 255,   0,
        db        0,   0, 255, 255,   0,

CURSOR_WIDTH:       equ     .r2 - rgbyCursorShape
CURSOR_HEIGHT:      equ     ($ - rgbyCursorShape) / CURSOR_WIDTH

rgbyAreaUnderCursor:
        times CURSOR_HEIGHT * CURSOR_WIDTH db 0
