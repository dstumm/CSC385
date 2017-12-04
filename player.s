.data
.align 1
RESPAWN:
    .hword(0)

.text
.global UpdatePlayer, PlayerHit

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

	# Update the respawn
	movia r10, RESPAWN
	ldh r11, 0(r10)
	beq r11, r0, CHECK_FIRE

	# Otherwise we're waiting to respawn, decrement
	subi r11, r11, 1
	stw r11, 0(r11)

	# If its equal to zero, reset self, otherwise draw explosion set
	beq r11, r0, RESET

	movia r4, PLAYER_STATE

	# Depending on respawn number, set to different sprite
	srli r12, r11, 4
	andi r12, r12, 0x1
	movia r13, 128
	mul r12, r12, r13
	movia r5, PLAYER_SPRITE_RESPAWN
	add r5, r5, r12

	movia r6, GREEN
	call drawing_draw_bitmap

	br PLAYER_DONE

RESET:
	# If life is zero restart game
	ldh r10, 4(r9)
	srli r10, r10, 16
	bgt r10, r0, REG_RESET
	call RestartGame
	br PLAYER_DONE

REG_RESET:
	# Reset player position and life
	movia r10, 0x00d00098
	stw r10, 0(r9)


CHECK_FIRE:
	# Check for pending fire
	andi r10, r9, SPACE_KEY
	beq r10, r0, CHECK_MOVEMENT

	# Fire
	addi sp, sp, -8	
	stw r8, 0(sp)
	sth r9, 4(sp)
	call Fire	
	movia r4, 0x001000B0
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
	br PLAYER_APPLY

MOVE_LEFT:
	# Calculate new position
	andi r9, r8, 0xFFFF
	movia r11, SPEED_PLAYER
	sub r9, r9, r11
	movi r10, LEFT_BOUND
	bgt r9, r10, MOVE_APPLY
	# If its over bounds, just set it to the bound
	mov r9, r10
	br MOVE_APPLY

MOVE_RIGHT:
	# Calculate new position
	andi r9, r8, 0xFFFF
	addi r9, r9, SPEED_PLAYER
	movi r10, RIGHT_BOUND # 320 - playerwidth (16)
	subi r10, r10, 16 
	blt r9, r10, MOVE_APPLY
	# If its over bounds, just set it to the bound
	mov r9, r10
	br MOVE_APPLY
    
MOVE_APPLY:
	movia r10, 0xFFFF0000
	and r8, r8, r10
	andi r9, r9, 0xFFFF
	or r8, r8, r9
	br PLAYER_APPLY

PLAYER_APPLY:
	# Apply new player state
	movia r9, PLAYER_STATE
	stw r8, 0(r9)

	# Draw it
	movia r4, PLAYER_STATE
	movia r5, PLAYER_SPRITE
	movia r6, GREEN
	call drawing_draw_bitmap

PLAYER_DONE:
	ldw ra, 0(sp)
	addi sp, sp, 4
	ret

# 
# Handle player hit by bullet
#
PlayerHit:
	addi sp, sp, -4
	stw ra, 0(sp)

    # If were respawning don't take off more life
    movia r10, RESPAWN
    ldh r10, 0(r10)
    bgt r10, r0, PLAYER_HIT_DONE

    movia r9, PLAYER_STATE
    ldw r8, 8(r9)
    srli r10, r8, 16 # r10 has life now

    # If its already zero quit
    beq r10, r10, PLAYER_HIT_DONE

    # Set the respawn
    movia r10, 0x78
    movia r11, RESPAWN
    stw r10, 0(r11)

PLAYER_LOSE_LIFE:
	# Apply the loss of life
    addi r10, r10, -1
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
