BITS 16
ORG 0x100

VIDEO_MODE equ 03h ; 80x25 color text
COLS equ 80
ROWS equ 25
BRICK_START_R equ 3
BRICK_CELL_W equ 8
BRICK_CELL_H equ 4
BRICK_ROWS equ 4
BRICK_COLS equ 10
BRICK_END_R equ (BRICK_START_R + (BRICK_ROWS-1)*BRICK_CELL_H)

PADDLE_ROW equ 22
PADDLE_LEN equ 12
PADDLE_MAX_X equ 67

BLOCK_EMPTY equ 0
BLOCK_BREAK equ 1
BLOCK_SOLID equ 2
ATTR_TITLE equ 1Eh ; yellow on blue

ATTR_BRICK equ 09h ; bright blue on black (removable)
ATTR_SOLID equ 0Eh ; bright yellow on black (non-removable)
ATTR_PADDLE equ 3Eh ; yellow on cyan
ATTR_BALL equ 0Eh ; yellow on black
ATTR_MSG equ 4Fh ; white on red (Game Over)
ATTR_WIN equ 2Fh ; white on green (Win)
SECTION .data
title_msg db ' A R K A N O I D ', 0
gameover_msg db 'GAME OVER', 0
win_msg db ' Win ', 0
paddle_str db '============', 0
ball_x db 40
ball_y db 14
ball_dx db 1
ball_dy db -1
ball_counter db 0

paddle_x     db 34          

BALL_SPEED equ 3
blocks:
  db 0,0,1,2,1,1,2,1,0,0
  db 0,1,2,1,2,1,1,2,1,0
  db 0,0,0,0,0,0,0,0,0,0
  db 0,0,0,0,0,0,0,0,0,0
removable_left: dw 0 
mouse_present: db 0 
SECTION .text
  mov ax, cs
  mov ds, ax
  mov ax, 03h
  int 10h
  mov ah, 01h
  mov cx, 2607h 
  int 10h
  call count_removable
  xor ax, ax
  int 33h
  cmp ax, 0
  je main_loop
  mov byte [mouse_present], 1
  mov ax, 1
  int 33h 
main_loop:
  call update_ball
  cmp ax, 1
  je do_gameover
  cmp ax, 2
  je do_win
  call draw_screen
  cmp byte [mouse_present], 0
  je .check_key
  mov ax, 3
  int 33h ;
  cmp cx, 79
  jbe .mouse_char 
  cmp cx, 80
  je .mouse_col79 
  mov ax, cx 
  mov bl, 8
  div bl
  mov cl, al
  jmp .mouse_char
.mouse_col79:
  mov cl, 79
.mouse_char: 
  mov al, cl
  sub al, PADDLE_LEN/2 
  jnc .pad_not_neg
  xor al, al
.pad_not_neg:
  cmp al, PADDLE_MAX_X
  jbe .pad_ok
  mov al, PADDLE_MAX_X 
.pad_ok:
  mov [paddle_x], al
.check_key:

  mov ah, 01h
  int 16h
  jz no_key
  mov ah, 00h

no_key:
  push cx
  mov cx, 50h
.delay_outer:
  mov dx, 0FFh
.delay_inner:
  dec dx
  jnz .delay_inner
  loop .delay_outer
  pop cx
  jmp main_loop
move_left:
  mov al, [paddle_x]
test al, al
  jz no_key
  dec byte [paddle_x]
  jmp no_key
move_right:
  mov al, [paddle_x]
  cmp al, PADDLE_MAX_X
  jae no_key
  inc byte [paddle_x]
  jmp no_key
update_ball:
  inc byte [ball_counter]
  cmp byte [ball_counter], BALL_SPEED
  jb .no_move
  mov byte [ball_counter], 0

  xor bx, bx
  mov bl, [ball_x]
  xor cx, cx
  mov cl, [ball_y]
  mov al, [ball_dx]
  cbw
  mov si, ax
  mov al, [ball_dy]
  cbw
  mov di, ax
  add bx, si
  add cx, di

  cmp bx, 1
  jge .x_ok_lo
  mov bx, 1
  neg si

.x_ok_lo:
  cmp bx, 78
  jle .x_ok_hi
  mov bx, 78
  neg si

.x_ok_hi:
  cmp cx, 2
  jge .y_ok_top
  mov cx, 2
  neg di
.y_ok_top:
  cmp cx, BRICK_START_R
  jb .after_blocks
  cmp cx, BRICK_END_R
  ja .after_blocks

  mov ax, cx
  sub ax, BRICK_START_R
  xor dx, dx
  mov bp, BRICK_CELL_H
  div bp 
test dx, dx
  jnz .after_blocks
  cmp ax, BRICK_ROWS
  jae .after_blocks
  push ax 

  mov ax, bx
  sub ax, 2
  jb .pop_after_blocks
  xor dx, dx
  mov bp, BRICK_CELL_W
  div bp 
  cmp ax, BRICK_COLS
  jae .pop_after_blocks
  cmp dx, 5
  jae .pop_after_blocks

  mov bp, ax
  pop ax 
  imul ax, BRICK_COLS
  add ax, bp 
  mov bp, ax

  push bx
  mov bx, blocks
  add bx, bp
  mov al, [bx]
  cmp al, BLOCK_EMPTY
  je .skip_block_hit
  neg di
  cmp al, BLOCK_BREAK
  jne .skip_block_hit
  mov byte [bx], BLOCK_EMPTY 
  dec word [removable_left]
.skip_block_hit:
  pop bx
  jmp .after_blocks
.pop_after_blocks:
  pop ax
.after_blocks:
  cmp cx, PADDLE_ROW
  jne .not_paddle
  xor ax, ax
  mov al, [paddle_x]
  mov dx, ax
  add dx, PADDLE_LEN
  cmp bx, ax
  jb .not_paddle
  cmp bx, dx
  ja .not_paddle
  mov cx, PADDLE_ROW
  neg di
.not_paddle:
  cmp cx, ROWS
  jb .save
  mov ax, 1
  ret
.save:
  cmp word [removable_left], 0
  jne .cont
  mov ax, 2
  ret
.cont:
  mov [ball_x], bl
  mov [ball_y], cl
  mov ax, si
  mov [ball_dx], al
  mov ax, di
  mov [ball_dy], al

  .no_move:
  xor ax , ax
  ret

set_cursor:
  mov ah, 02h
  mov bh, 0
  int 10h
  ret

write_char_attr:
  mov ah, 09h
  int 10h
  ret
draw_screen:

  mov ax, 0600h
  mov bh, 07h
  xor cx, cx
  mov dx, 184Fh
  int 10h

  mov dh, 1
  mov dl, 30
  call set_cursor
  mov si, title_msg
  mov bl, ATTR_TITLE
.title_loop:
  lodsb
test al, al
  jz .title_done
  mov cx, 1
  call write_char_attr
  mov ah, 02h
  mov bh, 0
  inc dl
  int 10h
  jmp .title_loop
.title_done:

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
  call set_cursor
  mov al, 0DBh 
  mov cx, 5
  call write_char_attr
  pop cx
  pop dx
.skip_b:
  inc cx
  jmp .block_col
.next_brow:
  add dx, BRICK_CELL_H 
  jmp .block_row
.blocks_done:

  mov dh, PADDLE_ROW
  xor dl, dl
  mov dl, [paddle_x]
  call set_cursor
  mov bl, ATTR_PADDLE
  mov si, paddle_str
  mov cx, PADDLE_LEN
.pad_loop:
  lodsb
  mov ah, 09h
  int 10h
  mov ah, 02h
  inc dl
  int 10h
  loop .pad_loop

  mov dh, [ball_y]
  mov dl, [ball_x]
  call set_cursor
  mov al, '*'
  mov bl, ATTR_BALL
  mov cx, 1
  call write_char_attr
  ret
do_gameover:
  call draw_screen
  mov dh, 12
  mov dl, 35
  call set_cursor
  mov si, gameover_msg
  mov bl, ATTR_MSG
.go_loop:
  lodsb
test al, al
  jz wait_key_go
  mov cx, 1
  call write_char_attr
  mov ah, 02h
  inc dl
  int 10h
  jmp .go_loop
do_win:
  call draw_screen
  mov dh, 12
  mov dl, 37
  call set_cursor
  mov si, win_msg
  mov bl, ATTR_WIN
.win_loop:
  lodsb
test al, al
  jz wait_key_win
  mov cx, 1
  call write_char_attr
  mov ah, 02h
  inc dl
  int 10h
  jmp .win_loop
wait_key_go:
wait_key_win:
  mov ah, 00h
  int 16h
  jmp exit_game
exit_game:
  mov ah, 01h
  mov cx, 0607h
  int 10h

  mov ax, 4C00h
  int 21h
count_removable:
  xor bx, bx 
  mov cx, BRICK_ROWS*BRICK_COLS
  mov si, blocks
.cnt_loop:
  mov al, [si]
  cmp al, BLOCK_BREAK
  jne .cnt_next
  inc bx
.cnt_next:
  inc si
  loop .cnt_loop
  mov [removable_left], bx
  ret