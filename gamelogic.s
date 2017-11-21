.data
.equ SPEED, 0x4

.align 2
# Player state has first byte as life, second byte as score, third and forth as position
PLAYER_STATE: 
	.word 0

.text

.global RestartGame
.global GameLoop
.global Fire
#
# Restart the game
#
RestartGame:
	
	# Initialize player
	# Position 160, score 0, life 3
	movia r8, 0x00A00003
	movia r9, PLAYER_STATE
	stw r8, 0(r9)

	# Initialize the enemies

	# Initialize shields

	ret

# 
# Game logic here
#
GameLoop:
	ret
	addi sp, sp, -4
	stw ra, 0(sp)

	call UpdatePlayer

	ldw ra, 0(sp)
	addi sp, sp, 4
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
	srli r10, r8, 16
	subi r10, r10, SPEED
	bgt r10, r0, INBOUNDS_LEFT
	# If its over bounds, just set it to the bound
	mov r10, r0
INBOUNDS_LEFT:
	slli r10, r10, 16
	andi r8, r8, 0xFFFF
	or r8, r8, r10
	
	br PLAYER_DONE

MOVE_RIGHT:
	# Calculate new position
	srli r10, r8, 16
	addi r10, r10, SPEED
	movi r11, 320
	blt r10, r11, INBOUNDS_RIGHT
	# If its over bounds, just set it to the bound
	mov r10, r11

INBOUNDS_RIGHT:
	# Apply if its within bounds
	slli r10, r10, 16
	andi r8, r8, 0xFFFF
	or r8, r8, r10

	br PLAYER_DONE

PLAYER_DONE:
	# Apply new player state
	movia r9, PLAYER_STATE
	stw r8, 0(r9)

	# Write player position to the leds
	#movia r9, ADDR_LEDS
	#srli r10, r8, 16
	#stw r10, 0(r9)

	ret

# 
# Fire
#
Fire:
	ret