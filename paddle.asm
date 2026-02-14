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

section .text
start:
    mov ax, 0013h 
    int 10h
    mov ax, 0A000h 
    mov es, ax
    call drawPaddle
    call drawBall

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