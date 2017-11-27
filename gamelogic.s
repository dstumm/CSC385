.data
.equ SPEED_PLAYER, 0x1
.equ SPEED_BULLET, 0x1
.equ SCREEN_HEIGHT, 240
.equ SCREEN_WIDTH, 320

.equ PLAYER_YPOS, 0x00C00000 # Player sits a height 32 from the bottom (240-32-playerheight(16) = 192) (from the bottom) at the moment, assuming top-left (0,0)

.align 2
# Player state has first and second as x position, third byte as life, fourth byte as score, 
PLAYER_STATE: 
	.word 0

.align 2
# Bullet represented as y/x position, i.e. 0xYYYYXXXXX value of 0 means dead
PLAYER_BULLET:
  .word 0

.align 2
# Enemy bullets array, max 10 bullets at a time (10x4byte ints as 0xYYYYXXXX)
ENEMY_BULLETS:
  .space(40)

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
SHIELD_POSITIONS:
  .word(0x00000000)
  .word(0x00000000)
  .word(0x00000000)
  .word(0x00000000)


.global PLAYER_STATE
.global PLAYER_BULLET
.global ENEMY_BULLETS
.global SHIELD

.text

.global RestartGame
.global GameLoop
.global Fire
.global PlayerHit

#
# Restart the game
#
RestartGame:
	
	# Initialize player
	# Position width/2, score 0, life 3
	movia r8, 0x000300A0
	movia r9, PLAYER_STATE
	stw r8, 0(r9)

  # Zero player bullet
  movia r9, PLAYER_BULLET
  stw r0, 0(r9)

  # Zero enemy bullets
  movi r10, 10
  movia r9, ENEMY_BULLETS:
ZERO_ENEMY_BULLET:
  stw r0, 0(r9)
  addi r10, r10, -1
  addi r9, r9, 4
  bgt r10, r0, ZERO_ENEMY_BULLET

	# Initialize the enemies
#call INIT_INVADERS

	# Initialize shields
  movi r8, -1
INIT_SHIELD:
  addi r8, r8, 1

  # Get shield in array SHIELD[i*4] and set initial value
  movia r9, SHIELDS
  slli r10, r8, 2
  add r9, r9, r10
  movia r10, 0x3CFFFFFF
  #stw r9, 0(r10)

  # Loop while i < 4
  movi r9, 4
  blt r8, r9, INIT_SHIELD

	ret

# 
# Game logic here
#
GameLoop:
	addi sp, sp, -20
	stw ra, 0(sp)
  stw r8, 4(sp)
  stw r9, 8(sp)
  stw r10, 12(sp)
  stw r11, 16(sp)

	call UpdatePlayer
  call UpdateBullets
  call CheckCollision

	ldw ra, 0(sp)
  ldw r8, 4(sp)
  ldw r9, 8(sp)
  ldw r10, 12(sp)
  ldw r11, 16(sp)
	addi sp, sp, 20
	ret
# 
# Playerlogic
#
UpdatePlayer: 

	# Get current player state and input state
	movia r9, PLAYER_STATE
	ldw r8, 0(r9)
	movia r9, INPUT_STATE
	ldh r9, 0(r9)

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

	# Write player position to the leds
	#movia r9, ADDR_LEDS
	#stwio r8, 0(r9)

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
  ldw r8, 0(r9)
  andi r8, r8, 0xFFFF
  movia r9, PLAYER_YPOS
  or r8, r8, r9

  # Add an offset of half the players width (-y +x), and enough height to fire above the player (assume width 16 height 8)
  movia r9, 0xFFFC0008
  add r8, r8, r9

  # Store the bullet
  movia r9, PLAYER_BULLET
  stw r8, 0(r9)

FIRE_DONE:
	ret

#
# Fire enemy bullet
# @param r2 word, x/y position of bullet to create
FireEnemy:
  # First we need to see if there is a free bullet struct
  movia r9, ENEMY_BULLETS
  movi r10, 10
GET_BULLET:
  ldw r8, 0(r9)
  beq r8, r0, INIT_BULLET

  addi r9, r9, 4
  addi r10, r10, -1
  bgt r10, r0, GET_BULLET
  br FIRE_ENEMY_DONE

INIT_BULLET:
  # Set bullet to the input position
  stw r2, 0(r9)

FIRE_ENEMY_DONE:
  ret

# 
# Update all bullets
#
UpdateBullets:
  
  # First just the player bullet
  movia r9, PLAYER_BULLET
  ldw r8, 0(r9)
  beq r8, r0, ENEMY_BULLETS

  # Move the bullet up 1
  srli r10, r8, 16
  subi r10, r10, SPEED_BULLET
  
  # If its above the screen bounds zero it out
  bgt r10, r0, PLAYER_B_APPLY
  mov r8, r0
  stw r8, 0(r9)
  br ENEMY_BULLETS
 
PLAYER_B_APPLY:
  slli r10, r10, 16
  andi r8, r8, 0xFFFF
  or r8, r8, r10
  stw r8, 0(r9)


ENEMY_BULLETS:
  # Now all the enemy bullets
  movia r9, ENEMY_BULLETS
  movi r10, 10
ENEMY_B_MOVE:
  ldw r8, 0(r9)
  beq r8, r0, NEXT_B

  # Valid bullet, move it
  srli r10, r8, 16
  addi r10, r10, SPEED_BULLET
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

NEXT_B:
  addi r9, r9, 4
  addi r10, r10, -1
  bgt r10, r0, ENEMY_B_MOVE
  br BULLET_DONE

BULLET_DONE:
  # Debug
  #movia r9, ADDR_LEDS
  #srli r8, r8, 16
  #stwio r8, 0(r9)
  ret


# 
# Handle player hit by bullet
PlayerHit:
  movia r9, PLAYER_STATE
  ldw r8, 0(r9)
  srli r8, r8, 16
  andi r8, r8, 0xFF # r8 has life now

  addi r8, r8, -1

  bgt r8, r0, PLAYER_HIT_DONE
  # No more life
  call RestartGame

PLAYER_HIT_DONE:
  ret 



