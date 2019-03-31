[bits 16]       ;Tells the assembler that its a 16 bit code
[org 0x7C00]    ;Origin, tell the assembler that where the code will
                ;be in memory after it is been loaded

; graphics mode
            mov ah, 0
            mov al, 13h
            int 10h 


;INT 10 - VIDEO - SET CURSOR POSITION
;        AH = 02h
;        BH = page number
;              0-3 in modes 2&3
;              0-7 in modes 0&1
;                0 in graphics modes
;        DH = row (00h is top)
;        DL = column (00h is left)

            mov ah, 2
            mov bh, 0
            mov dh,5
            mov dl, 10
            int 10h

            mov si, HelloString         ;Store string pointer to SI
            call PrintString            ;Call print string procedure


            ; color
            mov al, 13

            mov dx, 199
            call horiz

            mov cx, 0
            call vert

            mov cx, 319
            call vert

            mov dx, 0
            call horiz



            hlt

; Write graphics pixel	AH=0Ch	AL = Color, BH = Page Number, CX = x, DX = y
horiz:
            mov bh, 0
            mov ah, 0ch
            mov cx, 320
.loop:
            int 10h
            dec cx
            jnz .loop 
            ret

vert:
            mov bh, 0
            mov ah, 0ch
            mov dx, 200
.loop:
            dec dx
            int 10h
            jnz .loop
            ret
           

PrintCharacter:                     ;Procedure to print character on screen
                                    ;Assume that ASCII value is in register AL
            mov ah, 0x0e            ;Tell BIOS that we need to print one charater on screen.
            mov bh, 0x00            ;Page no.
            mov bl, 0x07            ;Text attribute 0x07 is lightgrey font on black background

            int 0x10                ;Call video interrupt
            ret                     ;Return to calling procedure

PrintString:                        ;Procedure to print string on screen
                                    ;Assume that string starting pointer is in register SI

.next_character:                    ;Lable to fetch next character from string
            mov al, [si]            ;Get a byte from string and store in AL register
            inc si                  ;Increment SI pointer
            or al, al               ;Check if value in AL is zero (end of string)
            jz .exit_function       ;If end then return
            call PrintCharacter     ;Else print the character which is in AL register
            jmp .next_character     ;Fetch next character from string
.exit_function:                     ;End label
            ret                     ;Return from procedure


;Data
HelloString db 'Hello Zsofi!', 0 

times 510 - ($ - $$) db 0   ;Fill the rest of sector with 0
dw 0xAA55                   ;Add boot signature at the end of bootloader