.text
.global INIT_INVASION, DRAW_INVASION, MOVE_INVASION, KILL_ALIEN, UPDATE_INVASION, GET_ALIEN
.global ALIEN_SPRITE_MEDIUM, ALIENS, GET_ALIEN_POSITION

# Initialize all aliens and invasion state for the given level.
# 
# r4: level
INIT_INVASION:
    movia r6, INVASION_STATE
    movi r7, 1                                      # set direction to right
    slli r7, r7, 8
    addi r7, r7, ALIEN_ROWS * ALIEN_COLS            # set number of alive aliens
    stw r7, 0(r6)

    movia r6, INVASION_POSITION                     # set invasion position
    movia r7, ALIEN_START_TABLE                     # get y start position for level
    add r7, r7, r4
    ldbu r8, 0(r7)
    slli r8, r8, 16
    movi r9, (320 - (ALIEN_COLS * ALIEN_SPRITE_WIDTH)) / 2
    or r8, r8, r9
    stw r8, 0(r6)

    movia r6, ALIENS                                # set all aliens to alive
    addi r7, r6, ALIEN_ROWS * ALIEN_COLS
    movi r8, 0x01
INIT_ALIEN_STATE:
    stb r8, 0(r6)
    addi r6, r6, 1
    blt r6, r7, INIT_ALIEN_STATE


    # Initialize move and fire counters
    movia r9, MOVE_COUNTER
    movia r10, 100
    stw r10, 0(r9)
    movia r9, FIRE_COUNTER
    movia r10, 200
    stw r10, 0(r9)

    movia r6, INVASION_MOVE_TIMER                   # reset move timer
    stw r0, 0(r6)

    movia r6, INVASION_SHOT_TIMER                   # reset shot timer
    stw r0, 0(r6)

    ret

UPDATE_INVASION:
    subi sp, sp, 4
    stw ra, 0(sp)

    call DRAW_INVASION
    call MOVE_INVASION
    call INVASION_AI

    ldw ra, 0(sp)
    addi sp, sp, 4
    ret

# Draws all the aliens.
DRAW_INVASION:
    subi sp, sp, 44
    stw ra, 40(sp)
    stw r16, 36(sp)
    stw r17, 32(sp)
    stw r18, 28(sp)
    stw r19, 24(sp)
    stw r20, 20(sp)
    stw r21, 16(sp)
    stw r22, 12(sp)
    stw r23, 8(sp)
    # rest of stack space is for a rectangle structure

    mov r16, r0                                     # r16: row index
    movia r17, ALIENS                               # r17: alien address
                                                    # r18: end row, will set later

    mov r19, r0                                     # r19: sprite offset

    movia r4, INVASION_POSITION
                                                    # r20: x position, will set later
    ldh r21, 2(r4)                                  # r21: y position
    addi r21, r21, ALIEN_SPRITE_HEIGHT              #      adjust to to top instead of bottom
    slli r21, r21, 16

                                                    # r22: sprite address, set later
                                                    # r23: color, set later

    movi r6, ALIEN_SPRITE_HEIGHT                    # store size of sprite in rectangle struct
    slli r6, r6, 16
    ori r6, r6, ALIEN_SPRITE_WIDTH
    stw r6, 4(sp)

    movia r4, INVASION_STATE
    ldw r5, 0(r4)                                   # each alien type has two sprites
    movia r6, ALIEN_SPRITE_STATE_MASK
    and r5, r5, r6                                  # check which one we're using
    beq r5, r0, DRAW_ALIEN_ROW
    addi r19, r19, ALIEN_SPRITE_SIZE

    DRAW_ALIEN_ROW:
        movia r4, INVASION_POSITION
        ldh r20, 0(r4)                              # reset x position

        addi r18, r17, ALIEN_COLS                   # reset end of row
        
        srli r4, r16, 1                             # get table index
        slli r4, r4, 2

        movia r5, ALIEN_SPRITE_TABLE                # get alien sprite address
        add r5, r5, r4
        ldw r22, 0(r5)
        add r22, r22, r19                           # offset into sprite for alien state

        movia r5, ALIEN_COLOR_TABLE                 # get alien color
        add r5, r5, r4
        ldw r23, 0(r5)

        DRAW_ALIEN:
            ldb r4, 0(r17)                          # move along if alien is dead
            beq r4, r0, NEXT_ALIEN

            or r4, r20, r21
            stw r4, 0(sp)
            mov r4, sp                              # rectangle
            mov r5, r22                             # sprite
            mov r6, r23                             # color
			call drawing_draw_bitmap
        
        NEXT_ALIEN:        
            addi r17, r17, 1                        # next alien
            addi r20, r20, GRID_WIDTH               # increase x position
            blt r17, r18, DRAW_ALIEN                # row done?

        addi r16, r16, 1                            # next row

        movi r4, GRID_HEIGHT                        # decrease y position
        slli r4, r4, 16
        sub r21, r21, r4

        movi r4, ALIEN_ROWS
        blt r16, r4, DRAW_ALIEN_ROW                 # rows done?

    ldw ra, 40(sp)
    ldw r16, 36(sp)
    ldw r17, 32(sp)
    ldw r18, 28(sp)
    ldw r19, 24(sp)
    ldw r20, 20(sp)
    ldw r21, 16(sp)
    ldw r22, 12(sp)
    ldw r23, 8(sp)
    addi sp, sp, 44

    ret

MOVE_INVASION:
    movia r4, INVASION_STATE
    ldw r5, 0(r4)

    movia r6, INVASION_MOVE_TIMER
    ldw r7, 0(r6)                                   # ticks since last move
    andi r8, r5, 0xFF                               # number of alive aliens

    bge r7, r8, DO_MOVE                             # move more frequently when there are less aliens
    addi r7, r7, 1                                  # increment move timer ...
    stw r7, 0(r6)                                   # ...
    ret                                             # ... and done

DO_MOVE:
    stw r0, 0(r6)                                   # reset move timer

    movia r6, INVASION_DIRECTION_MASK               # get direction
    and r6, r5, r6

    movia r7, ALIEN_SPRITE_STATE_MASK               # toggle sprite state
    xor r5, r5, r7
    stw r5, 0(r4)

    beq r6, r0, MOVE_INVASION_LEFT

    MOVE_INVASION_RIGHT:
        #movia r4, MAX_X                             # check for collision with right edge of screen
        #call FIND_COLUMN                            #
        #blt r2, r0, DO_MOVE_RIGHT                   # invalid column, no collision, just move right

        #mov r4, r2                                  # valid column, possible collision
        #call FIND_IN_COLUMN                         # check for live alien in column
        #bgt r2, r0, MOVE_INVASION_DOWN              # alive alien in column, move down

        movia r6, INVASION_POSITION
        ldh r7, 0(r6)                               # current invasion x position
        movia r8, MAX_X                             # right edge of screen
        sub r8, r8, r7                              # get distance from invasion to edge

        movi r9, ALIEN_COLS * GRID_WIDTH            # no collision with edge of screen
        bge r8, r9, DO_MOVE_RIGHT                   # just move right

        movi r9, GRID_WIDTH                         # find column that would collide with edge
        div r8, r8, r9
 
        movia r10, ALIENS                           # check if any aliens are still alive in this column
        add r8, r10, r8                             # first alien to check
        addi r9, r10, ALIEN_ROWS * ALIEN_COLS       # end of aliens array
        movi r10, 1                                 # alive state
 
        CHECK_RIGHT_EDGE_COLLISION:
            ldb r11, 0(r8)
            beq r11, r10, MOVE_INVASION_DOWN        # an alive alien collided with edge, move down 
            addi r8, r8, ALIEN_COLS
            blt r8, r9, CHECK_RIGHT_EDGE_COLLISION
 
        DO_MOVE_RIGHT:                              # no collision, move aliens right
            addi r7, r7, 2
            sth r7, 0(r6)            

        ret

    MOVE_INVASION_LEFT:
        #movia r4, MIN_X                             # Check for collision with left edge of screen
        #call FIND_COLUMN                            # 
        #blt r2, r0, DO_MOVE_LEFT                    # invalid column, no collision, just move

        #mov r4, r2                                  # valid column, possible collision
        #call FIND_IN_COLUMN                         # check for live alien in column
        #bgt r2, r0, MOVE_INVASION_DOWN              # live alien found, move down

        movia r6, INVASION_POSITION
        ldh r7, 0(r6)                               # current invasion x position
        movia r8, MIN_X                             # left edge of screen
        sub r8, r8, r7                              # get distance from invasion to edge

        blt r8, r7, DO_MOVE_LEFT                    # no collision, just move left

        movi r9, GRID_WIDTH                         # find column that would collide with edge
        div r8, r8, r9
        
        movia r10, ALIENS                           # check if any aliens are still alive in this column
        add r8, r10, r8                             # first alien to check
        addi r9, r10, ALIEN_ROWS * ALIEN_COLS       # end of aliens array
        movi r10, 1                                 # alive state
        CHECK_LEFT_EDGE_COLLISION:
	        ldb r11, 0(r8)
	        beq r11, r10, MOVE_INVASION_DOWN        # an alive alien collided with edge, move down
	        addi r8, r8, ALIEN_COLS
	        blt r8, r9, CHECK_LEFT_EDGE_COLLISION   # no collision, move aliens left

        DO_MOVE_LEFT:
	        subi r7, r7, 2
	        sth r7, 0(r6)

            ret

    MOVE_INVASION_DOWN:
	    movia r6, INVASION_POSITION
	    ldh r7, 2(r6)                               # current y position
	    movi r8, ALIEN_DROP_DISTANCE
	    add r7, r7, r8
	    sth r7, 2(r6)

	    movia r6, INVASION_DIRECTION_MASK           # toggle direction
	    xor r5, r5, r6
	    stw r5, 0(r4)
	
    ret

# Fire bullets
INVASION_AI:
    subi sp, sp, 4
    stw ra, 0(sp)

    movia r4, PLAYER_STATE                          # get score
    ldw r5, 8(r4)

    movi r6, 0x30                                   # figure out the reload rate based on player's score 
    movi r7, 200
    blt r5, r7, CHECK_TIMER
    movi r6, 0x10
    movi r7, 1000
    blt r5, r7, CHECK_TIMER
    movi r6, 0x0B
    movi r7, 2000
    blt r5, r7, CHECK_TIMER
    movi r6, 0x08
    movi r7, 3000
    blt r5, r7, CHECK_TIMER
    movi r6, 0x07

CHECK_TIMER:
    movia r4, INVASION_SHOT_TIMER
    ldw r5, 0(r4)
    bge r5, r6, TRY_TO_FIRE                         # shot timer expired, try to fire
    
    addi r5, r5, 1                                  # increment shot timer and done
    stw r5, 0(r4)
    br INVASION_AI_DONE

TRY_TO_FIRE:
    call FIND_COLUMN
    blt r2, r0, INVASION_AI_DONE                    # no column is over the player, don't fire

    mov r4, r2
    call FIND_IN_COLUMN
    beq r2, r0, INVASION_AI_DONE                    # no alive aliens in the column, don't fire

    mov r4, r3
    call GET_ALIEN_POSITION

    movi r5, ALIEN_SPRITE_HEIGHT                    # adjust to bottom of sprite
    slli r5, r5, 16
    add r4, r2, r5

    movi r5, 2                                      # adjust to center of sprite
    movi r6, ALIEN_SPRITE_WIDTH
    div r5, r6, r5
    add r4, r4, r5

    call FireEnemy
    beq r2, r0, INVASION_AI_DONE                    # failed to fire

    movia r4, INVASION_SHOT_TIMER                   # reset shot timer
    stw r0, 0(r4)

INVASION_AI_DONE:
    ldw ra, 0(sp)
    addi sp, sp, 4
    ret
    
#
#PLAYER_BULLET_COLLISION:
#    subi sp, sp, 16
#    stw ra, 12(sp)
#
#    movia r5, ?????
#    ldw r4, 0(r5)                                   # find alive alien at bullet position
#    mov r5, sp
#    call GET_ALIEN
#
#    beq r2, r0, _NO_COLLISION                        # nothing alive there
#
#    movia r4,  ???
#    mov r5, sp
#    ldh r6, 2(r4)                                   # get y position of bullet
#    ldh r7, 2(r5)                                   # get y position of alien
#
#_GET_MIN_Y:
#    sub r8, r6, r7                                  # get position of top of bullet within sprite
#    bge r8, r0, _GET_MAX_Y
#    mov r8, r0                                      # top is outside sprite, reset to 0
#
#_GET_MAX_Y:
#    ldh r9, 6(r4)
#    add r9, r9, r6                                  # bottom of bullet
#    sub r9, r9, r7                                  # bottom of bullet within sprite
#    bge r9, r0, _GET_X
#    ldh r10, 6(r5)
#    ble r9, r10, _GET_X
#    movi r9, -1                                     # bottom of bullet is outside sprite
#
#_GET_X:
#    ldh r10, 0(r4)                                  # get x offset within sprite
#    ldh r11, 0(r5)                                  # (bullet guaranteed to be in range)
#    sub r10, r10, r11
#
#    
#
#_CHECK_PIXEL:
#    ble r8, r9, _NO_COLLISION
#    ldb ???, ???
#    bgt ???, r0, _COLLISION
#    add ???, ???, ???
#    addi r8, r8, 1
#    br _CHECK_PIXEL
#
#_COLLISION:
#    mov r4, ?
#    call KILL_ALIEN
#    # TODO: adjust score
#
#_NO_COLLISION:
#    ldw ra, 12(sp)
#    addi sp, sp, 16
#    ret

# Get the position of an alien at the given index
#
# r4: alien index
#
# Returns a word with the aliens position formatted 0xYYYYXXXXX
#
# r2: position
GET_ALIEN_POSITION:
    movi r5, ALIEN_COLS
    div r6, r4, r5                                  # row index
    mul r7, r6, r5
    sub r7, r4, r7                                  # column index

    movia r5, INVASION_POSITION

	ldh r2, 2(r5)                                   # current y position
    muli r6, r6, GRID_HEIGHT                        # compute row offset
    #addi r6, r6, ALIEN_SPRITE_HEIGHT
    sub r2, r2, r6                                  # subtract from current position

    ldh r8, 0(r5)                                   # current x position
    muli r7, r7, GRID_WIDTH                         # compute column offset
    add r8, r8, r7                                  # add to current position
	andi r8, r8, 0xFFFF

    slli r2, r2, 16                                 # combine x/y positions
    or r2, r2, r8

  ret

# Get alien for the given x/y position.
#
# r4: position
# r5: pointer to memory for position, size and sprite (12 bytes)
#
# r2: success
# r3: alien index
GET_ALIEN:
	addi sp, sp, -20
	stw ra, 0(sp)
	stw r16, 4(sp)
	stw r17, 8(sp)
	stw r18, 12(sp)
	stw r19, 16(sp)

    mov r17, r5
    movia r18, ALIENS

    srli r16, r4, 16                                # save y position

    movia r6, 0xFFFF                                # find column
    and r4, r4, r6                                 
    call FIND_COLUMN
    blt r2, r0, GET_FAILED  

    add r19, r18, r2
    sth r3, 0(r17)                                  # store x position

    mov r4, r16                                     # find row
    call FIND_ROW
    blt r2, r0, GET_FAILED
    sth r3, 2(r17)                                  # store y position

    muli r4, r2, ALIEN_COLS                         # make sure alien is alive
    add r19, r19, r4
    ldb r4, 0(r19)
    beq r4, r0, GET_FAILED

    movi r4, ALIEN_SPRITE_WIDTH                     # store sprite size
    sth r4, 4(r17)
    movi r4, ALIEN_SPRITE_HEIGHT
    sth r4, 6(r17)

    movia r4, INVASION_STATE
    ldw r5, 0(r4)
    movia r6, ALIEN_SPRITE_STATE_MASK
    and r5, r5, r6

    srli r2, r2, 1                                  # lookup sprite
    slli r2, r2, 2
    movia r6, ALIEN_SPRITE_TABLE
    add r6, r2, r2
    ldw r7, 0(r6)
    beq r5, r0, _STASH_SPRITE_ADDRESS
    addi r7, r7, ALIEN_SPRITE_SIZE

	br GET_CLEANUP
    
_STASH_SPRITE_ADDRESS:
    stw r7, 8(r17)
    
    movi r2, 1                                      # success
    sub r3, r19, r18                                # alien index

	br GET_CLEANUP

GET_FAILED:
    mov r2, r0
	br GET_CLEANUP

GET_CLEANUP:
	ldw ra, 0(sp)
	ldw r16, 4(sp)
	ldw r17, 8(sp)
	ldw r18, 12(sp)
	ldw r19, 16(sp)
	addi sp, sp, 20
    ret

# Kills the alien at the given index.
#
# r4: alien index
#
# Returns the points for the alien and the number of aliens still alive
#
# r2: points
# r3: remaining alive aliens
KILL_ALIEN:
    movia r5, ALIENS                                # mark alien as dead
    add r5, r5, r4
    stb r0, 0(r5)

    movi r5, ALIEN_COLS                             # get row index
    div r4, r4, r5                                  
    srli r4, r4, 1                                  # get offset into points table
    slli r4, r4, 2

    movia r5, ALIEN_POINTS_TABLE                    # get points
    add r5, r5, r4
    ldw r2, 0(r5)

    movia r5, INVASION_STATE                        # decrement alive count
    ldw r6, 0(r5)
    subi r6, r6, 1
    stw r6, 0(r5)

    andi r3, r6, 0xFF

    ret


# Find the column for the given x coordinate.
#
# r4: x coordinate
#
# r2: column index
# r3: x position of column
FIND_COLUMN:
    movia r5, INVASION_POSITION                      # get invasion position
    ldh r5, 0(r5)
    sub r4, r5, r4                                  # convert x coordinate relative to invasion position
    blt r4, r0, FIND_COLUMN_FAIL                    # out of bounds...

    movi r6, GRID_WIDTH                             # get column index
    div r2, r4, r6

    movi r6, ALIEN_COLS
    bge r2, r6, FIND_COLUMN_FAIL                    # out of bounds...

    muli r3, r2, GRID_WIDTH                         # compute x position for column
    add r3, r3, r17
    ret

FIND_COLUMN_FAIL:
    movi r2, -1
    ret

# Find the row for the given y coordinate.
#
# r4: y coordinate
#
# r2: row index
# r3: y position of row
FIND_ROW:
    movia r5, INVASION_POSITION                     # get invasion position
    ldh r5, 2(r5)
    sub r4, r4, r5                                  # convert y coordinate relative to invasion position
    blt r4, r0, FIND_ROW_FAIL                       # out of bounds...

    movi r6, GRID_HEIGHT                            # get row index
    div r2, r4, r6

    movi r6, ALIEN_ROWS                                
    bge r2, r6, FIND_ROW_FAIL                       # out of bounds....

    sub r2, r6, r2

    muli r3, r2, GRID_HEIGHT                        # compute y position for row
    add r3, r3, r5
    addi r3, r3, ALIEN_SPRITE_HEIGHT                # offset to top of sprite
    ret

FIND_ROW_FAIL:
    movi r2, -1
    ret

# Find an alive alien in the given column, starting at the lowest alien
#
# r4: column number
#
# r2: 1 if found
# r3: index of alien
FIND_IN_COLUMN:
    mov r2, r0
    mov r3, r0

    movi r5, ALIEN_COLS                             # is it a valid column index?
    blt r4, r0, NO_LIFE_IN_COLUMN
    bge r4, r5, NO_LIFE_IN_COLUMN

    movia r5, ALIENS                                # first alien
    addi r6, r5, N_ALIENS                           # end of aliens
    add r7, r5, r4                                  # first alien in column

    LIFE_CHECK:
        ldb r8, 0(r7)
        bgt r8, r0, LIFE_IN_COLUMN                  # found a live one
        addi r7, r7, ALIEN_COLS
        blt r7, r6, LIFE_CHECK

NO_LIFE_IN_COLUMN:
    ret
    
LIFE_IN_COLUMN:
    movi r2, 1
    sub r3, r7, r5

.data

.align  2
MOVE_COUNTER:
    .word 0

.align 2
FIRE_COUNTER:
    .word 0

.equ ALIEN_ROWS, 5
.equ ALIEN_COLS, 11
.equ N_ALIENS, 55
.equ ALIEN_SPRITE_WIDTH, 16
.equ ALIEN_SPRITE_HEIGHT, 8
.equ ALIEN_SPRITE_SIZE, 128
.equ ALIEN_DROP_DISTANCE, 8
.equ GRID_WIDTH, 16
.equ GRID_HEIGHT, 16
.equ MIN_X, 49
.equ MAX_X, 268
.equ INVASION_DIRECTION_MASK, 0x00000100
.equ ALIEN_SPRITE_STATE_MASK, 0x00010000

.align 2
INVASION_POSITION: 
    .word 0                                         # position of bottom left alien in grid
                                                    # base: x position
                                                    # base + 2: y position

.align 2    
INVASION_MOVE_TIMER: 
    .word 0                                         # counts up to next move

.align 2
INVASION_STATE: 
    .word 0                                         # state of invasion
                                                    # base: unused
                                                    # base + 1: sprite flag (0 primary, 1 secondary)
                                                    # base + 2: direction flag (0 right, 1 left)
                                                    # base + 3: number of aliens still alive

.align 2
INVASION_SHOT_TIMER:
    .word 0                                         # counts up from last shot


# Stores the state of each alien, 1 byte each.
# (0 = dead, 1 = exploding, 2 = alive)
#
# Aliens are stored by row starting at the bottom left of the grid.
#
# For an m x n grid the order is:
# (0, n - 1), (1, n - 1), ... (m - 1, n - 1),
# (0, n - 2), (1, n - 2), ... (m - 1, n - 2), 
# ..., 
# (0, 0), (1, 0), ... (m - 1, 0)
ALIENS: .skip 55

# Starting y position for the bottom left alien by level
#
# If they get past level 9, just repeat the same starting position
# and they'll play forever
ALIEN_START_TABLE:
    .byte 0x78
    .byte 0x90
    .byte 0xA0
    .byte 0xA8
    .byte 0xA8
    .byte 0xA8
    .byte 0xB0
    .byte 0xB0
    .byte 0xB0

# The following are tables of an alien row index to points/color/sprites.
#
# To compute the offset into the tables perform the follwing:
#
# movia r8, <row>  
# srli r8, r8, 1
# slli r8, r8, 2
#
# rows 0 & 1  -> offset 0
# rows 2 & 3  -> offset 4
# row 4 (top) -> offset 8
#
# (Yes, wasting some space for convenience)

.align 2
ALIEN_POINTS_TABLE:
    .word 10                    # bottom 2 rows
    .word 20                    # middle 2 row
    .word 30                    # top row

.align 2
ALIEN_SPRITE_TABLE:
    .word ALIEN_SPRITE_LARGE    # bottom 2 rows
    .word ALIEN_SPRITE_MEDIUM   # middle 2 rows
    .word ALIEN_SPRITE_SMALL    # top row

.align 2
ALIEN_COLOR_TABLE:
    .word 0xFFFF                # bottom 2 rows
    .word 0xFFFF                # middle 2 rows
    .word 0xFFFF                # top row

# Sprites
ALIEN_SPRITE_SMALL:
    .byte 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0    # .......**.......
    .byte 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0    # ......****......
    .byte 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0    # .....******.....
    .byte 0, 0, 0, 0, 1, 1, 0, 1, 1, 0, 1, 1, 0, 0, 0, 0    # ....**.**.**....
    .byte 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0    # ....********....
    .byte 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0    # ......*..*...... 
    .byte 0, 0, 0, 0, 0, 1, 0, 1, 1, 0, 1, 0, 0, 0, 0, 0    # .....*.**.*.....
    .byte 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0, 1, 0, 0, 0, 0    # ....*.*..*.*....
                                                       
    .byte 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0    # .......**.......
    .byte 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0    # ......****......
    .byte 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0    # .....******.....
    .byte 0, 0, 0, 0, 1, 1, 0, 1, 1, 0, 1, 1, 0, 0, 0, 0    # ....**.**.**....
    .byte 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0    # ....********....
    .byte 0, 0, 0, 0, 0, 1, 0, 1, 1, 0, 1, 0, 0, 0, 0, 0    # .....*.**.*.....
    .byte 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0    # ....*......*....
    .byte 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0    # .....*....*.....
                                                       
ALIEN_SPRITE_MEDIUM:
    .byte 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0    # .....*.....*....
    .byte 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0    # ...*..*...*..*..
    .byte 0, 0, 0, 1, 0, 1, 1, 1, 1, 1, 1, 0, 1, 0, 0, 0    # ...*.*******.*..
    .byte 0, 0, 0, 1, 1, 1, 0, 1, 1, 0, 1, 1, 1, 0, 0, 0    # ...***.***.***..
    .byte 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0    # ...***********..
    .byte 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0    # ....*********...
    .byte 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0    # .....*.....*....
    .byte 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0    # ....*.......*...
                                                       
    .byte 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0    # .....*.....*....
    .byte 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0    # ......*...*.....
    .byte 0, 0, 0, 1, 0, 1, 1, 1, 1, 1, 1, 0, 1, 0, 0, 0    # .....*******....
    .byte 0, 0, 0, 1, 1, 1, 0, 1, 1, 0, 1, 1, 1, 0, 0, 0    # ....**.***.**...
    .byte 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0    # ...***********..
    .byte 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0    # ...*.*******.*.. 
    .byte 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0    # ...*.*.....*.*..
    .byte 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0    # ......**.**.....

ALIEN_SPRITE_LARGE:
    .byte 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0    # ......****......
    .byte 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0    # ...**********...
    .byte 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0    # ..************..
    .byte 0, 0, 1, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 1, 0, 0    # ..***..**..***..
    .byte 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0    # ..************..
    .byte 0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0    # .....**..**.....
    .byte 0, 0, 0, 0, 1, 1, 0, 1, 1, 0, 1, 1, 0, 0, 0, 0    # ....**.**.**....
    .byte 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0    # ..**........**..

    .byte 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0    # ......****......
    .byte 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0    # ...**********...
    .byte 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0    # ..************..
    .byte 0, 0, 1, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 1, 0, 0    # ..***..**..***..
    .byte 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0    # ..************..
    .byte 0, 0, 0, 0, 1, 1, 1, 0, 0, 1, 1, 1, 0, 0, 0, 0    # ....***..***....
    .byte 0, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 0    # ...**..**..**...
    .byte 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0    # ....**....**....

ALIEN_SPRITE_EXPLOSION:
    .word 0x00000000, 0x00000000, 0x00000000, 0x00000000    # .....*...*......
    .word 0x00000000, 0x00000000, 0x00000000, 0x00000000    # ..*...*.*...*...
    .word 0x00000000, 0x00000000, 0x00000000, 0x00000000    # ...*.......*....
    .word 0x00000000, 0x00000000, 0x00000000, 0x00000000    # ....*.....*.....
    .word 0x00000000, 0x00000000, 0x00000000, 0x00000000    # .**.........**..
    .word 0x00000000, 0x00000000, 0x00000000, 0x00000000    # ....*.....*.....
    .word 0x00000000, 0x00000000, 0x00000000, 0x00000000    # ...*..*.*..*....
    .word 0x00000000, 0x00000000, 0x00000000, 0x00000000    # ..*..*...*..*...
