[bits 16]
[org 0x7c00]
                    jmp     bootStart
times 3-($-$$)      db      0x90                ; Support 2 or 3 byte encoded JMPs before BPB.

                    ; Dos 4.0 EBPB 1.44MB floppy
OemName:            db      "csokavar"          ; 8 bytes
bytesPerSector:     dw      512
sectPerCluster:     db      1
reservedSectors:    dw      1
numFAT:             db      2
numRootDirEntries:  dw      224
numSectors:         dw      2880
mediaType:          db      0xf0
numFATsectors:      dw      9
sectorsPerTrack:    dw      18
numHeads:           dw      2
numHiddenSectors:   dd      0
numSectorsHuge:     dd      0
driveNum:           db      0
reserved:           db      0
signature:          db      0x29
volumeID:           dd      0x2d7e5a1a
volumeLabel:        db      "MANDELBROT "       ; 11 bytes
fileSysType:        db      "FAT12   "          ; 8 bytes

bootStart:          xor     ax, ax
                    mov     ds, ax
                    mov     es, ax
                    mov     ss, ax              ; Set stack pointer just below bootloader
                    mov     sp, 0x7c00

                    cld                         ; Set string instructions to use forward movement
                    jmp     0x0000:.setCs       ; FAR JMP to ensure set CS to 0
.setCs:

                    ; https://en.wikipedia.org/wiki/INT_13H#INT_13h_AH=02h:_Read_Sectors_From_Drive
MAIN_START:         equ     0x7e00
SECTOR_COUNT:       equ     8192 / 512 - 1
START_SECTOR:       equ     2

                    mov     bx, MAIN_START      ; es:bx contains the buffer address
                    mov     dh, 0x00            ; head number
                                                ; dl contains the drive number (set by bios)
                    mov     ah, 0x02            ; 2 for reading
                    mov     al, SECTOR_COUNT
                    mov     ch, 0x00            ; cylinder
                    mov     cl, START_SECTOR
                    int     0x13

                    jc      .diskReadError

                    cmp     al, SECTOR_COUNT
                    jne     .diskReadError

                    jmp     MAIN_START

.diskReadError:     mov     bx, diskReadError
                    call    printString
                    call    terminate


; Function: printString
; Inputs:   bx points to string
; Returns:  None
; Clobbers: AX
printString:        pusha
.loop:              mov     al, [bx]    ; load what `bx` points to
                    cmp     al, 0
                    je      .ret
                    push    bx          ; save bx
                    mov     ah, 0x0e    ; load this every time through the loop
                                        ; you don't know if `int` preserves it
                    int     0x10
                    pop     bx          ; restore bx
                    inc     bx
                    jmp     .loop

.ret:               popa
                    ret

; Function: terminate
; Inputs:   None
; Returns:  Never
terminate:          jmp     $

;;;;;;;;;;;;;;;;;;;;;;;
; DATA
;;;;;;;;;;;;;;;;;;;;;;;
diskReadError:      db      `Disk read error\r\n`, 0

times 510 - ($-$$)  db      0           ; Fill the rest of sector with 0
                    dw      0xAA55      ; Add boot signature at the end of bootloader