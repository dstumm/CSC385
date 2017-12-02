.data

.align 2
ALIEN_DUMMY:
.word 0
.word 0x00100008

.text
.global CheckCollision
CheckCollision:
    addi sp, sp, -8 
    stw ra, 0(sp)
    stw r16, 4(sp)

    # The only collision really is with bullets

COL_ENEMY_BULLETS:
    movi r16, 0           # Save bullet counter
ENEMY_B_COL:
    movia r8, ENEMY_BULLETS
    slli r9, r16, 3       # Multiply counter by 8
    add r8, r8, r9
    ldw r9, 0(r8)        # Save reference to bullet
    beq r9, r0, COL_NEXT_B

    # Bullet is arg 1, arg 2 is player/enemy 0/1 call checker
    mov r4, r8
    movi r5, 1
    call CheckBullet

COL_NEXT_B:
    addi r16, r16, 1
    movi r8, 10
    blt r16, r8, ENEMY_B_COL
    br COL_PLAYER_BULLET

COL_PLAYER_BULLET:
    movia r8, PLAYER_BULLET
    ldw r9, 0(r8)
    beq r9, r0, COLLISION_DONE 

    # Bullet is arg 1, arg 2 is 0 for player
    mov r4, r8
    movi r5, 0
    call CheckBullet

COLLISION_DONE:
    ldw ra, 0(sp)
    ldw r16, 4(sp)
    addi sp, sp, 8
    ret

# 
# Check the individual bullet
#
CheckBullet:
    addi sp, sp, -16
    stw ra, 0(sp)
    stw r16, 4(sp)
    stw r17, 8(sp)
    stw r18, 12(sp)

    # Save bullet and check type
    mov r16, r4
    mov r17, r5

    # Check collision against player and shields
    beq r17, r0, CHECK_PLAYER_BULLET

    # 
    # Check all enemy bullets against player and player bullet
CHECK_ENEMY_BULLET:
AGAINST_PLAYER:
    # Player first
    mov r4, r16           # Bullet struct
    movia r5, PLAYER_STATE
    call ABAB
    beq r2, r0, AGAINST_PLAYER_BULLET

    # Bullet collision to player, zero it out, apply to player
    stw r0, 0(r16)
    # TODO: call pixel wise collision checker
    call PlayerHit
    br CHECK_DONE

    # Player bullet
AGAINST_PLAYER_BULLET:
    mov r4, r16
    movia r5, PLAYER_BULLET
    call ABAB
    beq r2, r0, ALL_BULLETS

    # Bullet to bullet collision, zero them both out
    stw r0, 0(r16)
    movia r8, PLAYER_BULLET
    stwo, r0, 0(r8)
    br CHECK_DONE

# 
# Check player bullet against all enemies
#
CHECK_PLAYER_BULLET:
    # Index into invasion
    movi r18, 0

    CHECK_ENEMY:

    movia r8, ALIENS
    add r8, r8, r18           # r8 has index into Aliens, we need to calculate the position
ldb r8, 0(r8)
    andi r8, r8, 0x1      # r8 is this aliens state
    movi r9, 2
    bne r8, r9, CHECK_NEXT_ENEMY # 2 = alive, only collide with living aliens

# Alien is alive, get its actual
    mov r4, r18
    call GET_ALIEN_POSITION

    mov r4, r16           # Bullet struct
    movia r5, ALIEN_DUMMY # Alien dummy
    stw r2, 0(r5)         # Load position get getter

    call ABAB

    beq r2, r0, CHECK_NEXT_ENEMY:
# Bullet collision to enemy, zero it out
stw r0, 0(r16)
    mov r4, r18
    call KILL_ALIEN
# r2 has pointers, r3 has remaining alive aliens

    CHECK_NEXT_ENEMY:
    addi r18, r18, 1
    movi r8, 55
    blt r18, r8, CHECK_ENEMY
    br ALL_BULLETS

#
# Check all bullets against shield
#
    ALL_BULLETS:
    movi r18, 0           # Save shield counter
    CHECK_SHIELD:

# First 2 params are bullet
    mov r4, r16           # Bullet
    movia r5, SHIELDS
    slli r8, r18, 3
    add r5, r5, r8        # Shield pointer

    movi r9, 352
    mul r8, r18, r9
    movia r6, SHIELD_STATES
    add r6, r6, r8        # Sprite pointer
    mov r7, r17           # Player/enemy bullet

# Call recursive function on shield, returns collision happens in r2, collision row/column in r3
    call CheckShield
    beq r2, r0, CHECK_NEXT_S

# Zero the bullet out
stw r0, 0(r16)
    br CHECK_DONE

    CHECK_NEXT_S:
    addi r18, r18, 1
    movi r8, 4
    blt r18, r8, CHECK_SHIELD

    CHECK_DONE:
    ldw ra, 0(sp)
    ldw r16, 4(sp)
    ldw r17, 8(sp)
ldw r18, 12(sp)
    addi sp, sp, 16
    ret

#
# Check Shield
# If there is a collision we'll flag those bits of the shield off
# @param r4, bullet pointer
# @param r5, shield pointer
# @param r6, shield state
# @param r7, player 0 or enemy 1 bullet
# @return r2, collision 1, not 0
#
    CheckShield:
# Save a few callee that we can rely on
    addi sp, sp, -24
    stw r16, 0(sp)
    stw r17, 4(sp)
    stw r18, 8(sp)
    stw r19, 12(sp)
    stw r20, 16(sp)
stw ra, 20(sp)

# Now we can safely keep shield number and original offset and use it anywhere in the function
    mov r16, r4
    mov r17, r5
    mov r18, r6
    mov r19, r7

# First we call ABAB on the bullet and shield
    call ABAB

# If theres no collision return
    bne r2, r0, SHIELD_COL
    br SHIELD_NO_COL

    SHIELD_COL:
# Bullet and shield positions
    ldw r8, 0(r16)
ldw r9, 0(r17)

# Need to check all 4 bits of the bullet
    movi r20, 0
    CHECK_BIT:
# Get the offset of the bullet into the shield
    sub r10, r8, r9 # offset of bullet into shield

# There are 4 bits we need to check, from bullet position to bullet position + 3
# Add into the offset based on the counter 
# The direciton of the check depends on whether its from its form the enemy or player
    beq r19, r0, BIT_PLAYER
    BIT_ENEMY:
    slli r11, r20, 16
    add r10, r10, r11
    br GET_BIT

    BIT_PLAYER:
    movi r11, 3
    sub r11, r11, r20
    slli r11, r11, 16
    add r10, r10, r11
    br GET_BIT

    GET_BIT:
    # Get the address of the row by multiplying the y offset by 22
    srli r11, r10, 16
    # THIS WAS A GARBAGE ONE OFF ERROR THAT TOOK HOURS TO FIX ARRGGGG
    subi r11, r11, 1
    movi r12, 22
    mul r11, r11, r12 

    # Column is just the x
    andi r12, r10, 0xFFFF

    # Bit is now at SPRITE + r11 + r12
    add r13, r11, r12
    # If its greater or equal to 352 we've gone over into the next
    movi r11, 352
    bge r13, r11, NEXT_BIT
    add r11, r13, r18 # r11 now has pointer to the byte with the pixel at the position of the bullet

    # Load the byte
    ldb r11, 0(r11)

    # Return whethers theres a collision or not
    beq r11, r0, NEXT_BIT

    SHIELD_BIT_COL:
    # If theres a collision flip the bit off, return a 1
    # Pass the bitmap and offset in to the bitmap
    mov r4, r18
    mov r5, r10

    call ShieldHit
    movi r2, 1
    br CHECK_SHIELD_DONE

    NEXT_BIT:
    addi r20, r20, 1
    movi r10, 4
    blt r20, r10, CHECK_BIT

    # If were here there was collision
    SHIELD_NO_COL:
    movi r2, 0
    br CHECK_SHIELD_DONE

    CHECK_SHIELD_DONE:
    ldw r16, 0(sp)
    ldw r17, 4(sp)
    ldw r18, 8(sp)
    ldw r19, 12(sp)
    ldw r20, 16(sp)
ldw ra, 20(sp)
    addi sp, sp, 24
    ret 

# Shield has been hit, destroy a number of pixels at that location
# @param r4 sprite of the shield
# @param r5 pixel index into the sprite from the top left
ShieldHit:
    addi sp, sp, -8
    stw r16, 0(sp)
    stw r17, 4(sp)
    # Go in loop from (-2, -2) to (2, 2)
    # Depending on distance from center, set a probability of destruction

    # Random seed
    add r16, r4, r5

    # Row
    movi r9, -2 # y
DESTROY_ROW:
    # Column
    movi r8, -2 # x

DESTROY_PIXEL:

    # First do bounds check if this is even part of the shield
    # Add offset to original offset
    slli r17, r9, 16
    add r17, r17, r5
    add r17, r17, r8

    # Check its within the bounds of the shield
    srli r11, r17, 16
    movi r12, 22
    bge r11, r12, NEXT_PIXEL
    blt r11, r0, NEXT_PIXEL
    andi r11, r17, 0xFFFF
    movi r12, 16
    bge r11, r12, NEXT_PIXEL
    blt r11, r0, NEXT_PIXEL

    # Within bounds, do a probability check
    # Calculate distance from center
    add r10, r8, r9
    # Add/Subtract 1 will give a number between 0 and 3 giving three different probabilities
    bgt r10, r0, SUB_1
    blt r10, r0, ADD_1
    br PROB
ADD_1:
    add r10, r10, 1
    br PROB
SUB_1:
    subi r10, r10, 1
    br PROB
PROP:
    # Multiply by 3 to get number between 0 and 9
    movi r11, 3
    mul r11, r10, r11

    # Subtract from 10, so that pixels with distance 0 represent 10, and distance 3 represent 1. With the numbers representing probability out of 8 of being destroyed
    movi r10, 10
    sub r10, r10, r11

    # Get the first 4 bits of the seed
    andi r11, r16, 0xF

    # If r10 is greater than these 4 bits, destroy the pixel
    blt r10, r11, NEXT_PIXEL

    # Pass bounds and probability check
    # Can calculate actual pixel now
    slri r11, r17, 16
    subi r11, r11 1
    movi r12, 22
    mul r11, r11, r12
    andi r12, r10, 0xFFFF
    add r13, r11, r12

    # If its greater or equal to 352 we've gone over into the next
    movi r11, 352
    bge r13, r11, NEXT_PIXEL
    add r11, r13, r16 # r11 now has pointer to the byte with the pixel at the position of the bullet

    # Zero it out
    stb r0, 0(r11)

    # Ready for next pixel
NEXT_PIXEL:
    # Shift seed and add random stuff
    srli r16, r16, 1
    add r16, r16, r11

    # Increment x, if greater than width go to next row
    addi r8, r8, 1
    movi r10, 22
    bge r8, r10, NEXT_ROW
    br DESTROY_PIXEL
    
NEXT_ROW:
    addi r9, r9, 1
    movi r10, 16
    bge r9, r10, SHIELD_HIT_DONE
    br DESTROY_ROW

SHIELD_HIT_DONE:
    ldw r16, 0(sp)
    ldw r17, 4(sp)
    addi sp, sp, 8
    ret

# 
# ABAB test, given rect A rect B, return if they overlay
# Rect as 2 words postition:0xYYYYXXXX, size:0xHHHHWWWW
# @param r4, struct A, position/size
# @param r5, struct A, position/size
# @return r2 1 if overlap, 0 if not
ABAB:
    addi sp, sp, -4
stw ra, 0(sp)

    # Load and spread across r6, r7
    ldw r6, 0(r5)
    ldw r7, 4(r5)
    ldw r5, 4(r4)
ldw r4, 0(r4)

    call ABAB_NO_STRUCT

ldw ra, 0(sp)
    addi sp, sp, 4
    ret

# 
# ABAB that takes its arguments as 
# r4, r5 with positionA and sizeA, 
# r6, r7 with positionB and sizeB
ABAB_NO_STRUCT:
    # Basically we do the opposide of an overlap, check if A is outside of B
    #AX
    andi r8, r6, 0xFFFF  # B's x
    andi r9, r7, 0xFFFF  # B's width
    add r8, r8, r9      # B's right edge

    andi r9, r4, 0xFFFF  # A's x
    bgt r9, r8, NOCOL    # If A's x is greater than B's right edge, no collision

    #AY
    srli r8, r6, 16      # B's y
    srli r9, r7, 16      # B's height
    add r8, r8, r9      # B's top edge

    srli r9, r4, 16      # A's y
    bgt r9, r8, NOCOL    # If A's y is greater than B's top edge, no collision

    
    #AWidth
    andi r8, r6, 0xFFFF  # B's x

    andi r9, r4, 0xFFFF  # A's x
    andi r10, r5, 0xFFFF # A's width
    add r9, r9, r10     # A's right edge
    blt r9, r8, NOCOL    # If A's right edge is less than B's x, no collision

    #AHeight
    srli r8, r6, 16      # B's Y

    srli r9, r4, 16      # A's y
    srli r10, r5, 16     # A's height
    add r9, r9, r10     # A's top edge
    blt r9, r8, NOCOL    # If A's top edge is less than B's y, no collision

    # If we got here there must be overlap
    COL:
    movi r2, 1
    ret

    NOCOL:
    movi r2, 0
    ret

