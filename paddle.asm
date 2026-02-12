BITS 16
ORG 100h                

section .data
    paddleX        dw 140      
    paddleY       dw 180      
    paddleWidth    dw 40
    paddleHeight   dw 5
    paddleColor    db 15       

section .text
start:
    
    mov ax, 0013h           ; VGA mode
    int 10h                 

    
    mov ax, 0A000h          ; video memory
    mov es, ax              

    
    call drawPaddle

    ; wait until any key is pressed
    mov ah, 00h            
    int 16h                 

    ; switch to text mode 
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

    
