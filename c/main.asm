VGA     equ 0xa000

%include "bootloader.asm"
%include "mandelbrot.asm"
%include "mouse.asm"
times   8192 - ($ - $$) db 0    

