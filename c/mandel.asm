; https://en.wikibooks.org/wiki/X86_Assembly/Floating_Point
; https://rosettacode.org/wiki/Mandelbrot_set#Pascal
; https://www.felixcloutier.com/x86/index.html

; +--------------+---+---+-----+------------------------------------+
; | Test         | Z | C | Jcc | Notes                              |
; +--------------+---+---+-----+------------------------------------+
; | ST0 < ST(i)  | X | 1 | JB  | ZF will never be set when CF = 1   |
; | ST0 <= ST(i) | 1 | 1 | JBE | Either ZF or CF is ok              |
; | ST0 == ST(i) | 1 | X | JE  | CF will never be set in this case  |
; | ST0 != ST(i) | 0 | X | JNE |                                    |
; | ST0 >= ST(i) | X | 0 | JAE | As long as CF is clear we are good |
; | ST0 > ST(i)  | 0 | 0 | JA  | Both CF and ZF must be clear       |
; +--------------+---+---+-----+------------------------------------+
; Legend: X: don't care, 0: clear, 1: set

[bits 16]              
[org 0x7c00]          
%include "bpb.inc"

data:
    x       dw 0
    y       dw 0
    i       dw 0

    c1      dq 0.0
    c2      dq 0.0
    z1      dq 0.0
    z2      dq 0.0
    new1    dq 0.0
    new2    dq 0.0

    const2  dq 2.0
    const4  dq 4.0

    width   dq 320.0
    height  dq 200.0
    min_x   dq -2.0
    max_x   dq 1.0
    min_y   dq -1.0
    max_y   dq 1.0

    fpu_status  dw 0
              

boot_start:         
    xor     ax, ax
    mov     ds, ax          
    mov     ss, ax          ; Set stack pointer just below bootloader
    mov     sp, 0x7c00

    mov     ax, 13h         ; Turn on graphics mode (320x200)
    int     10h

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
    cmp     cx, 255
    je      .iloopend

    ; new1 = z1 * z1 - z2 * z2 + c1
    fld     qword [c1]
    fld     qword [z2]
    fmul    st0
    fld     qword [z1]
    fmul    st0
    fsub    st1           
    fadd    st2        
    fstp    qword [new1]
    fstp    st0
    fstp    st0

    ; new2 = 2 * z1 * z2 + c2
    fld     qword [c2]
    fld     qword [z2]
    fld     qword [z1]
    fld     qword [const2]
    fmul    st1
    fmul    st2
    fadd    st3
    fstp    qword [new2]
    fstp    st0
    fstp    st0
    fstp    st0

    fld     qword [new1]
    fstp    qword [z1]

    fld     qword [new2]
    fstp    qword [z2]

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

    mov     ax, [i]                
    cmp     ax, 255         ; dont set pixel
    je      .nextx

    mov     al, 1           ; color
    mov     ah, 0ch         ; Write graphics pixel
    mov     bh, 0           ; page number
    int     10h

.nextx:         
    inc     cx
    mov     [x], cx
    jmp     .xloop

.xloopend:      
.nexty:         
    inc     dx
    mov     [y], dx
    jmp     .yloop

.yloopend:

.exit:      
    hlt                             ; Halt processor until next interrupt
    jmp     .exit

    times   510 - ($ - $$) db 0     ; Fill the rest of sector with 0
    dw      0xAA55                  ; Add boot signature at the end of bootloader