;https://stackoverflow.com/questions/54280828/making-a-mouse-handler-in-x86-assembly 

HW_EQUIP_PS2     equ 4          ; PS2 mouse installed?
MOUSE_PKT_BYTES  equ 3          ; Number of bytes in mouse packet
MOUSE_RESOLUTION equ 3          ; Mouse resolution 8 counts/mm

VIDEO_MODE       equ 0x13

bits 16
cpu 8086
ORG 0x7c00

; Include a BPB (1.44MB floppy with FAT12) to be more compatible with USB floppy media
%include "bpb.inc"

boot_start:
    xor ax, ax                  ; DS=SS=ES=0
    mov ds, ax
    mov ss, ax                  ; Stack at 0x0000:0x7c00
    mov sp, 0x7c00
    cld                         ; Set string instructions to use forward movement

    ; FAR JMP to ensure set CS to 0
    jmp 0x0000:.setcs
.setcs:

    mov ax, VIDEO_MODE
    int 0x10                    ; Set video mode

    call mouse_initialize
    jc .no_mouse                ; If CF set then error, inform user and end
    call mouse_enable           ; Enable the mouse

    sti
.main_loop:
    hlt                         ; Halt processor until next interrupt
    call poll_mouse             ; Poll mouse and update display with coordintes & status
    jmp .main_loop              ; Endless main loop

.no_mouse:
    mov si, noMouseMsg          ; Error enabling mouse
    call print_string           ; Display message and enter infinite loop

.err_loop:
    hlt
    jmp .err_loop

; Function: mouse_initialize
;           Initialize the mouse if present
;
; Inputs:   None
; Returns:  CF = 1 if error, CF=0 success
; Clobbers: AX

mouse_initialize:
    push es
    push bx

    int 0x11                    ; Get equipment list
    test ax, HW_EQUIP_PS2       ; Is a PS2 mouse installed?
    jz .no_mouse                ;     if not print error and end

    mov ax, 0xC205              ; Initialize mouse
    mov bh, MOUSE_PKT_BYTES     ; 3 byte packets
    int 0x15                    ; Call BIOS to initialize
    jc .no_mouse                ;    If not successful assume no mouse

    mov ax, 0xC203              ; Set resolution
    mov bh, MOUSE_RESOLUTION    ; 8 counts / mm
    int 0x15                    ; Call BIOS to set resolution
    jc .no_mouse                ;    If not successful assume no mouse

    push cs
    pop es                      ; ES = segment where code and mouse handler reside

    mov bx, mouse_callback_dummy
    mov ax, 0xC207              ; Install a default null handler (ES:BX)
    int 0x15                    ; Call BIOS to set callback
    jc .no_mouse                ;    If not successful assume no mouse

    clc                         ; CF=0 is success
    jmp .finished
.no_mouse:
    stc                         ; CF=1 is error
.finished:
    pop bx
    pop es
    ret

; Function: mouse_enable
;           Enable the mouse
;
; Inputs:   None
; Returns:  None
; Clobbers: AX

mouse_enable:
    push es
    push bx

    call mouse_disable          ; Disable mouse before enabling

    push cs
    pop es
    mov bx, mouse_callback
    mov ax, 0xC207              ; Set mouse callback function (ES:BX)
    int 0x15                    ; Call BIOS to set callback

    mov ax, 0xC200              ; Enable/Disable mouse
    mov bh, 1                   ; BH = Enable = 1
    int 0x15                    ; Call BIOS to disable mouse

    pop bx
    pop es
    ret

; Function: mouse_disable
;           Disable the mouse
;
; Inputs:   None
; Returns:  None
; Clobbers: AX

mouse_disable:
    push es
    push bx

    mov ax, 0xC200              ; Enable/Disable mouse
    xor bx, bx                  ; BH = Disable = 0
    int 0x15                    ; Call BIOS to disable mouse

    mov es, bx
    mov ax, 0xC207              ; Clear callback function (ES:BX=0:0)
    int 0x15                    ; Call BIOS to set callback

    pop bx
    pop es
    ret

; Function: mouse_callback (FAR)
;           called by the interrupt handler to process a mouse data packet
;           All registers that are modified must be saved and restored
;           Since we are polling manually this handler does nothing
;
; Inputs:   SP+4  = Unused (0)
;           SP+6  = MovementY
;           SP+8  = MovementX
;           SP+10 = Mouse Status
;
; Returns:  None
; Clobbers: None

ARG_OFFSETS      equ 6          ; Offset of args from BP

mouse_callback:
    push bp                     ; Function prologue
    mov bp, sp
    push ds                     ; Save registers we modify
    push ax
    push bx
    push cx
    push dx

    push cs
    pop ds                      ; DS = CS, CS = where our variables are stored

    mov al,[bp+ARG_OFFSETS+6]
    mov bl, al                  ; BX = copy of status byte
    mov cl, 3                   ; Shift signY (bit 5) left 3 bits
    shl al, cl                  ; CF = signY
                                ; Sign bit of AL = SignX
    sbb dh, dh                  ; CH = SignY value set in all bits
    cbw                         ; AH = SignX value set in all bits
    mov dl, [bp+ARG_OFFSETS+2]  ; CX = movementY
    mov al, [bp+ARG_OFFSETS+4]  ; AX = movementX

    ; new mouse X_coord = X_Coord + movementX
    ; new mouse Y_coord = Y_Coord + (-movementY)
    neg dx
    mov cx, [mouseY]
    add dx, cx                  ; DX = new mouse Y_coord
    mov cx, [mouseX]
    add ax, cx                  ; AX = new mouse X_coord

    ; Status
    mov [curStatus], bl         ; Update the current status with the new bits
    mov [mouseX], ax            ; Update current virtual mouseX coord
    mov [mouseY], dx            ; Update current virtual mouseY coord

    pop dx                      ; Restore all modified registers
    pop cx
    pop bx
    pop ax
    pop ds
    pop bp                      ; Function epilogue

mouse_callback_dummy:
    retf                        ; This routine was reached via FAR CALL. Need a FAR RET

; Function: poll_mouse
;           Poll the mouse state and display the X and Y coordinates and the status byte
;
; Inputs:   None
; Returns:  None
; Clobbers: None

poll_mouse:
    push ax
    push bx
    push dx

    mov bx, 0x0002              ; Set display page to 0 (BH) and color green (BL)

    cli
    mov ax, [mouseX]            ; Retrieve current mouse coordinates. Disable interrupts
    mov dx, [mouseY]            ; So that these two variables are read atomically
    sti

    call print_word_hex         ; Print the mouseX coordinate
    mov si, delimCommaSpc
    call print_string

    mov ax, dx
    call print_word_hex         ; Print the mouseY coordinate
    mov si, delimCommaSpc
    call print_string

    mov al, [curStatus]
    call print_byte_hex         ; Print the last read mouse state byte

    mov al, 0x0d
    call print_char             ; Print carriage return to return to beginning of line

    pop dx
    pop bx
    pop ax
    ret

; Function: print_string
;           Display a string to the console on the specified page and in a
;           specified color if running in a graphics mode
;
; Inputs:   SI = Offset of address to print
;           BH = Page number
;           BL = foreground color (graphics modes only)
; Clobbers: SI

print_string:
    push ax
    mov ah, 0x0e                ; BIOS TTY Print
    jmp .getch
.repeat:
    int 0x10                    ; print character
.getch:
    lodsb                       ; Get character from string
    test al,al                  ; Have we reached end of string?
    jnz .repeat                 ;     if not process next character
.end:
    pop ax
    ret

; Function: print_char
;           Print character on specified page and in a specified color
;           if running in a graphics mode
;
; Inputs:   AL = Character to print
;           BH = Page number
;           BL = foreground color (graphics modes only)
; Returns:  None
; Clobbers: AX

print_char:
    mov ah, 0x0e                ; TTY function to display character in AL
    int 0x10                    ; Make BIOS call
    ret

; Function: print_word_hex
;           Print a 16-bit unsigned integer in hexadecimal on specified
;           page and in a specified color if running in a graphics mode
;
; Inputs:   AX = Unsigned 16-bit integer to print
;           BH = Page number
;           BL = foreground color (graphics modes only)
; Returns:  None
; Clobbers: Mone

print_word_hex:
    xchg al, ah                 ; Print the high byte first
    call print_byte_hex
    xchg al, ah                 ; Print the low byte second
    call print_byte_hex
    ret

; Function: print_byte_hex
;           Print a 8-bit unsigned integer in hexadecimal on specified
;           page and in a specified color if running in a graphics mode
;
; Inputs:   AL = Unsigned 8-bit integer to print
;           BH = Page number
;           BL = foreground color (graphics modes only)
; Returns:  None
; Clobbers: Mone

print_byte_hex:
    push ax
    push cx
    push bx

    lea bx, [.table]            ; Get translation table address

    ; Translate each nibble to its ASCII equivalent
    mov ah, al                  ; Make copy of byte to print
    and al, 0x0f                ;     Isolate lower nibble in AL
    mov cl, 4
    shr ah, cl                  ; Isolate the upper nibble in AH
    xlat                        ; Translate lower nibble to ASCII
    xchg ah, al
    xlat                        ; Translate upper nibble to ASCII

    pop bx                      ; Restore attribute and page
    mov ch, ah                  ; Make copy of lower nibble
    mov ah, 0x0e
    int 0x10                    ; Print the high nibble
    mov al, ch
    int 0x10                    ; Print the low nibble

    pop cx
    pop ax
    ret
.table: db "0123456789ABCDEF", 0

; Uncomment these lines if not using a BPB (via bpb.inc)
; numHeads:        dw 2         ; 1.44MB Floppy has 2 heads & 18 sector per track
; sectorsPerTrack: dw 18

align 2
mouseX:       dw 0              ; Current mouse X coordinate
mouseY:       dw 0              ; Current mouse Y coordinate
curStatus:    db 0              ; Current mouse status
noMouseMsg:   db "Error setting up & initializing mouse", 0x0d, 0x0a, 0
delimCommaSpc:db ", ", 0

bootDevice:   db 0x00

; Pad boot sector to 510 bytes and add 2 byte boot signature for 512 total bytes
TIMES 510-($-$$) db  0
dw 0xaa55