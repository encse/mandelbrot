    mov     ax, 13h         ; Turn on graphics mode (320x200)
    int     10h

    call    init_palette

    mov     ax, 15
    call    draw_mandelbrot
    mov     ax, 100
    call    draw_mandelbrot
    mov     ax, 255
    call    draw_mandelbrot

    call    terminate

draw_mandelbrot:
    jmp         start

    x           dw 0
    y           dw 0
    i           dw 0

    c1          dq 0.0
    c2          dq 0.0
    z1          dq 0.0
    z2          dq 0.0
    tmp         dq 0.0

    const2      dq 2.0
    const4      dq 4.0

    width       dq 320.0
    height      dq 200.0

    min_x       dq -2.0
    max_x       dq 1.0
    min_y       dq -1.0
    max_y       dq 1.0
              
    VGA         dw 0xa000
    screen_ptr  dw 0x0000

    loop_count  dw 0

start:

    mov     [loop_count], ax
    mov     [screen_ptr], word 0
    mov     [x], word 0
    mov     [y], word 0
    xor     ax, ax
    mov     ds, ax          
    mov     es, word [VGA]
    
    finit
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

    ; $c1 = $min_x + ($max_x - $min_x) / $width * $x;
    fild    word [x]
    fld     qword [width]
    fld     qword [min_x]
    fld     qword [max_x]
    fsub    st1
    fdiv    st2
    fmul    st3
    fadd    st1
    fstp    qword [c1]
    fstp    st0
    fstp    st0
    fstp    st0

    ; $c2 = $min_y + ($max_y - $min_y) / $height * $y;
    fild    word [y]
    fld     qword [height]
    fld     qword [min_y]
    fld     qword [max_y]
    fsub    st1
    fdiv    st2
    fmul    st3
    fadd    st1
    fstp     qword [c2]
    fstp    st0
    fstp    st0
    fstp    st0

    xor     ax, ax
    mov     [i], ax

.iloop:         
    mov     cx, [i]
    cmp     cx, [loop_count]
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
    cmp     ax, [loop_count]         
    mov     byte [es:di], al
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

    ret
  
    

init_palette:
    ;; http://www.techhelpmanual.com/144-int_10h_1010h__set_one_dac_color_register.html
    ;; INT 10H 1010H: Set One DAC Color Register
    ;; Expects: AX    1010H
    ;;          BX    color register to set (0-255)
    ;;          CH    green value (00H-3fH)
    ;;          CL    blue value  (00H-3fH)
    ;;          DH    red value   (00H-3fH)

    xor     bx, bx
    xor     dx, dx

.loop1:
    mov     ax, bx
    add     ax, bx
    mov     dh, al
    mov     ch, al
    mov     cl, al

    mov     ax, 1010h
    int     10h
    inc     bx
    cmp     bx, 128
    jl      .loop1

.loop2:
    mov     ax, 512
    sub     ax, bx
    sub     ax, bx

    mov     dh, al
    mov     ch, al
    mov     cl, al
    sub     cl, 128

    mov     ax, 1010h
    int     10h
    inc     bx
    cmp     bx, 256
    jl      .loop2

    ret


; %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    times   8192 - ($ - $$) db 0      
  