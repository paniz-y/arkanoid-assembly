BITS 16
ORG 0x100

VIDEO_MODE    equ 03h  ;80x25 color text
COLS          equ 80
ROWS          equ 25
BRICK_START_R equ 3
BRICK_CELL_W  equ 8
BRICK_CELL_H  equ 4
BRICK_ROWS    equ 4
BRICK_COLS    equ 10
BRICK_END_R   equ (BRICK_START_R + (BRICK_ROWS-1)*BRICK_CELL_H)

PADDLE_ROW    equ 22
PADDLE_LEN    equ 12
PADDLE_MAX_X  equ 67

BLOCK_EMPTY   equ 0
BLOCK_BREAK   equ 1
BLOCK_SOLID   equ 2

ATTR_BRICK    equ 09h     ; bright blue on black
ATTR_SOLID    equ 0Eh     ; bright yellow on black
ATTR_PADDLE   equ 3Eh     ; yellow on cyan

paddle_str    db '============', 0

paddle_x      db 34       


blocks:
  db 0,0,1,2,1,1,2,1,0,0     ; row 0 (screen row 3)
  db 0,1,2,1,2,1,1,2,1,0     ; row 1 (screen row 7)
  db 0,0,0,0,0,0,0,0,0,0     ; row 2 (screen row 11)
  db 0,0,0,0,0,0,0,0,0,0     ; row 3 (screen row 15)

SECTION .text
  mov ax, cs
  mov ds, ax

  
  mov ax, VIDEO_MODE
  int 10h

  
  mov ah, 01h
  mov cx, 2607h
  int 10h

  xor bp, bp
  mov dx, BRICK_START_R           

.block_row:
  cmp dx, BRICK_END_R
  ja .blocks_done

  mov cx, 0                       

.block_col:
  cmp cx, BRICK_COLS
  jae .next_brow

  push dx
  mov ax, dx
  sub ax, BRICK_START_R
  xor dx, dx
  mov bp, BRICK_CELL_H
  div bp                          
  pop dx

  imul ax, BRICK_COLS
  add ax, cx
  mov si, blocks
  add si, ax
  mov al, [si]

  cmp al, BLOCK_EMPTY
  je .skip_b

  mov bl, ATTR_BRICK
  cmp al, BLOCK_SOLID
  jne .draw_b
  mov bl, ATTR_SOLID

.draw_b:
  push dx
  push cx

  mov dh, dl                      
  mov al, cl
  mov ah, BRICK_CELL_W
  mul ah                          
  add al, 2                       
  mov dl, al                     

  mov ah, 02h
  xor bh, bh
  int 10h                         

  mov al, 0DBh                    
  mov cx, 5                       ; width 5 chars
  mov ah, 09h
  int 10h                         

  pop cx
  pop dx

.skip_b:
  inc cx
  jmp .block_col

.next_brow:
  add dx, BRICK_CELL_H            
  jmp .block_row

.blocks_done:


forever:

  mov dh, PADDLE_ROW
  mov dl, [paddle_x]
  mov ah, 02h
  xor bh, bh
  int 10h

  ; Draw paddle
  mov si, paddle_str
  mov cx, PADDLE_LEN
  mov bl, ATTR_PADDLE

.pad_loop:
  lodsb                           
  mov ah, 09h
  xor bh, bh
  push cx
  mov cx, 1
  int 10h                        
  pop cx

  mov ah, 02h                     
  xor bh, bh
  inc dl
  int 10h

  loop .pad_loop

  mov cx, 0FFFFh
.delay:
  loop .delay

  jmp forever