.data
.equ SPEED_PLAYER, 0x1
.equ SPEED_PLAYER_BULLET, 0x4
.equ SPEED_ENEMY_BULLET, 0x2

.equ SCREEN_HEIGHT, 240
.equ SCREEN_WIDTH, 320
.equ LEFT_BOUND, 51
.equ RIGHT_BOUND, 269

.equ GREEN, 0x27E4 


.align 2
# Player state has first and second as x position, third byte as life, fourth byte as score, 
PLAYER_STATE: 
	.word 0 # position
	.word 0x00070010 # size 16x7
	.word 0

.align 2
# Position and rects of the lives images to display
LIVES_UI:
  .word(0x00E8004B)
  .word(0x00070010)

  .word(0x00E8005B)
  .word(0x00070010)

  .word(0x00E8006B)
  .word(0x00070010)

.align 2
# Bullet represented as y/x position, i.e. 0xYYYYXXXXX value of 0 means dead
PLAYER_BULLET:
  .word 0
  .word 0x00040001

.align 2
# Enemy bullets array, max 10 bullets at a time (10x4byte ints as 0xYYYYXXXX)
ENEMY_BULLETS:
  .space(80)

.align 2
SHIELDS_STATES:
	.space(1408)

# Sprites
SHIELD_SPRITE:
  .byte 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0
  .byte 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0
  .byte 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0
  .byte 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0
  .byte 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
  .byte 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
  .byte 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
  .byte 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
  .byte 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
  .byte 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
  .byte 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
  .byte 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
  .byte 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1
  .byte 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1
  .byte 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1
  .byte 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1

PLAYER_SPRITE:
  .byte 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0
  .byte 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0
  .byte 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0
  .byte 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0
  .byte 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0
  .byte 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0
  .byte 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0

.align 2
SHIELDS: # Positions and the rect (22x16)
  .word(0x00b80051)
  .word(0x00100016)
  .word(0x00b8007E)
  .word(0x00100016)
  .word(0x00b800AB)
  .word(0x00100016)
  .word(0x00b800D8)
  .word(0x00100016)

.align
TICK:
	.word(0x00000000)

.global LEFT_BOUND, RIGHT_BOUND
.global PLAYER_STATE
.global PLAYER_BULLET
.global ENEMY_BULLETS
.global SHIELDS, SHIELDS_STATES, SHIELD_SPRITE
.global PushAll
.global PopAll
.global TICK
.global GREEN

.global RestartGame
.global GameLoop

.text

# 
# Game logic here
#
GameLoop:
	addi sp, sp, -4
	stw ra, 0(sp)
	call PushAll

	call drawing_clear_buffer


	#call DRAW_INVASION
	#call MOVE_INVASION

  call UpdatePlayer
  call UpdateBullets
	call UpdateShields
  #call CheckCollision
  call DrawLives

	call drawing_swap_buffers

	call PopAll
	ldw ra, 0(sp)
	addi sp, sp, 4
	ret

#
# Restart the game
#
RestartGame:
	addi sp, sp, -4
	stw ra, 0(sp)
	
	# Initialize player
	# Position height and width/2
	movia r8, 0x00d00098
	movia r9, PLAYER_STATE
	stw r8, 0(r9)
	# Score 0, life 3
	movia r8, 0x00030000
	stw r8, 8(r9)
	
	# Game tick to zero
	movia r8, TICK
	stw r0, 0(r8)

  # Zero player bullet
  movia r9, PLAYER_BULLET
  stw r0, 0(r9)

  # Zero enemy bullets
  movi r10, 10
  movia r9, ENEMY_BULLETS:
ZERO_ENEMY_BULLET:
  stw r0, 0(r9)
  movia r12, 0x00040001
  stw r12, 4(r9)
  addi r10, r10, -1
  addi r9, r9, 8
  bgt r10, r0, ZERO_ENEMY_BULLET

  # 
  # Initialize the enemies
  #
	movi r4, 0
	call INIT_INVASION

  #
	# Initialize shields
  #
  movi r8, 0
INIT_SHIELD:

  # Get shield in array SHIELD_STATES[i*352] and set initial value
  movia r9, SHIELD_STATES
  movi r10, 352
  mul r10, r8, r10 
  add r9, r9, r10
  # r9 is 352 aligned address into SHIELD_STATES

  # Need to load 88 words from the shield sprite
  movi r11, 0
  movia r12, SHIELD_SPRITE
SHIELD_WORD:
  slli r13, r11, 2
  add r14, r13, r12
  ldw r14, 0(r14)
  # r14 has word from sprite

  # Get offset into shield itself
  add r13, r13, r9
  stw r15, 0(r13)

  # Loop 88 times
  movi r13, 88
  addi r11, r11, 1
  blt r11, r13 SHIELD_WORD

  # Loop for 4 shields
  movi r9, 4
  addi r8, r8, 1
  blt r8, r9, INIT_SHIELD

RESTART_DONE:
	ldw ra, 0(sp)
	addi sp, sp, 4
	ret


#
# Update Shields
#
UpdateShields:
	addi sp, sp, -8
	stw ra, 0(sp)
	stw r16, 4(sp)

	movi r16, 0
UPDATE_SHIELD:
	# Position and size
	movia r8, SHIELDS
	slli r9, r16, 3
	add r8, r8, r9
	mov r4, r8 # r4 is 8 aligned address into SHIELDS

	# Sprite
	movia r8, SHIELD_STATES
  movi r9, 352
  mul r9, r9, r16
	add r8, r8, r9 
	mov r5, r8 # r5 is 352 aligned address into SHIELD_STATES

	# Draw it
	movia r6, GREEN
	call drawing_draw_bitmap

	addi r16, r16, 1
	movi r8, 4
	blt r16, r8, UPDATE_SHIELD

UPDATE_SHIELDS_DONE:
	ldw ra, 0(sp)
	ldw r16, 4(sp)
	addi sp, sp, 8
	ret

# 
# Draw Lives
#
DrawLives:
  addi sp, sp, -12
  stw ra, 0(sp)
  stw r16, 4(sp)
  stw r17, 8(sp)

  # Load player lives
  movia r8, PLAYER_STATE
  ldw r8, 8(r8)
  srli r17, r8, 16

  // Loop
  movi r16, 0
DRAW_LIFE:
  bge r16, r17, DRAW_LIVES_DONE

  movia r4, LIVES_UI
  slli r8, r16, 2
  add r4, r4, r8
  movia r5, PLAYER_SPRITE
  movia r6, GREEN
  call drawing_draw_bitmap

  addi r16, r16, 1
  br DRAW_LIFE

DRAW_LIVES_DONE:
  ldw ra, 0(sp)
  ldw r16, 4(sp)
  ldw r17, 8(sp)
  addi sp, sp, 12
  ret

PushAll:
	addi sp, sp, -96
	stw r2, 0(sp)
	stw r3, 4(sp)
	stw r4, 8(sp)
	stw r5, 12(sp)
	stw r6, 16(sp)
	stw r7, 20(sp)
	stw r8, 24(sp)
	stw r9, 28(sp)
	stw r10, 32(sp)
	stw r11, 36(sp)
	stw r12, 40(sp)
	stw r13, 44(sp)
	stw r14, 48(sp)
	stw r15, 52(sp)
	stw r16, 56(sp)
	stw r17, 60(sp)
	stw r18, 64(sp)
	stw r19, 68(sp)
	stw r20, 72(sp)
	stw r21, 76(sp)
	stw r22, 80(sp)
	stw r23, 84(sp)
	stw r24, 88(sp)
	stw fp, 92(sp)
	ret

PopAll:
	ldw r2, 0(sp)
	ldw r3, 4(sp)
	ldw r4, 8(sp)
	ldw r5, 12(sp)
	ldw r6, 16(sp)
	ldw r7, 20(sp)
	ldw r8, 24(sp)
	ldw r9, 28(sp)
	ldw r10, 32(sp)
	ldw r11, 36(sp)
	ldw r12, 40(sp)
	ldw r13, 44(sp)
	ldw r14, 48(sp)
	ldw r15, 52(sp)
	ldw r16, 56(sp)
	ldw r17, 60(sp)
	ldw r18, 64(sp)
	ldw r19, 68(sp)
	ldw r20, 72(sp)
	ldw r21, 76(sp)
	ldw r22, 80(sp)
	ldw r23, 84(sp)
	ldw r24, 88(sp)
	ldw fp, 92(sp)
	addi sp, sp, 96
	ret

