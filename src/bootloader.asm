BOOT_START:         equ     0x7c00
MAIN_START:         equ     0x7e00
SECTOR_COUNT:       equ     8192 / 512 - 1

[bits 16]
[org BOOT_START]

bootStart:
        xor     ax, ax
        mov     ds, ax
        mov     es, ax
        mov     ss, ax              ; Set stack pointer just below bootloader
        mov     sp, BOOT_START

        jmp     0x0000:.setCs       ; FAR JMP to ensure set CS to 0
    .setCs:

        ; https://en.wikipedia.org/wiki/INT_13H#INT_13h_AH=02h:_Read_Sectors_From_Drive
        mov     bx, MAIN_START      ; es:bx contains the buffer address
        mov     dh, 0x00            ; head number
                                    ; dl contains the drive number (set by BIOS)
        mov     ah, 0x02            ; 2 for reading
        mov     al, SECTOR_COUNT
        mov     ch, 0x00            ; cylinder
        mov     cl, 0x02            ; start sector
        int     0x13

        jc      .diskReadError

        cmp     al, SECTOR_COUNT
        jne     .diskReadError

        jmp     MAIN_START

    .diskReadError:
        mov     bx, stDiskReadError
        call    printString
        call    terminate


;; Function: printString
;; Inputs:
;;           bx points to string
;; Returns:  None
;; Locals:   None

printString:
        pusha
    .loop:
        mov     al, [bx]    ; load what `bx` points to
        cmp     al, 0
        je      .ret
        push    bx          ; save bx
        mov     ah, 0x0e    ; load this every time through the loop
                            ; you don't know if `int` preserves it
        int     0x10
        pop     bx          ; restore bx
        inc     bx
        jmp     .loop

    .ret:
        popa
        ret

;; Function: terminate
;; Inputs:   None
;; Returns:  Never
;; Locals:   None

terminate:
        jmp     $

;;
;; DATA
;;

stDiskReadError:    db      `Disk read error\r\n`, 0

times 510 - ($-$$)  db      0           ; Fill the rest of sector with 0
                    dw      0xAA55      ; Add boot signature at the end of bootloader