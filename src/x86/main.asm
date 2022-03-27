;; Hungarian Notation Reference
;; https://www.cse.iitk.ac.in/users/dsrkg/cs245/html/Guide.htm
%assign Main.CodeSize    8192
%assign Main.LoadAddress 0x7e00

%include "proc.asm"

%include "bootloader.asm"
%include "mandelbrot.asm"
%include "mouse.asm"
%include "graphics.asm"

times Main.CodeSize - ($ - $$) db 0
