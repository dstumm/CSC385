.data
.equ SPEED_PLAYER, 0x1
.equ SPEED_PLAYER_BULLET, 0x4
.equ SPEED_ENEMY_BULLET, 0x2

.equ SCREEN_HEIGHT, 240
.equ SCREEN_WIDTH, 320

.global FireEnemy, SHIELDS, SHIELD_STATES

.align 2
# Player state has first and second as x position, third byte as life, fourth byte as score, 
PLAYER_STATE: 
	.word 0 # position
	.word 0x00080010 # size
	.word 0

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
SHIELDS:
	.space(16)

# Shield is represented as an int, each byte of the int is a row of pixels
# ex 0x3CFFFFFF = 
# 0011 1100
# 1111 1111
# 1111 1111
# 1111 1111

.align 2
SHIELD_STATES:
  .word(0x00c80000)
  .word(0x00040008)
  .word(0x00c80050)
  .word(0x00040008)
  .word(0x00c800A0)
  .word(0x00040008)
  .word(0x00c800F0)
  .word(0x00040008)

.align
TICK:
	.word(0x00000000)

.align 2
TEST:
	.word(0x000f0000)
	.word(0x00080008)

.global PLAYER_STATE
.global PLAYER_BULLET
.global ENEMY_BULLETS
.global SHIELD_POSITIONS
.global SHIELDS
.global PushAll
.global PopAll
.global TICK

.global RestartGame
.global GameLoop
.global Fire
.global PlayerHit

.text
#
# Restart the game
#
RestartGame:
	addi sp, sp, -4
	stw ra, 0(sp)
	
	# Initialize player
	# Position height and width/2
	movia r8, 0x00c000A0
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

	# Initialize the enemies
	movi r4, 0
	call INIT_INVASION

	# Initialize shields
  movi r8, 0
INIT_SHIELD:

  # Get shield in array SHIELD[i*4] and set initial value
  movia r9, SHIELDS
  slli r10, r8, 2
  add r9, r9, r10
  movia r10, 0x3CFFFFFF
  stw r10, 0(r9)

  # Loop while i < 4
  movi r9, 4
  addi r8, r8, 1
  blt r8, r9, INIT_SHIELD

RESTART_DONE:
	ldw ra, 0(sp)
	addi sp, sp, 4
	ret

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

	call drawing_swap_buffers

	call PopAll
	ldw ra, 0(sp)
	addi sp, sp, 4
	ret

# 
# Playerlogic
#
UpdatePlayer: 
	addi sp, sp, -4
	stw ra, 0(sp)

	# Get current player state and input state
	movia r9, PLAYER_STATE
	ldw r8, 0(r9)
	movia r9, INPUT_STATE
	ldh r9, 0(r9)

CHECK_FIRE:
	# Check for pending fire
	andi r10, r9, SPACE_KEY
	beq r10, r0, CHECK_MOVEMENT

	# Fire
	addi sp, sp, -8	
	stw r8, 0(sp)
	sth r9, 4(sp)
	call Fire	
	movia r4, 0x00100010
	call FireEnemy
	ldw r8, 0(sp)
	ldh r9, 4(sp)
	addi sp, sp, 8

	movia r10, SPACE_KEY
	xori r10, r10, 0xF
	and r9, r9, r10
	movia r10, INPUT_STATE
	sth r9, 0(r10)

CHECK_MOVEMENT:

	# Check if player should move left, move left or fire
	andi r10, r9, LEFT_ARROW_KEY
	bne r10, r0, MOVE_LEFT
	andi r10, r9, RIGHT_ARROW_KEY
	bne r10, r0, MOVE_RIGHT
	br PLAYER_DONE

MOVE_LEFT:
	# Calculate new position
	andi r9, r8, 0xFFFF
	subi r9, r9, SPEED_PLAYER
	bgt r9, r0, MOVE_APPLY
	# If its over bounds, just set it to the bound
	mov r9, r0
	br MOVE_APPLY

MOVE_RIGHT:
	# Calculate new position
	andi r9, r8, 0xFFFF
	addi r9, r9, SPEED_PLAYER
	movi r10, 0x130 # 320 - playerwidth (16)
	blt r9, r10, MOVE_APPLY
	# If its over bounds, just set it to the bound
	mov r9, r10
	br MOVE_APPLY
    
MOVE_APPLY:
  movia r10, 0xFFFF0000
  and r8, r8, r10
	andi r9, r9, 0xFFFF
	or r8, r8, r9
	br PLAYER_DONE

PLAYER_DONE:
	# Apply new player state
	movia r9, PLAYER_STATE
	stw r8, 0(r9)

	# Draw it
	movia r4, PLAYER_STATE
	movia r5, ALIEN_SPRITE_MEDIUM
	movia r6, 0x2FD6
	call drawing_draw_bitmap

	ldw ra, 0(sp)
	addi sp, sp, 4
	ret

# 
# Update all bullets
#
UpdateBullets:
  # First just the player bullet
  movia r9, PLAYER_BULLET
  ldw r8, 0(r9)
  beq r8, r0, UP_ENEMY_BULLETS

  # Move the bullet up 1
  srli r10, r8, 16
  subi r10, r10, SPEED_PLAYER_BULLET
  
  # If its above the screen bounds zero it out
  bgt r10, r0, PLAYER_B_APPLY
  mov r8, r0
  stw r8, 0(r9)
  br UP_ENEMY_BULLETS
 
PLAYER_B_APPLY:
  slli r10, r10, 16
  andi r8, r8, 0xFFFF
  or r8, r8, r10
  stw r8, 0(r9)

	addi sp, sp, -4
	stw ra, 0(sp)
	mov r4, r9
	movia r5, 0x2FD6
	call drawing_fill_rect
	ldw ra, 0(sp)
	addi sp, sp, 4

UP_ENEMY_BULLETS:
  # Now all the enemy bullets
  movia r9, ENEMY_BULLETS
  movi r12, 10
ENEMY_B_MOVE:
  ldw r8, 0(r9)
  beq r8, r0, NEXT_B

  # Valid bullet, move it
  srli r10, r8, 16
  addi r10, r10, SPEED_ENEMY_BULLET
  #If its blow the screen bounds zero it out
  movi r11, SCREEN_HEIGHT
  blt r10, r11, ENEMY_B_APPLY
  mov r8, r0
  stw r8, 0(r9)
  br NEXT_B
 
ENEMY_B_APPLY:
  slli r10, r10, 16
  andi r8, r8, 0xFFFF
  or r8, r8, r10
  stw r8, 0(r9)

	
	addi sp, sp, -12
	stw ra, 0(sp)
	stw r9, 4(sp)
	stw r12, 8(sp)
	mov r4, r9
	movia r5, 0x2FD6
	call drawing_fill_rect
	ldw ra, 0(sp)
	ldw r9, 4(sp)
	ldw r12, 8(sp)
	addi sp, sp, 12


NEXT_B:
  addi r9, r9, 8
  addi r12, r12, -1
  bgt r12, r0, ENEMY_B_MOVE
  br BULLET_DONE

BULLET_DONE:
  # Debug
  #movia r9, ADDR_LEDS
  #srli r8, r8, 16
  #stwio r8, 0(r9)
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
	movia r8, SHIELD_STATES
	slli r9, r16, 3
	add r8, r8, r9
	mov r4, r8

	# Sprite
	movia r8, SHIELDS
	slli r9, r16, 2
	add r8, r8, r9
	mov r5, r8

	# Draw it
	movia r6, 0x2FD6
	#movia r5, 0x2FD6
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
# Fire player bullets
#
Fire:
  # Only create a bullet when one doesn't already exist (i.e. PLAYER_BULLET == 0)
  movia r9, PLAYER_BULLET
  ldw r8, 0(r9)
  bne r8, r0, FIRE_DONE

  # Create a new bullet at the players position + an offset
  # Get the players position with the y in the upper bits, x in the lower bits
  movia r9, PLAYER_STATE
  ldw r10, 0(r9)

  # Add an offset of half the players width (-y +x), and enough height to fire above the player (assume width 16 height 8)
  movia r9, 0xFFFC0008
  add r8, r10, r9

  # Store the bullet
  movia r9, PLAYER_BULLET
  stw r8, 0(r9)

FIRE_DONE:
	ret

#
# Fire enemy bullet
# @param r4 word, x/y position of bullet to create
FireEnemy:
  # First we need to see if there is a free bullet struct
  movia r9, ENEMY_BULLETS
  movi r10, 10
GET_BULLET:
  ldw r8, 0(r9)
  beq r8, r0, INIT_BULLET

  addi r9, r9, 8
  addi r10, r10, -1
  bgt r10, r0, GET_BULLET
  br FIRE_ENEMY_DONE

INIT_BULLET:
  # Set bullet to the input position
  stw r4, 0(r9)

FIRE_ENEMY_DONE:
  ret



# 
# Handle player hit by bullet
PlayerHit:
	addi sp, sp, -4
	stw ra, 0(sp)

  movia r9, PLAYER_STATE
  ldw r8, 8(r9)
  srli r10, r8, 16 # r10 has life now

  addi r10, r10, -1

  bgt r10, r0, PLAYER_LOSE_LIFE
  # No more life
  call RestartGame
	br PLAYER_HIT_DONE

PLAYER_LOSE_LIFE:
	# Apply the loss of life
	slli r10, r10, 16
	movia r11, 0x0000FFFF
	and r8, r8, r11
	or r8, r8, r10
	stw r8, 8(r9)
	br PLAYER_HIT_DONE

PLAYER_HIT_DONE:
	ldw ra, 0(sp)
	addi sp, sp, 4
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

