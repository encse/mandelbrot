%include "bootloader.asm"
%include "mandelbrot.asm"
%include "mouse.asm"
%include "graphics.asm"

times 8192 - ($-$$) db      0
