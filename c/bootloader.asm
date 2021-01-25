bits 16            
org 0x7c00

global bpb_disk_info

    jmp boot_start
    times 3-($-$$)     db 0x90   ; Support 2 or 3 byte encoded JMPs before BPB.

bpb_disk_info:
    ; Dos 4.0 EBPB 1.44MB floppy
    OEMname:           db    "csokavar.hu"
    bytesPerSector:    dw    512
    sectPerCluster:    db    1
    reservedSectors:   dw    1
    numFAT:            db    2
    numRootDirEntries: dw    224
    numSectors:        dw    2880
    mediaType:         db    0xf0
    numFATsectors:     dw    9
    sectorsPerTrack:   dw    18
    numHeads:          dw    2
    numHiddenSectors:  dd    0
    numSectorsHuge:    dd    0
    driveNum:          db    0
    reserved:          db    0
    signature:         db    0x29
    volumeID:          dd    0x2d7e5a1a
    volumeLabel:       db    "MANDELBROT"
    fileSysType:       db    "FAT12   "


boot_start:  
    xor     ax, ax
    mov     ds, ax          
    mov     es, ax
    mov     ss, ax          ; Set stack pointer just below bootloader
    mov     sp, 0x7c00

    ; https://en.wikipedia.org/wiki/INT_13H#INT_13h_AH=02h:_Read_Sectors_From_Drive
    adr_main     EQU 0x7e00
    sector_count EQU 2
    start_sector EQU 2

    mov     bx, adr_main        ; es:bx contains the buffer address
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

    jmp     mandel_start

.disk_read_error:
	mov     bx, DISK_READ_ERROR
	call    print_string
    jmp abort

print_string:
    pusha

.loop:
    mov     al, [bx]    ; load what `bx` points to
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

abort:
    hlt
    jmp     abort  

    DISK_READ_ERROR db `DISK_READ_ERROR\r\n`, 0

    times 510 - ($ - $$) db 0   ;Fill the rest of sector with 0	times 510 - ($ - $$) db 0           
    dw 0xAA55                   ;Add boot signature at the end of bootloader 
