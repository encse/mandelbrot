
;; Hungarian Notation Reference
;; https://www.cse.iitk.ac.in/users/dsrkg/cs245/html/Guide.htm

%include "bootloader.asm"
%include "mandelbrot.asm"
%include "mouse.asm"
%include "graphics.asm"

times 8192 - ($-$$) db      0
