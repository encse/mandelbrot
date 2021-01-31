[bits 16]
[org 0x7c00]
                    jmp     boot_start
times 3-($-$$)      db      0x90                ; Support 2 or 3 byte encoded JMPs before BPB.

                    ; Dos 4.0 EBPB 1.44MB floppy
OEMname:            db      "csokavar.hu"
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
volumeLabel:        db      "MANDELBROT "
fileSysType:        db      "FAT12   "

disk_read_error:    db      `Disk read error\r\n`, 0

boot_start:         xor     ax, ax
                    mov     ds, ax
                    mov     es, ax
                    mov     ss, ax              ; Set stack pointer just below bootloader
                    mov     sp, 0x7c00

                    cld                         ; Set string instructions to use forward movement
                    jmp     0x0000:.setcs       ; FAR JMP to ensure set CS to 0
.setcs:

                    ; https://en.wikipedia.org/wiki/INT_13H#INT_13h_AH=02h:_Read_Sectors_From_Drive
main_start:         equ     0x7e00
sector_count:       equ     15
start_sector:       equ     2

                    mov     bx, main_start      ; es:bx contains the buffer address
                    mov     dh, 0x00            ; head number
                                                ; dl contains the drive number (set by bios)
                    mov     ah, 0x02            ; 2 for reading
                    mov     al, sector_count
                    mov     ch, 0x00            ; cylinder
                    mov     cl, start_sector
                    int     0x13

                    jc      .disk_read_error

                    cmp     al, sector_count
                    jne     .disk_read_error

                    jmp     main_start

.disk_read_error:   mov     bx, disk_read_error
                    call    print_string
                    call    terminate


; Function: print_string
; Inputs:   bx points to string
; Returns:  None
; Clobbers: AX
print_string:       pusha
.loop:              mov     al, [bx]    ; load what `bx` points to
                    cmp     al, 0
                    je      .return
                    push    bx          ; save bx
                    mov     ah, 0x0e    ; load this every time through the loop
                                        ; you don't know if `int` preserves it
                    int     0x10
                    pop     bx          ; restore bx
                    inc     bx
                    jmp     .loop
.return:
                    popa
                    ret

; Function: terminate
; Inputs:   None
; Returns:  Never
terminate:          jmp     $

times 510 - ($-$$)  db      0           ; Fill the rest of sector with 0
                    dw      0xAA55      ; Add boot signature at the end of bootloader