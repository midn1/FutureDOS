bits 16
cpu 8086

__CGA_CURSOR_X: dw 0x0000
__CGA_CURSOR_Y: dw 0x0000

; Initializes the driver.
init_cga:
    push bx

    ; INT 0x10, AH = 0: Set video mode
    ; Input AL = video mode, output AL = flags
    push ax
    mov ah, 0
    mov al, 3 ; CGA color textmode
    int 0x10
    pop ax

    mov bl, 0x0F
    call cga_clear_screen

    pop bx
    ret

; Prints a char.
; IN: BL = Color, AL = Char
; OUT: Nothing
cga_putc:
    push ax
    push bx
    push cx
    push dx
    push di
    push ds
    push es
    pushf

    push cs
    pop ds

    mov ah, bl

    push ax
    mov ax, 0xb800
    mov es, ax

    ; Get where to place the char
    mov bx, [__CGA_CURSOR_X]
    mov ax, [__CGA_CURSOR_Y]
    mov dl, 80
    mul dl
    add ax, bx
    mov bx, 2
    mul bx
    mov di, ax
    pop ax

    mov [es:di], word ax

    mov bx, [__CGA_CURSOR_X]
    mov cx, [__CGA_CURSOR_Y]
    inc bx
    cmp bx, 80
    je .new_line
    call cga_move_cursor
    jmp .check_if_scroll

.new_line:
    xor bx, bx
    inc cx
    call cga_move_cursor

.check_if_scroll:
    cmp cx, 24
    je .scroll
    jmp .end

.scroll:
    call cga_scroll

.end:
    popf
    pop es
    pop ds
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Clears the screen and places the cursor left at the top.
; IN: BL = Color
; OUT: Nothing
cga_clear_screen:
    push ax
    push bx
    push cx
    push dx
    push di
    push es

    mov ax, 0xb800
    mov es, ax

    ; NULL + Color
    xor ax, ax
    mov ah, bl

    mov cx, 2000
    xor di, di

.fill_screen:
    mov [es:di], word ax
    add di, 2
    loop .fill_screen

    ; Place the cursor at the top
    xor bx, bx
    xor cx, cx
    call cga_move_cursor

    pop es
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Moves the cursor.
; IN: BX = X, CX = Y
; OUT: Nothing
cga_move_cursor:
    push ax
    push bx
    push dx
    push ds

    push cs
    pop ds

    mov [__CGA_CURSOR_X], bx
    mov [__CGA_CURSOR_Y], cx

    mov ax, cx
    mov dl, 80
    mul dl
    add ax, bx
    mov bx, ax

    ; Actually move the cursor
    mov dx, 0x3D4
    mov al, 0x0F
    out dx, al

    inc dx
    mov al, bl
    out dx, al

    dec dx
    mov al, 0x0E
    out dx, al

    inc dx
    mov al, bh
    out dx, al

    pop ds
    pop dx
    pop bx
    pop ax
    ret

; Returns the cursor position.
; IN: Nothing
; OUT: X position in BX, Y position in CX
cga_get_cursor:
    push ds

    push cs
    pop ds

    mov bx, [__CGA_CURSOR_X]
    mov cx, [__CGA_CURSOR_Y]

    pop ds
    ret

; Scrolls.
; IN/OUT: Nothing
cga_scroll:
    push ax
    push bx
    push cx
    push si
    push di
    push ds
    push es

    push cs
    pop ds

    mov ax, 0xb800
    mov es, ax

    mov cx, 80 * 24

    xor di, di
    mov si, 80
    sal si, 1

.move_lines:
    mov ax, word [es:si]
    mov [es:di], word ax

    add si, 2
    add di, 2

    loop .move_lines

    xor bx, bx
    mov cx, [__CGA_CURSOR_Y]
    dec cx
    call cga_move_cursor

    pop es
    pop ds
    pop di
    pop si
    pop cx
    pop bx
    pop ax
    ret
