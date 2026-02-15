BITS 16
ORG 100h
section .data
    paddleX dw 140
    paddleY dw 180
    paddleWidth dw 40
    paddleHeight dw 5
    paddleColor db 15

    ballX dw 160
    ballY dw 175
    ballRadius dw 5
    ballRadiusSq dw 25
    ballColor db 4

    screenWidth     dw  320
    blocksRows      dw  5
    blocksCols      dw  10
    blockWidth      dw  28
    blockHeight     dw  10
    blockGap        dw  2
    blockStartX     dw  10
    blockStartY     dw  30
    blockColor      db  14
    currentBlockX   dw  0

section .text
start:
    mov ax, 0013h 
    int 10h
    mov ax, 0A000h 
    mov es, ax

    call drawPaddle
    call drawBall
    call drawBlocks

    mov ah, 00h
    int 16h

    mov ax, 0003h
    int 10h
    mov ax, 4C00h
    int 21h

drawPaddle:
    pusha
    mov bx, [paddleY]
    mov dx, [paddleHeight]
nextRow:
    mov ax, bx
    mov di, 320
    mul di
    add ax, [paddleX]
    mov di, ax
    mov al, [paddleColor]
    mov cx, [paddleWidth]
drawRow:
    stosb
    loop drawRow
    inc bx
    dec dx
    jnz nextRow
    popa
    ret

drawBall:
    pusha
    mov bp, [ballRadiusSq]  ; bp = r^2
    mov cx, [ballY]
    sub cx, [ballRadius]     
yloop:
    mov dx, cx
    sub dx, [ballY]         
    mov ax, dx
    or ax, ax
    jge no_neg_dy
    neg ax
no_neg_dy:
    mul ax                  
    mov si, ax              ; si = dy^2
    mov bx, [ballX]
    sub bx, [ballRadius]    
xloop:
    mov dx, bx
    sub dx, [ballX]         
    mov ax, dx
    or ax, ax
    jge no_neg_dx
    neg ax
no_neg_dx:
    mul ax                  ; ax = dx^2
    add ax, si              ; ax = dx^2 + dy^2
    cmp ax, bp
    ja next_x               ; if > r^2

    mov ax, cx              
    mov di, 320
    mul di                  
    add ax, bx              
    mov di, ax
    mov al, [ballColor]
    stosb
next_x:
    inc bx
    mov ax, [ballX]
    add ax, [ballRadius]
    cmp bx, ax
    jle xloop              
    inc cx
    mov ax, [ballY]
    add ax, [ballRadius]
    cmp cx, ax
    jle yloop               
    popa
    ret




drawBlocks:
    pusha
    xor     si, si          ; row 

.row_loop:
    cmp     si, [blocksRows]
    jge     .done

    xor     di, di          ; col 

.col_loop:
    cmp     di, [blocksCols]
    jge     .next_row

    
    mov     ax, di
    mov     bx, [blockWidth]
    add     bx, [blockGap]
    mul     bx
    add     ax, [blockStartX]
    mov     [currentBlockX], ax

    
    mov     ax, si
    mov     bx, [blockHeight]
    add     bx, [blockGap]
    mul     bx
    add     ax, [blockStartY]
    mov     bx, ax          

    push    di             

    mov     bp, [blockHeight] 

.block_y_loop:
    mov     ax, bx          
    mul     word [screenWidth]
    add     ax, [currentBlockX]
    mov     di, ax          ; VRAM pos

    mov     al, [blockColor]
    mov     cx, [blockWidth]
    rep     stosb           

    inc     bx              
    dec     bp
    jnz     .block_y_loop 

    pop     di              
    inc     di              
    jmp     .col_loop

.next_row:
    inc     si             
    jmp     .row_loop

.done:
    popa
    ret


clear_screen:
    pusha
    xor di, di             
    mov cx, 320*200         
    xor al, al              ; black
    rep stosb               
    popa
    ret