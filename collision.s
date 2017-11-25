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
  movia r9, SHIELDS
  slli r10, r19, 2      # Multiply counter by 4
  add r9, r9, r10
  ldw r20, 0(r9)        # Load shield itself
  movia r9, SHIELD_POSITIONS
  ldw r9, 0(r9)         # Load predifined shield position

  mov r4, r18           # rectA.pos
  movia r5, BULLET_SIZE # rectA.size
  mov r6, r9            # rectB.pos
  movia r7, SHIELD_SIZE # rectB.size

  call ABAB

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
  

