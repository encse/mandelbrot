%define FRAC 10
%define mkFixedPoint(a,b) ((a)*(1<<FRAC) + (b)) 
; https://en.wikibooks.org/wiki/X86_Assembly/Floating_Point

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

; %macro sqax 0: 
;     imul ax
;     call print_ax
;     shr ax, FRAC
;     shl dx, 16-FRAC
;     add ax, dx
;%endmacro

            [bits 16]                   ; Tells the assembler that its a 16 bit code
            [org 0x7C00]                ; Origin, tell the assembler that where the code will 
                                        ; be in memory after it is been loaded


            xor ax, ax
            ; Set stack pointer just below bootloader
            mov ss, ax
            mov sp, 0x7c00


            mov ax, 13h                 ; Turn on graphics mode (320x200)
            int 10h

            ; fld    qword [foo]          ;load a into st0
            ; fmul   st0, st0             ;st0 = a * a = a^2
            ; fld1                        ;st0 -> st1; st0 = 1  
            ; faddp                       ; st0 = 1+ st1
            ; fstp   qword [foo]

            ; mov ax, [foo+6]
            ; call print_ax
            ; mov ax, [foo+4]
            ; call print_ax
            ; mov ax, [foo+2]
            ; call print_ax
            ; mov ax, [foo]
            ; call print_ax
            ; mov ax, [foo+8]
            ; call print_ax
           

;            ; check if >= 0
;            fld qword [foo]
;            fldz
;            fcomip
;            jbe @pos
;            mov al, 'n'
;            call print_ch
; @pos:
;            mov al, 'p'
;            call print_ch

          
            

; for($y=0;$y<=$dim_y;$y++) {
;   for($x=0;$x<=$dim_x;$x++) {
;     $c1=$min_x+($max_x-$min_x)/$dim_x*$x;
;     $c2=$min_y+($max_y-$min_y)/$dim_y*$y;
 
;     $z1=0;
;     $z2=0;
 
;     for($i=0;$i<100;$i++) {
;       $new1=$z1*$z1-$z2*$z2+$c1;
;       $new2=2*$z1*$z2+$c2;
;       $z1=$new1;
;       $z2=$new2;
;       if($z1*$z1+$z2*$z2>=4) {
;         break;
;       }
;     }
;     if($i<100) {
;       imagesetpixel ($im, $x, $y, $white_color);
;     }
;   }
; }
 
; imagepng($im);
; imagedestroy($im);
            ; dc1 =($max_x-$min_x)/$dim_x
            fld qword [width]
            fld qword [min_x]
            fld qword [max_x]
            fsub st0, st1
            fdiv st0, st1
            fstp qword [dc1]
            

            ; dc2 =($max_x-$min_x)/$dim_x
            fld qword [height]
            fld qword [min_y]
            fld qword [max_y]
            fsub st0, st1
            fdiv st0, st1
            fstp qword [dc2]
.yloop:
            mov cx, [y]
            cmp cx, 200
            je .yloopend

            xor ax, ax
           
            mov [x], ax
            fldz
            fstp qword [c1]
.xloop:            
            mov cx, [x]
            cmp cx, 320
            je .xloopend

            xor ax, ax
            mov [z1], ax
            mov [z2], ax
            mov [i], ax
.iloop:    
            mov cx, [i]
            cmp cx, 100
            je .iloopend

            ;  $new1=$z1*$z1-$z2*$z2+$c1;
            fld  qword [z1]
            fmul st0, st0
            fld  qword [z2]
            fmul st0, st0
            fsubp st1, st0
            fld qword [c1]
            faddp 

            ; $new2=2*$z1*$z2+$c2;
            fld  qword [const2]
            fld  qword [z1]
            fld  qword [z2]
            fmulp st1
            fmulp st1
            fld  qword [c2]
            faddp st1

            fst qword [z1]
            ;$z2=$new2;
            fst qword [z2]
            fstp st2

            ;$z1=$new1;
            fst qword [z1]

            ; if($z1*$z1+$z2*$z2>=4) break
            fmul st0, st0
            fstp st2
            fmul st0, st0
            faddp

            fld qword [const4]
            fcomip
            jbe .iloopend

            inc cx
            mov [i], cx
            jmp .iloop
.iloopend:

            mov ah, 15                 ; Write graphics pixel
            mov cx, [x]
            mov dx, [y]
            mov al, 13                  ; color
            mov bh, 0                   ; page number
            int 10h


            inc cx
            mov [x], cx

            ; c1 += dc1
            fld qword [c1]
            fld qword [dc1]
            faddp st1
            fstp qword [c1]

            jmp .xloop
          
.xloopend:

            ; c2 += dc2
            fld qword [c2]
            fld qword [dc2]
            faddp st1
            fstp qword [c2]

            inc dx
            mov [y], dx
            jmp .yloop

.yloopend:
            hlt

.exit:      ret


marker db 0x80,0x80
foo dq -2.1
new1 db 0x80,0x80
new2 db 0x81
dc1 dq 0
c1 dq 0
dc2 dq 0
c2 dq 0
z1 dw 0
z2 dw 0
x dw 0
y dw 0
i dw 0
const2 dq 2
const4 dq 4

width dq 320
height dq 200
min_x dq -2;
max_x dq 1;
min_y dq -1;
max_y dq 1;


print_fixed_point:
    push ax
    test ax, ax
    jns @@numbers
    mov al, '-'
    call print_ch
    pop ax
    push ax
    neg ax
    inc ax
@@numbers:
    shr ax, FRAC
    call print_ax
    mov al, '.'
    call print_ch
    pop ax
    push ax
    and ax, (1 << FRAC)-1
    call print_ax
    pop ax
    push ax
    mov al, 0ah
    call print_ch
    mov al, 0dh
    call print_ch
    pop ax
    ret

print_ax:
  ; assume number is in eax
    push ax
    mov ax, ' '
    call print_ch
    pop ax
    mov cx, 0
    mov bx, 16

@@loophere:
    mov dx, 0
    div bx

    ; now eax <-- eax/10
    ;     edx <-- eax % 10

    ; print edx
    ; this is one digit, which we have to convert to ASCII
    ; the print routine uses edx and eax, so let's push eax
    ; onto the stack. we clear edx at the beginning of the
    ; loop anyway, so we don't care if we much around with it

    ; convert dl to ascii
    cmp dl, 9
    jg @@hex
    add dl, '0'
    jmp @@x
@@hex:
    add dl, 'a' - 10
@@x:
    push dx                         ;digits are in reversed order, must use stack
    inc cx                          ;remember how many digits we pushed to stack
    cmp ax, 0                       ;if ax is zero, we can quit
    jnz @@loophere

@@loophere2:
    pop ax                          ; restore digits from last to first
    mov ah, 0x0e                    ; Print one charater
    mov bh, 0x00                    ; page numebr
    mov bl, 0x07                    ; text attribute 0x07 is lightgrey font on black background
    int 0x10
    loop @@loophere2
    ret



print_ch:
    mov ah, 0x0e                    ; Print one charater
    mov bh, 0x00                    ; page numebr
    mov bl, 0x07                    ; text attribute 0x07 is lightgrey font on black background
    int 0x10
    ret





times 510 - ($ - $$) db 0           ; Fill the rest of sector with 0
dw 0xAA55                           ; Add boot signature at the end of bootloader





; +0000000 00000000 0000000 00000000




