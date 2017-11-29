.data
.global UpdatePlayer, PlayerHit
.text
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
	br PLAYER_DONE

PLAYER_DONE:
	# Apply new player state
	movia r9, PLAYER_STATE
	stw r8, 0(r9)

	# Draw it
	movia r4, PLAYER_STATE
	movia r5, ALIEN_SPRITE_MEDIUM
	movia r6, GREEN
	call drawing_draw_bitmap

	ldw ra, 0(sp)
	addi sp, sp, 4
	ret

# 
# Handle player hit by bullet
#
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
