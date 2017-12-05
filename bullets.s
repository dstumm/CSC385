.text
.global Fire, FireEnemy, UpdateBullets, EnemyCheckFire
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
	movia r11, SPEED_PLAYER_BULLET
	sub r10, r10, r11

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
	slli r11, r10, 16
	andi r8, r8, 0xFFFF
	or r8, r8, r11
	stw r8, 0(r9)

	addi sp, sp, -12
	stw ra, 0(sp)
	stw r9, 4(sp)
	stw r12, 8(sp)
	mov r4, r9
	movia r5, ENEMY_BULLET_SPRITE

	# Add offset into sprite based off height to animate
	srli r10, r10, 3 # Height / 8
	andi r10, r10, 1
	movi r11, 10 # Sprite size
	mul r10, r10, r11
	add r5, r5, r10

	movia r6, 0xFFFF
	call drawing_draw_bitmap
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
	movia r9, 0x00000008
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
