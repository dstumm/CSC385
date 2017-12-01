.text
.global INIT_INVASION, DRAW_INVASION, MOVE_INVASION, KILL_ALIEN
.global ALIEN_SPRITE_MEDIUM, ALIENS

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
            #mov r5, r23
			#call drawing_fill_rect
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
    # TODO: check if we should move at all

    movia r4, INVASION_STATE
    ldw r5, 0(r4)

    movia r6, INVASION_DIRECTION_MASK               # get direction
    and r6, r5, r6

    movia r7, ALIEN_SPRITE_STATE_MASK               # toggle sprite state
    xor r5, r5, r7
    stw r5, 0(r4)

    beq r6, r0, MOVE_INVASION_LEFT

    MOVE_INVASION_RIGHT:
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

ALIEN_BULLET_COLLISION:
    ret

# Get the position of an alien at the given index
#
# r4: alien index
#
# Returns a word with the aliens position formatted 0xYYYYXXXXX
#
# r2: position
GET_ALIEN_POSITION:
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

.data

.equ ALIEN_ROWS, 5
.equ ALIEN_COLS, 11
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
    .word 0

.align 2    
INVASION_LAST_MOVE: 
    .word 0

.align 2
INVASION_STATE: 
    .word 0

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
