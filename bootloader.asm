            [bits 16]                   ; Tells the assembler that its a 16 bit code
            [org 0x7C00]                ; Origin, tell the assembler that where the code will 
                                        ; be in memory after it is been loaded

            mov ax, 13h                 ; Turn on graphics mode (320x200)
            int 10h 

            mov ah, 2                   ; Set cursor position
            mov bh, 0                   ; BH = page number (0 in graphics modes)
            mov dh, 5                   ; row
            mov dl, 10                  ; column
            int 10h

            mov si, message
            call printString            ; Call print string procedure

            mov al, 13                  ; color

            mov dx, 199                 ; row
            call horiz

            mov cx, 0                   ; column 
            call vert

            mov cx, 319                 ; column
            call vert

            mov dx, 0                   ; row
            call horiz

            hlt


; Draw horizontal line
; dx = row
; al = color
horiz:
            mov ah, 0ch                 ; Write graphics pixel
            mov bh, 0                   ; page number
            mov cx, 320                 ; column
.loop:
            int 10h
            dec cx
            jnz .loop 
            ret

; Draw vertival line 
; cx = column
; al = color
vert:
            mov ah, 0ch                 ; Write graphics pixel
            mov bh, 0                   ; page number
            mov dx, 200                 ; row
.loop:
            dec dx
            int 10h
            jnz .loop
            ret

; Print string on screen
; si = string starting pointer
printString:
.next_character:
            mov al, [si]            ; Get a byte from string and store in AL register
            inc si                 
            or al, al               ; Check if value in AL is zero (end of string)
            jz .exit_function       ; If end then return

            mov ah, 0x0e            ; Print one charater
            mov bh, 0x00            ; page numebr
            mov bl, 0x07            ; text attribute 0x07 is lightgrey font on black background
            int 0x10                

            jmp .next_character
.exit_function:
            ret

; Data
message db 'Hello Zsofi!', 0 

times 510 - ($ - $$) db 0           ; Fill the rest of sector with 0
dw 0xAA55                           ; Add boot signature at the end of bootloader