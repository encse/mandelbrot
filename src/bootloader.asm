;; Boot sector load address
%assign BootLoader.Begin 0x7c00

;; Sector size in bytes
%assign BootLoader.SectorSize 512

;; Words in 16 bit x86 are 2 bytes
%assign BootLoader.WordSize 2

;; Number of sectors used by main program
%assign BootLoader.MainSectorCount (Main.CodeSize / BootLoader.SectorSize - 1)

[bits 16]
[org BootLoader.Begin]

BootLoader:
    xor ax, ax
    mov ds, ax
    mov es, ax

    ; set stack pointer just below bootloader
    mov ss, ax
    mov sp, BootLoader.Begin

    ; far jmp to set CS = 0
    jmp 0x0000:.setCs
.setCs:

    ; read & start main program
    ; ah = 2 for reading
    mov ah, 0x02
    ; drive head number, dl contains the drive number (set by BIOS)
    mov dh, 0x00
    ; cylinder of drive
    mov ch, 0x00
    ; number of sectors to read
    mov al, BootLoader.MainSectorCount
    ; start sector to read from
    mov cl, 0x02
    ; es:bx contains the target address
    mov bx, Main.Start
    int 0x13
    jc .diskReadError

    cmp al, BootLoader.MainSectorCount
    jne .diskReadError

    jmp Main.Start

.diskReadError:
    mov si, BootLoader.stDiskReadError
    call BootLoader.printString
    call BootLoader.terminate


;; Function:
;;      Print a string to the terminal
;; Parameters
;;      * ds:si points to string
BootLoader.printString:
    pusha

    ; teletype output
    mov ah, 0x0e
.loop:
    ; until [si] != 0
    cmp byte [si], 0
    je .ret

    mov al, [si]
    int 0x10

    ; next character
    inc si
    jmp .loop

.ret:
    popa
    ret

;; Function:
;;      terminate exection
BootLoader.terminate:
    jmp $

BootLoader.stDiskReadError:
    db `Disk read error...\r\n`, 0

%assign BootLoader.CodeSize $ - $$

; Pad to size of boot sector, minus the size of a word for the boot sector
; magic value. If the code is too big to fit in a boot sector, the `times`
; directive uses a negative value, causing a build error.
times (BootLoader.SectorSize - BootLoader.WordSize) - BootLoader.CodeSize db 0

; Add boot signature at the end of bootloader
dw 0xAA55