BITS 16
ORG 0x100

VIDEO_MODE equ 03h ;80x25 color text
PADDLE_ROW equ 22
PADDLE_LEN equ 12
ATTR_PADDLE equ 3Eh     ;yellow on cyan
paddle_str db '============', 0

paddle_x db 34          

SECTION .text
  mov ax, cs
  mov ds, ax

  
  mov ax, VIDEO_MODE
  int 10h

  mov ah, 01h
  mov cx, 2607h         
  int 10h

forever:

  mov dh, PADDLE_ROW
  mov dl, [paddle_x]
  mov ah, 02h
  mov bh, 0
  int 10h

  mov si, paddle_str
  mov cx, PADDLE_LEN
  mov bl, ATTR_PADDLE     

.pad_loop:
  lodsb                   
  mov ah, 09h
  mov bh, 0
  push cx
  mov cx, 1
  int 10h               
  pop cx

  mov ah, 02h          
  mov bh, 0
  inc dl
  int 10h

  loop .pad_loop

  mov cx, 0FFFFh
.delay:
  loop .delay

  jmp forever            
