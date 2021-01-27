 mandelbrot_module:
    mov     ax, 13h                 ; Turn on graphics mode (320x200)
    int     10h

    call    init_palette
    call    mouse_start

.loop:
    call    draw_mandelbrot

.waitClick:
    hlt

    mov     al, [curStatus]
    cmp     al, 0x9              
    jne    .l1  
    push    dword [zoom + 4]        ; left click  
    push    dword [zoom]   
    push    word  [mouseY]
    push    word  [mouseX]       
    call    handle_zoom
    jmp     .loop
.l1:
    cmp     al, 0xa
    jne    .waitClick               ; right click
    push    dword [unzoom + 4]            
    push    dword [unzoom]   
    push    word  [mouseY]
    push    word  [mouseX]
    call    handle_zoom
    jmp     .loop
    

; Function: handle_zoom
;           change the world x, y, width and height values based on a mouse click at x,y and zoom factor 
; Inputs:   SP+4   = x
;           SP+6   = y
;           SP+8   = zoom
; Returns:  None
; Clobbers: None

handle_zoom:
    push    sp          
    mov     bp, sp

    finit

    ; world_x =  world_x +  (world_width * mouse_x / width) - (world_width / zoom / 2)
    fld     qword [world_x]
    fld     qword [width]
    fild    word [bp + 4]
    fld     qword [world_width] 
    fmul    st1
    fdiv    st2
    fadd    st3
    fld     qword [bp + 8]
    fld     qword [const2]
    fmulp   st1
    fld     qword [world_width]
    fdiv    st1
    fsubr   st2
    fstp    qword [world_x]
    fstp    st0
    fstp    st0
    fstp    st0
    fstp    st0
    fstp    st0
    
    ; ; ; world_width = world_width / zoom 
    fld     qword [bp + 8]
    fld     qword [world_width]
    fdiv    st1
    fstp    qword [world_width]
    fstp    st0

    ; ; world_y =  world_y +  (world_height * mouse_y / height) - (world_height / zoom / 2)
    fld     qword [world_y]
    fld     qword [height]
    fild    word [bp + 6]
    fld     qword [world_height]
    fmul    st1
    fdiv    st2
    fadd    st3
    fld     qword [bp + 8]
    fld     qword [const2]
    fmulp   st1
    fld     qword [world_height]
    fdiv    st1
    fsubr   st2
    fstp    qword [world_y]
    fstp    st0
    fstp    st0
    fstp    st0
    fstp    st0
    fstp    st0
    
    ; world_height = world_height / 10 
    fld     qword [bp + 8]
    fld     qword [world_height]
    fdiv    st1
    fstp    qword [world_height]
    fstp    st0

    pop     sp
    retn    8


    
; Function: draw_mandelbrot
;           
; Inputs:   None
; Returns:  None
; Clobbers: None

draw_mandelbrot:

    push    sp
    mov     bp, sp
    
    finit

    mov     [screen_ptr], word 0
    mov     [x], word 0
    mov     [y], word 0
    xor     ax, ax
    mov     ds, ax       
    
    push    VGA
    pop     es   
    
.yloop:         
    mov     cx, [y]
    cmp     cx, 200
    je      .yloopend

    xor     ax, ax
    mov     [x], ax

    fldz
    fstp    qword [c1]

.xloop:         
    mov     cx, [x]
    cmp     cx, 320
    je .xloopend

    fldz
    fst     qword [z1]
    fstp    qword [z2]

    ; $c1 = $world_x + world_width / width * x;
    fld     qword [world_x]
    fild    word [x]
    fld     qword [width]
    fld     qword [world_width]
    fdiv    st1
    fmul    st2
    fadd    st3
    fstp    qword [c1]
    fstp    st0
    fstp    st0
    fstp    st0

    ; $c2 = $min_y + ($max_y - $min_y) / $height * $y;
    fld     qword [world_y]
    fild    word [y]
    fld     qword [height]
    fld     qword [world_height]
    fdiv    st1
    fmul    st2
    fadd    st3
    fstp    qword [c2]
    fstp    st0
    fstp    st0
    fstp    st0

    xor     ax, ax
    mov     [i], ax

.iloop:         
    mov     cx, [i]
    cmp     cx, MAX_ITER
    je      .iloopend

    ; tmp = z1 * z1 - z2 * z2 + c1
    fld     qword [c1]
    fld     qword [z2]
    fmul    st0
    fld     qword [z1]
    fmul    st0
    fsub    st1           
    fadd    st2        
    fstp    qword [tmp]
    fstp    st0
    fstp    st0

    ; z2 = 2 * z1 * z2 + c2
    fld     qword [c2]
    fld     qword [z2]
    fld     qword [z1]
    fld     qword [const2]
    fmul    st1
    fmul    st2
    fadd    st3
    fstp    qword [z2]
    fstp    st0
    fstp    st0
    fstp    st0

    fld     qword [tmp]
    fstp    qword [z1]

    ; if (z1 * z1 + z2 * z2 >= 4) break
    fld     qword [z2]
    fmul    st0
    fld     qword [z1]
    fmul    st0
    fadd
    fst     qword [tmp2]
    fld     qword [const4]
    fcomi   st1
    fstp    st0
    fstp    st0
    fstp    st0

    jbe     .iloopend

 .nexti:        
    inc     cx
    mov     [i], cx
    jmp     .iloop

.iloopend:      
    mov     cx, [x]
    mov     dx, [y]

    mov     di, [screen_ptr]
    mov     ax, [i]                

    cmp     ax, MAX_ITER                      
    jl      .j1
    mov     ax, 253              ; the last 2 items of the palette are used by the mouse
    jmp     .j2
.j1:    
   

    ; push    dx
    ; xor     dx, dx
    ; mov     bx, 252
    ; mul     bx
    ; mov     bx, MAX_ITER
    ; div     bx
    ; pop dx

    ; http://linas.org/art-gallery/escape/escape.html
    ; n + 1 - log(log2(abs(z)))
    ; fld     qword [log2_10_inv]
    ; fld1
    ; fld     qword [tmp2]   ; holds z^2
    ; fsqrt
    ; fyl2x   
    ; fyl2x
    ; fchs   
    ; fld1    
    ; fadd    st1
    ; frndint
    ; fistp   word [tmp2]
    ; fstp    st0
    ; fstp    st0
    ; fstp    st0
    ; add     ax, [tmp2]


.j2:
    push    cx
    push    dx
    push    ax
    call    set_pixel
    inc     di
    mov     [screen_ptr], di
    
.nextx:
    inc     cx
    mov     [x], cx
    jmp     .xloop

.xloopend:      
.nexty:         
    mov     ax, [y]
    inc     ax
    mov     [y], ax

    jmp     .yloop

.yloopend:

    pop     sp
    ret
  
    
; Function: init_palette
;           change the world x, y, width and height values based on a mouse click at x,y and zoom factor 
; Inputs:   None
; Returns:  None
; Clobbers: None
init_palette:
    pusha

    ;; http://www.techhelpmanual.com/144-int_10h_1010h__set_one_dac_color_register.html
    ;; INT 10H 1010H: Set One DAC Color Register
    ;; Expects: AX    1010H
    ;;          BX    color register to set (0-255)
    ;;          DH    red value   (00H-3fH)
    ;;          CH    green value (00H-3fH)
    ;;          CL    blue value  (00H-3fH)

    mov     di, palette
    mov     [tmp], byte 0
    xor     bx, bx
.loop:
    mov     dh,  [di]
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
    ret

;;;;;;;;;;;;;;;;;;;;;;;
; DATA
;;;;;;;;;;;;;;;;;;;;;;;

    x            dw 0
    y            dw 0
    i            dw 0

    c1           dq 0.0
    c2           dq 0.0
    z1           dq 0.0
    z2           dq 0.0
    tmp          dq 0.0
    tmp2         dq 0.0

    const1       dq 1.0
    const2       dq 2.0
    const4       dq 4.0
    log2_10_inv  dq 0.30102999566
    
    width        dq 320.0
    height       dq 200.0

    world_x      dq -2.0
    world_y      dq -1.0
    world_width  dq 3.2
    world_height dq 2.0

    zoom         dq 2.0
    unzoom       dq 0.5

    screen_ptr  dw 0x0000

    MAX_ITER    equ 253

palette:
    db 255, 0, 0
    db 255, 6, 0
    db 255, 12, 0
    db 255, 18, 0
    db 255, 24, 0
    db 255, 30, 0
    db 255, 36, 0
    db 255, 42, 0
    db 255, 48, 0
    db 255, 54, 0
    db 255, 60, 0
    db 255, 66, 0
    db 255, 72, 0
    db 255, 78, 0
    db 255, 84, 0
    db 255, 90, 0
    db 255, 96, 0
    db 255, 102, 0
    db 255, 108, 0
    db 255, 114, 0
    db 255, 120, 0
    db 255, 126, 0
    db 255, 131, 0
    db 255, 137, 0
    db 255, 143, 0
    db 255, 149, 0
    db 255, 155, 0
    db 255, 161, 0
    db 255, 167, 0
    db 255, 173, 0
    db 255, 179, 0
    db 255, 185, 0
    db 255, 191, 0
    db 255, 197, 0
    db 255, 203, 0
    db 255, 209, 0
    db 255, 215, 0
    db 255, 221, 0
    db 255, 227, 0
    db 255, 233, 0
    db 255, 239, 0
    db 255, 245, 0
    db 255, 251, 0
    db 253, 255, 0
    db 247, 255, 0
    db 241, 255, 0
    db 235, 255, 0
    db 229, 255, 0
    db 223, 255, 0
    db 217, 255, 0
    db 211, 255, 0
    db 205, 255, 0
    db 199, 255, 0
    db 193, 255, 0
    db 187, 255, 0
    db 181, 255, 0
    db 175, 255, 0
    db 169, 255, 0
    db 163, 255, 0
    db 157, 255, 0
    db 151, 255, 0
    db 145, 255, 0
    db 139, 255, 0
    db 133, 255, 0
    db 128, 255, 0
    db 122, 255, 0
    db 116, 255, 0
    db 110, 255, 0
    db 104, 255, 0
    db 98, 255, 0
    db 92, 255, 0
    db 86, 255, 0
    db 80, 255, 0
    db 74, 255, 0
    db 68, 255, 0
    db 62, 255, 0
    db 56, 255, 0
    db 50, 255, 0
    db 44, 255, 0
    db 38, 255, 0
    db 32, 255, 0
    db 26, 255, 0
    db 20, 255, 0
    db 14, 255, 0
    db 8, 255, 0
    db 2, 255, 0
    db 0, 255, 4
    db 0, 255, 10
    db 0, 255, 16
    db 0, 255, 22
    db 0, 255, 28
    db 0, 255, 34
    db 0, 255, 40
    db 0, 255, 46
    db 0, 255, 52
    db 0, 255, 58
    db 0, 255, 64
    db 0, 255, 70
    db 0, 255, 76
    db 0, 255, 82
    db 0, 255, 88
    db 0, 255, 94
    db 0, 255, 100
    db 0, 255, 106
    db 0, 255, 112
    db 0, 255, 118
    db 0, 255, 124
    db 0, 255, 129
    db 0, 255, 135
    db 0, 255, 141
    db 0, 255, 147
    db 0, 255, 153
    db 0, 255, 159
    db 0, 255, 165
    db 0, 255, 171
    db 0, 255, 177
    db 0, 255, 183
    db 0, 255, 189
    db 0, 255, 195
    db 0, 255, 201
    db 0, 255, 207
    db 0, 255, 213
    db 0, 255, 219
    db 0, 255, 225
    db 0, 255, 231
    db 0, 255, 237
    db 0, 255, 243
    db 0, 255, 249
    db 0, 255, 255
    db 0, 249, 255
    db 0, 243, 255
    db 0, 237, 255
    db 0, 231, 255
    db 0, 225, 255
    db 0, 219, 255
    db 0, 213, 255
    db 0, 207, 255
    db 0, 201, 255
    db 0, 195, 255
    db 0, 189, 255
    db 0, 183, 255
    db 0, 177, 255
    db 0, 171, 255
    db 0, 165, 255
    db 0, 159, 255
    db 0, 153, 255
    db 0, 147, 255
    db 0, 141, 255
    db 0, 135, 255
    db 0, 129, 255
    db 0, 124, 255
    db 0, 118, 255
    db 0, 112, 255
    db 0, 106, 255
    db 0, 100, 255
    db 0, 94, 255
    db 0, 88, 255
    db 0, 82, 255
    db 0, 76, 255
    db 0, 70, 255
    db 0, 64, 255
    db 0, 58, 255
    db 0, 52, 255
    db 0, 46, 255
    db 0, 40, 255
    db 0, 34, 255
    db 0, 28, 255
    db 0, 22, 255
    db 0, 16, 255
    db 0, 10, 255
    db 0, 4, 255
    db 2, 0, 255
    db 8, 0, 255
    db 14, 0, 255
    db 20, 0, 255
    db 26, 0, 255
    db 32, 0, 255
    db 38, 0, 255
    db 44, 0, 255
    db 50, 0, 255
    db 56, 0, 255
    db 62, 0, 255
    db 68, 0, 255
    db 74, 0, 255
    db 80, 0, 255
    db 86, 0, 255
    db 92, 0, 255
    db 98, 0, 255
    db 104, 0, 255
    db 110, 0, 255
    db 116, 0, 255
    db 122, 0, 255
    db 128, 0, 255
    db 133, 0, 255
    db 139, 0, 255
    db 145, 0, 255
    db 151, 0, 255
    db 157, 0, 255
    db 163, 0, 255
    db 169, 0, 255
    db 175, 0, 255
    db 181, 0, 255
    db 187, 0, 255
    db 193, 0, 255
    db 199, 0, 255
    db 205, 0, 255
    db 211, 0, 255
    db 217, 0, 255
    db 223, 0, 255
    db 229, 0, 255
    db 235, 0, 255
    db 241, 0, 255
    db 247, 0, 255
    db 253, 0, 255
    db 255, 0, 251
    db 255, 0, 245
    db 255, 0, 239
    db 255, 0, 233
    db 255, 0, 227
    db 255, 0, 221
    db 255, 0, 215
    db 255, 0, 209
    db 255, 0, 203
    db 255, 0, 197
    db 255, 0, 191
    db 255, 0, 185
    db 255, 0, 179
    db 255, 0, 173
    db 255, 0, 167
    db 255, 0, 161
    db 255, 0, 155
    db 255, 0, 149
    db 255, 0, 143
    db 255, 0, 137
    db 255, 0, 131
    db 255, 0, 126
    db 255, 0, 120
    db 255, 0, 114
    db 255, 0, 108
    db 255, 0, 102
    db 255, 0, 96
    db 255, 0, 90
    db 255, 0, 84
    db 255, 0, 78
    db 255, 0, 72
    db 255, 0, 66
    db 255, 0, 60
    db 255, 0, 54
    db 255, 0, 48
    db 255, 0, 42
    db 255, 0, 36
    db 255, 0, 30
    db 255, 0, 24
    db 0, 0, 0      ; 253
    db 0, 0, 0      ; 254
    db 0, 0, 0      ; 255