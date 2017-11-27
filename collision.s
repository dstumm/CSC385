.data
.equ BULLET_SIZE, 0x00030001  # 1x3
.equ ENEMY_SIZE, 0x00100008   # 16x8 
.equ PLAYER_SIZE, 0x00100008  # 16x8
.equ SHIELD_SIZE, 0x00200010  # 32x16

.text
.global CheckCollision
CheckCollision:
  addi sp, sp, -20
  stw r16, 0(sp)
  stw r17, 4(sp)
  stw r18, 8(sp)
  stw r19, 12(sp)
  stw r20, 16(sp)
  stw r21, 18(sp)

  # Check player bullet against enemies, shields

  
  # Check enemy bullets against player, shields
  call CheckEnemyBullets

COLLISION_DONE:
  ldw r16, 0(sp)
  ldw r17, 4(sp)
  ldw r18, 8(sp)
  ldw r19, 12(sp)
  ldw r20, 16(sp)
  ldw r21, 18(sp)
  addi sp, sp, 24
  ret

CheckEnemyBullets:
  # Get player position
  movia r16, PLAYER_STATE
  ldw r16, 0(r16)
  movia r17, 0x0000FFFF
  and r16, r16, r17
  movia r17, PLAYER_YPOS
  or r16, r16, r17      # Player position in r16
  
CHECK_ENEMY_BULLETS:
  movi r17, 0           # Save bullet counter
ENEMY_B_CHECK:
  movia r8, ENEMY_BULLETS
  slli r9, r17, 2       # Multiply counter by 4
  add r8, r9, r9
  ldw r18, 0(r8)        # Save reference to bullet
  beq r18, r0, NEXT_B

  # Valid bullet, check collision against player and shields
  # Player first
  mov r4, r18            # rectA.pos
  movia r5, BULLET_SIZE # rectA.size
  mov r6, r16           # rectB.pos
  movia r7, PLAYER_SIZE # rectB.size

  call ABAB

  beq r2, r0, CHECK_SHIELD:
  # Bullet collision, zero it out, apply to player
  stw r0, 0(r18)
  call PlayerHit
  br CHECK_NEXT_B

CHECK_SHIELD:
  # I could loop.. or i could not
  movi r19, 0           # Save shield counter
S_CHECK:
  # First 2 params are bullet
  mov r4, r18           # rectA.pos
  movia r5, BULLET_SIZE # rectA.size

  mov r6, r0            # Offset of current shield rect
  movia r7, SHIELD_SIZE # Starting shield rect
  addi sp, sp, -4        # Which shield
  stw r19, 0(sp)

  # Call recursive function on shield, returns collision happens in r2, collision row/column in r3
  call CheckShield

  addi sp, sp, 4

  beq r2, r0, CHECK_NEXT_S
  # Collision, for now we zero it out, later we need to call another check to check individual pixels
  # TODO call ShieldPixelCheck with bullet position, bullet size, and shield reference r20
  stw r0, 0(r18)
  br CHECK_NEXT_B

CHECK_NEXT_S:
  addi r19, r19, 1
  movi r8, 4
  blt r19, r8, S_CHECK

CHECK_NEXT_B:
  addi r17, r17, 1
  movi r8, 10
  blt r17, r8, ENEMY_B_CHECK

# Were done
  ret

# 
# ABAB test, given rect A rect B, return if they overlay
# Rect as 2 words postition:0xYYYYXXXX, size:0xHHHHWWWW
# @param r4, r5 positionA, sizeA
# @param r6, r7 positionB, sizeB
# @return r2 1 if overlap, 0 if not
ABAB:
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

#
# Check Shield
# This is a recursive function to check exactly which pixel/chunk of the shield the bullet is colliding with
# Starts with entire bounds, then splits it into 4 and checks each of those, and so on until we reach our base case chunk size
# If there is a collision we'll flag those bits of the shield off
# @param r4, position of target
# @param r5, size of target
# @param r6, offset of shield rect
# @param r7, current bounds of shield check
# @param 0(sp), shield number
# @return r2, collision 1, not 0
#
CheckShield:
  # Get the shield number offset (num*4)
  ldw r10, 0(sp)
  slli r10, r10, 2

  # Save a couple callee that we can rely on
  addi sp, sp, -16
  stw r16, 0(sp)
  stw r17, 4(sp)
  stw r18, 8(sp)
  stw ra, 12(sp)

  # Now we can safely keep shield number and original offset and use it anywhere in the function
  mov r16, r10
  mov r17, r6
  mov r18, r7

  # Get the position of the bounds rect and add it to offset
  movia r8, SHIELD_POSITIONS
  add r9, r16, r8
  add r6, r6, r9

  # Call the abab 
  call ABAB

  # If theres no collision return
  bne r2, r0, SHIELD_COL
  br SHIELD_NOCOL

SHIELD_COL:
  # We have a collision, are we at the base case? (size = 1x1)
  movia r8, 0x00010001
  bne r7, r8, SPLIT

  # Get the row bit, and shift a 1 to that position (i.e. 3 = 0b1000
  andi r9, r6, 0xFFFF
  movia r10, 0x80000000 # 1 in the highest position
  srl r10, r10, r9

  # Get the column offset, and shift it up 8xcolumn
  srli r9, r6, 16
  slli r9, r9, 3  # x 8

  # Get final bitmap
  srl r10, r10, r9

  # Get the value of this bit
  movia r8, SHIELDS
  add r8, r8, r16
  ldw r9, 0(r8)        # Load shield itself

  and r10, r10, r9

  # Return whethers theres a collision or not
  beq r10, r0, SHIELD_NOCOL
  # If theres a collision flip the bit off, return a 1
  movi r11, 0xFFFFFFFF
  xor r10, r10, r11
  and r9, r9, r19
  stw r9, 0(r8)
  movi r2, 1
  br CHECK_SHIELD_DONE

SHIELD_NOCOL:
  movi r2, 0
  br CHECK_SHIELD_DONE

SPLIT:
  # Here is where we recurse. We need to make 4 recursive calls to each quadrant of the current bounds
  # First we know we can divide the bounds by 2 
  andi r8, r7, 0xFFFF 
  srli r8, r8, 1     # Width/2

  # The height will reach one before the width, so only split if its greater than one
  srli r9, r7, 16
  beq r9, r10, SKIP_DIV
  srli r9, r7, 1     # Height/2
SKIP_DIV:
  slli r9, r9, 16
  or r7, r8, r9       # New bounds/2
  
  # Save the new bounds call CheckShield with offsets (0, 0)(width, 0)(0, height)(width, height)
  mov r18, r7 #bounds

  # First call changes nothing (0,0)
  call CheckShield
  # If theres a collision return
  movi r10, 1
  beq r10, r2, CHECK_SHIELD_DONE
  
  # (width, 0) 
  andi r8, r18, 0xFFFF
  add r6, r17, r8 # original offset + width
  mov r7, r18
  call CheckShield
  # If theres a collision return
  movi r10, 1
  beq r10, r2, CHECK_SHIELD_DONE

  # (0, height) 
  movia r10, 0xFFFF0000
  and r8, r18, r10
  add r6, r17, r8 # original offset + height
  mov r7, r18
  call CheckShield
  # If theres a collision return
  movi r10, 1
  beq r10, r2, CHECK_SHIELD_DONE

  # (width, height) 
  add r6, r17, r18 # original offset + bounds
  mov r7, r18
  call CheckShield
  # If theres a collision return
  movi r10, 1
  beq r10, r2, CHECK_SHIELD_DONE

  # If were here there was no collision double check we return 0
  movi r2, 0
  br CHECK_SHIELD_DONE

CHECK_SHIELD_DONE:
  ldw r16, 0(sp)
  ldw r17, 4(sp)
  ldw r18, 8(sp)
  ldw ra, 12(sp)
  addi sp, sp, 16
  ret
